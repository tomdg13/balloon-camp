import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final _api     = ApiService();
  final _storage = const FlutterSecureStorage();

  // ── Auth ──────────────────────────────────────────────────
  Staff? _staff;
  Staff? get staff => _staff;
  bool get isLoggedIn => _staff != null;

  // ── Active table ──────────────────────────────────────────
  RestaurantTable? _selectedTable;
  RestaurantTable? get selectedTable => _selectedTable;

  Map<String, Map<String, bool>> _permissions = {};
  Map<String, Map<String, bool>> get permissions => _permissions;
  Set<String> get allowedPages => _permissions.entries.where((e) => e.value["view"] == true).map((e) => e.key).toSet();
  bool canView(String pageKey) => _permissions[pageKey]?["view"] ?? false;
  bool canEdit(String pageKey) => _permissions[pageKey]?["edit"] ?? false;
  bool canDelete(String pageKey) => _permissions[pageKey]?["delete"] ?? false;

  // ── Per-table carts  { tableId -> List<CartItem> } ────────
  final Map<int, List<CartItem>> _tableCarts = {};

  List<CartItem> get cart => _selectedTable != null
      ? List.unmodifiable(_tableCarts[_selectedTable!.id] ?? [])
      : [];

  List<CartItem> cartForTable(int tableId) =>
      List.unmodifiable(_tableCarts[tableId] ?? []);

  int get cartCount => cart.fold(0, (s, c) => s + c.quantity);
  double get cartTotal => cart.fold(0.0, (s, c) => s + c.total);

  int cartCountForTable(int tableId) =>
      (_tableCarts[tableId] ?? []).fold(0, (s, c) => s + c.quantity);

  // ── Login ─────────────────────────────────────────────────
  Future<void> login(String username, String password) async {
    final staff = await _api.login(username, password);
    _staff = staff;
    await _storage.write(key: 'token', value: staff.token);
    _permissions = await _api.getMyPermissions();
    notifyListeners();
  }

  void logout() {
    _staff = null;
    _selectedTable = null;
    _tableCarts.clear();
    _permissions = {};
    _api.clearToken();
    _storage.delete(key: 'token');
    notifyListeners();
  }

  // ── Table selection ───────────────────────────────────────
  void selectTable(RestaurantTable table) {
    _selectedTable = table;
    // Don't clear cart — keep existing items for this table
    if (!_tableCarts.containsKey(table.id)) {
      _tableCarts[table.id] = [];
    }
    notifyListeners();
  }

  void clearTableSelection() {
    _selectedTable = null;
    notifyListeners();
  }

  // ── Cart management ───────────────────────────────────────
  void addToCart(MenuItem item) {
    if (_selectedTable == null) return;
    final tableId = _selectedTable!.id;
    _tableCarts[tableId] ??= [];
    final idx = _tableCarts[tableId]!.indexWhere((c) => c.menuItem.id == item.id);
    if (idx >= 0) {
      _tableCarts[tableId]![idx].quantity++;
    } else {
      _tableCarts[tableId]!.add(CartItem(menuItem: item));
    }
    notifyListeners();
  }

  void removeFromCart(MenuItem item) {
    if (_selectedTable == null) return;
    final tableId = _selectedTable!.id;
    final idx = _tableCarts[tableId]?.indexWhere((c) => c.menuItem.id == item.id) ?? -1;
    if (idx < 0) return;
    if (_tableCarts[tableId]![idx].quantity > 1) {
      _tableCarts[tableId]![idx].quantity--;
    } else {
      _tableCarts[tableId]!.removeAt(idx);
    }
    notifyListeners();
  }

  void removeItemCompletely(int menuItemId) {
    if (_selectedTable == null) return;
    _tableCarts[_selectedTable!.id]?.removeWhere((c) => c.menuItem.id == menuItemId);
    notifyListeners();
  }

  int cartQuantityFor(int menuItemId) {
    if (_selectedTable == null) return 0;
    final idx = _tableCarts[_selectedTable!.id]
        ?.indexWhere((c) => c.menuItem.id == menuItemId) ?? -1;
    return idx >= 0 ? _tableCarts[_selectedTable!.id]![idx].quantity : 0;
  }

  void clearCartForTable(int tableId) {
    _tableCarts.remove(tableId);
    notifyListeners();
  }

  // ── Submit order ──────────────────────────────────────────
  Future<int> submitOrder({String? note}) async {
    final tableId = _selectedTable!.id;
    final items = _tableCarts[tableId] ?? [];
    final orderId = await _api.submitOrder(
      tableId: tableId,
      items: items,
      note: note,
    );
    // Clear only this table's cart after submit
    _tableCarts[tableId] = [];
    // Keep table selected so staff can order more
    notifyListeners();
    return orderId;
  }
}
