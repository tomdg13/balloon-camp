import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});
  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  List<dynamic> _summary = [];
  bool _loading = true;

  int? _daysUntil(String? dateStr) {
    if (dateStr == null) return null;
    final d = DateTime.tryParse(dateStr);
    if (d == null) return null;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return d.difference(todayDate).inDays;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getStockTransactionsSummary();
      if (mounted) setState(() { _summary = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openHistory(dynamic item) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _HistorySheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF16213E),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Text('ລາຍງານວັດຖຸດິບ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
              ],
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFFE94560))))
          else if (_summary.isEmpty)
            const Expanded(child: Center(child: Text('ບໍ່ມີຂໍ້ມູນ', style: TextStyle(color: Colors.white54))))
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F3460),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 44),
                          SizedBox(width: 10),
                          Expanded(flex: 3, child: Text('ວັດຖຸດິບ', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('ເພີ່ມ', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('ໃຊ້', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('ຄົງເຫຼືອ', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                          SizedBox(width: 24),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._summary.map((item) {
                      final added = double.tryParse(item['total_added'].toString()) ?? 0;
                      final used = double.tryParse(item['total_used'].toString()) ?? 0;
                      final current = double.tryParse(item['current_quantity'].toString()) ?? 0;
                      final unit = item['unit'];
                      return InkWell(
                        onTap: () => _openHistory(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16213E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: item['image_url'] != null
                                      ? CachedNetworkImage(
                                          imageUrl: item['image_url'],
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(color: const Color(0xFF0F3460)),
                                          errorWidget: (_, __, ___) => Container(
                                              color: const Color(0xFF0F3460),
                                              child: const Icon(Icons.restaurant, color: Colors.white24, size: 18)),
                                        )
                                      : Container(
                                          color: const Color(0xFF0F3460),
                                          child: const Icon(Icons.restaurant, color: Colors.white24, size: 18)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${item['name_lao']}',
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Builder(builder: (_) {
                                      final days = _daysUntil(item['nearest_expiry']?.toString());
                                      if (days == null) return const SizedBox.shrink();
                                      final expired = days < 0;
                                      final soon = days <= 1;
                                      return Text(
                                        expired ? 'ໝົດອາຍຸແລ້ວ' : (soon ? 'ໃກ້ໝົດອາຍຸ' : 'ອີກ $days ມື້'),
                                        style: TextStyle(
                                          color: expired || soon ? const Color(0xFFE94560) : Colors.white38,
                                          fontSize: 10,
                                          fontWeight: expired || soon ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('+${added.toStringAsFixed(2)} $unit',
                                    style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('-${used.toStringAsFixed(2)} $unit',
                                    style: const TextStyle(color: Color(0xFFE94560), fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('${current.toStringAsFixed(2)} $unit',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistorySheet extends StatefulWidget {
  final dynamic item;
  const _HistorySheet({required this.item});
  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  List<dynamic> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService().getStockTransactions(widget.item['id']);
      if (mounted) setState(() { _history = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('${widget.item['name_lao']} · ປະຫວັດ', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
                : _history.isEmpty
                    ? const Center(child: Text('ບໍ່ມີປະຫວັດ', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _history.length,
                        itemBuilder: (_, i) {
                          final e = _history[i];
                          final isAdd = e['type'] == 'add';
                          final qty = double.tryParse(e['quantity'].toString()) ?? 0;
                          final t = DateTime.tryParse(e['created_at']?.toString() ?? '');
                          final dateLabel = t == null
                              ? ''
                              : '${t.day.toString().padLeft(2, "0")}/${t.month.toString().padLeft(2, "0")}/${t.year} ${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F3460),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isAdd ? Icons.add_circle : Icons.remove_circle,
                                  color: isAdd ? const Color(0xFF4CAF50) : const Color(0xFFE94560),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(isAdd ? 'ເພີ່ມ' : 'ໃຊ້', style: TextStyle(color: isAdd ? const Color(0xFF4CAF50) : const Color(0xFFE94560), fontSize: 13, fontWeight: FontWeight.bold)),
                                      if (e['note'] != null) Text('${e['note']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                      Text(dateLabel, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                      if (e['expiry_date'] != null)
                                        Text('ໝົດອາຍຸ: ${e['expiry_date'].toString().substring(0, 10)}',
                                            style: const TextStyle(color: Colors.white24, fontSize: 10)),
                                    ],
                                  ),
                                ),
                                Text('${isAdd ? "+" : "-"}${qty.toStringAsFixed(2)}',
                                    style: TextStyle(color: isAdd ? const Color(0xFF4CAF50) : const Color(0xFFE94560), fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
