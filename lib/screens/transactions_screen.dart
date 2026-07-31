import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'bill_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _api = ApiService();
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  bool _loading = true;
  List<dynamic> _transactions = [];

  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _timeFmt = DateFormat('MM/dd HH:mm');
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
    final transactions = await _api.getReportTransactions(from, to);
    if (!mounted) return;
    setState(() {
      _transactions = transactions;
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

  double get _totalSum => _transactions.fold(
      0.0, (sum, tx) => sum + (double.tryParse(tx['total'].toString()) ?? 0));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Text('${_transactions.length} bills · ${_money.format(_totalSum)} kip',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text('${_dateFmt.format(_from)} → ${_dateFmt.format(_to)}'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty
                  ? const Center(child: Text('No transactions in this range'))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                          color: Colors.white,
                          child: DataTable(
                            showCheckboxColumn: false,
                            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                            headingTextStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                            dataTextStyle: const TextStyle(color: Colors.black87),
                            columns: const [
                              DataColumn(label: Text('Bill #')),
                              DataColumn(label: Text('Table')),
                              DataColumn(label: Text('Subtotal'), numeric: true),
                              DataColumn(label: Text('Discount'), numeric: true),
                              DataColumn(label: Text('Total'), numeric: true),
                              DataColumn(label: Text('Payment')),
                              DataColumn(label: Text('Staff')),
                              DataColumn(label: Text('Date')),
                            ],
                            rows: _transactions.map((tx) {
                              final subtotal = double.tryParse(tx['subtotal'].toString()) ?? 0;
                              final discount = double.tryParse(tx['discount'].toString()) ?? 0;
                              final total = double.tryParse(tx['total'].toString()) ?? 0;
                              final method = _paymentLabel(tx['payment_method']);
                              final createdAt = DateTime.tryParse(tx['created_at'] ?? '');
                              return DataRow(
                                onSelectChanged: (_) => _openBill(tx),
                                cells: [
                                DataCell(Text('#${tx['bill_id']}')),
                                DataCell(Text(tx['table_number']?.toString() ?? '')),
                                DataCell(Text(_money.format(subtotal))),
                                DataCell(Text(_money.format(discount))),
                                DataCell(Text(_money.format(total), style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_paymentIcon(tx['payment_method']), size: 15, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(method),
                                  ],
                                )),
                                DataCell(Text(tx['staff_name'] ?? '')),
                                DataCell(Text(createdAt != null ? _timeFmt.format(createdAt) : '')),
                              ]);
                            }).toList(),
                          ),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }



  void _openBill(Map tx) {
    final orderId = tx['order_id'] as int?;
    if (orderId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BillScreen(orderId: orderId)),
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
      case 'other':
        return Icons.credit_card;
      default:
        return Icons.help_outline;
    }
  }
}
