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
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  Timer? _timer;
  final Set<String> _acting = {};

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
      final results = await Future.wait([
        ApiService().getItemsReady(),
        ApiService().getWaiterCalls(),
      ]);
      final items = results[0];
      final calls = results[1];
      final merged = <Map<String, dynamic>>[
        ...items.map((it) => {
              'type': 'item',
              'key': 'item_${it['id']}',
              'id': it['id'],
              'table_number': it['table_number'],
              'quantity': it['quantity'],
              'name_lao': it['name_lao'],
              'image_url': it['image_url'],
            }),
        ...calls.map((c) => {
              'type': 'call',
              'key': 'call_${c['id']}',
              'id': c['id'],
              'table_number': c['table_number'],
              'waiter_called_at': c['waiter_called_at'],
              'call_type': c['call_type'],
            }),
      ];
      if (mounted) setState(() { _entries = merged; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markServed(int itemId, String key) async {
    setState(() => _acting.add(key));
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
      if (mounted) setState(() => _acting.remove(key));
    }
  }

  Future<void> _clearCall(int orderId, String key) async {
    setState(() => _acting.add(key));
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
      if (mounted) setState(() => _acting.remove(key));
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
              const Text('ອາຫານພ້ອມ · ເອີ້ນພະນັກງານ',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              if (_entries.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${_entries.length}',
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
              : _entries.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 80),
                          SizedBox(height: 16),
                          Text('ບໍ່ມີສິ່ງທີ່ລໍຖ້າ',
                              style: TextStyle(color: Colors.white54, fontSize: 20)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (_, i) {
                          final entry = _entries[i];
                          final isCall = entry['type'] == 'call';
                          final key = entry['key'] as String;
                          final isActing = _acting.contains(key);
                          final accentColor = isCall
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF2196F3);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16213E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: accentColor, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: isCall
                                      ? Container(
                                          width: 52, height: 52,
                                          color: accentColor.withValues(alpha: 0.15),
                                          child: Icon(Icons.notifications_active, color: accentColor),
                                        )
                                      : (entry['image_url'] != null
                                          ? CachedNetworkImage(
                                              imageUrl: entry['image_url'],
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
                                            )),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('${entry['table_number']}',
                                      style: TextStyle(
                                          color: accentColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isCall
                                        ? (entry['call_type'] == 'bill'
                                            ? '💰 ລູກຄ້າຂໍເກັບເງິນ/ອອກບິນ'
                                            : '🔔 ລູກຄ້າເອີ້ນພະນັກງານ')
                                        : '${entry['quantity']}x ${entry['name_lao']}',
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ),
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    onPressed: isActing
                                        ? null
                                        : () => isCall
                                            ? _clearCall(entry['id'] as int, key)
                                            : _markServed(entry['id'] as int, key),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: isActing
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
