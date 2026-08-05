import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';
import 'payment_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<MenuCategory> _categories = [];
  bool _loading = true;
  int _selectedCategoryIndex = 0;
  String _search = '';
  final ScrollController _gridScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _loading = true);
    try {
      final cats = await ApiService().getFullMenu();
      setState(() { _categories = cats; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _gridScroll.dispose();
    super.dispose();
  }

  List<MenuItem> get _currentItems {
    if (_categories.isEmpty) return [];
    if (_search.isNotEmpty) {
      return _categories
          .expand((c) => c.items)
          .where((i) => i.isAvailable &&
              (i.nameLao.toLowerCase().contains(_search) ||
                  (i.nameEn?.toLowerCase().contains(_search) ?? false)))
          .toList();
    }
    return _categories[_selectedCategoryIndex].items
        .where((i) => i.isAvailable)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final table = provider.selectedTable;
    final isWeb = kIsWeb || MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ໂຕະ ${table?.tableNumber ?? ''}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('ເລືອກອາຫານ', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          // Payment button
          if (table != null)
            IconButton(
              icon: const Icon(Icons.payments, color: Color(0xFF4CAF50)),
              tooltip: 'ຊຳລະເງິນ',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaymentScreen(
                  tableNumber: table.tableNumber,
                  tableId: table.id,
                )),
              ),
            ),
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: 4, end: 4),
            showBadge: provider.cartCount > 0,
            badgeContent: Text('${provider.cartCount}',
                style: const TextStyle(color: Colors.white, fontSize: 11)),
            badgeStyle: const badges.BadgeStyle(badgeColor: Color(0xFFE94560)),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: provider.cartCount > 0
                  ? () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CartScreen()))
                  : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : Row(children: [
              // Previous orders panel (web only)
              if (isWeb && table != null)
                Container(
                  width: 260,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16213E),
                    border: Border(right: BorderSide(color: Colors.white10)),
                  ),
                  child: _PreviousOrdersPanel(tableId: table.id, tableNumber: table.tableNumber),
                ),
              // ── Category sidebar ──────────────────────────
              Container(
                width: isWeb ? 200 : 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F3460),
                  border: Border(right: BorderSide(color: Colors.white10)),
                ),
                child: Column(children: [
                  // Search
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      style: TextStyle(color: Colors.white, fontSize: isWeb ? 13 : 11),
                      decoration: InputDecoration(
                        hintText: 'ຄົ້ນຫາ...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 16),
                        filled: true,
                        fillColor: const Color(0xFF1A1A2E),
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() {
                        _search = v.toLowerCase();
                      }),
                    ),
                  ),
                  // Category list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final selected = _selectedCategoryIndex == i && _search.isEmpty;
                        final availCount = cat.items.where((it) => it.isAvailable).length;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = i;
                              _search = '';
                            });
                            _gridScroll.jumpTo(0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            padding: EdgeInsets.symmetric(
                                horizontal: isWeb ? 12 : 6, vertical: isWeb ? 10 : 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFE94560).withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: selected
                                  ? Border.all(color: const Color(0xFFE94560).withValues(alpha: 0.5))
                                  : null,
                            ),
                            child: isWeb
                                ? Row(children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(cat.nameLao,
                                              style: TextStyle(
                                                  color: selected
                                                      ? const Color(0xFFE94560)
                                                      : Colors.white70,
                                                  fontWeight: selected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  fontSize: 13)),
                                          Text('$availCount ລາຍການ',
                                              style: const TextStyle(
                                                  color: Colors.white38, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(Icons.chevron_right,
                                          color: Color(0xFFE94560), size: 16),
                                  ])
                                : Column(children: [
                                    Icon(Icons.restaurant_menu,
                                        color: selected
                                            ? const Color(0xFFE94560)
                                            : Colors.white38,
                                        size: 20),
                                    const SizedBox(height: 4),
                                    Text(cat.nameLao,
                                        style: TextStyle(
                                            color: selected
                                                ? const Color(0xFFE94560)
                                                : Colors.white54,
                                            fontSize: 9,
                                            fontWeight: selected
                                                ? FontWeight.bold
                                                : FontWeight.normal),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis),
                                  ]),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ),

              // ── Food grid ─────────────────────────────────
              Expanded(
                child: Column(children: [
                  // Category header
                  if (_search.isEmpty && _categories.isNotEmpty)
                    Container(
                      color: const Color(0xFF16213E),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Row(children: [
                        Text(
                          _categories[_selectedCategoryIndex].nameLao,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE94560).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_currentItems.length} ລາຍການ',
                            style: const TextStyle(
                                color: Color(0xFFE94560), fontSize: 12),
                          ),
                        ),
                      ]),
                    )
                  else if (_search.isNotEmpty)
                    Container(
                      color: const Color(0xFF16213E),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Row(children: [
                        const Icon(Icons.search, color: Colors.white54, size: 18),
                        const SizedBox(width: 8),
                        Text('ຜົນການຄົ້ນຫາ: $_search',
                            style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(width: 8),
                        Text('(${_currentItems.length})',
                            style: const TextStyle(color: Color(0xFFE94560))),
                      ]),
                    ),

                  // Grid
                  Expanded(
                    child: _currentItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.restaurant_menu,
                                    color: Colors.white24, size: 64),
                                const SizedBox(height: 12),
                                Text(
                                  _search.isNotEmpty
                                      ? 'ບໍ່ພົບ "$_search"'
                                      : 'ບໍ່ມີເມນູ',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            controller: _gridScroll,
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWeb ? 8 : 4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: isWeb ? 0.75 : 0.62,
                            ),
                            itemCount: _currentItems.length,
                            itemBuilder: (_, i) {
                              final item = _currentItems[i];
                              final qty = provider.cartQuantityFor(item.id);
                              return _MenuCard(
                                  item: item, qty: qty, provider: provider);
                            },
                          ),
                  ),
                ]),
              ),
            ]),
      floatingActionButton: provider.cartCount > 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFE94560),
              elevation: 8,
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const CartScreen())),
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${provider.cartCount} ລາຍການ',
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                  Text('${NumberFormat.decimalPattern().format(provider.cartTotal)} ກີບ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : null,
    );
  }
}

