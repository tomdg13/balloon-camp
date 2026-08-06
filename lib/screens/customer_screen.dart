import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class Customer {
  final int id;
  final String name;
  final String phone;
  final int points;
  final double totalSpent;
  final int visitCount;
  final String? note;
  final bool isActive;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.points,
    required this.totalSpent,
    required this.visitCount,
    this.note,
    required this.isActive,
  });

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'],
        name: j['name'],
        phone: j['phone'],
        points: j['points'] ?? 0,
        totalSpent: double.tryParse(j['total_spent'].toString()) ?? 0,
        visitCount: j['visit_count'] ?? 0,
        note: j['note'],
        isActive: (j['is_active'] ?? 1) == 1,
      );
}

class Promotion {
  final int id;
  final String nameLao;
  final String nameEn;
  final String type; // percent | fixed | points
  final double value;
  final int pointsRequired;
  final double minSpend;
  final double maxDiscount;
  final bool isActive;

  Promotion({
    required this.id,
    required this.nameLao,
    required this.nameEn,
    required this.type,
    required this.value,
    required this.pointsRequired,
    required this.minSpend,
    required this.maxDiscount,
    required this.isActive,
  });

  factory Promotion.fromJson(Map<String, dynamic> j) => Promotion(
        id: j['id'],
        nameLao: j['name_lao'],
        nameEn: j['name_en'],
        type: j['type'],
        value: double.tryParse(j['value'].toString()) ?? 0,
        pointsRequired: j['points_required'] ?? 0,
        minSpend: double.tryParse(j['min_spend'].toString()) ?? 0,
        maxDiscount: double.tryParse(j['max_discount'].toString()) ?? 0,
        isActive: (j['is_active'] ?? 1) == 1,
      );

  String get typeLabel {
    switch (type) {
      case 'percent': return '${value.toStringAsFixed(0)}%';
      case 'fixed': return '${NumberFormat.decimalPattern().format(value)} ກີບ';
      case 'points': return '$pointsRequired ຄະແນນ';
      default: return type;
    }
  }
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  static const _bg = Color(0xFF1A1A2E);
  static const _card = Color(0xFF16213E);
  static const _deep = Color(0xFF0F3460);
  static const _red = Color(0xFFE94560);
  static const _green = Color(0xFF4CAF50);
  static const _orange = Color(0xFFFF9800);

  // customers tab
  List<Customer> _customers = [];
  bool _loadingC = false;
  final _searchCtrl = TextEditingController();

  // promotions tab
  List<Promotion> _promotions = [];
  bool _loadingP = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadCustomers();
    _loadPromotions();
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── API ────────────────────────────────────────────────────────────────────

  Future<void> _loadCustomers({String search = ''}) async {
    setState(() => _loadingC = true);
    try {
      final q = search.isNotEmpty ? '?search=${Uri.encodeComponent(search)}' : '';
      final res = await ApiService().dioForExport.get('/api/customers$q');
      final d1 = res.data;
      if (d1['success']) {
        setState(() => _customers = (d1['data'] as List).map((e) => Customer.fromJson(e)).toList());
      }
    } catch (_) {} finally {
      setState(() => _loadingC = false);
    }
  }

  Future<void> _loadPromotions() async {
    setState(() => _loadingP = true);
    try {
      final res = await ApiService().dioForExport.get('/api/customers/promotions/all');
      final d2 = res.data;
      if (d2['success']) {
        setState(() => _promotions = (d2['data'] as List).map((e) => Promotion.fromJson(e)).toList());
      }
    } catch (_) {} finally {
      setState(() => _loadingP = false);
    }
  }

  Future<void> _saveCustomer(Map<String, dynamic> data, {int? id}) async {
    try {
      final res = id == null
          ? await ApiService().dioForExport.post('/api/customers', data: data)
          : await ApiService().dioForExport.put('/api/customers/$id', data: data);
      final b1 = res.data;
      if (b1['success']) {
        _loadCustomers(search: _searchCtrl.text);
        _showSnack('ບັນທຶກສຳເລັດ', color: _green);
      } else {
        _showSnack(b1['message'] ?? 'ຜິດພາດ', color: _red);
      }
    } catch (e) {
      _showSnack('ຜິດພາດ: $e', color: _red);
    }
  }

