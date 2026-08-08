// ── Staff ─────────────────────────────────────────────────────
class Staff {
  final int id;
  final String name;
  final String role;
  final String token;

  Staff({required this.id, required this.name, required this.role, required this.token});

  factory Staff.fromJson(Map<String, dynamic> j, String token) =>
      Staff(id: j['id'], name: j['name'], role: j['role'], token: token);
}

// ── Restaurant Table ─────────────────────────────────────────
class RestaurantTable {
  final int id;
  final String tableNumber;
  final int capacity;
  final String status;
  final String? qrToken;

  RestaurantTable({required this.id, required this.tableNumber, required this.capacity, required this.status, this.qrToken});

  factory RestaurantTable.fromJson(Map<String, dynamic> j) => RestaurantTable(
        id: j['id'],
        tableNumber: j['table_number'] ?? '',
        capacity: j['capacity'] ?? 4,
        status: j['status'] ?? 'available',
        qrToken: j['qr_token'],
      );

  bool get isAvailable => status == 'available';
}

// ── Menu Category ─────────────────────────────────────────────
class MenuCategory {
  final int id;
  final String nameLao;
  final String? nameEn;
  final List<MenuItem> items;

  MenuCategory({required this.id, required this.nameLao, this.nameEn, required this.items});

  factory MenuCategory.fromJson(Map<String, dynamic> j) => MenuCategory(
        id: j['id'],
        nameLao: j['name_lao'],
        nameEn: j['name_en'],
        items: (j['items'] as List? ?? []).map((i) => MenuItem.fromJson(i)).toList(),
      );
}

// ── Menu Item ─────────────────────────────────────────────────
class MenuItem {
  final int id;
  final int categoryId;
  final String nameLao;
  final String? nameEn;
  final double price;
  final String? imageUrl;
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.categoryId,
    required this.nameLao,
    this.nameEn,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'],
        categoryId: j['category_id'],
        nameLao: j['name_lao'],
        nameEn: j['name_en'],
        price: double.tryParse(j['price'].toString()) ?? 0.0,
        imageUrl: j['image_url'],
        isAvailable: j['is_available'] == 1 || j['is_available'] == true,
      );
}

// ── Cart Item ─────────────────────────────────────────────────
class CartItem {
  final MenuItem menuItem;
  int quantity;
  String? note;

  CartItem({required this.menuItem, this.quantity = 1, this.note});

  double get total => menuItem.price * quantity;
}

// ── Order ────────────────────────────────────────────────────
class Order {
  final int id;
  final String tableNumber;
  final String? staffName;
  final String status;
  final int itemCount;
  final double? totalAmount;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.tableNumber,
    this.staffName,
    required this.status,
    required this.itemCount,
    this.totalAmount,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        tableNumber: j['table_number'] ?? '',
        staffName: j['staff_name'],
        status: j['status'] ?? '',
        itemCount: j['item_count'] ?? 0,
        totalAmount: j['total_amount'] != null ? double.tryParse(j['total_amount'].toString()) : null,
        createdAt: j['created_at'] != null ? DateTime.parse(j['created_at']) : DateTime.now(),
      );
}

// ── Bill ─────────────────────────────────────────────────────
class Bill {
  final int id;
  final int orderId;
  final double subtotal;
  final double discount;
  final double total;
  final String? paymentMethod;
  final String? paymentSlipUrl;
  final String tableNumber;

  Bill({
    required this.id,
    required this.orderId,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.paymentMethod,
    this.paymentSlipUrl,
    required this.tableNumber,
  });

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
        id: j['id'],
        orderId: j['order_id'],
        subtotal: double.tryParse(j['subtotal'].toString()) ?? 0,
        discount: double.tryParse(j['discount'].toString()) ?? 0,
        total: double.tryParse(j['total'].toString()) ?? 0,
        paymentMethod: j['payment_method'],
        paymentSlipUrl: j['payment_slip_url'],
        tableNumber: j['table_number'] ?? '',
      );
}
