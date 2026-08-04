import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});
  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<dynamic> _pending = [];
  List<dynamic> _stockItems = [];
  bool _loading = true;
  String _selectedCategory = 'meat';
  final Map<int, double> _cart = {};
  final Set<int> _buying = {};
  bool _submitting = false;

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
      final results = await Future.wait([
        ApiService().getShoppingList(),
        ApiService().getStockItems(),
      ]);
      if (mounted) {
        setState(() {
          _pending = results[0];
          _stockItems = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _currentItems =>
      _stockItems.where((it) => it['category'] == _selectedCategory).toList();

  Future<void> _tapAdd(dynamic item) async {
    final itemId = item['id'] as int;
    final qtyCtrl = TextEditingController(text: _cart[itemId]?.toString() ?? '');

    final result = await showDialog<double>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text('${item['name_lao']}', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: qtyCtrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 20),
          decoration: InputDecoration(
            labelText: 'ຈຳນວນ (${item['unit']})',
            labelStyle: const TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, double.tryParse(qtyCtrl.text)),
            child: const Text('ຕົກລົງ', style: TextStyle(color: Color(0xFFE94560))),
          ),
        ],
      ),
    );

    if (result == null || result <= 0) return;
    setState(() => _cart[itemId] = result);
  }

  Future<void> _submitCart() async {
    if (_cart.isEmpty) return;
    setState(() => _submitting = true);
    try {
      for (final entry in _cart.entries) {
        await ApiService().addToShoppingList(stockItemId: entry.key, quantityNeeded: entry.value);
      }
      setState(() => _cart.clear());
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to shopping list'), backgroundColor: Color(0xFF4CAF50)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFE94560)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _markBought(dynamic entry) async {
    final id = entry['id'] as int;
    setState(() => _buying.add(id));
    try {
      await ApiService().markShoppingItemBought(id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bought ${entry['quantity_needed']} ${entry['unit']} of ${entry['name_lao']}'),
                backgroundColor: const Color(0xFF4CAF50)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _buying.remove(id));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFE94560)));
      }
    }
  }

  Future<void> _removeItem(dynamic entry) async {
    try {
      await ApiService().deleteShoppingItem(entry['id']);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFE94560)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF16213E),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Text('ລາຍການອອກຕະຫຼາດ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
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
                    width: 150,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F3460),
                      border: Border(right: BorderSide(color: Colors.white10)),
                    ),
                    child: ListView(
                      children: _categories.map((cat) {
                        final selected = cat['value'] == _selectedCategory;
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
                            onTap: () => setState(() => _selectedCategory = cat['value']!),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _currentItems.isEmpty
                        ? const Center(child: Text('No ingredients in this category', style: TextStyle(color: Colors.white54)))
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWeb ? 6 : 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _currentItems.length,
                            itemBuilder: (_, i) {
                              final item = _currentItems[i];
                              final itemId = item['id'] as int;
                              final inCart = _cart[itemId];
                              return GestureDetector(
                                onTap: () => _tapAdd(item),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16213E),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: inCart != null ? const Color(0xFFE94560) : Colors.white10,
                                        width: inCart != null ? 2 : 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Container(
                                                color: const Color(0xFF0F3460),
                                                child: item['image_url'] != null
                                                    ? CachedNetworkImage(imageUrl: item['image_url'], fit: BoxFit.cover)
                                                    : const Center(child: Icon(Icons.restaurant, color: Colors.white24, size: 28)),
                                              ),
                                              if (inCart != null)
                                                Positioned(
                                                  top: 6, right: 6,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(color: const Color(0xFFE94560), borderRadius: BorderRadius.circular(10)),
                                                    child: Text('$inCart ${item['unit']}',
                                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        child: Text('${item['name_lao']}',
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    width: 260,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16213E),
                      border: Border(left: BorderSide(color: Colors.white10)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.list_alt, color: Color(0xFFE94560), size: 18),
                              const SizedBox(width: 8),
                              const Text('ລໍຖ້າຊື້', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _pending.length,
                            itemBuilder: (_, i) {
                              final entry = _pending[i];
                              final id = entry['id'] as int;
                              final isBuying = _buying.contains(id);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F3460),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${entry['name_lao']}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    Text('${entry['quantity_needed']} ${entry['unit']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 30,
                                            child: ElevatedButton(
                                              onPressed: isBuying ? null : () => _markBought(entry),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF4CAF50),
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: isBuying
                                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                  : const Text('ຊື້ແລ້ວ', style: TextStyle(color: Colors.white, fontSize: 12)),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                                          onPressed: () => _removeItem(entry),
                                        ),
                                      ],
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
              ),
            ),
        ],
      ),
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFE94560),
              onPressed: _submitting ? null : _submitCart,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text('ເພີ່ມ ${_cart.length} ລາຍການ', style: const TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}
