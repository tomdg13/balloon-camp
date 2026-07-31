import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'menu_screen.dart';
import 'kitchen_screen.dart';
import 'staff_management_screen.dart';
import 'table_management_screen.dart';
import 'menu_management_screen.dart';
import 'settings_screen.dart';
import 'qr_screen.dart';
import 'reports_hub_screen.dart';

// ── Page index constants ──────────────────────────────────────
const int kPageTables  = 0;
const int kPageKitchen = 1;
const int kPageStaff   = 2;
const int kPageTableMgmt = 3;
const int kPageMenuMgmt = 4;
const int kPageSettings = 5;
const int kPageReports = 6;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedPage = kPageTables;

  void _navigate(int page) => setState(() => _selectedPage = page);

  @override
  Widget build(BuildContext context) {
    final staff   = context.watch<AppProvider>().staff;
    final isAdmin = staff?.role == 'admin';
    final isKitchen = staff?.role == 'kitchen';
    final isWeb   = kIsWeb || MediaQuery.of(context).size.width > 700;

    final pages = [
      const _TablesPage(),
      const KitchenScreen(),
      const StaffManagementScreen(),
      const TableManagementScreen(),
      const MenuManagementScreen(),
      const SettingsScreen(),
      const ReportsHubScreen(),
    ];

    if (isWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Row(
          children: [
            // ── Persistent sidebar ──────────────────────────
            SizedBox(
              width: 220,
              child: _SideNav(
                selected: _selectedPage,
                isAdmin: isAdmin,
                isKitchen: isKitchen,
                staff: staff,
                onSelect: _navigate,
              ),
            ),
            // ── Main content area ───────────────────────────
            Expanded(child: pages[_selectedPage]),
          ],
        ),
      );
    }

    // Mobile — drawer
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text(_pageTitle(_selectedPage),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF16213E),
        child: _SideNav(
          selected: _selectedPage,
          isAdmin: isAdmin,
          isKitchen: isKitchen,
          staff: staff,
          onSelect: (p) {
            Navigator.pop(context);
            _navigate(p);
          },
        ),
      ),
      body: pages[_selectedPage],
    );
  }

  String _pageTitle(int page) {
    switch (page) {
      case kPageTables:  return 'ເລືອກໂຕະ';
      case kPageKitchen: return 'ຄົວ';
      case kPageStaff:   return 'ຈັດການພະນັກງານ';
      case kPageTableMgmt: return 'ຈັດການໂຕະ';
      case kPageMenuMgmt: return 'ຈັດການເມນູ';
      case kPageSettings: return 'ຕັ້ງຄ່າຮ້ານ';
      case kPageReports: return 'ລາຍງານ';
      default:           return 'Balloon Camp';
    }
  }
}

// ── Side Navigation ───────────────────────────────────────────
class _SideNav extends StatelessWidget {
  final int selected;
  final bool isAdmin;
  final bool isKitchen;
  final dynamic staff;
  final void Function(int) onSelect;

  const _SideNav({
    required this.selected,
    required this.isAdmin,
    required this.isKitchen,
    required this.staff,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF16213E),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            color: const Color(0xFF0F3460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE94560),
                  child: Text(
                    (staff?.name ?? 'A').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Text(staff?.name ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(staff?.role ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Nav items
          _item(context, Icons.table_restaurant, 'ເລືອກໂຕະ', kPageTables),
          if (isAdmin || isKitchen)
            _item(context, Icons.kitchen, 'ຄົວ · ອໍເດີ', kPageKitchen),

          if (isAdmin) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 6),
              child: Text('ADMIN',
                  style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 2)),
            ),
            _item(context, Icons.manage_accounts, 'ຈັດການພະນັກງານ', kPageStaff),
            _item(context, Icons.table_bar, 'ຈັດການໂຕະ', kPageTableMgmt),
            _item(context, Icons.restaurant_menu, 'ຈັດການເມນູ', kPageMenuMgmt),
            _item(context, Icons.settings, 'ຕັ້ງຄ່າຮ້ານ', kPageSettings),
            _item(context, Icons.bar_chart, 'ລາຍງານ', kPageReports),
          ],

          const Spacer(),
          const Divider(color: Colors.white12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFE94560)),
              title: const Text('ອອກຈາກລະບົບ',
                  style: TextStyle(color: Color(0xFFE94560), fontSize: 14)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () {
                context.read<AppProvider>().logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, int page) {
    final active = selected == page;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(icon,
            color: active ? const Color(0xFFE94560) : Colors.white70),
        title: Text(label,
            style: TextStyle(
                color: active ? const Color(0xFFE94560) : Colors.white70,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                fontSize: 14)),
        selected: active,
        selectedTileColor: const Color(0xFFE94560).withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () => onSelect(page),
      ),
    );
  }
}