  Future<void> _savePromotion(Map<String, dynamic> data, {int? id}) async {
    try {
      final res = id == null
          ? await ApiService().dioForExport.post('/api/customers/promotions', data: data)
          : await ApiService().dioForExport.put('/api/customers/promotions/$id', data: data);
      final b2 = res.data;
      if (b2['success']) {
        _loadPromotions();
        _showSnack('ບັນທຶກສຳເລັດ', color: _green);
      } else {
        _showSnack(b2['message'] ?? 'ຜິດພາດ', color: _red);
      }
    } catch (e) {
      _showSnack('ຜິດພາດ: $e', color: _red);
    }
  }

  void _showSnack(String msg, {Color color = Colors.grey}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        title: const Text('ຈັດການລູກຄ້າ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: _red,
          labelColor: _red,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'ລູກຄ້າປະຈຳ'),
            Tab(icon: Icon(Icons.local_offer), text: 'ໂປຣໂມຊັນ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildCustomersTab(), _buildPromotionsTab()],
      ),
    );
  }

  // ── Customers Tab ──────────────────────────────────────────────────────────

  Widget _buildCustomersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ຄົ້ນຫາຊື່ / ເບີໂທ...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: _deep,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => _loadCustomers(search: v),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showCustomerDialog(),
                icon: const Icon(Icons.add),
                label: const Text('ເພີ່ມ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingC
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : _customers.isEmpty
                  ? const Center(child: Text('ບໍ່ມີຂໍ້ມູນ', style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _customers.length,
                      itemBuilder: (_, i) => _customerCard(_customers[i]),
                    ),
        ),
      ],
    );
  }

  Widget _customerCard(Customer c) {
    final fmt = NumberFormat.decimalPattern();
    return GestureDetector(
      onTap: () => _showCustomerDialog(customer: c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.isActive ? _deep : Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _red.withValues(alpha: 0.2),
              child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(c.phone, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  if (c.note != null && c.note!.isNotEmpty)
                    Text(c.note!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _badge('${c.points} ຄະແນນ', _orange),
                const SizedBox(height: 4),
                Text('${c.visitCount} ຄັ້ງ', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                Text('${fmt.format(c.totalSpent)} ກີບ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _showCustomerDialog({Customer? customer}) {
    final nameCtrl = TextEditingController(text: customer?.name ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final noteCtrl = TextEditingController(text: customer?.note ?? '');
    bool isActive = customer?.isActive ?? true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: _card,
          title: Text(customer == null ? 'ເພີ່ມລູກຄ້າໃໝ່' : 'ແກ້ໄຂລູກຄ້າ',
              style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'ຊື່ລູກຄ້າ', Icons.person),
                const SizedBox(height: 10),
                _field(phoneCtrl, 'ເບີໂທ', Icons.phone,
                    type: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 10),
                _field(noteCtrl, 'ໝາຍເຫດ (ທາງເລືອກ)', Icons.note),
                if (customer != null) ...[
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) => setS(() => isActive = v),
                    title: const Text('ເປີດໃຊ້ງານ', style: TextStyle(color: Colors.white)),
                    activeColor: _green,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
              onPressed: () {
                final data = {
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'note': noteCtrl.text.trim(),
                  if (customer != null) 'is_active': isActive ? 1 : 0,
                };
                Navigator.pop(ctx);
                _saveCustomer(data, id: customer?.id);
              },
              child: const Text('ບັນທຶກ'),
            ),
          ],
        );
      }),
    );
  }

  // ── Promotions Tab ─────────────────────────────────────────────────────────

  Widget _buildPromotionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showPromotionDialog(),
                icon: const Icon(Icons.add),
                label: const Text('ເພີ່ມໂປຣໂມຊັນ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingP
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : _promotions.isEmpty
                  ? const Center(child: Text('ບໍ່ມີໂປຣໂມຊັນ', style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _promotions.length,
                      itemBuilder: (_, i) => _promotionCard(_promotions[i]),
                    ),
        ),
      ],
    );
  }

  Widget _promotionCard(Promotion p) {
    final fmt = NumberFormat.decimalPattern();
    final typeColor = p.type == 'percent' ? _green : p.type == 'fixed' ? _orange : Colors.purpleAccent;
    return GestureDetector(
      onTap: () => _showPromotionDialog(promo: p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.isActive ? _deep : Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                p.type == 'percent' ? Icons.percent : p.type == 'fixed' ? Icons.money_off : Icons.stars,
                color: typeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nameLao, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(p.nameEn, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  if (p.minSpend > 0)
                    Text('ຂັ້ນຕ່ຳ: ${fmt.format(p.minSpend)} ກີບ', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _badge(p.typeLabel, typeColor),
                const SizedBox(height: 4),
                _badge(p.isActive ? 'ເປີດ' : 'ປິດ', p.isActive ? _green : Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPromotionDialog({Promotion? promo}) {
    final nameLaoCtrl = TextEditingController(text: promo?.nameLao ?? '');
    final nameEnCtrl = TextEditingController(text: promo?.nameEn ?? '');
    final valueCtrl = TextEditingController(text: promo != null ? promo.value.toStringAsFixed(0) : '');
    final pointsCtrl = TextEditingController(text: promo?.pointsRequired.toString() ?? '0');
    final minSpendCtrl = TextEditingController(text: promo != null ? promo.minSpend.toStringAsFixed(0) : '0');
    final maxDiscCtrl = TextEditingController(text: promo != null ? promo.maxDiscount.toStringAsFixed(0) : '0');
    String selectedType = promo?.type ?? 'percent';
    bool isActive = promo?.isActive ?? true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          backgroundColor: _card,
          title: Text(promo == null ? 'ເພີ່ມໂປຣໂມຊັນ' : 'ແກ້ໄຂໂປຣໂມຊັນ',
              style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameLaoCtrl, 'ຊື່ (ພາສາລາວ)', Icons.label),
                const SizedBox(height: 10),
                _field(nameEnCtrl, 'ຊື່ (English)', Icons.label_outline),
                const SizedBox(height: 10),
                // Type selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: _deep, borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedType,
                      dropdownColor: _deep,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'percent', child: Text('ເປີເຊັນ (%)')),
                        DropdownMenuItem(value: 'fixed', child: Text('ສ່ວນລຸດຄົງທີ່ (ກີບ)')),
                        DropdownMenuItem(value: 'points', child: Text('ແລກຄະແນນ')),
                      ],
                      onChanged: (v) => setS(() => selectedType = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (selectedType == 'points')
                  _field(pointsCtrl, 'ຄະແນນທີ່ໃຊ້', Icons.stars, type: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly])
                else
                  _field(valueCtrl, selectedType == 'percent' ? 'ເປີເຊັນ (0-100)' : 'ຈຳນວນ (ກີບ)',
                      Icons.discount, type: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 10),
                _field(minSpendCtrl, 'ຍອດຂັ້ນຕ່ຳ (ກີບ)', Icons.shopping_cart,
                    type: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 10),
                _field(maxDiscCtrl, 'ສ່ວນລຸດສູງສຸດ (0=ບໍ່ຈຳກັດ)', Icons.money_off,
                    type: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: isActive,
                  onChanged: (v) => setS(() => isActive = v),
                  title: const Text('ເປີດໃຊ້ງານ', style: TextStyle(color: Colors.white)),
                  activeColor: const Color(0xFF4CAF50),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
              onPressed: () {
                final data = {
                  'name_lao': nameLaoCtrl.text.trim(),
                  'name_en': nameEnCtrl.text.trim(),
                  'type': selectedType,
                  'value': selectedType == 'points' ? 0 : int.tryParse(valueCtrl.text) ?? 0,
                  'points_required': selectedType == 'points' ? int.tryParse(pointsCtrl.text) ?? 0 : 0,
                  'min_spend': int.tryParse(minSpendCtrl.text) ?? 0,
                  'max_discount': int.tryParse(maxDiscCtrl.text) ?? 0,
                  'is_active': isActive ? 1 : 0,
                };
                Navigator.pop(ctx);
                _savePromotion(data, id: promo?.id);
              },
              child: const Text('ບັນທຶກ'),
            ),
          ],
        );
      }),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38),
        filled: true,
        fillColor: _deep,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
