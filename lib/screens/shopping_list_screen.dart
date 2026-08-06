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
  List<dynamic> _history = [];
  bool _showHistory = false;
  final Set<int> _expandedGroups = {};
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
        ApiService().getShoppingListHistory(),
      ]);
      if (mounted) {
        setState(() {
          _pending = results[0];
          _stockItems = results[1];
          _history = results[2];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
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

  List<dynamic> get _groupedHistory {
    final Map<int, Map<String, dynamic>> groups = {};
    for (final entry in _history) {
      final stockId = entry['stock_item_id'] as int;
      if (!groups.containsKey(stockId)) {
        // Find live stock item for current quantity
        final stock = _stockItems.firstWhere(
          (s) => s['id'] == stockId,
          orElse: () => {'quantity': entry['quantity_needed'], 'unit': entry['unit']},
        );
        groups[stockId] = {
          'stock_item_id': stockId,
          'name_lao': entry['name_lao'],
          'unit': entry['unit'],
          'quantity_needed': stock['quantity'],
          'expiry_date': entry['expiry_date'],
          'bought_at': entry['bought_at'],
          'purchase_count': 1,
          'entries': [entry],
        };
      } else {
        final g = groups[stockId]!;
        g['purchase_count'] = (g['purchase_count'] as int) + 1;
        (g['entries'] as List).add(entry);
        // Keep the soonest (earliest) expiry across purchases
        final currentExpiry = DateTime.tryParse(g['expiry_date']?.toString() ?? '');
        final newExpiry = DateTime.tryParse(entry['expiry_date']?.toString() ?? '');
        if (newExpiry != null && (currentExpiry == null || newExpiry.isBefore(currentExpiry))) {
          g['expiry_date'] = entry['expiry_date'];
        }
        // Keep the most recent bought_at
        final currentBought = DateTime.tryParse(g['bought_at']?.toString() ?? '');
        final newBought = DateTime.tryParse(entry['bought_at']?.toString() ?? '');
        if (newBought != null && (currentBought == null || newBought.isAfter(currentBought))) {
          g['bought_at'] = entry['bought_at'];
        }
      }
    }
    return groups.values.toList();
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

  Future<void> _markDepleted(dynamic entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('ເຄື່ອງໝົດແລ້ວ?', style: TextStyle(color: Colors.white)),
        content: Text('ຕັ້ງຄ່າ "${entry['name_lao']}" ເປັນໝົດແລ້ວ (ຈຳນວນ = 0)?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ຢືນຢັນ', style: TextStyle(color: Color(0xFFE94560)))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService().updateStockItem(entry['stock_item_id'], {'quantity': 0});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${entry['name_lao']} ໝົດແລ້ວ'), backgroundColor: const Color(0xFFE94560)));
      }
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
                              final days = _daysUntilExpiry(item);
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
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${item['name_lao']}',
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                maxLines: 1, overflow: TextOverflow.ellipsis),
                                            if (days != null)
                                              Text(
                                                days < 0 ? 'ໝົດອາຍຸແລ້ວ' : 'ອີກ $days ມື້',
                                                style: TextStyle(color: (days <= 1) ? const Color(0xFFE94560) : Colors.white38, fontSize: 10),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    width: 420,
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
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _showHistory = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: !_showHistory ? const Color(0xFFE94560).withValues(alpha: 0.15) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('ລໍຖ້າຊື້', textAlign: TextAlign.center,
                                        style: TextStyle(color: !_showHistory ? const Color(0xFFE94560) : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _showHistory = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _showHistory ? const Color(0xFFE94560).withValues(alpha: 0.15) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('ປະຫວັດ', textAlign: TextAlign.center,
                                        style: TextStyle(color: _showHistory ? const Color(0xFFE94560) : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _showHistory
                              ? ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _groupedHistory.length,
                                  itemBuilder: (_, i) {
                                    final group = _groupedHistory[i];
                                    final stockId = group['stock_item_id'] as int;
                                    final expanded = _expandedGroups.contains(stockId);
                                    final days = _daysUntilExpiry(group);
                                    final entries = group['entries'] as List;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F3460),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        children: [
                                          InkWell(
                                            onTap: () => setState(() {
                                              if (expanded) {
                                                _expandedGroups.remove(stockId);
                                              } else {
                                                _expandedGroups.add(stockId);
                                              }
                                            }),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Row(
                                                children: [
                                                  Icon(expanded ? Icons.expand_less : Icons.expand_more, color: Colors.white54, size: 18),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('${group['name_lao']}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                                        Text('${group['quantity_needed']} ${group['unit']} · ${group['purchase_count']} ຄັ້ງ',
                                                            style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                                        if (days != null)
                                                          Text(
                                                            days < 0 ? 'ໝົດອາຍຸແລ້ວ' : 'ອີກ $days ມື້',
                                                            style: TextStyle(color: (days <= 1) ? const Color(0xFFE94560) : Colors.white38, fontSize: 10),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 28,
                                                    child: ElevatedButton(
                                                      onPressed: () => _markDepleted(group),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFFE94560),
                                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                      ),
                                                      child: const Text('ໝົດແລ້ວ', style: TextStyle(color: Colors.white, fontSize: 11)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (expanded)
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(34, 0, 10, 8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: entries.map<Widget>((e) {
                                                  final t = DateTime.tryParse(e['bought_at']?.toString() ?? '');
                                                  final dateLabel = t == null ? '' : '${t.day.toString().padLeft(2, "0")}/${t.month.toString().padLeft(2, "0")}/${t.year}';
                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text('${e['quantity_needed']} ${e['unit']} · $dateLabel',
                                                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                                        ),
                                                        IconButton(
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(),
                                                          icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                                                          onPressed: () => _removeItem(e),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _pending.length,
                                  itemBuilder: (_, i) {
                                    final entry = _pending[i];
                                    final id = entry['id'] as int;
                                    final isBuying = _buying.contains(id);
                                    final days = _daysUntilExpiry(entry);
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F3460),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${entry['name_lao']}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                                Text('${entry['quantity_needed']} ${entry['unit']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                                if (days != null)
                                                  Text(
                                                    days < 0 ? 'ໝົດອາຍຸແລ້ວ' : 'ອີກ $days ມື້',
                                                    style: TextStyle(color: (days <= 1) ? const Color(0xFFE94560) : Colors.white38, fontSize: 10),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                            child: ElevatedButton(
                                              onPressed: isBuying ? null : () => _markBought(entry),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF4CAF50),
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: isBuying
                                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                  : const Text('ຊື້ແລ້ວ', style: TextStyle(color: Colors.white, fontSize: 12)),
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
