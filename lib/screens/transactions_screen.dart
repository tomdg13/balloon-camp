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
  final _money = NumberFormat.decimalPattern();
  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _timeFmt = DateFormat('MM/dd HH:mm');
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  bool _loading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final transactions = await _api.getReportTransactions(
          _dateFmt.format(_from), _dateFmt.format(_to));
      if (mounted) setState(() { _transactions = transactions; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked != null) {
      setState(() { _from = picked.start; _to = picked.end; });
      _loadData();
    }
  }

  double get _totalSum => _transactions.fold(
      0.0, (sum, tx) => sum + (double.tryParse(tx['total'].toString()) ?? 0));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Transactions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range, size: 16),
                label: Text('${_dateFmt.format(_from)} → ${_dateFmt.format(_to)}',
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        // Summary bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Text('${_transactions.length} bills · ${_money.format(_totalSum)} kip',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
        // Table
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
                              headingTextStyle: const TextStyle(
                                  color: Colors.black87, fontWeight: FontWeight.w600),
                              dataTextStyle: const TextStyle(color: Colors.black87),
                              columns: const [
                                DataColumn(label: Text('Bill #')),
                                DataColumn(label: Text('Table')),
                                DataColumn(label: Text('ກຸ່ມ')),
                                DataColumn(label: Text('Subtotal'), numeric: true),
                                DataColumn(label: Text('Discount'), numeric: true),
                                DataColumn(label: Text('Total'), numeric: true),
                                DataColumn(label: Text('ລວມອໍເດີ'), numeric: true),
                                DataColumn(label: Text('Payment')),
                                DataColumn(label: Text('Staff')),
                                DataColumn(label: Text('Date')),
                              ],
                              rows: _transactions.map((tx) {
                                final subtotal = double.tryParse(tx['subtotal'].toString()) ?? 0;
                                final discount = double.tryParse(tx['discount'].toString()) ?? 0;
                                final total = double.tryParse(tx['total'].toString()) ?? 0;
                                final orderTotal = double.tryParse(tx['order_total']?.toString() ?? '0') ?? 0;
                                final splitGroup = tx['split_group'];
                                final isSplit = splitGroup != null;
                                final method = _paymentLabel(tx['payment_method']);
                                final createdAt = DateTime.tryParse(tx['created_at'] ?? '');

                                return DataRow(
                                  color: isSplit
                                      ? WidgetStateProperty.all(Colors.orange.shade50)
                                      : null,
                                  onSelectChanged: (_) => _openBill(tx),
                                  cells: [
                                    DataCell(Text('#${tx['bill_id']}')),
                                    DataCell(Text(tx['table_number']?.toString() ?? '')),
                                    // Split group cell
                                    DataCell(
                                      isSplit
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: splitGroup == 1
                                                    ? const Color(0xFFE94560).withValues(alpha: 0.15)
                                                    : const Color(0xFF4CAF50).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'ກຸ່ມ $splitGroup',
                                                style: TextStyle(
                                                  color: splitGroup == 1
                                                      ? const Color(0xFFE94560)
                                                      : const Color(0xFF4CAF50),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            )
                                          : const Text('-',
                                              style: TextStyle(color: Colors.black38)),
                                    ),
                                    DataCell(Text(_money.format(subtotal))),
                                    DataCell(Text(_money.format(discount))),
                                    DataCell(Text(_money.format(total),
                                        style: const TextStyle(fontWeight: FontWeight.w600))),
                                    // Order total (sum of all split bills)
                                    DataCell(
                                      isSplit
                                          ? Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Order #${tx['order_id']}',
                                                  style: TextStyle(
                                                      color: Colors.grey.shade500,
                                                      fontSize: 11),
                                                ),
                                                Text(
                                                  _money.format(orderTotal),
                                                  style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            )
                                          : const Text('-',
                                              style: TextStyle(color: Colors.black38)),
                                    ),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_paymentIcon(tx['payment_method']),
                                            size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(method),
                                      ],
                                    )),
                                    DataCell(Text(tx['staff_name'] ?? '')),
                                    DataCell(Text(createdAt != null
                                        ? _timeFmt.format(createdAt)
                                        : '')),
                                  ],
                                );
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
    final billId = tx['bill_id'] as int?;
    final splitGroup = tx['split_group'] as int?;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillScreen(
          orderId: orderId,
          billId: billId,
          splitGroup: splitGroup,
        ),
      ),
    );
  }

  String _paymentLabel(String? method) {
    switch (method) {
      case 'cash': return 'cash';
      case 'transfer': return 'QR';
      case 'other': return 'POS';
      default: return 'unpaid';
    }
  }

  IconData _paymentIcon(String? method) {
    switch (method) {
      case 'cash': return Icons.payments;
      case 'transfer': return Icons.qr_code;
      case 'other': return Icons.credit_card;
      default: return Icons.help_outline;
    }
  }
}
