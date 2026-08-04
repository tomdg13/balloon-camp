import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../services/api_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});
  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String _selectedCategory = 'meat';
  final Map<int, bool> _uploadingImage = {};

  final _categories = const [
    {'value': 'meat', 'label': 'ຊີ້ນ'},
    {'value': 'vegetable', 'label': 'ຜັກ'},
    {'value': 'seasoning', 'label': 'ເຄື່ອງປຸງ'},
    {'value': 'other', 'label': 'ອື່ນໆ'},
  ];

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

  Future<void> _uploadImage(dynamic item) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null) return;
    final itemId = item['id'] as int;
    setState(() => _uploadingImage[itemId] = true);
    try {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await ApiService().uploadStockImageBytes(itemId, bytes, picked.name);
      } else {
        await ApiService().uploadStockImage(itemId, File(picked.path));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload error: $e'), backgroundColor: const Color(0xFFE94560)));
      }
    } finally {
      if (mounted) setState(() => _uploadingImage.remove(itemId));
    }
  }

  List<dynamic> get _currentItems =>
      _items.where((it) => it['category'] == _selectedCategory).toList();

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


  Future<void> _quickAddPurchase(dynamic item) async {
    final qtyCtrl = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text("Buy today: ${item['name_lao']}", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: qtyCtrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 20),
          decoration: InputDecoration(
            labelText: "Quantity (${item['unit']})",
            labelStyle: const TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(qtyCtrl.text);
              Navigator.pop(dCtx, v);
            },
            child: const Text('Add', style: TextStyle(color: Color(0xFFE94560))),
          ),
        ],
      ),
    );

    if (result == null || result <= 0) return;

    try {
      await ApiService().adjustStockItem(item['id'], result);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Added $result ${item['unit']} of ${item['name_lao']}"),
                backgroundColor: const Color(0xFF4CAF50)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: \$e'), backgroundColor: const Color(0xFFE94560)));
      }
    }
  }

  Future<void> _showItemDialog({dynamic item}) async {
    final nameLaoCtrl = TextEditingController(text: item?['name_lao'] ?? '');
    final nameEnCtrl = TextEditingController(text: item?['name_en'] ?? '');
    final unitCtrl = TextEditingController(text: item?['unit']?.toString() ?? 'kg');
    final qtyCtrl = TextEditingController(text: item?['quantity']?.toString() ?? '0');
    final thresholdCtrl = TextEditingController(text: item?['low_stock_threshold']?.toString() ?? '1');
    String category = item?['category'] ?? _selectedCategory;
    DateTime? expiryDate = item?['expiry_date'] != null ? DateTime.tryParse(item['expiry_date'].toString()) : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Text(item == null ? 'Add ingredient' : 'Edit ingredient',
              style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameLaoCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Name (Lao)', labelStyle: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameEnCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Name (English)', labelStyle: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: Colors.white54)),
                  items: const [
                    DropdownMenuItem(value: 'meat', child: Text('Meat')),
                    DropdownMenuItem(value: 'vegetable', child: Text('Vegetable')),
                    DropdownMenuItem(value: 'seasoning', child: Text('Seasoning')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
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
                        decoration: const InputDecoration(labelText: 'Quantity', labelStyle: TextStyle(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Unit', labelStyle: TextStyle(color: Colors.white54)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: thresholdCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Low stock alert below', labelStyle: TextStyle(color: Colors.white54)),
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
                      labelText: 'Expiry date',
                      labelStyle: TextStyle(color: Colors.white54),
                      suffixIcon: Icon(Icons.calendar_today, color: Colors.white54, size: 18),
                    ),
                    child: Text(
                      expiryDate != null
                          ? '\${expiryDate!.year}-\${expiryDate!.month.toString().padLeft(2, "0")}-\${expiryDate!.day.toString().padLeft(2, "0")}'
                          : 'Auto-calculated',
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
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dCtx, true),
              child: const Text('Save', style: TextStyle(color: Color(0xFFE94560))),
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
        'expiry_date': '\${expiryDate!.year}-\${expiryDate!.month.toString().padLeft(2, "0")}-\${expiryDate!.day.toString().padLeft(2, "0")}',
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
            SnackBar(content: Text('Error: \$e'), backgroundColor: const Color(0xFFE94560)));
      }
    }
  }

  Future<void> _confirmDelete(dynamic item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Delete ingredient?', style: TextStyle(color: Colors.white)),
        content: Text("Delete \"${item['name_lao']}\"?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFE94560)))),
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
            SnackBar(content: Text('Error: \$e'), backgroundColor: const Color(0xFFE94560)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowCount = _items.where(_isLow).length;
    final isWeb = MediaQuery.of(context).size.width > 700;

    return Column(
      children: [
        Container(
          color: const Color(0xFF16213E),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const Text('Stock', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              if (lowCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFE94560), borderRadius: BorderRadius.circular(12)),
                  child: Text('\$lowCount low', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showItemDialog(),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('Add ingredient', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
            ],
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFFE94560))))
        else
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 170,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F3460),
                    border: Border(right: BorderSide(color: Colors.white10)),
                  ),
                  child: ListView(
                    children: _categories.map((cat) {
                      final selected = cat['value'] == _selectedCategory;
                      final count = _items.where((it) => it['category'] == cat['value']).length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFE94560).withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: selected ? Border.all(color: const Color(0xFFE94560).withValues(alpha: 0.4)) : null,
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(cat['label']!,
                              style: TextStyle(
                                  color: selected ? const Color(0xFFE94560) : Colors.white70,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13)),
                          trailing: Text('$count', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          onTap: () => setState(() => _selectedCategory = cat['value']!),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: _currentItems.isEmpty
                      ? const Center(child: Text('No ingredients in this category', style: TextStyle(color: Colors.white54, fontSize: 16)))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isWeb ? 6 : 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _currentItems.length,
                          itemBuilder: (_, i) {
                            final item = _currentItems[i];
                            final isLow = _isLow(item);
                            final days = _daysUntilExpiry(item);
                            final qty = double.tryParse(item['quantity'].toString()) ?? 0;
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF16213E),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isLow ? const Color(0xFFE94560) : Colors.white10, width: isLow ? 2 : 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: GestureDetector(
                                      onTap: () => _uploadImage(item),
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                        child: Container(
                                          decoration: const BoxDecoration(color: Color(0xFF0F3460)),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              item['image_url'] != null
                                                  ? CachedNetworkImage(
                                                      imageUrl: item['image_url'],
                                                      fit: BoxFit.cover,
                                                      placeholder: (_, __) => const Center(
                                                          child: CircularProgressIndicator(color: Color(0xFFE94560), strokeWidth: 2)),
                                                      errorWidget: (_, __, ___) => const Center(
                                                          child: Icon(Icons.restaurant, color: Colors.white24, size: 32)),
                                                    )
                                                  : const Center(child: Icon(Icons.restaurant, color: Colors.white24, size: 32)),
                                              if (_uploadingImage[item['id']] == true)
                                                Container(
                                                  color: Colors.black54,
                                                  child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                                ),
                                              if (item['image_url'] == null)
                                                const Positioned(
                                                  bottom: 4, right: 4,
                                                  child: Icon(Icons.add_a_photo, color: Colors.white38, size: 16),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['name_lao'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text("${qty.toStringAsFixed(1)} ${item['unit']}",
                                            style: TextStyle(color: isLow ? const Color(0xFFE94560) : Colors.white54, fontSize: 11)),
                                        if (days != null)
                                          Text(
                                            days < 0 ? 'Expired' : (days <= 1 ? 'Expires soon' : 'Exp \$days d'),
                                            style: TextStyle(
                                                color: (days <= 1) ? const Color(0xFFE94560) : Colors.white38,
                                                fontSize: 10),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 30,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFE94560),
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () => _quickAddPurchase(item),
                                              child: const Text('+ Add', style: TextStyle(color: Colors.white, fontSize: 12)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          width: 30, height: 30,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.edit, color: Color(0xFF2196F3), size: 16),
                                            onPressed: () => _showItemDialog(item: item),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 30, height: 30,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.delete_outline, color: Color(0xFFE94560), size: 16),
                                            onPressed: () => _confirmDelete(item),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
