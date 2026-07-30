import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'menu_screen.dart';
import 'kitchen_screen.dart';
import 'staff_management_screen.dart';

class TableSelectionScreen extends StatefulWidget {
  const TableSelectionScreen({super.key});
  @override
  State<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
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
      final tables = await ApiService().getTables();
      setState(() { _tables = tables; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ບໍ່ສາມາດໂຫລດໂຕະໄດ້: $e')));
    }
  }

  void _selectTable(RestaurantTable table) {
    context.read<AppProvider>().selectTable(table);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuScreen()));
  }

  Color _tableColor(String status) {
    switch (status) {
      case 'available': return const Color(0xFF4CAF50);
      case 'occupied':  return const Color(0xFFE94560);
      case 'reserved':  return const Color(0xFFFF9800);
      default:          return Colors.grey;
    }
  }

  String _tableStatusLabel(String status) {
    switch (status) {
      case 'available': return 'ວ່າງ';
      case 'occupied':  return 'ມີລູກຄ້າ';
      case 'reserved':  return 'ຈອງແລ້ວ';
      default:          return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<AppProvider>().staff;
    final isAdmin = staff?.role == 'admin';
    final isKitchen = staff?.role == 'kitchen';
    final isWeb = kIsWeb || MediaQuery.of(context).size.width > 700;

    final sideNav = _SideNav(
      staff: staff,
      isAdmin: isAdmin,
      isKitchen: isKitchen,
      onRefresh: _loadTables,
    );

    final body = _TableBody(
      loading: _loading,
      tables: _tables,
      onSelect: _selectTable,
      tableColor: _tableColor,
      tableStatusLabel: _tableStatusLabel,
      onRefresh: _loadTables,
    );

    if (isWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Row(
          children: [
            SizedBox(width: 220, child: sideNav),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Balloon Camp', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('ສະວັດດີ, ${staff?.name ?? ''}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadTables),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF16213E),
        child: sideNav,
      ),
      body: body,
    );
  }
}

class _SideNav extends StatelessWidget {
  final dynamic staff;
  final bool isAdmin;
  final bool isKitchen;
  final VoidCallback onRefresh;

  const _SideNav({required this.staff, required this.isAdmin, required this.isKitchen, required this.onRefresh});

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
            decoration: const BoxDecoration(color: Color(0xFF0F3460)),
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
                Text(staff?.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(staff?.role ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          _navItem(context, Icons.table_restaurant, 'ເລືອກໂຕະ', true, () {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }),

          if (isAdmin || isKitchen)
            _navItem(context, Icons.kitchen, 'ຄົວ · ອໍເດີທີ່ລໍຖ້າ', false, () {
              if (Navigator.canPop(context)) Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const KitchenScreen()));
            }),

          if (isAdmin) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 6),
              child: Text('ADMIN', style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 2)),
            ),
            _navItem(context, Icons.manage_accounts, 'ຈັດການພະນັກງານ', false, () {
              if (Navigator.canPop(context)) Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen()));
            }),
          ],

          const Spacer(),
          const Divider(color: Colors.white12),
          _navItem(context, Icons.logout, 'ອອກຈາກລະບົບ', false, () {
            context.read<AppProvider>().logout();
            Navigator.pushReplacementNamed(context, '/');
          }, color: const Color(0xFFE94560)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool selected,
      VoidCallback onTap, {Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: ListTile(
          leading: Icon(icon, color: color ?? (selected ? const Color(0xFFE94560) : Colors.white70)),
          title: Text(label,
              style: TextStyle(
                  color: color ?? (selected ? const Color(0xFFE94560) : Colors.white70),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14)),
          selected: selected,
          selectedTileColor: const Color(0xFFE94560).withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: onTap,
        ),
      );
}

class _TableBody extends StatelessWidget {
  final bool loading;
  final List<RestaurantTable> tables;
  final void Function(RestaurantTable) onSelect;
  final Color Function(String) tableColor;
  final String Function(String) tableStatusLabel;
  final VoidCallback onRefresh;

  const _TableBody({
    required this.loading,
    required this.tables,
    required this.onSelect,
    required this.tableColor,
    required this.tableStatusLabel,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb || MediaQuery.of(context).size.width > 700;

    return Column(
      children: [
        // Top bar for web
        if (isWeb)
          Container(
            color: const Color(0xFF16213E),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                const Text('ເລືອກໂຕະ', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),

        // Legend
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: isWeb ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              _legend(const Color(0xFF4CAF50), 'ວ່າງ'),
              const SizedBox(width: 20),
              _legend(const Color(0xFFE94560), 'ມີລູກຄ້າ'),
              const SizedBox(width: 20),
              _legend(const Color(0xFFFF9800), 'ຈອງແລ້ວ'),
            ],
          ),
        ),

        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : RefreshIndicator(
                  onRefresh: () async => onRefresh(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWeb ? 6 : 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: tables.length,
                    itemBuilder: (_, i) {
                      final t = tables[i];
                      final color = tableColor(t.status);
                      return GestureDetector(
                        onTap: t.isAvailable ? () => onSelect(t) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: t.isAvailable ? const Color(0xFF16213E) : const Color(0xFF0F3460),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color, width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.table_restaurant, color: color, size: isWeb ? 40 : 36),
                              const SizedBox(height: 8),
                              Text(t.tableNumber,
                                  style: TextStyle(color: color, fontSize: isWeb ? 20 : 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(tableStatusLabel(t.status),
                                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
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
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      );
}
