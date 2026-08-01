import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WaiterCallsScreen extends StatefulWidget {
  const WaiterCallsScreen({super.key});
  @override
  State<WaiterCallsScreen> createState() => _WaiterCallsScreenState();
}

class _WaiterCallsScreenState extends State<WaiterCallsScreen> {
  List<dynamic> _calls = [];
  bool _loading = true;
  Timer? _timer;
  final Set<int> _clearing = {};

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final calls = await ApiService().getWaiterCalls();
      if (mounted) setState(() { _calls = calls; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clear(int orderId) async {
    setState(() => _clearing.add(orderId));
    try {
      await ApiService().clearWaiterCall(orderId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e'),
                backgroundColor: const Color(0xFFE94560)));
      }
    } finally {
      if (mounted) setState(() => _clearing.remove(orderId));
    }
  }

  String _elapsed(String? isoTime) {
    if (isoTime == null) return '';
    final t = DateTime.tryParse(isoTime);
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'ຫາກໍ';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ນາທີ';
    return '${diff.inHours} ຊົ່ວໂມງ';
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
              const Text('ອາຫານພ້ອມ · ໄປຮັບເລີຍ',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              if (_calls.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${_calls.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _load),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : _calls.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 80),
                          SizedBox(height: 16),
                          Text('ບໍ່ມີອາຫານທີ່ລໍຖ້າຮັບ',
                              style: TextStyle(color: Colors.white54, fontSize: 20)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _calls.length,
                        itemBuilder: (_, i) {
                          final call = _calls[i];
                          final orderId = call['id'] as int;
                          final isClearing = _clearing.contains(orderId);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF2196F3), width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 56, height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text('${call['table_number']}',
                                            style: const TextStyle(
                                                color: Color(0xFF2196F3),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('ໂຕະ ${call['table_number']}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text('${_elapsed(call['waiter_called_at'])} ທີ່ຜ່ານມາ',
                                              style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 40,
                                      child: ElevatedButton.icon(
                                        onPressed: isClearing ? null : () => _clear(orderId),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4CAF50),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: isClearing
                                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Icon(Icons.check, color: Colors.white, size: 18),
                                        label: const Text('ຮັບແລ້ວ', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: Colors.white12),
                                FutureBuilder<Map<String, dynamic>>(
                                  future: ApiService().getOrderDetail(orderId),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        child: SizedBox(
                                            height: 16, width: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE94560))),
                                      );
                                    }
                                    final items = snapshot.data!['items'] as List? ?? [];
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: items.map((item) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            children: [
                                              if (item['image_url'] != null) ...[
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: CachedNetworkImage(
                                                    imageUrl: item['image_url'],
                                                    width: 32, height: 32,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (_, __, ___) => Container(
                                                      width: 32, height: 32,
                                                      color: const Color(0xFF0F3460),
                                                      child: const Icon(Icons.restaurant, color: Colors.white38, size: 16),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Text('${item['quantity']}x',
                                                  style: const TextStyle(color: Color(0xFFE94560), fontSize: 13, fontWeight: FontWeight.bold)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(item['name_lao'] ?? '',
                                                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
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
