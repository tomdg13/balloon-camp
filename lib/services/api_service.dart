import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
        error: true,
        logPrint: (o) => print('\ud83c\udf10 ' + o.toString()),
      ));
    }
  }

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  // ── Auth ───────────────────────────────────────────────────
  Future<Staff> login(String username, String password) async {
    final res = await _dio.post(ApiConfig.login,
        data: {'username': username, 'password': password});
    final token = res.data['token'];
    setToken(token);
    return Staff.fromJson(res.data['staff'], token);
  }

  // ── Tables ─────────────────────────────────────────────────
  Future<List<RestaurantTable>> getTables() async {
    final res = await _dio.get(ApiConfig.tables);
    return (res.data['data'] as List).map((j) => RestaurantTable.fromJson(j)).toList();
  }

  Future<void> updateTableStatus(int tableId, String status) async {
    await _dio.patch(ApiConfig.tableStatus(tableId), data: {'status': status});
  }

  // ── Menu ───────────────────────────────────────────────────
  Future<List<MenuCategory>> getFullMenu() async {
    final res = await _dio.get(ApiConfig.menuFull);
    return (res.data['data'] as List).map((j) => MenuCategory.fromJson(j)).toList();
  }

  // ── Orders ─────────────────────────────────────────────────
  Future<int> submitOrder({
    required int tableId,
    required List<CartItem> items,
    String? note,
  }) async {
    final data = {
      'table_id': tableId,
      'note': note,
      'items': items.map((c) => {
        'menu_item_id': c.menuItem.id,
        'quantity': c.quantity,
        'note': c.note,
      }).toList(),
    };
    final res = await _dio.post(ApiConfig.orders, data: data);
    return res.data['order_id'];
  }

  Future<List<Order>> getOrders({String? status}) async {
    final res = await _dio.get(ApiConfig.orders,
        queryParameters: status != null ? {'status': status} : null);
    return (res.data['data'] as List).map((j) => Order.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    final res = await _dio.get('${ApiConfig.orders}/$orderId');
    return res.data['data'];
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    await _dio.patch(ApiConfig.orderStatus(orderId), data: {'status': status});
  }

  // ── Bills ──────────────────────────────────────────────────
  Future<Bill> generateBill(int orderId, {double discount = 0}) async {
    final res = await _dio.post(ApiConfig.bills,
        data: {'order_id': orderId, 'discount': discount});
    final billId = res.data['bill_id'];
    return getBill(billId);
  }

  Future<Bill> getBill(int billId) async {
    final res = await _dio.get('${ApiConfig.bills}/$billId');
    return Bill.fromJson(res.data['data']);
  }

  Future<String> uploadPaymentSlip(int billId, File imageFile, String method) async {
    final form = FormData.fromMap({
      'slip': await MultipartFile.fromFile(imageFile.path, filename: 'slip.jpg'),
      'payment_method': method,
    });
    final res = await _dio.post(ApiConfig.billSlip(billId), data: form);
    return res.data['slip_url'];
  }

  Future<void> verifyPayment(int billId, String status, {String? note}) async {
    await _dio.post(ApiConfig.billVerify(billId),
        data: {'status': status, 'note': note});
  }

  // ── Menu image ─────────────────────────────────────────────
  Future<String> uploadMenuImage(int itemId, File imageFile) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path, filename: 'item.jpg'),
    });
    final res = await _dio.post(ApiConfig.menuItemImage(itemId), data: form);
    return res.data['image_url'];
  }

  // ── Staff management ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> getStaffList() async {
    final res = await _dio.get('/api/staff');
    return List<Map<String, dynamic>>.from(res.data['data']);
  }

  Future<void> createStaff({
    required String name,
    required String username,
    required String password,
    required String role,
  }) async {
    await _dio.post('/api/staff',
        data: {'name': name, 'username': username, 'password': password, 'role': role});
  }

  Future<void> updateStaff(int id, Map<String, dynamic> data) async {
    await _dio.patch('/api/staff/$id', data: data);
  }

  Future<void> createTable({required String tableNumber, required int capacity}) async {
    await _dio.post('/api/tables', data: {'table_number': tableNumber, 'capacity': capacity});
  }

  Future<void> updateTable(int id, Map<String, dynamic> data) async {
    await _dio.put('/api/tables/$id', data: data);
  }

  Future<void> deleteTable(int id) async {
    await _dio.delete('/api/tables/$id');
  }

  Future<void> createMenuItem({required int categoryId, required String nameLao, String? nameEn, double price = 0}) async {
    await _dio.post('/api/menu/items', data: {'category_id': categoryId, 'name_lao': nameLao, 'name_en': nameEn, 'price': price});
  }

  Future<void> updateMenuItem(int id, Map<String, dynamic> data) async {
    await _dio.patch('/api/menu/items/$id', data: data);
  }

  // Upload image from web (bytes)
  Future<String> uploadMenuImageBytes(int itemId, Uint8List bytes, String filename) async {
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post(ApiConfig.menuItemImage(itemId), data: form);
    return res.data['image_url'];
  }

  // Upload payment slip from web (bytes)
  Future<String> uploadPaymentSlipBytes(int billId, dynamic bytes, String filename) async {
    final form = FormData.fromMap({
      'slip': MultipartFile.fromBytes(bytes, filename: filename),
      'payment_method': 'transfer',
    });
    final res = await _dio.post(ApiConfig.billSlip(billId), data: form);
    return res.data['slip_url'];
  }

  Future<Map<String, dynamic>> getSettings() async {
    final res = await _dio.get('/api/staff/settings');
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<String> uploadBankQr(File imageFile) async {
    final form = FormData.fromMap({'image': await MultipartFile.fromFile(imageFile.path, filename: 'bank_qr.jpg')});
    final res = await _dio.post('/api/staff/settings/bank-qr', data: form);
    return res.data['bank_qr_url'];
  }

  Future<String> uploadBankQrBytes(Uint8List bytes, String filename) async {
    final form = FormData.fromMap({'image': MultipartFile.fromBytes(bytes, filename: filename)});
    final res = await _dio.post('/api/staff/settings/bank-qr', data: form);
    return res.data['bank_qr_url'];
  }
}