// ── Tables page (inline — no separate screen push) ────────────
class _TablesPage extends StatefulWidget {
  const _TablesPage();
  @override
  State<_TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<_TablesPage> {
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ໂຫລດໂຕະບໍ່ສຳເລັດ: $e')));
    }
  }

  Color _color(String status) {
    switch (status) {
      case 'available': return const Color(0xFF4CAF50);
      case 'occupied':  return const Color(0xFFE94560);
      case 'reserved':  return const Color(0xFFFF9800);
      default:          return Colors.grey;
    }
  }

  String _label(String status) {
    switch (status) {
      case 'available': return 'ວ່າງ';
      case 'occupied':  return 'ມີລູກຄ້າ';
      case 'reserved':  return 'ຈອງແລ້ວ';
      default:          return status;
    }
  }

  void _showTableOptions(BuildContext context, RestaurantTable t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ໂຕະ \${t.tableNumber}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Order button - available for both available and occupied tables
            _sheetBtn(
              context,
              icon: t.isAvailable ? Icons.restaurant_menu : Icons.add_shopping_cart,
              label: t.isAvailable ? 'ຮັບອໍເດີ' : 'ສັ່ງເພີ່ມອາຫານ',
              color: const Color(0xFFE94560),
              onTap: () {
                Navigator.pop(context);
                context.read<AppProvider>().selectTable(t);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MenuScreen()));
              },
            ),
            const SizedBox(height: 12),
            _sheetBtn(
              context,
              icon: Icons.qr_code,
              label: 'ສະແດງ QR Code',
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => QrScreen(table: t)));
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetBtn(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) =>
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white),
          label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb || MediaQuery.of(context).size.width > 700;

    return Column(
      children: [
        // Top bar
        Container(
          color: const Color(0xFF16213E),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              const Text('ເລືອກໂຕະ',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _load,
              ),
            ],
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              _dot(const Color(0xFF4CAF50), 'ວ່າງ'),
              const SizedBox(width: 20),
              _dot(const Color(0xFFE94560), 'ມີລູກຄ້າ'),
              const SizedBox(width: 20),
              _dot(const Color(0xFFFF9800), 'ຈອງແລ້ວ'),
            ],
          ),
        ),
        // Grid + Orders panel
        Expanded(
          child: Row(
            children: [
              // Tables grid
              Expanded(
                flex: 3,
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isWeb ? 6 : 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: _tables.length,
                          itemBuilder: (_, i) {
                            final t = _tables[i];
                            final c = _color(t.status);
                            return GestureDetector(
                              onTap: () => _showTableOptions(context, t),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: t.isAvailable
                                      ? const Color(0xFF16213E)
                                      : const Color(0xFF0F3460),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: c, width: 2),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: FittedBox(child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.table_restaurant, color: c, size: isWeb ? 36 : 30),
                                          const SizedBox(height: 6),
                                          Text(t.tableNumber,
                                              style: TextStyle(color: c, fontSize: isWeb ? 18 : 15, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text(_label(t.status),
                                              style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                        ],
                                      ),)
                                    ),
                                    Builder(builder: (ctx) {
                                      final count = context.watch<AppProvider>().cartCountForTable(t.id);
                                      if (count == 0) return const SizedBox();
                                      return Positioned(
                                        top: 6, right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF9800),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text('$count',
                                              style: const TextStyle(
                                                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              // Recent orders panel (web only)
              if (isWeb)
                Container(
                  width: 300,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16213E),
                    border: Border(left: BorderSide(color: Colors.white10)),
                  ),
                  child: _RecentOrdersPanel(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dot(Color color, String label) => Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      );
}

// ── Recent Orders Panel ───────────────────────────────────────
class _RecentOrdersPanel extends StatefulWidget {
  @override
  State<_RecentOrdersPanel> createState() => _RecentOrdersPanelState();
}

class _RecentOrdersPanelState extends State<_RecentOrdersPanel> {
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await ApiService().getOrders();
      setState(() {
        _orders = orders.take(20).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':             return const Color(0xFF9E9E9E);
      case 'sent_to_kitchen':  return const Color(0xFFFF9800);
      case 'ready':            return const Color(0xFF2196F3);
      case 'billed':           return const Color(0xFF9C27B0);
      case 'paid':             return const Color(0xFF4CAF50);
      case 'cancelled':        return const Color(0xFFE94560);
      default:                 return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':             return 'ເປີດ';
      case 'sent_to_kitchen':  return 'ໃນຄົວ';
      case 'ready':            return 'ພ້ອມ';
      case 'billed':           return 'ອອກບິນ';
      case 'paid':             return 'ຊຳລະແລ້ວ';
      case 'cancelled':        return 'ຍົກເລີກ';
      default:                 return status;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ຫາກໍ';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ນາທີ';
    if (diff.inHours < 24) return '${diff.inHours} ຊົ່ວໂມງ';
    return '${diff.inDays} ວັນ';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFFE94560), size: 18),
              const SizedBox(width: 8),
              const Text('ອໍເດີລ່າສຸດ',
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: _load,
                child: const Icon(Icons.refresh, color: Colors.white38, size: 18),
              ),
            ],
          ),
        ),

        // Orders list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : _orders.isEmpty
                  ? const Center(
                      child: Text('ຍັງບໍ່ມີອໍເດີ',
                          style: TextStyle(color: Colors.white38)),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final o = _orders[i];
                          final statusColor = _statusColor(o.status);
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F3460),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE94560).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('ໂຕະ ${o.tableNumber}',
                                        style: const TextStyle(
                                            color: Color(0xFFE94560),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(_statusLabel(o.status),
                                        style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Icon(Icons.person, color: Colors.white38, size: 13),
                                  const SizedBox(width: 4),
                                  Text(o.staffName,
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 12)),
                                  const Spacer(),
                                  const Icon(Icons.access_time,
                                      color: Colors.white38, size: 13),
                                  const SizedBox(width: 4),
                                  Text(_timeAgo(o.createdAt),
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 12)),
                                ]),
                                const SizedBox(height: 6),
                                Row(children: [
                                  const Icon(Icons.restaurant, color: Colors.white38, size: 13),
                                  const SizedBox(width: 4),
                                  Text('${o.itemCount} ລາຍການ',
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 12)),
                                  if (o.totalAmount != null && o.totalAmount! > 0) ...[
                                    const Spacer(),
                                    Text(
                                      '${o.totalAmount!.toStringAsFixed(0)} ກີບ',
                                      style: const TextStyle(
                                          color: Color(0xFFE94560),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ]),
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
