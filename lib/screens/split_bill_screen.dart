import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../utils/print_helper.dart';


String _fmtNum(double v) {
  final s = v.toStringAsFixed(0);
  final result = StringBuffer();
  final reversed = s.split('').reversed.toList();
  for (int i = 0; i < reversed.length; i++) {
    if (i > 0 && i % 3 == 0) result.write(',');
    result.write(reversed[i]);
  }
  return result.toString().split('').reversed.join();
}

class SplitBillScreen extends StatefulWidget {
  final int orderId;
  final String tableNumber;
  const SplitBillScreen({
    super.key,
    required this.orderId,
    required this.tableNumber,
  });

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  final _api = ApiService();
  final _money = NumberFormat.decimalPattern();
  List<dynamic> _items = [];
  Map<int, int> _itemGroup = {};
  int _totalGroups = 2; // start with 2 groups
  bool _loading = true;
  bool _splitting = false;
  List<dynamic>? _splitResult;
  String? _logoUrl;
  String? _bankQrUrl;

  // Colors for groups (supports up to 8 groups)
  static const List<Color> _groupColors = [
    Color(0xFFE94560), // group 1 - red
    Color(0xFF4CAF50), // group 2 - green
    Color(0xFF2196F3), // group 3 - blue
    Color(0xFFFF9800), // group 4 - orange
    Color(0xFF9C27B0), // group 5 - purple
    Color(0xFF00BCD4), // group 6 - cyan
    Color(0xFFFFEB3B), // group 7 - yellow
    Color(0xFFFF5722), // group 8 - deep orange
  ];

