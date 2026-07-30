import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class BillScreen extends StatefulWidget {
  final int orderId;
  const BillScreen({super.key, required this.orderId});
  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  Bill? _bill;
  bool _loading = true;
  bool _uploading = false;
  File? _slipFile;
  String _method = 'transfer';
  bool _slipUploaded = false;

  @override
  void initState() {
    super.initState();
    _generateBill();
  }

  Future<void> _generateBill() async {
    try {
      final bill = await ApiService().generateBill(widget.orderId);
      if (mounted) setState(() { _bill = bill; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickSlip() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _slipFile = File(picked.path));
  }

  Future<void> _uploadSlip() async {
    if (_slipFile == null || _bill == null) return;
    setState(() => _uploading = true);
    try {
      await ApiService().uploadPaymentSlip(_bill!.id, _slipFile!, _method);
      if (mounted) {
        setState(() { _uploading = false; _slipUploaded = true; });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ອັບໂຫລດສຳເລັດ · ລໍຖ້າການຢືນຢັນ'),
                backgroundColor: Color(0xFF4CAF50)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ອັບໂຫລດບໍ່ສຳເລັດ: $e'),
                backgroundColor: const Color(0xFFE94560)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('ບິນ & ຊຳລະເງິນ',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : _bill == null
              ? const Center(
                  child: Text('ບໍ່ສາມາດໂຫລດບິນໄດ້',
                      style: TextStyle(color: Colors.white54)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Bill card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long,
                                color: Color(0xFFE94560), size: 48),
                            const SizedBox(height: 8),
                            Text('ໂຕະ ${_bill!.tableNumber}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white12),
                            _row('ລວມກ່ອນສ່ວນຫຼຸດ',
                                '${_bill!.subtotal.toStringAsFixed(0)} ກີບ'),
                            if (_bill!.discount > 0)
                              _row('ສ່ວນຫຼຸດ',
                                  '- ${_bill!.discount.toStringAsFixed(0)} ກີບ',
                                  color: const Color(0xFF4CAF50)),
                            const Divider(color: Colors.white12),
                            _row('ລວມທັງໝົດ',
                                '${_bill!.total.toStringAsFixed(0)} ກີບ',
                                isTotal: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (!_slipUploaded) ...[
                        // Payment method selector
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16213E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ວິທີຊຳລະ',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 15)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _methodBtn('transfer', Icons.account_balance, 'ໂອນ'),
                                  const SizedBox(width: 12),
                                  _methodBtn('cash', Icons.payments, 'ເງິນສົດ'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Slip upload
                        GestureDetector(
                          onTap: _pickSlip,
                          child: Container(
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: _slipFile != null
                                      ? const Color(0xFF4CAF50)
                                      : Colors.white24,
                                  width: 2),
                            ),
                            child: _slipFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(_slipFile!, fit: BoxFit.cover),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.upload_file,
                                          color: Colors.white38, size: 48),
                                      SizedBox(height: 8),
                                      Text('ແຕະເພື່ອອັບໂຫລດສະລິບໂອນ',
                                          style: TextStyle(color: Colors.white38)),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _slipFile != null && !_uploading
                                ? _uploadSlip
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE94560),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: _uploading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.send, color: Colors.white),
                            label: Text(
                              _uploading ? 'ກຳລັງສົ່ງ...' : 'ສົ່ງຫຼັກຖານການຊຳລະ',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ] else
                        // Success state
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF4CAF50)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Color(0xFF4CAF50), size: 56),
                              SizedBox(height: 12),
                              Text('ສົ່ງຫຼັກຖານສຳເລັດ',
                                  style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('ລໍຖ້າການຢືນຢັນຈາກພະນັກງານ',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 14)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _row(String label, String value,
      {Color? color, bool isTotal = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: isTotal ? Colors.white : Colors.white54,
                    fontSize: isTotal ? 17 : 14,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
            Text(value,
                style: TextStyle(
                    color: color ?? (isTotal ? const Color(0xFFE94560) : Colors.white),
                    fontSize: isTotal ? 20 : 14,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );

  Widget _methodBtn(String value, IconData icon, String label) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _method = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _method == value
                  ? const Color(0xFFE94560).withOpacity(0.15)
                  : const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _method == value
                      ? const Color(0xFFE94560)
                      : Colors.transparent),
            ),
            child: Column(
              children: [
                Icon(icon,
                    color: _method == value
                        ? const Color(0xFFE94560)
                        : Colors.white54),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        color: _method == value
                            ? const Color(0xFFE94560)
                            : Colors.white54)),
              ],
            ),
          ),
        ),
      );
}
