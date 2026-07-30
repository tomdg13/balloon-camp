import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'menu_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final int orderId;
  final String tableNumber;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.tableNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 80),
            ),
            const SizedBox(height: 24),
            const Text('ສົ່ງໄປຄົວສຳເລັດ!',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('ໂຕະ $tableNumber · ອໍເດີ #$orderId',
                style: const TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('ສາມາດສັ່ງໂຕະອື່ນ ຫຼື ສັ່ງເພີ່ມໃຫ້ໂຕະນີ້ໄດ້',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 48),

            // Order more for same table
            SizedBox(
              width: 300,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MenuScreen()),
                  (r) => r.isFirst,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: Text('ສັ່ງເພີ່ມໂຕະ $tableNumber',
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),

            // Go to another table
            SizedBox(
              width: 300,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AppProvider>().clearTableSelection();
                  Navigator.pushNamedAndRemoveUntil(context, '/main', (r) => false);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.table_restaurant, color: Colors.white54),
                label: const Text('ສັ່ງໂຕະອື່ນ',
                    style: TextStyle(color: Colors.white54, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
