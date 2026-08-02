import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'move_table_screen.dart';
import 'split_bill_screen.dart';
import 'merge_bill_screen.dart';

class TableOperationsScreen extends StatefulWidget {
  const TableOperationsScreen({super.key});

  @override
  State<TableOperationsScreen> createState() => _TableOperationsScreenState();
}

class _TableOperationsScreenState extends State<TableOperationsScreen> {
  final _api = ApiService();
  List<RestaurantTable> _tables = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _loading = true);
    try {
      final tables = await _api.getTables();
      setState(() {
        _tables = tables;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ໂຫລດໂຕະບໍ່ສຳເລັດ: $e'),
              backgroundColor: const Color(0xFFE94560)),
        );
      }
    }
  }

  Color _tableColor(String status) {
    switch (status) {
      case 'available': return const Color(0xFF4CAF50);
      case 'occupied': return const Color(0xFFE94560);
      case 'reserved': return const Color(0xFFFF9800);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available': return 'ວ່າງ';
      case 'occupied': return 'ມີລູກຄ້າ';
      case 'reserved': return 'ຈອງແລ້ວ';
      default: return status;
    }
  }

  void _showTableOptions(RestaurantTable table) {
    if (table.status == 'available') return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TableOptionsSheet(
        table: table,
        onMoveTable: () async {
          Navigator.pop(context);
          final orders = await _api.getOrders();
          final activeOrders = orders.where((o) =>
              o.tableNumber == table.tableNumber &&
              !['paid', 'cancelled'].contains(o.status)).toList();
          if (activeOrders.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ບໍ່ພົບອໍເດີສຳລັບໂຕະນີ້'),
                  backgroundColor: Color(0xFFE94560)),
            );
            return;
          }
          final order = activeOrders.first;
          if (!mounted) return;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MoveTableScreen(
                orderId: order.id,
                currentTableNumber: table.tableNumber,
              ),
            ),
          );
          if (result == true) _loadTables();
        },
        onSplitBill: () async {
          Navigator.pop(context);
          final orders = await _api.getOrders();
          final tableOrders = orders.where((o) =>
              o.tableNumber == table.tableNumber &&
              !['paid', 'cancelled'].contains(o.status)).toList();
          if (tableOrders.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ບໍ່ພົບອໍເດີສຳລັບໂຕະນີ້'),
                  backgroundColor: Color(0xFFE94560)),
            );
            return;
          }
          if (!mounted) return;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SplitBillScreen(
                orderId: tableOrders.first.id,
                tableNumber: table.tableNumber,
              ),
            ),
          );
          if (result == true) _loadTables();
        },
        onMergeBill: () async {
          Navigator.pop(context);
          final orders = await _api.getOrders();
          final tableOrders = orders.where((o) =>
              o.tableNumber == table.tableNumber &&
              !['paid', 'cancelled'].contains(o.status)).toList();
          if (tableOrders.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ບໍ່ພົບອໍເດີສຳລັບໂຕະນີ້'),
                  backgroundColor: Color(0xFFE94560)),
            );
            return;
          }
          if (!mounted) return;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MergeBillScreen(
                primaryOrderId: tableOrders.first.id,
                tableNumber: table.tableNumber,
              ),
            ),
          );
          if (result == true) _loadTables();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb || MediaQuery.of(context).size.width > 700;

    return Column(
      children: [
        // Top bar
        Container(
          color: const Color(0xFF16213E),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              const Text('ຈັດການໂຕະລູກຄ້າ',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadTables,
              ),
            ],
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _legend(const Color(0xFF4CAF50), 'ວ່າງ'),
              const SizedBox(width: 20),
              _legend(const Color(0xFFE94560), 'ມີລູກຄ້າ'),
              const SizedBox(width: 20),
              _legend(const Color(0xFFFF9800), 'ຈອງແລ້ວ'),
              const Spacer(),
              const Icon(Icons.touch_app, color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              const Text('ແຕະໂຕະທີ່ຕ້ອງການຈັດການ',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _statChip(
                '${_tables.where((t) => t.status == 'available').length}',
                'ວ່າງ',
                const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 10),
              _statChip(
                '${_tables.where((t) => t.status == 'occupied').length}',
                'ມີລູກຄ້າ',
                const Color(0xFFE94560),
              ),
              const SizedBox(width: 10),
              _statChip(
                '${_tables.length}',
                'ທັງໝົດ',
                Colors.white54,
              ),
            ],
          ),
        ),

        // Tables grid
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : RefreshIndicator(
                  onRefresh: _loadTables,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWeb ? 6 : 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: _tables.length,
                    itemBuilder: (_, i) {
                      final t = _tables[i];
                      final color = _tableColor(t.status);
                      final isOccupied = t.status == 'occupied';
                      return GestureDetector(
                        onTap: () => _showTableOptions(t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isOccupied
                                ? const Color(0xFF0F3460)
                                : const Color(0xFF16213E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color, width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Icon(Icons.table_restaurant,
                                      color: color,
                                      size: isWeb ? 40 : 34),
                                  if (isOccupied)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE94560),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t.tableNumber,
                                style: TextStyle(
                                    color: color,
                                    fontSize: isWeb ? 18 : 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _statusLabel(t.status),
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11),
                              ),
                              if (isOccupied) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE94560)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('ຈັດການ',
                                      style: TextStyle(
                                          color: Color(0xFFE94560),
                                          fontSize: 10)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) => Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );

  Widget _statChip(String count, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(count,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12)),
          ],
        ),
      );
}

// ── Bottom sheet for table options ────────────────────────────
class _TableOptionsSheet extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onMoveTable;
  final VoidCallback onSplitBill;
  final VoidCallback onMergeBill;

  const _TableOptionsSheet({
    required this.table,
    required this.onMoveTable,
    required this.onSplitBill,
    required this.onMergeBill,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_restaurant,
                  color: Color(0xFFE94560), size: 24),
              const SizedBox(width: 10),
              Text(
                'ໂຕະ ${table.tableNumber}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('ມີລູກຄ້າ',
                    style: TextStyle(
                        color: Color(0xFFE94560), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _optionTile(
            icon: Icons.swap_horiz,
            color: const Color(0xFF2196F3),
            title: 'ຍ້າຍໂຕະ',
            subtitle: 'ຍ້າຍລູກຄ້າໄປໂຕະອື່ນທີ່ຫວ່າງ',
            onTap: onMoveTable,
          ),
          const SizedBox(height: 10),
          _optionTile(
            icon: Icons.call_split,
            color: const Color(0xFFFF9800),
            title: 'ແຍກບິນ',
            subtitle: 'ແບ່ງລາຍການໃຫ້ລູກຄ້າຈ່າຍແຍກກັນ',
            onTap: onSplitBill,
          ),
          const SizedBox(height: 10),
          _optionTile(
            icon: Icons.merge,
            color: const Color(0xFF4CAF50),
            title: 'ລວມບິນ',
            subtitle: 'ລວມຫຼາຍໂຕະໃຫ້ຈ່າຍພ້ອມກັນ',
            onTap: onMergeBill,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      );
}
