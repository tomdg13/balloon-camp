import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class MergeBillScreen extends StatefulWidget {
  final int primaryOrderId;
  final String tableNumber;
  const MergeBillScreen({
    super.key,
    required this.primaryOrderId,
    required this.tableNumber,
  });

  @override
  State<MergeBillScreen> createState() => _MergeBillScreenState();
}

class _MergeBillScreenState extends State<MergeBillScreen> {
  final _api = ApiService();
  final _money = NumberFormat.decimalPattern();
  List<dynamic> _orders = [];
  Set<int> _selectedIds = {};
  bool _loading = true;
  bool _merging = false;
  Map<String, dynamic>? _mergeResult;

  @override
  void initState() {
    super.initState();
    _selectedIds.add(widget.primaryOrderId); // primary always selected
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _api.getOrders();
      setState(() {
        _orders = orders
            .where((o) =>
                !['paid', 'cancelled'].contains(o.status) &&
                o.id != widget.primaryOrderId)
            .map((o) => {
                  'id': o.id,
                  'table_number': o.tableNumber ?? '',
                  'status': o.status,
                  'created_at': o.createdAt,
                })
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _mergeBills() async {
    if (_selectedIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ກະລຸນາເລືອກຢ່າງໜ້ອຍ 2 ອໍເດີ'),
          backgroundColor: Color(0xFFE94560),
        ),
      );
      return;
    }

    setState(() => _merging = true);
    try {
      final result = await _api.mergeBills(_selectedIds.toList());
      setState(() => _mergeResult = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ລວມບິນບໍ່ສຳເລັດ: $e'),
            backgroundColor: const Color(0xFFE94560),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _merging = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open': return 'ເປີດ';
      case 'sent_to_kitchen': return 'ສົ່ງຄົວ';
      case 'ready': return 'ພ້ອມ';
      case 'billed': return 'ອອກບິນແລ້ວ';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open': return Colors.blue;
      case 'sent_to_kitchen': return Colors.orange;
      case 'ready': return const Color(0xFF4CAF50);
      case 'billed': return const Color(0xFFE94560);
      default: return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          'ລວມບິນ · ໂຕະ ${widget.tableNumber}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : _mergeResult != null
              ? _buildResult()
              : _buildMerger(),
    );
  }

  Widget _buildMerger() {
    return Column(
      children: [
        // Primary order (always selected)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ອໍເດີຫຼັກ',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE94560)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.table_restaurant,
                        color: Color(0xFFE94560), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'ໂຕະ ${widget.tableNumber} · ອໍເດີ #${widget.primaryOrderId}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.check_circle,
                        color: Color(0xFFE94560), size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('ເລືອກອໍເດີທີ່ຕ້ອງການລວມ',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
        // Other orders
        Expanded(
          child: _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, color: Colors.white24, size: 60),
                      SizedBox(height: 12),
                      Text('ບໍ່ມີອໍເດີອື່ນທີ່ສາມາດລວມໄດ້',
                          style: TextStyle(color: Colors.white54, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _orders.length,
                  itemBuilder: (_, i) => _buildOrderTile(_orders[i]),
                ),
        ),
        // Bottom confirm
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF16213E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ອໍເດີທີ່ເລືອກ',
                      style: TextStyle(color: Colors.white54)),
                  Text(
                    '${_selectedIds.length} ອໍເດີ',
                    style: const TextStyle(
                        color: Color(0xFFE94560), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _selectedIds.length >= 2 && !_merging
                      ? _mergeBills
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _merging
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.merge, color: Colors.white),
                  label: Text(
                    _merging ? 'ກຳລັງລວມ...' : 'ຢືນຢັນລວມບິນ',
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

  Widget _buildOrderTile(dynamic order) {
    final id = order['id'] as int;
    final selected = _selectedIds.contains(id);
    final status = order['status'] as String;

    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE94560).withOpacity(0.1)
              : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFE94560) : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              color: selected ? const Color(0xFFE94560) : Colors.white38,
            ),
            const SizedBox(width: 12),
            Icon(Icons.table_restaurant,
                color: selected ? const Color(0xFFE94560) : Colors.white38,
                size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ໂຕະ ${order['table_number']} · ອໍເດີ #$id',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                          color: _statusColor(status), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 64),
            const SizedBox(height: 16),
            const Text('ລວມບິນສຳເລັດ',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _resultRow('ເລກບິນ', '#${_mergeResult!['bill_id']}'),
                  _resultRow('ອໍເດີທີ່ລວມ',
                      '${(_mergeResult!['merged_order_ids'] as List).join(', ')}'),
                  const Divider(color: Colors.white12, height: 24),
                  _resultRow(
                    'ລວມທັງໝົດ',
                    '${_money.format(_mergeResult!['total'])} ກີບ',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('ກັບຄືນ',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isTotal ? Colors.white : Colors.white54,
                  fontSize: isTotal ? 16 : 14)),
          Text(value,
              style: TextStyle(
                  color: isTotal ? const Color(0xFFE94560) : Colors.white,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 18 : 14)),
        ],
      ),
    );
  }
}
