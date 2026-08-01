import 'package:flutter/material.dart';
import 'dart:async';
import '../models/models.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
                  child: Text('${_orders.length}',
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
                      onAllPrepared: _loadOrders,
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
  final VoidCallback onAllPrepared;
  const _OrderCard({required this.order, required this.onAllPrepared});
  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  Map<String, dynamic>? _detail;
  bool _loadingDetail = true;
  final Set<int> _togglingIds = {};

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final d = await ApiService().getOrderDetail(widget.order.id);
      if (mounted) setState(() { _detail = d; _loadingDetail = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _toggleItem(int itemId, bool newValue) async {
    setState(() => _togglingIds.add(itemId));
    try {
      final allPrepared = await ApiService().toggleItemPrepared(widget.order.id, itemId, newValue);
      // Reload fresh detail from server to reflect the real state (avoids mutating an unmodifiable list)
      final d = await ApiService().getOrderDetail(widget.order.id);
      if (mounted) {
        setState(() {
          _detail = d;
          _togglingIds.remove(itemId);
        });
      }
      if (allPrepared) {
        await ApiService().callWaiter(widget.order.id);
        widget.onAllPrepared();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _togglingIds.remove(itemId));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e'),
                backgroundColor: const Color(0xFFE94560)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final elapsed = DateTime.now().difference(order.createdAt);
    final isUrgent = elapsed.inMinutes >= 15;
    final items = _detail?['items'] as List? ?? [];
    final doneCount = items.where((it) => it['prepared'] == 1).length;

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
            title: Text('ໂຕະ ${order.tableNumber} · $doneCount/${items.length} ລາຍການ',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${elapsed.inMinutes} ນາທີທີ່ຜ່ານມາ · ${order.staffName}',
              style: TextStyle(
                  color: isUrgent ? const Color(0xFFFF9800) : Colors.white54),
            ),
          ),

          _loadingDetail
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      ...items.map((item) {
                        final itemId = item['id'] as int;
                        final isPrepared = item['prepared'] == 1;
                        final isCancelled = item['cancelled'] == 1;
                        final isToggling = _togglingIds.contains(itemId);
                        return InkWell(
                          onTap: (isToggling || isPrepared) ? null : () => _toggleItem(itemId, true),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                isToggling
                                    ? const SizedBox(
                                        width: 24, height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE94560)))
                                    : Checkbox(
                                        value: isPrepared,
                                        activeColor: const Color(0xFF4CAF50),
                                        onChanged: isPrepared ? null : (v) => _toggleItem(itemId, true),
                                      ),
                                if (item['image_url'] != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: CachedNetworkImage(
                                      imageUrl: item['image_url'],
                                      width: 36, height: 36,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 36, height: 36,
                                        color: const Color(0xFF0F3460),
                                        child: const Icon(Icons.restaurant, color: Colors.white38, size: 18),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: isPrepared ? const Color(0xFF4CAF50) : const Color(0xFFE94560),
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
                                  child: Text(
                                      isCancelled ? '${item['name_lao']} (ຍົກເລີກ)' : item['name_lao'],
                                      style: TextStyle(
                                          color: isCancelled
                                              ? const Color(0xFFE94560)
                                              : (isPrepared ? Colors.white38 : Colors.white),
                                          fontSize: 14,
                                          decoration: (isPrepared || isCancelled) ? TextDecoration.lineThrough : null)),
                                ),
                                if (item['note'] != null && item['note'] != '')
                                  Text(item['note'],
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 12)),

                              ],
                            ),
                          ),
                        );
                      }),
                      if (_detail?['note'] != null && _detail!['note'] != '')
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
        ],
      ),
    );
  }
}
