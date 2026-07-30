import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});
  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<Map<String, dynamic>> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getStaffList();
      setState(() { _staff = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _showError('ໂຫລດຂໍ້ມູນບໍ່ສຳເລັດ: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE94560)));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFF4CAF50)));
  }

  Future<void> _toggleActive(Map<String, dynamic> member) async {
    final currentId = context.read<AppProvider>().staff?.id;
    if (member['id'] == currentId) {
      _showError('ບໍ່ສາມາດປິດໃຊ້ງານຕົນເອງໄດ້');
      return;
    }
    try {
      final newStatus = member['is_active'] == 1 ? 0 : 1;
      await ApiService().updateStaff(member['id'], {'is_active': newStatus});
      await _loadStaff();
      _showSuccess(newStatus == 1 ? 'ເປີດໃຊ້ງານສຳເລັດ' : 'ປິດໃຊ້ງານສຳເລັດ');
    } catch (e) {
      _showError('ເກີດຂໍ້ຜິດພາດ: $e');
    }
  }

  void _showAddDialog() => _showStaffDialog();
  void _showEditDialog(Map<String, dynamic> member) => _showStaffDialog(member: member);

  void _showStaffDialog({Map<String, dynamic>? member}) {
    final isEdit = member != null;
    final nameCtrl = TextEditingController(text: member?['name'] ?? '');
    final userCtrl = TextEditingController(text: member?['username'] ?? '');
    final passCtrl = TextEditingController();
    String role = member?['role'] ?? 'waiter';
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Text(
            isEdit ? 'ແກ້ໄຂຂໍ້ມູນ' : 'ເພີ່ມພະນັກງານ',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dlgField('ຊື່', nameCtrl, Icons.person),
                const SizedBox(height: 12),
                _dlgField('ຊື່ຜູ້ໃຊ້', userCtrl, Icons.account_circle,
                    enabled: !isEdit),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: isEdit ? 'ລະຫັດໃໝ່ (ຖ້າຕ້ອງການປ່ຽນ)' : 'ລະຫັດຜ່ານ',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white54),
                      onPressed: () => setDlg(() => obscure = !obscure),
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE94560))),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'ບົດບາດ',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.badge, color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE94560))),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin',   child: Text('Admin')),
                    DropdownMenuItem(value: 'waiter',  child: Text('Waiter')),
                    DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                    DropdownMenuItem(value: 'kitchen', child: Text('Kitchen')),
                  ],
                  onChanged: (v) => setDlg(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  if (isEdit) {
                    final updates = <String, dynamic>{'name': nameCtrl.text, 'role': role};
                    if (passCtrl.text.isNotEmpty) updates['password'] = passCtrl.text;
                    await ApiService().updateStaff(member!['id'], updates);
                    _showSuccess('ແກ້ໄຂສຳເລັດ');
                  } else {
                    await ApiService().createStaff(
                      name: nameCtrl.text,
                      username: userCtrl.text,
                      password: passCtrl.text,
                      role: role,
                    );
                    _showSuccess('ເພີ່ມພະນັກງານສຳເລັດ');
                  }
                  await _loadStaff();
                } catch (e) {
                  _showError('ເກີດຂໍ້ຜິດພາດ: $e');
                }
              },
              child: Text(isEdit ? 'ບັນທຶກ' : 'ເພີ່ມ',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dlgField(String label, TextEditingController ctrl, IconData icon,
      {bool enabled = true}) =>
      TextField(
        controller: ctrl,
        enabled: enabled,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white54),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white24)),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE94560))),
        ),
      );

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':   return const Color(0xFFE94560);
      case 'waiter':  return const Color(0xFF4CAF50);
      case 'cashier': return const Color(0xFFFF9800);
      case 'kitchen': return const Color(0xFF2196F3);
      default:        return Colors.grey;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':   return 'Admin';
      case 'waiter':  return 'Waiter';
      case 'cashier': return 'Cashier';
      case 'kitchen': return 'Kitchen';
      default:        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentId = context.read<AppProvider>().staff?.id;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE94560),
        onPressed: _showAddDialog,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('ເພີ່ມພະນັກງານ', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF16213E),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Text('ຈັດການພະນັກງານ',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadStaff),
              ],
            ),
          ),
          Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : RefreshIndicator(
              onRefresh: _loadStaff,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _staff.length,
                itemBuilder: (_, i) {
                  final m = _staff[i];
                  final isMe = m['id'] == currentId;
                  final isActive = m['is_active'] == 1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(14),
                      border: isMe
                          ? Border.all(color: const Color(0xFFE94560), width: 1.5)
                          : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: _roleColor(m['role']).withValues(alpha: 0.15),
                        child: Text(
                          (m['name'] as String).substring(0, 1).toUpperCase(),
                          style: TextStyle(
                              color: _roleColor(m['role']),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(m['name'],
                              style: TextStyle(
                                  color: isActive ? Colors.white : Colors.white38,
                                  fontWeight: FontWeight.w600)),
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE94560).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('ຂ້ອຍ',
                                  style: TextStyle(
                                      color: Color(0xFFE94560), fontSize: 11)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('@${m['username']}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _roleColor(m['role']).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_roleLabel(m['role']),
                                    style: TextStyle(
                                        color: _roleColor(m['role']),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                                      : Colors.white12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isActive ? 'ໃຊ້ງານຢູ່' : 'ປິດໃຊ້ງານ',
                                  style: TextStyle(
                                      color: isActive
                                          ? const Color(0xFF4CAF50)
                                          : Colors.white38,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        color: const Color(0xFF16213E),
                        icon: const Icon(Icons.more_vert, color: Colors.white54),
                        onSelected: (v) async {
                          if (v == 'edit') _showEditDialog(m);
                          if (v == 'toggle') await _toggleActive(m);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit, color: Colors.white70, size: 18),
                              SizedBox(width: 8),
                              Text('ແກ້ໄຂ', style: TextStyle(color: Colors.white70)),
                            ]),
                          ),
                          if (!isMe)
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(children: [
                                Icon(
                                  isActive ? Icons.block : Icons.check_circle,
                                  color: isActive
                                      ? const Color(0xFFE94560)
                                      : const Color(0xFF4CAF50),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isActive ? 'ປິດໃຊ້ງານ' : 'ເປີດໃຊ້ງານ',
                                  style: TextStyle(
                                      color: isActive
                                          ? const Color(0xFFE94560)
                                          : const Color(0xFF4CAF50)),
                                ),
                              ]),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