  Color _groupColor(int group) => _groupColors[(group - 1) % _groupColors.length];

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _api.getSettings();
      if (mounted) setState(() {
        _logoUrl = settings['logo_url'];
        _bankQrUrl = settings['bank_qr_url'];
      });
    } catch (_) {}
  }

  Future<void> _loadItems() async {
    try {
      final detail = await _api.getOrderDetail(widget.orderId);
      final items = List<dynamic>.from(detail['items'] ?? []);
      setState(() {
        _items = items.where((i) => i['cancelled'] != 1).toList();
        for (final item in _items) {
          _itemGroup[item['id']] = 1;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  double _groupTotal(int group) {
    double total = 0;
    for (final item in _items) {
      if (_itemGroup[item['id']] == group) {
        final price = double.tryParse(item['line_total']?.toString() ?? '0') ?? 0;
        total += price;
      }
    }
    return total;
  }

  List<dynamic> _groupItems(int group) =>
      _items.where((i) => _itemGroup[i['id']] == group).toList();

  void _addGroup() {
    setState(() => _totalGroups++);
  }

  void _removeGroup() {
    if (_totalGroups <= 2) return;
    // Move items from last group to group 1
    setState(() {
      for (final key in _itemGroup.keys.toList()) {
        if (_itemGroup[key] == _totalGroups) {
          _itemGroup[key] = 1;
        }
      }
      _totalGroups--;
    });
  }

  Future<void> _splitBill() async {
    // Build groups list
    final groups = <List<int>>[];
    for (int g = 1; g <= _totalGroups; g++) {
      final groupItems = _items
          .where((i) => _itemGroup[i['id']] == g)
          .map((i) => i['id'] as int)
          .toList();
      groups.add(groupItems);
    }

    // Check all groups have at least 1 item
    final emptyGroups = groups.asMap().entries
        .where((e) => e.value.isEmpty)
        .map((e) => e.key + 1)
        .toList();

    if (emptyGroups.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ກຸ່ມ ${emptyGroups.join(', ')} ຍັງບໍ່ມີລາຍການ'),
          backgroundColor: const Color(0xFFE94560),
        ),
      );
      return;
    }

    setState(() => _splitting = true);
    try {
      final result = await _api.splitBill(widget.orderId, groups);
      await _api.generateSplitBills(widget.orderId);
      setState(() => _splitResult = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ແຍກບິນບໍ່ສຳເລັດ: $e'),
            backgroundColor: const Color(0xFFE94560),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _splitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          'ແຍກບິນ · ໂຕະ ${widget.tableNumber}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : _splitResult != null
              ? _buildResult()
              : _buildSplitter(),
    );
  }

  Widget _buildSplitter() {
    return Column(
      children: [
        // Group headers with add/remove
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Group chips row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int g = 1; g <= _totalGroups; g++) ...[
                      _groupChip(g),
                      const SizedBox(width: 8),
                    ],
                    // Add group button
                    GestureDetector(
                      onTap: _addGroup,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: Colors.white54, size: 16),
                            SizedBox(width: 4),
                            Text('ເພີ່ມກຸ່ມ',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    if (_totalGroups > 2) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _removeGroup,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16213E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFE94560).withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.remove,
                                  color: Color(0xFFE94560), size: 16),
                              SizedBox(width: 4),
                              Text('ລຶບກຸ່ມ',
                                  style: TextStyle(
                                      color: Color(0xFFE94560),
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Items list
        Expanded(
          child: _items.isEmpty
              ? const Center(
                  child: Text('ບໍ່ມີລາຍການ',
                      style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _items.length,
                  itemBuilder: (_, i) => _buildItemRow(_items[i]),
                ),
        ),

        // Bottom totals + confirm
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF16213E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Group totals row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int g = 1; g <= _totalGroups; g++) ...[
                      _totalChip(g),
                      if (g < _totalGroups) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: !_splitting ? _splitBill : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _splitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.call_split, color: Colors.white),
                  label: Text(
                    _splitting
                        ? 'ກຳລັງແຍກ...'
                        : 'ຢືນຢັນແຍກ $_totalGroups ກຸ່ມ',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _groupChip(int group) {
    final color = _groupColor(group);
    final count = _groupItems(group).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text('ກຸ່ມ $group',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          Text('$count ລາຍການ',
              style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    final group = _itemGroup[item['id']] ?? 1;
    final lineTotal = double.tryParse(item['line_total']?.toString() ?? '0') ?? 0;
    final color = _groupColor(group);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Group badge
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$group',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 10),
          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name_lao'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text('${item['quantity']}x · ${_money.format(lineTotal)} ກີບ',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          // Group selector dropdown
          GestureDetector(
            onTap: () => _showGroupPicker(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ກຸ່ມ $group',
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: color, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupPicker(dynamic item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ເລືອກກຸ່ມສຳລັບ "${item['name_lao']}"',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int g = 1; g <= _totalGroups; g++)
                  GestureDetector(
                    onTap: () {
                      setState(() => _itemGroup[item['id']] = g);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _itemGroup[item['id']] == g
                            ? _groupColor(g).withValues(alpha: 0.2)
                            : const Color(0xFF0F3460),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _itemGroup[item['id']] == g
                              ? _groupColor(g)
                              : Colors.white12,
                          width: _itemGroup[item['id']] == g ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        'ກຸ່ມ $g',
                        style: TextStyle(
                          color: _groupColor(g),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _totalChip(int group) {
    final color = _groupColor(group);
    final total = _groupTotal(group);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ກຸ່ມ $group',
              style: TextStyle(color: color, fontSize: 11)),
          Text('${_money.format(total)} ກີບ',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final paidGroups = <int>{};

    return StatefulBuilder(
      builder: (context, setLocalState) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.call_split, color: Color(0xFF4CAF50), size: 56),
            const SizedBox(height: 12),
            const Text('ແຍກບິນສຳເລັດ',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            Text('ແຍກເປັນ ${_splitResult!.length} ກຸ່ມ',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 24),
            ...(_splitResult ?? []).asMap().entries.map((entry) {
              final s = entry.value;
              final group = s['group'] as int;
              final subtotal = (s['subtotal'] as num).toDouble();
              final color = _groupColor(group);
              final isPaid = paidGroups.contains(group);
              final groupItems = _items
                  .where((item) => _itemGroup[item['id']] == group)
                  .toList();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isPaid
                        ? const Color(0xFF4CAF50)
                        : color.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    // Group header
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(13)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.group, color: color, size: 18),
                          const SizedBox(width: 8),
                          Text('ກຸ່ມ $group',
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const Spacer(),
                          Text('${_money.format(subtotal)} ກີບ',
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                    // Items
                    ...groupItems.map((item) {
                      final lineTotal = double.tryParse(
                              item['line_total']?.toString() ?? '0') ??
                          0;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            Text('${item['quantity']}x',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(item['name_lao'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13)),
                            ),
                            Text('${_money.format(lineTotal)} ກີບ',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    // Print + Pay buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await _printGroupBill(
                                      group, subtotal, groupItems);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Color(0xFF2196F3)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.print,
                                    color: Color(0xFF2196F3), size: 18),
                                label: const Text('ພິມບິນ',
                                    style: TextStyle(
                                        color: Color(0xFF2196F3),
                                        fontSize: 13)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: isPaid
                                    ? null
                                    : () => _payGroup(
                                        group,
                                        subtotal,
                                        groupItems,
                                        () => setLocalState(
                                            () => paidGroups.add(group))),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPaid
                                      ? Colors.white12
                                      : const Color(0xFF4CAF50),
                                  disabledBackgroundColor: Colors.white12,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                icon: Icon(
                                    isPaid
                                        ? Icons.check_circle
                                        : Icons.payments,
                                    color: Colors.white,
                                    size: 18),
                                label: Text(
                                  isPaid ? 'ຊຳລະແລ້ວ' : 'ຊຳລະ',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_back,
                    color: Colors.white54, size: 18),
                label: const Text('ກັບຄືນ',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printGroupBill(
      int group, double subtotal, List<dynamic> items) async {
    if (_logoUrl == null && _bankQrUrl == null) await _loadSettings();

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final itemRows = StringBuffer();
    for (final item in items) {
      final lineTotal =
          double.tryParse(item['line_total']?.toString() ?? '0') ?? 0;
      itemRows.write("""
        <tr>
          <td>${item['quantity']}x</td>
          <td>${item['name_lao'] ?? ''}</td>
          <td style="text-align:right">${_fmtNum(lineTotal)}</td>
        </tr>""");
    }

    final logoHtml = _logoUrl != null
        ? '<img src="$_logoUrl" style="width:72px;height:72px;object-fit:contain;display:block;margin:0 auto 6px;">'
        : '<div style="font-size:28px;text-align:center;">🎈</div>';

    final qrHtml = _bankQrUrl != null
        ? '''<div style="text-align:center;margin:12px 0;">
            <img src="$_bankQrUrl" style="width:150px;height:150px;object-fit:contain;">
            <div style="font-size:11px;color:#666;margin-top:4px;">ສະແກນເພື່ອຊຳລະ · PromptPay / BCEL / LDB</div>
           </div>'''
        : '';

    final html = """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ບິນ ກຸ່ມ $group · ໂຕະ ${widget.tableNumber}</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Lao&display=swap');
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family: 'Noto Sans Lao', sans-serif; width:300px; margin:0 auto; padding:16px; font-size:13px; }
  h2 { text-align:center; font-size:18px; margin-bottom:4px; }
  .sub { text-align:center; color:#666; font-size:11px; margin-bottom:4px; }
  .group-badge { background:#e94560; color:white; padding:4px 16px; border-radius:20px; font-size:12px; font-weight:bold; display:inline-block; margin:6px auto 12px; }
  .divider { border-top:1px dashed #000; margin:8px 0; }
  table { width:100%; border-collapse:collapse; }
  td { padding:4px 2px; vertical-align:top; }
  td:first-child { width:30px; }
  td:last-child { width:80px; }
  .total-row { font-size:16px; font-weight:bold; }
  .total-row td { padding-top:8px; }
  .footer { text-align:center; margin-top:16px; font-size:11px; color:#666; }
  @media print { body { width:100%; } button { display:none; } }
</style>
</head>
<body>
$logoHtml
<h2>Balloon Camp</h2>
<div class="sub">ໂຕະ ${widget.tableNumber} · $dateStr</div>
<div style="text-align:center"><span class="group-badge">ກຸ່ມ $group</span></div>
<div class="divider"></div>
<table>
  <tr style="font-weight:bold; border-bottom:1px solid #000">
    <td>ຈຳ</td><td>ລາຍການ</td><td style="text-align:right">ກີບ</td>
  </tr>
  $itemRows
  <tr class="total-row">
    <td colspan="2">ລວມທັງໝົດ</td>
    <td style="text-align:right">${_fmtNum(subtotal)}</td>
  </tr>
</table>
<div class="divider"></div>
$qrHtml
<div class="footer">ຂອບໃຈທີ່ໃຊ້ບໍລິການ 🙏</div>
<br>
<button onclick="window.print()" style="width:100%;padding:10px;background:#e94560;color:white;border:none;border-radius:8px;font-size:14px;cursor:pointer">🖨️ ພິມ</button>
<script>setTimeout(()=>window.print(),500);</script>
</body>
</html>""";

    if (kIsWeb) openHtmlInNewTab(html);
  }

  void _payGroup(int group, double subtotal, List<dynamic> items,
      VoidCallback onPaid) async {
    int? billId;
    try {
      final bills = await _api.getBillsByOrderSplit(widget.orderId);
      final groupBill = bills.firstWhere(
        (b) => b['split_group'] == group,
        orElse: () => null,
      );
      if (groupBill != null) billId = groupBill['id'] as int?;
    } catch (_) {}

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GroupPaySheet(
        group: group,
        subtotal: subtotal,
        items: items,
        orderId: widget.orderId,
        billId: billId,
        bankQrUrl: _bankQrUrl,
        groupColor: _groupColor(group),
        onPaid: onPaid,
      ),
    );
  }
}

// ── Group Payment Bottom Sheet ────────────────────────────────
class _GroupPaySheet extends StatefulWidget {
  final int group;
  final double subtotal;
  final List<dynamic> items;
  final int orderId;
  final int? billId;
  final String? bankQrUrl;
  final Color groupColor;
  final VoidCallback onPaid;

  const _GroupPaySheet({
    required this.group,
    required this.subtotal,
    required this.items,
    required this.orderId,
    this.billId,
    required this.bankQrUrl,
    required this.groupColor,
    required this.onPaid,
  });

  @override
  State<_GroupPaySheet> createState() => _GroupPaySheetState();
}

class _GroupPaySheetState extends State<_GroupPaySheet> {
  final _api = ApiService();
  final _money = NumberFormat.decimalPattern();
  final _cashCtrl = TextEditingController();
  String _method = 'cash';
  double _change = 0;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _cashCtrl.addListener(_calcChange);
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  void _calcChange() {
    final paid = double.tryParse(_cashCtrl.text) ?? 0;
    setState(() => _change = paid - widget.subtotal);
  }

  Future<void> _confirmPay() async {
    setState(() => _paying = true);
    try {
      Bill bill;
      if (widget.billId != null) {
        bill = await _api.getBill(widget.billId!);
      } else {
        try {
          bill = await _api.generateBill(widget.orderId);
        } on DioException catch (e) {
          if (e.response?.statusCode == 409) {
            final existingId = await _api.getBillIdByOrder(widget.orderId);
            if (existingId == null) rethrow;
            bill = await _api.getBill(existingId);
          } else {
            rethrow;
          }
        }
      }
      await _api.verifyPayment(bill.id, 'approved',
          note: _method == 'cash'
              ? 'ແຍກບິນ ກຸ່ມ ${widget.group} · ເງິນສົດ · ທອນ ${_fmtNum(_change)}'
              : 'ແຍກບິນ ກຸ່ມ ${widget.group} · $_method',
          paymentMethod: _method);
      if (mounted) {
        Navigator.pop(context);
        widget.onPaid();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ກຸ່ມ ${widget.group} ຊຳລະສຳເລັດ ✓'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('ຊຳລະບໍ່ສຳເລັດ: $e'),
              backgroundColor: const Color(0xFFE94560)),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  bool _canPay() {
    if (_method == 'cash') return _change >= 0 && _cashCtrl.text.isNotEmpty;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: widget.groupColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${widget.group}',
                      style: TextStyle(
                          color: widget.groupColor,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Text('ຊຳລະ ກຸ່ມ ${widget.group}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${_money.format(widget.subtotal)} ກີບ',
                  style: TextStyle(
                      color: widget.groupColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _methodBtn('cash', Icons.payments, 'ເງິນສົດ'),
              const SizedBox(width: 8),
              _methodBtn('qr', Icons.qr_code, 'QR'),
              const SizedBox(width: 8),
              _methodBtn('pos', Icons.credit_card, 'POS'),
            ]),
            const SizedBox(height: 16),
            if (_method == 'cash') ...[
              TextField(
                controller: _cashCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'ຈຳນວນທີ່ຈ່າຍ',
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
              Wrap(spacing: 8, runSpacing: 8, children: [
                ...[5000, 10000, 20000, 50000, 100000, 200000]
                    .where((v) => v >= widget.subtotal)
                    .take(4)
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
                            child: Text(
                                '${(v / 1000).toStringAsFixed(0)}K',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ),
                        )),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _change >= 0
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                      : const Color(0xFFE94560).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _change >= 0
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                          : const Color(0xFFE94560).withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Text(_change >= 0 ? 'ເງິນທອນ' : 'ຍັງຂາດ',
                      style: TextStyle(
                          color: _change >= 0
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE94560),
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${_fmtNum(_change.abs())} ກີບ',
                      style: TextStyle(
                          color: _change >= 0
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE94560),
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
            if (_method == 'qr' && widget.bankQrUrl != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Image.network(widget.bankQrUrl!,
                      width: 180, height: 180, fit: BoxFit.contain),
                  const SizedBox(height: 6),
                  Text('${_money.format(widget.subtotal)} ກີບ',
                      style: const TextStyle(
                          color: Color(0xFFE94560),
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const Text('PromptPay / BCEL / LDB',
                      style:
                          TextStyle(color: Colors.black54, fontSize: 11)),
                ]),
              ),
            ],
            if (_method == 'pos') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFF0F3460),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.credit_card,
                      color: Color(0xFF2196F3), size: 28),
                  const SizedBox(width: 12),
                  Text('${_money.format(widget.subtotal)} ກີບ',
                      style: const TextStyle(
                          color: Color(0xFFE94560),
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _canPay() && !_paying ? _confirmPay : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  disabledBackgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: _paying
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle, color: Colors.white),
                label: Text(
                  _paying
                      ? 'ກຳລັງດຳເນີນການ...'
                      : 'ຢືນຢັນຊຳລະ ກຸ່ມ ${widget.group}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _methodBtn(String method, IconData icon, String label) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _method = method),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _method == method
                  ? const Color(0xFFE94560).withValues(alpha: 0.15)
                  : const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _method == method
                      ? const Color(0xFFE94560)
                      : Colors.transparent),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  color: _method == method
                      ? const Color(0xFFE94560)
                      : Colors.white54,
                  size: 20),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      color: _method == method
                          ? const Color(0xFFE94560)
                          : Colors.white54,
                      fontSize: 11)),
            ]),
          ),
        ),
      );
}