// ── Menu Card ─────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final MenuItem item;
  final int qty;
  final AppProvider provider;
  const _MenuCard({required this.item, required this.qty, required this.provider});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: qty > 0 ? const Color(0xFFE94560) : Colors.white10,
          width: qty > 0 ? 2 : 1,
        ),
        boxShadow: qty > 0
            ? [BoxShadow(
                color: const Color(0xFFE94560).withValues(alpha: 0.2),
                blurRadius: 10, spreadRadius: 1)]
            : [BoxShadow(
                color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: Stack(fit: StackFit.expand, children: [
                item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: const Color(0xFF0F3460),
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFE94560), strokeWidth: 2))),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
                // gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent,
                          Colors.black.withValues(alpha: 0.3)],
                      ),
                    ),
                  ),
                ),
                // qty badge
                if (qty > 0)
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                          color: Color(0xFFE94560), shape: BoxShape.circle),
                      child: Center(
                        child: Text('$qty',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.nameLao,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w600, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (item.price > 0)
                    Text('${NumberFormat.decimalPattern().format(item.price)}',
                        style: const TextStyle(
                            color: Color(0xFFE94560), fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  qty == 0
                      ? SizedBox(
                          width: double.infinity,
                          height: 28,
                          child: ElevatedButton(
                            onPressed: () => provider.addToCart(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE94560),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('+ ເພີ່ມ',
                                style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        )
                      : Row(children: [
                          _qtyBtn(Icons.remove, () => provider.removeFromCart(item)),
                          Expanded(
                            child: Center(
                              child: Text('$qty',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                          ),
                          _qtyBtn(Icons.add, () => provider.addToCart(item)),
                        ]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF0F3460),
        child: const Center(
            child: Icon(Icons.restaurant_menu, color: Colors.white24, size: 32)),
      );

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFE94560),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      );
}

// ── Previous Orders Panel ─────────────────────────────────────
class _PreviousOrdersPanel extends StatefulWidget {
  final int tableId;
  final String tableNumber;
  const _PreviousOrdersPanel({required this.tableId, required this.tableNumber});

  @override
  State<_PreviousOrdersPanel> createState() => _PreviousOrdersPanelState();
}

class _PreviousOrdersPanelState extends State<_PreviousOrdersPanel> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Get all active orders for this table
      final allOrders = await ApiService().getOrders();
      final tableOrders = allOrders
          .where((o) =>
              o.tableNumber == widget.tableNumber &&
              o.status != 'paid' &&
              o.status != 'cancelled')
          .toList();

      // Load detail for each order
      final details = <Map<String, dynamic>>[];
      for (final o in tableOrders) {
        try {
          final d = await ApiService().getOrderDetail(o.id);
          details.add(d);
        } catch (_) {}
      }
      setState(() {
        _orders = details;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'sent_to_kitchen': return 'ໃນຄົວ';
      case 'ready':           return 'ພ້ອມ';
      case 'billed':          return 'ອອກບິນ';
      default:                return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'sent_to_kitchen': return const Color(0xFFFF9800);
      case 'ready':           return const Color(0xFF2196F3);
      case 'billed':          return const Color(0xFF9C27B0);
      default:                return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Count total items ordered
    int totalItems = 0;
    for (final o in _orders) {
      final items = o['items'] as List? ?? [];
      totalItems += items.fold<int>(0, (s, i) => s + ((i['quantity'] as num?)?.toInt() ?? 0));
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF0F3460),
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(children: [
            const Icon(Icons.history, color: Color(0xFFE94560), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ອໍເດີກ່ອນໜ້າ',
                      style: TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('ໂຕະ ${widget.tableNumber} · $totalItems ລາຍການ',
                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            GestureDetector(
              onTap: _load,
              child: const Icon(Icons.refresh, color: Colors.white38, size: 16),
            ),
          ]),
        ),

        // Pay button
        if (!_loading && _orders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PaymentScreen(
                    tableNumber: widget.tableNumber,
                    tableId: widget.tableId,
                  )),
                ),
                icon: const Icon(Icons.payments, color: Colors.white, size: 18),
                label: const Text('ຊຳລະເງິນ',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        const SizedBox(height: 8),

        // Orders
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE94560), strokeWidth: 2))
              : _orders.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_outlined, color: Colors.white24, size: 40),
                          SizedBox(height: 8),
                          Text('ຍັງບໍ່ມີອໍເດີ',
                              style: TextStyle(color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _orders.length,
                      itemBuilder: (_, i) {
                        final order = _orders[i];
                        final items = order['items'] as List? ?? [];
                        final status = order['status'] as String? ?? '';
                        final statusColor = _statusColor(status);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F3460),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.4), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                                child: Row(children: [
                                  Text('ອໍເດີ #${order['id']}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(_statusLabel(status),
                                        style: TextStyle(
                                            color: statusColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ]),
                              ),
                              const Divider(color: Colors.white10, height: 1),
                              // Items
                              ...items.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    child: Row(children: [
                                      Container(
                                        width: 22, height: 22,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE94560).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Center(
                                          child: Text('${item['quantity']}',
                                              style: const TextStyle(
                                                  color: Color(0xFFE94560),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['name_lao'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.white70, fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (item['line_total'] != null &&
                                          double.tryParse(item['line_total'].toString())! > 0)
                                        Text(
                                          '${NumberFormat.decimalPattern().format(double.tryParse(item['line_total'].toString()) ?? 0)}',
                                          style: const TextStyle(
                                              color: Colors.white38, fontSize: 10),
                                        ),
                                    ]),
                                  )),
                              // Total
                              if (order['total'] != null)
                                Container(
                                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                                  child: Row(children: [
                                    const SizedBox(height: 4),
                                    const Text('ລວມ: ',
                                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                                    Text(
                                      '${NumberFormat.decimalPattern().format(double.tryParse(order['total'].toString()) ?? 0)} ກີບ',
                                      style: const TextStyle(
                                          color: Color(0xFFE94560),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ]),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
