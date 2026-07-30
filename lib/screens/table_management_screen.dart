import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});
  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  List<RestaurantTable> _tables = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tables = await ApiService().getTables();
      setState(() { _tables = tables; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _showError('ໂຫລດໂຕະບໍ່ສຳເລັດ: $e');
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE94560)));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF4CAF50)));

  void _showDialog({RestaurantTable? table}) {
    final isEdit = table != null;
    final numCtrl = TextEditingController(text: table?.tableNumber ?? '');
    final capCtrl = TextEditingController(text: table?.capacity.toString() ?? '4');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(isEdit ? 'ແກ້ໄຂໂຕະ' : 'ເພີ່ມໂຕະ',
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('ໝາຍເລກໂຕະ (ເຊັ່ນ A1, B2)', numCtrl, Icons.table_restaurant),
            const SizedBox(height: 12),
            _field('ຈຳນວນທີ່ນັ່ງ', capCtrl, Icons.people,
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (isEdit) {
                  await ApiService().updateTable(table!.id, {
                    'table_number': numCtrl.text.trim(),
                    'capacity': int.tryParse(capCtrl.text) ?? 4,
                  });
                  _showSuccess('ແກ້ໄຂໂຕະສຳເລັດ');
                } else {
                  await ApiService().createTable(
                    tableNumber: numCtrl.text.trim(),
                    capacity: int.tryParse(capCtrl.text) ?? 4,
                  );
                  _showSuccess('ເພີ່ມໂຕະສຳເລັດ');
                }
                await _load();
              } catch (e) {
                _showError('ເກີດຂໍ້ຜິດພາດ: $e');
              }
            },
            child: Text(isEdit ? 'ບັນທຶກ' : 'ເພີ່ມ',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTable(RestaurantTable table) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('ລຶບໂຕະ', style: TextStyle(color: Colors.white)),
        content: Text('ຕ້ອງການລຶບໂຕະ ${table.tableNumber} ແທ້ບໍ?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ລຶບ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService().deleteTable(table.id);
        _showSuccess('ລຶບໂຕະສຳເລັດ');
        await _load();
      } catch (e) {
        _showError('ລຶບໂຕະບໍ່ສຳເລັດ: $e');
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available': return const Color(0xFF4CAF50);
      case 'occupied':  return const Color(0xFFE94560);
      case 'reserved':  return const Color(0xFFFF9800);
      default:          return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available': return 'ວ່າງ';
      case 'occupied':  return 'ມີລູກຄ້າ';
      case 'reserved':  return 'ຈອງແລ້ວ';
      default:          return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFF16213E),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const Text('ຈັດການໂຕະ',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showDialog(),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('ເພີ່ມໂຕະ', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _load,
              ),
            ],
          ),
        ),

        // Stats bar
        if (!_loading)
          Container(
            color: const Color(0xFF0F3460),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _stat('ທັງໝົດ', _tables.length.toString(), Colors.white70),
                const SizedBox(width: 24),
                _stat('ວ່າງ',
                    _tables.where((t) => t.status == 'available').length.toString(),
                    const Color(0xFF4CAF50)),
                const SizedBox(width: 24),
                _stat('ມີລູກຄ້າ',
                    _tables.where((t) => t.status == 'occupied').length.toString(),
                    const Color(0xFFE94560)),
              ],
            ),
          ),

        // Table list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : _tables.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.table_restaurant, color: Colors.white24, size: 80),
                          const SizedBox(height: 16),
                          const Text('ຍັງບໍ່ມີໂຕະ',
                              style: TextStyle(color: Colors.white54, fontSize: 18)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
                            onPressed: () => _showDialog(),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('ເພີ່ມໂຕະທຳອິດ',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tables.length,
                        itemBuilder: (_, i) {
                          final t = _tables[i];
                          final color = _statusColor(t.status);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.table_restaurant, color: color, size: 26),
                              ),
                              title: Text('ໂຕະ ${t.tableNumber}',
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Row(
                                children: [
                                  Icon(Icons.people, color: Colors.white38, size: 14),
                                  const SizedBox(width: 4),
                                  Text('${t.capacity} ທີ່ນັ່ງ',
                                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(_statusLabel(t.status),
                                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                                    onPressed: () => _showDialog(table: t),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Color(0xFFE94560), size: 20),
                                    onPressed: t.status == 'available'
                                        ? () => _deleteTable(t)
                                        : null,
                                  ),
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

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white54),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white24)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE94560))),
        ),
      );

  Widget _stat(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      );
}
