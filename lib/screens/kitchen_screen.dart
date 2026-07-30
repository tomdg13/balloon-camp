import 'package:flutter/material.dart';
import 'dart:async';
import '../models/models.dart';
import '../services/api_service.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});
  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    // Auto-refresh every 15 seconds
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await ApiService().getOrders(status: 'sent_to_kitchen');
      if (mounted) setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markReady(int orderId) async {
    try {
      await ApiService().updateOrderStatus(orderId, 'ready');
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ອໍເດີພ້ອມແລ້ວ ✓'),
                backgroundColor: Color(0xFF4CAF50)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e'),
                backgroundColor: const Color(0xFFE94560)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF16213E),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const Text('ຄົວ · ອໍເດີທີ່ລໍຖ້າ',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              if (_orders.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE94560),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('\${_orders.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadOrders),
            ],
          ),
        ),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 80),
                      SizedBox(height: 16),
                      Text('ບໍ່ມີອໍເດີທີ່ລໍຖ້າ',
                          style: TextStyle(color: Colors.white54, fontSize: 20)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (_, i) => _OrderCard(
                      order: _orders[i],
                      onReady: () => _markReady(_orders[i].id),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback onReady;
  const _OrderCard({required this.order, required this.onReady});
  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  Map<String, dynamic>? _detail;
  bool _expanded = false;

  Future<void> _loadDetail() async {
    if (_detail != null) return;
    try {
      final d = await ApiService().getOrderDetail(widget.order.id);
      if (mounted) setState(() => _detail = d);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final elapsed = DateTime.now().difference(order.createdAt);
    final isUrgent = elapsed.inMinutes >= 15;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isUrgent ? const Color(0xFFFF9800) : const Color(0xFF0F3460),
            width: 2),
      ),
      child: Column(
        children: [
          // Header
          ListTile(
            leading: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE94560).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(order.tableNumber,
                    style: const TextStyle(
                        color: Color(0xFFE94560),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
            title: Text('ໂຕະ ${order.tableNumber} · ${order.itemCount} ລາຍການ',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${elapsed.inMinutes} ນາທີທີ່ຜ່ານມາ · ${order.staffName}',
              style: TextStyle(
                  color: isUrgent ? const Color(0xFFFF9800) : Colors.white54),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white54),
                  onPressed: () {
                    setState(() => _expanded = !_expanded);
                    if (_expanded) _loadDetail();
                  },
                ),
              ],
            ),
          ),

          // Items detail (expandable)
          if (_expanded)
            _detail == null
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: Color(0xFFE94560)))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      children: [
                        ...(_detail!['items'] as List).map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE94560),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text('${item['quantity']}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(item['name_lao'],
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 14)),
                                  ),
                                  if (item['note'] != null && item['note'] != '')
                                    Text(item['note'],
                                        style: const TextStyle(
                                            color: Colors.white38, fontSize: 12)),
                                ],
                              ),
                            )),
                        if (_detail!['note'] != null && _detail!['note'] != '')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.note, color: Colors.white38, size: 16),
                                const SizedBox(width: 8),
                                Text(_detail!['note'],
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

          // Ready button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: widget.onReady,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('ອາຫານພ້ອມແລ້ວ',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
