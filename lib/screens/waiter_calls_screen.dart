import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';

class WaiterCallsScreen extends StatefulWidget {
  const WaiterCallsScreen({super.key});
  @override
  State<WaiterCallsScreen> createState() => _WaiterCallsScreenState();
}

class _WaiterCallsScreenState extends State<WaiterCallsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  Timer? _timer;
  final Set<int> _serving = {};

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await ApiService().getItemsReady();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markServed(int itemId) async {
    setState(() => _serving.add(itemId));
    try {
      await ApiService().markItemServed(itemId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e'),
                backgroundColor: const Color(0xFFE94560)));
      }
    } finally {
      if (mounted) setState(() => _serving.remove(itemId));
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
              const Text('ອາຫານພ້ອມ · ໄປຮັບເລີຍ',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              if (_items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${_items.length}',
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
              : _items.isEmpty
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
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          final itemId = item['id'] as int;
                          final isServing = _serving.contains(itemId);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF2196F3), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: item['image_url'] != null
                                      ? CachedNetworkImage(
                                          imageUrl: item['image_url'],
                                          width: 52, height: 52,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => Container(
                                            width: 52, height: 52,
                                            color: const Color(0xFF0F3460),
                                            child: const Icon(Icons.restaurant, color: Colors.white38),
                                          ),
                                        )
                                      : Container(
                                          width: 52, height: 52,
                                          color: const Color(0xFF0F3460),
                                          child: const Icon(Icons.restaurant, color: Colors.white38),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('${item['table_number']}',
                                      style: const TextStyle(
                                          color: Color(0xFF2196F3),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('${item['quantity']}x ${item['name_lao']}',
                                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                                ),
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    onPressed: isServing ? null : () => _markServed(itemId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: isServing
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.check, color: Colors.white, size: 16),
                                    label: const Text('ຮັບແລ້ວ', style: TextStyle(color: Colors.white, fontSize: 13)),
                                  ),
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
