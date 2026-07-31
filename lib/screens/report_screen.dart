import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/export_button.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _api = ApiService();
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  bool _loading = true;

  Map<String, dynamic>? _summary;
  List<dynamic> _daily = [];
  List<dynamic> _topItems = [];
  List<dynamic> _paymentMethods = [];

  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _money = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final from = _dateFmt.format(_from);
    final to = _dateFmt.format(_to);
    final results = await Future.wait([
      _api.getReportSummary(from, to),
      _api.getReportDaily(from, to),
      _api.getReportTopItems(from, to),
      _api.getReportPaymentMethods(from, to),
    ]);
    if (!mounted) return;
    setState(() {
      _summary = results[0] as Map<String, dynamic>;
      _daily = results[1] as List<dynamic>;
      _topItems = results[2] as List<dynamic>;
      _paymentMethods = results[3] as List<dynamic>;
      _loading = false;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sales Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text('${_dateFmt.format(_from)} → ${_dateFmt.format(_to)}'),
                    ),
                    const SizedBox(width: 10),
                    ExportButton(
                      dio: _api.dioForExport,
                      from: _dateFmt.format(_from),
                      to: _dateFmt.format(_to),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            const Text('Revenue by day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SizedBox(height: 200, child: _buildDailyChart()),
            const SizedBox(height: 24),
            const Text('Top selling items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildTopItemsTable(),
            const SizedBox(height: 24),
            const Text('Payment methods', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildPaymentMethodsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final orderCount = _summary?['order_count'] ?? 0;
    final revenue = double.tryParse(_summary?['total_revenue']?.toString() ?? '0') ?? 0;
    final avgOrder = double.tryParse(_summary?['avg_order_value']?.toString() ?? '0') ?? 0;

    return Row(
      children: [
        Expanded(child: _statCard('Revenue', '${_money.format(revenue)} kip')),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Orders', '$orderCount')),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Avg order', '${_money.format(avgOrder)} kip')),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDailyChart() {
    if (_daily.isEmpty) return const Center(child: Text('No data for this range'));
    final spots = <FlSpot>[];
    for (var i = 0; i < _daily.length; i++) {
      final revenue = double.tryParse(_daily[i]['revenue'].toString()) ?? 0;
      spots.add(FlSpot(i.toDouble(), revenue));
    }
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemsTable() {
    if (_topItems.isEmpty) return const Text('No sales in this range');
    return Column(
      children: _topItems.map((item) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(item['name_lao'] ?? ''),
          trailing: Text('${item['qty_sold']} sold · ${_money.format(double.tryParse(item['revenue'].toString()) ?? 0)} kip'),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodsList() {
    if (_paymentMethods.isEmpty) return const Text('No data');
    return Column(
      children: _paymentMethods.map((pm) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(_paymentIcon(pm['payment_method'])),
          title: Text(_paymentLabel(pm['payment_method'])),
          trailing: Text('${pm['count']} · ${_money.format(double.tryParse(pm['revenue'].toString()) ?? 0)} kip'),
        );
      }).toList(),
    );
  }




  String _paymentLabel(String? method) {
    switch (method) {
      case 'cash':
        return 'cash';
      case 'transfer':
        return 'QR';
      case 'other':
        return 'POS';
      default:
        return 'unpaid';
    }
  }

  IconData _paymentIcon(String? method) {
    switch (method) {
      case 'cash':
        return Icons.payments;
      case 'transfer':
        return Icons.qr_code;
      default:
        return Icons.credit_card;
    }
  }
}
