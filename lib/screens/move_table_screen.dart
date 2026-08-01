import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MoveTableScreen extends StatefulWidget {
  final int orderId;
  final String currentTableNumber;
  const MoveTableScreen({
    super.key,
    required this.orderId,
    required this.currentTableNumber,
  });

  @override
  State<MoveTableScreen> createState() => _MoveTableScreenState();
}

class _MoveTableScreenState extends State<MoveTableScreen> {
  final _api = ApiService();
  List<dynamic> _tables = [];
  bool _loading = true;
  bool _moving = false;
  int? _selectedTableId;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    try {
      final tables = await _api.getTables();
      setState(() {
        _tables = tables
            .where((t) =>
                t.tableNumber != widget.currentTableNumber &&
                t.status == 'available')
            .map((t) => {'id': t.id, 'table_number': t.tableNumber, 'capacity': t.capacity})
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _moveTable() async {
    if (_selectedTableId == null) return;
    setState(() => _moving = true);
    try {
      await _api.moveTable(widget.orderId, _selectedTableId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ຍ້າຍໂຕະສຳເລັດ'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ຍ້າຍໂຕະບໍ່ສຳເລັດ: $e'),
            backgroundColor: const Color(0xFFE94560),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          'ຍ້າຍໂຕະ · ໂຕະ ${widget.currentTableNumber}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white54, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'ເລືອກໂຕະໃໝ່ທີ່ຕ້ອງການຍ້າຍໄປ\n(ສະແດງສະເພາະໂຕະທີ່ຫວ່າງ)',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _tables.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.table_restaurant, color: Colors.white24, size: 60),
                              SizedBox(height: 12),
                              Text('ບໍ່ມີໂຕະຫວ່າງ',
                                  style: TextStyle(color: Colors.white54, fontSize: 16)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: _tables.length,
                          itemBuilder: (_, i) {
                            final t = _tables[i];
                            final selected = _selectedTableId == t['id'];
                            return GestureDetector(
                              onTap: () => setState(() => _selectedTableId = t['id']),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFE94560).withOpacity(0.15)
                                      : const Color(0xFF16213E),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFFE94560)
                                        : Colors.white12,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.table_restaurant,
                                      color: selected
                                          ? const Color(0xFFE94560)
                                          : Colors.white38,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'ໂຕະ ${t['table_number']}',
                                      style: TextStyle(
                                        color: selected ? const Color(0xFFE94560) : Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${t['capacity']} ທີ່ນັ່ງ',
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _selectedTableId != null && !_moving ? _moveTable : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE94560),
                        disabledBackgroundColor: Colors.white12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _moving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.swap_horiz, color: Colors.white),
                      label: Text(
                        _moving ? 'ກຳລັງຍ້າຍ...' : 'ຢືນຢັນຍ້າຍໂຕະ',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
