import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});
  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ApiService().getStockItems();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isLow(dynamic item) {
    final qty = double.tryParse(item['quantity'].toString()) ?? 0;
    final threshold = double.tryParse(item['low_stock_threshold'].toString()) ?? 0;
    return qty <= threshold;
  }

  int? _daysUntilExpiry(dynamic item) {
    final expiryStr = item['expiry_date'];
    if (expiryStr == null) return null;
    final expiry = DateTime.tryParse(expiryStr.toString());
    if (expiry == null) return null;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return expiry.difference(todayDate).inDays;
  }

  String _categoryLabel(String? cat) {
    switch (cat) {
      case 'meat':
        return 'ຊີ້ນ';
      case 'vegetable':
        return 'ຜັກ';
      case 'seasoning':
        return 'ເຄື່ອງປຸງ';
      default:
        return 'ອື່ນໆ';
    }
  }

  IconData _categoryIcon(String? cat) {
    switch (cat) {
      case 'meat':
        return Icons.set_meal;
      case 'vegetable':
        return Icons.eco;
      case 'seasoning':
        return Icons.spa;
      default:
        return Icons.inventory_2;
    }
  }

  Future<void> _adjust(Map item, double delta) async {
    try {
      await ApiService().adjustStockItem(item['id'], delta);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: \$e'),
                backgroundColor: const Color(0xFFE94560)));
      }
    }
  }

  Future<void> _showItemDialog({Map? item}) async {
    final nameLaoCtrl = TextEditingController(text: item?['name_lao'] ?? '');
    final nameEnCtrl = TextEditingController(text: item?['name_en'] ?? '');
    final unitCtrl = TextEditingController(text: item?['unit']?.toString() ?? 'kg');
    final qtyCtrl = TextEditingController(text: item?['quantity']?.toString() ?? '0');
    final thresholdCtrl = TextEditingController(text: item?['low_stock_threshold']?.toString() ?? '1');
    String category = item?['category'] ?? 'meat';
    DateTime? expiryDate = item?['expiry_date'] != null ? DateTime.tryParse(item!['expiry_date'].toString()) : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Text(item == null ? 'ເພີ່ມວັດຖຸດິບ' : 'ແກ້ໄຂວັດຖຸດິບ',
              style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameLaoCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'ຊື່ (ລາວ)', labelStyle: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameEnCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'ຊື່ (English)', labelStyle: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'ໝວດໝູ່', labelStyle: TextStyle(color: Colors.white54)),
                  items: const [
                    DropdownMenuItem(value: 'meat', child: Text('ຊີ້ນ')),
                    DropdownMenuItem(value: 'vegetable', child: Text('ຜັກ')),
                    DropdownMenuItem(value: 'seasoning', child: Text('ເຄື່ອງປຸງ')),
                    DropdownMenuItem(value: 'other', child: Text('ອື່ນໆ')),
                  ],
                  onChanged: (v) => setDlg(() => category = v ?? 'meat'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'ຈຳນວນ', labelStyle: TextStyle(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'ຫົວໜ່ວຍ', labelStyle: TextStyle(color: Colors.white54)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: thresholdCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'ແຈ້ງເຕືອນເມື່ອຕ່ຳກວ່າ', labelStyle: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dCtx,
                      initialDate: expiryDate ?? DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setDlg(() => expiryDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'ວັນທີ່ໝົດອາຍຸ',
                      labelStyle: TextStyle(color: Colors.white54),
                      suffixIcon: Icon(Icons.calendar_today, color: Colors.white54, size: 18),
                    ),
                    child: Text(
                      expiryDate != null
                          ? '${expiryDate!.year}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}'
                          : 'ຄິດໄລ່ອັດຕະໂນມັດ',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dCtx, true),
              child: const Text('ບັນທຶກ', style: TextStyle(color: Color(0xFFE94560))),
            ),
          ],
        ),
      ),
    );

    if (result != true || nameLaoCtrl.text.trim().isEmpty) return;

    final data = {
      'name_lao': nameLaoCtrl.text.trim(),
      'name_en': nameEnCtrl.text.trim(),
      'category': category,
      'unit': unitCtrl.text.trim(),
      'quantity': double.tryParse(qtyCtrl.text) ?? 0,
      'low_stock_threshold': double.tryParse(thresholdCtrl.text) ?? 1,
      if (expiryDate != null)
        'expiry_date': '${expiryDate!.year}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}',
    };

    try {
      if (item == null) {
        await ApiService().createStockItem(data);
      } else {
        await ApiService().updateStockItem(item['id'], data);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: \$e'),
                backgroundColor: const Color(0xFFE94560)));
      }
    }
  }

  Future<void> _confirmDelete(Map item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('ລຶບວັດຖຸດິບ?', style: TextStyle(color: Colors.white)),
        content: Text("ຕ້ອງການລຶບ \"${item['name_lao']}\" ອອກແທ້ບໍ?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ລຶບ', style: TextStyle(color: Color(0xFFE94560)))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService().deleteStockItem(item['id']);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: \$e'),
                backgroundColor: const Color(0xFFE94560)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowCount = _items.where(_isLow).length;

    return Column(
      children: [
        Container(
          color: const Color(0xFF16213E),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const Text('ຄັງວັດຖຸດິບ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              if (lowCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFE94560), borderRadius: BorderRadius.circular(12)),
                  child: Text('\$lowCount ໃກ້ໝົດ', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showItemDialog(),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('ເພີ່ມວັດຖຸດິບ', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : _items.isEmpty
                  ? const Center(child: Text('ຍັງບໍ່ມີວັດຖຸດິບ', style: TextStyle(color: Colors.white54, fontSize: 16)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          final isLow = _isLow(item);
                          final qty = double.tryParse(item['quantity'].toString()) ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isLow ? const Color(0xFFE94560) : Colors.white10, width: isLow ? 2 : 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: (isLow ? const Color(0xFFE94560) : const Color(0xFF2196F3)).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(_categoryIcon(item['category']), color: isLow ? const Color(0xFFE94560) : const Color(0xFF2196F3), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name_lao'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text("${_categoryLabel(item['category'])} \u00b7 ${qty.toStringAsFixed(1)} ${item['unit']}",
                                          style: TextStyle(color: isLow ? const Color(0xFFE94560) : Colors.white54, fontSize: 12)),
                                      Builder(builder: (_) {
                                        final days = _daysUntilExpiry(item);
                                        if (days == null) return const SizedBox();
                                        final expired = days < 0;
                                        final soon = days <= 1;
                                        final label = expired ? 'ໝົດອາຍຸແລ້ວ' : (days == 0 ? 'ໝົດອາຍຸມື້ນີ້' : 'ອີກ $days ມື້ໝົດອາຍຸ');
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(label,
                                              style: TextStyle(
                                                  color: (expired || soon) ? const Color(0xFFE94560) : Colors.white38,
                                                  fontSize: 11,
                                                  fontWeight: (expired || soon) ? FontWeight.bold : FontWeight.normal)),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white54, size: 20),
                                  onPressed: () => _adjust(item, -1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.white54, size: 20),
                                  onPressed: () => _adjust(item, 1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFF2196F3), size: 18),
                                  onPressed: () => _showItemDialog(item: item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFE94560), size: 18),
                                  onPressed: () => _confirmDelete(item),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
