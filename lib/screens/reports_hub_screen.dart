import 'package:flutter/material.dart';
import 'report_screen.dart';
import 'transactions_screen.dart';

class ReportsHubScreen extends StatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen> {
  int? _selected; // null = show menu, 0 = transactions, 1 = sales report

  @override
  Widget build(BuildContext context) {
    if (_selected == 0) return _wrapWithBack(const TransactionsScreen());
    if (_selected == 1) return _wrapWithBack(const ReportScreen());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ລາຍງານ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          _menuTile(
            icon: Icons.receipt_long,
            title: 'ລາຍການທຸລະກຳ',
            subtitle: 'Transaction list — table, amount, payment method',
            onTap: () => setState(() => _selected = 0),
          ),
          const SizedBox(height: 12),
          _menuTile(
            icon: Icons.bar_chart,
            title: 'ລາຍງານຍອດຂາຍ',
            subtitle: 'Sales summary — revenue, top items, payment split',
            onTap: () => setState(() => _selected = 1),
          ),
        ],
      ),
    );
  }

  Widget _wrapWithBack(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: TextButton.icon(
            onPressed: () => setState(() => _selected = null),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('ກັບຄືນ'),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
