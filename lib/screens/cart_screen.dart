import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'order_success_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  Future<void> _submitOrder() async {
    final provider = context.read<AppProvider>();
    if (provider.cart.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final tableNumber = provider.selectedTable?.tableNumber ?? '';
      final orderId = await provider.submitOrder(note: _noteCtrl.text.trim());
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => OrderSuccessScreen(
            orderId: orderId,
            tableNumber: tableNumber,
          )),
          (r) => r.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ສົ່ງອໍເດີບໍ່ສຳເລັດ: $e'),
                backgroundColor: const Color(0xFFE94560)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cart = provider.cart;
    final table = provider.selectedTable;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text('ກະຕ່າ · ໂຕະ ${table?.tableNumber ?? ''}',
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, color: Colors.white24, size: 80),
                  SizedBox(height: 16),
                  Text('ກະຕ່າຫວ່າງເປົ່າ',
                      style: TextStyle(color: Colors.white54, fontSize: 18)),
                ],
              ),
            )
          : Column(
              children: [
                // Items list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = cart[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.menuItem.nameLao,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  if (c.menuItem.price > 0)
                                    Text(
                                      '${c.menuItem.price.toStringAsFixed(0)} ກີບ x ${c.quantity} = ${c.total.toStringAsFixed(0)} ກີບ',
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 13),
                                    ),
                                ],
                              ),
                            ),
                            // Qty controls
                            Row(
                              children: [
                                _qtyBtn(Icons.remove,
                                    () => provider.removeFromCart(c.menuItem)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('${c.quantity}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ),
                                _qtyBtn(Icons.add,
                                    () => provider.addToCart(c.menuItem)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Color(0xFFE94560)),
                              onPressed: () =>
                                  provider.removeItemCompletely(c.menuItem.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Note + Summary + Submit
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16213E),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _noteCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'ໝາຍເຫດ (ຖ້າມີ)',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.note, color: Colors.white38),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE94560)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ລວມທັງໝົດ',
                              style: TextStyle(color: Colors.white70, fontSize: 16)),
                          Text(
                            '${provider.cartTotal.toStringAsFixed(0)} ກີບ',
                            style: const TextStyle(
                                color: Color(0xFFE94560),
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submitOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE94560),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: _submitting
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send, color: Colors.white),
                          label: Text(
                            _submitting ? 'ກຳລັງສົ່ງ...' : 'ສົ່ງໄປຄົວ',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0F3460),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );
}
