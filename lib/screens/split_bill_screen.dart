import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

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
  Map<int, int> _itemGroup = {}; // item id -> group (1 or 2)
  bool _loading = true;
  bool _splitting = false;
  List<dynamic>? _splitResult;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final detail = await _api.getOrderDetail(widget.orderId);
      final items = List<dynamic>.from(detail['items'] ?? []);
      setState(() {
        _items = items.where((i) => i['cancelled'] != 1).toList();
        // Default all items to group 1
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

  Future<void> _splitBill() async {
    final group1 = _items
        .where((i) => _itemGroup[i['id']] == 1)
        .map((i) => i['id'] as int)
        .toList();
    final group2 = _items
        .where((i) => _itemGroup[i['id']] == 2)
        .map((i) => i['id'] as int)
        .toList();

    if (group1.isEmpty || group2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ກະລຸນາແບ່ງລາຍການໃຫ້ຄົບທັງ 2 ກຸ່ມ'),
          backgroundColor: Color(0xFFE94560),
        ),
      );
      return;
    }

    setState(() => _splitting = true);
    try {
      final result = await _api.splitBill(widget.orderId, [group1, group2]);
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
        // Group headers
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _groupHeader(1, const Color(0xFFE94560))),
              const SizedBox(width: 12),
              Expanded(child: _groupHeader(2, const Color(0xFF4CAF50))),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _items.length,
                  itemBuilder: (_, i) => _buildItemRow(_items[i]),
                ),
        ),
        // Bottom totals + confirm
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF16213E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _totalChip(
                      'ກຸ່ມ 1',
                      _groupTotal(1),
                      const Color(0xFFE94560),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _totalChip(
                      'ກຸ່ມ 2',
                      _groupTotal(2),
                      const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                    _splitting ? 'ກຳລັງແຍກ...' : 'ຢືນຢັນແຍກບິນ',
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

  Widget _groupHeader(int group, Color color) {
    final count = _groupItems(group).length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text('ກຸ່ມ $group',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text('$count ລາຍການ',
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    final group = _itemGroup[item['id']] ?? 1;
    final lineTotal = double.tryParse(item['line_total']?.toString() ?? '0') ?? 0;
    final isGroup1 = group == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGroup1
              ? const Color(0xFFE94560).withOpacity(0.3)
              : const Color(0xFF4CAF50).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Group badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isGroup1
                  ? const Color(0xFFE94560).withOpacity(0.15)
                  : const Color(0xFF4CAF50).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$group',
                style: TextStyle(
                  color: isGroup1 ? const Color(0xFFE94560) : const Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name_lao'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text(
                  '${item['quantity']}x · ${_money.format(lineTotal)} ກີບ',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          // Toggle group button
          GestureDetector(
            onTap: () => setState(() {
              _itemGroup[item['id']] = isGroup1 ? 2 : 1;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isGroup1
                    ? const Color(0xFF4CAF50).withOpacity(0.15)
                    : const Color(0xFFE94560).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isGroup1
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFE94560),
                ),
              ),
              child: Text(
                isGroup1 ? '→ ກຸ່ມ 2' : '→ ກຸ່ມ 1',
                style: TextStyle(
                  color: isGroup1 ? const Color(0xFF4CAF50) : const Color(0xFFE94560),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalChip(String label, double total, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            '${_money.format(total)} ກີບ',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
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
            const Text('ແຍກບິນສຳເລັດ',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ...(_splitResult ?? []).map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ກຸ່ມ ${s['group']}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600)),
                      Text(
                        '${_money.format(s['subtotal'])} ກີບ',
                        style: const TextStyle(
                            color: Color(0xFFE94560),
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ],
                  ),
                )),
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
}
