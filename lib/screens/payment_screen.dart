import 'package:cached_network_image/cached_network_image.dart';
import '../utils/print_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../models/models.dart';

class PaymentScreen extends StatefulWidget {
  final String tableNumber;
  final int tableId;
  const PaymentScreen({super.key, required this.tableNumber, required this.tableId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _payMethod = 'cash';
  final _cashCtrl = TextEditingController();
  double _change = 0;
  double _totalAmt = 0;
  dynamic _slipFile; // File or Uint8List for web
  bool _submitting = false;
  bool _paid = false;
  String? _bankQrUrl;

  @override
  void initState() {
    super.initState();
    _cashCtrl.addListener(_calcChange);
    _load();
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  void _calcChange() {
    final paid = double.tryParse(_cashCtrl.text) ?? 0;
    setState(() => _change = paid - _totalAmt);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final allOrders = await ApiService().getOrders();
      final tableOrders = allOrders.where((o) =>
          o.tableNumber == widget.tableNumber &&
          o.status != 'paid' && o.status != 'cancelled').toList();

      final details = <Map<String, dynamic>>[];
      for (final o in tableOrders) {
        try {
          final d = await ApiService().getOrderDetail(o.id);
          details.add(d);
        } catch (_) {}
      }

      // Load bank QR
      try {
        final settings = await ApiService().getSettings();
        if (mounted) setState(() => _bankQrUrl = settings['bank_qr_url']);
      } catch (_) {}

      double total = 0;
      for (final o in details) {
        total += double.tryParse(o['total']?.toString() ?? '0') ?? 0;
      }

      setState(() {
        _orders = details;
        _totalAmt = total;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickSlip() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() => _slipFile = bytes);
    } else {
      setState(() => _slipFile = File(picked.path));
    }
  }

  Future<void> _confirmPayment() async {
    setState(() => _submitting = true);
    try {
      // Generate bills for all orders and verify
      for (final order in _orders) {
        final orderId = order['id'] as int;
        // Generate bill
        final bill = await ApiService().generateBill(orderId);
        // If slip uploaded, upload it
        if (_slipFile != null) {
          if (kIsWeb) {
          } else {
            await ApiService().uploadPaymentSlip(bill.id, _slipFile, _payMethod);
          }
        }
        // Verify payment
        await ApiService().verifyPayment(bill.id, 'approved',
            note: _payMethod == 'cash'
                ? 'ເງິນສົດ · ຈ່າຍ ${_cashCtrl.text} · ທອນ ${_change.toStringAsFixed(0)}'
                : _payMethod);
      }
      setState(() { _submitting = false; _paid = true; });
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ຊຳລະບໍ່ສຳເລັດ: $e'),
              backgroundColor: const Color(0xFFE94560)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_paid) return _PaidSuccess(tableNumber: widget.tableNumber);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text('ຊຳລະເງິນ · ໂຕະ ${widget.tableNumber}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.print, color: Colors.white),
              onPressed: _loading ? null : _print),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Bill summary ──────────────────────────────
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    // Bill header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(children: [
                        const Text('🎈 Balloon Camp',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('ໂຕະ ${widget.tableNumber}',
                            style: const TextStyle(color: Colors.white54, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} '
                          '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    // Order items
                    ..._orders.map((order) {
                      final items = order['items'] as List? ?? [];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                            child: Row(children: [
                              Text('ອໍເດີ #${order['id']}',
                                  style: const TextStyle(color: Colors.white70,
                                      fontWeight: FontWeight.bold, fontSize: 13)),
                              const Spacer(),
                              Text('${items.length} ລາຍການ',
                                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            ]),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ...items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                child: Row(children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text('${item['quantity']}x',
                                        style: const TextStyle(
                                            color: Color(0xFFE94560),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                  Expanded(
                                    child: Text(item['name_lao'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 13)),
                                  ),
                                  Text(
                                    '${double.tryParse(item['line_total']?.toString() ?? '0')!.toStringAsFixed(0)} ກີບ',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ]),
                              )),
                          const Divider(color: Colors.white10, height: 1),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                            child: Row(children: [
                              const Text('ລວມ',
                                  style: TextStyle(color: Colors.white54, fontSize: 13)),
                              const Spacer(),
                              Text(
                                '${double.tryParse(order['total']?.toString() ?? '0')!.toStringAsFixed(0)} ກີບ',
                                style: const TextStyle(
                                    color: Color(0xFFE94560),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ]),
                          ),
                        ]),
                      );
                    }),

                    // Grand total
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE94560).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE94560).withValues(alpha: 0.4)),
                      ),
                      child: Row(children: [
                        const Text('ລວມທັງໝົດ',
                            style: TextStyle(color: Colors.white,
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${_totalAmt.toStringAsFixed(0)} ກີບ',
                            style: const TextStyle(
                                color: Color(0xFFE94560),
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ]),
                ),
              ),

              // ── Payment panel ─────────────────────────────
              Container(
                width: 320,
                decoration: const BoxDecoration(
                  color: Color(0xFF16213E),
                  border: Border(left: BorderSide(color: Colors.white10)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('ວິທີຊຳລະ',
                        style: TextStyle(color: Colors.white,
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Payment method selector
                    Row(children: [
                      _methodBtn('cash', Icons.payments, 'ເງິນສົດ'),
                      const SizedBox(width: 8),
                      _methodBtn('qr', Icons.qr_code, 'Scan QR'),
                      const SizedBox(width: 8),
                      _methodBtn('pos', Icons.credit_card, 'POS Card'),
                    ]),
                    const SizedBox(height: 20),

                    // Cash method
                    if (_payMethod == 'cash') ...[
                      const Text('ລູກຄ້າຈ່າຍ',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cashCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: const TextStyle(color: Colors.white38),
                          suffixText: 'ກີບ',
                          suffixStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF0F3460),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Quick amount buttons
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        ...[1000, 2000, 5000, 10000, 20000, 50000, 100000]
                            .where((v) => v >= _totalAmt)
                            .take(6)
                            .map((v) => GestureDetector(
                                  onTap: () {
                                    _cashCtrl.text = v.toString();
                                    _calcChange();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F3460),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Text('${(v / 1000).toStringAsFixed(0)}K',
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 12)),
                                  ),
                                )),
                      ]),
                      const SizedBox(height: 16),
                      // Change display
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _change >= 0
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                              : const Color(0xFFE94560).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _change >= 0
                                  ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                                  : const Color(0xFFE94560).withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          Text(
                            _change >= 0 ? 'ເງິນທອນ' : 'ຍັງຂາດ',
                            style: TextStyle(
                                color: _change >= 0
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFE94560),
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            '${_change.abs().toStringAsFixed(0)} ກີບ',
                            style: TextStyle(
                                color: _change >= 0
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFE94560),
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ]),
                      ),
                    ],

                    // QR slip upload
                    if (_payMethod == 'qr') ...[
                      const Text('ອັບໂຫລດສະລິບໂອນ',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      _slipUploadWidget(),
                    ],

                    // POS slip upload
                    if (_payMethod == 'pos') ...[
                      const Text('ອັບໂຫລດໃບ POS',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      _slipUploadWidget(),
                    ],

                    const SizedBox(height: 16),

                    // Print button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _print,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2196F3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.print, color: Color(0xFF2196F3), size: 18),
                        label: const Text('ພິມໃບບິນ',
                            style: TextStyle(color: Color(0xFF2196F3), fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _canPay() && !_submitting ? _confirmPayment : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          disabledBackgroundColor: Colors.white12,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _submitting
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle, color: Colors.white),
                        label: Text(
                          _submitting ? 'ກຳລັງດຳເນີນການ...' : 'ຢືນຢັນການຊຳລະ',
                          style: const TextStyle(color: Colors.white, fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
    );
  }

  bool _canPay() {
    if (_orders.isEmpty) return false;
    if (_payMethod == 'cash') {
      return _change >= 0 && _cashCtrl.text.isNotEmpty;
    }
    return true; // QR and POS can pay without slip
  }

  Widget _methodBtn(String method, IconData icon, String label) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() { _payMethod = method; _slipFile = null; }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _payMethod == method
                  ? const Color(0xFFE94560).withValues(alpha: 0.15)
                  : const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _payMethod == method
                      ? const Color(0xFFE94560)
                      : Colors.transparent,
                  width: 1.5),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  color: _payMethod == method
                      ? const Color(0xFFE94560)
                      : Colors.white54, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: _payMethod == method
                          ? const Color(0xFFE94560)
                          : Colors.white54,
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );

  Widget _slipUploadWidget() => GestureDetector(
        onTap: _pickSlip,
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF0F3460),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _slipFile != null
                    ? const Color(0xFF4CAF50)
                    : Colors.white24,
                width: 1.5),
          ),
          child: _slipFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: kIsWeb
                      ? Image.memory(_slipFile, fit: BoxFit.cover)
                      : Image.file(_slipFile, fit: BoxFit.cover),
                )
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    _payMethod == 'qr' ? Icons.qr_code_scanner : Icons.receipt,
                    color: Colors.white38, size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _payMethod == 'qr' ? 'ແຕະເພື່ອອັບໂຫລດສະລິບ' : 'ແຕະເພື່ອອັບໂຫລດໃບ POS',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text('(ບໍ່ຈຳເປັນ)',
                      style: TextStyle(color: Colors.white24, fontSize: 10)),
                ]),
        ),
      );

  void _print() {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year} ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';

    // Build HTML bill for printing
    final itemRows = StringBuffer();
    for (final o in _orders) {
      final items = o['items'] as List? ?? [];
      for (final item in items) {
        final lineTotal = double.tryParse(item['line_total']?.toString() ?? '0') ?? 0;
        itemRows.write("""
          <tr>
            <td>${item['quantity']}x</td>
            <td>${item['name_lao'] ?? ''}</td>
            <td style="text-align:right">${lineTotal.toStringAsFixed(0)}</td>
          </tr>""");
      }
      itemRows.write("""
        <tr class="subtotal">
          <td colspan="2">ລວມ #${o['id']}</td>
          <td style="text-align:right">${double.tryParse(o['total']?.toString() ?? '0')!.toStringAsFixed(0)}</td>
        </tr>""");
    }

    final html = """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Bill - ໂຕະ ${widget.tableNumber}</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Lao&display=swap');
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family: 'Noto Sans Lao', sans-serif; width:300px; margin:0 auto; padding:16px; font-size:13px; }
  h2 { text-align:center; font-size:18px; margin-bottom:4px; }
  .sub { text-align:center; color:#666; font-size:11px; margin-bottom:12px; }
  .divider { border-top:1px dashed #000; margin:8px 0; }
  table { width:100%; border-collapse:collapse; }
  td { padding:3px 2px; vertical-align:top; }
  td:first-child { width:30px; }
  td:last-child { width:80px; }
  .subtotal td { color:#666; font-size:11px; border-top:1px solid #eee; }
  .total-row { font-size:16px; font-weight:bold; }
  .total-row td { padding-top:8px; }
  .footer { text-align:center; margin-top:16px; font-size:11px; color:#666; }
  @media print {
    body { width:100%; }
    button { display:none; }
  }
</style>
</head>
<body>
<h2>🎈 Balloon Camp</h2>
<div class="sub">ໂຕະ ${widget.tableNumber} · $dateStr</div>
<div class="divider"></div>
<table>
  <tr style="font-weight:bold; border-bottom:1px solid #000">
    <td>ຈຳ</td><td>ລາຍການ</td><td style="text-align:right">ກີບ</td>
  </tr>
  $itemRows
  <tr class="total-row">
    <td colspan="2">ລວມທັງໝົດ</td>
    <td style="text-align:right">${_totalAmt.toStringAsFixed(0)}</td>
  </tr>
</table>
<div class="divider"></div>
<div class="footer">ຂອບໃຈທີ່ໃຊ້ບໍລິການ 🙏</div>
<br>
<button onclick="window.print()" style="width:100%;padding:10px;background:#e94560;color:white;border:none;border-radius:8px;font-size:14px;cursor:pointer">🖨️ ພິມ</button>
<script>setTimeout(()=>window.print(),500);</script>
</body>
</html>""";

    // Open in new window
    if (kIsWeb) {
      openHtmlInNewTab(html);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ການພິມໃຊ້ໄດ້ສະເພາະ Web'),
            backgroundColor: Color(0xFF2196F3)),
      );
    }
  }
}

// ── Payment Success ───────────────────────────────────────────
class _PaidSuccess extends StatelessWidget {
  final String tableNumber;
  const _PaidSuccess({required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 80),
          ),
          const SizedBox(height: 24),
          const Text('ຊຳລະສຳເລັດ!',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('ໂຕະ $tableNumber ວ່າງແລ້ວ',
              style: const TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 48),
          SizedBox(
            width: 280,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil('/main', (r) => false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.table_restaurant, color: Colors.white),
              label: const Text('ກັບໄປໜ້າຫຼັກ',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}
