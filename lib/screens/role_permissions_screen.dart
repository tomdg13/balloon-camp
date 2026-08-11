import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RolePermissionsScreen extends StatefulWidget {
  const RolePermissionsScreen({super.key});

  @override
  State<RolePermissionsScreen> createState() => _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends State<RolePermissionsScreen> {
  final List<String> roles = ['admin', 'waiter', 'cashier', 'kitchen'];
  String selectedRole = 'waiter';

  List<Map<String, dynamic>> pages = [];
  Map<String, Map<String, bool>> permissions = {};
  bool loading = true;
  bool saving = false;

  static const bgColor = Color(0xFF1A1A2E);
  static const cardColor = Color(0xFF16213E);
  static const accentRed = Color(0xFFE94560);
  static const successGreen = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    final allPages = await ApiService().getAllPages();
    final rolePerms = await ApiService().getRolePermissions(selectedRole);

    // fill in defaults for pages with no row yet
    final Map<String, Map<String, bool>> merged = {};
    for (var p in allPages) {
      final key = p['page_key'];
      merged[key] = rolePerms[key] ?? {'view': false, 'edit': false, 'delete': false};
    }

    setState(() {
      pages = allPages;
      permissions = merged;
      loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => saving = true);
    final payload = pages.map((p) {
      final key = p['page_key'];
      final perm = permissions[key]!;
      return {
        'page_key': key,
        'can_view': perm['view'],
        'can_edit': perm['edit'],
        'can_delete': perm['delete'],
      };
    }).toList();

    final ok = await ApiService().saveRolePermissions(selectedRole, payload);
    setState(() => saving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'ບັນທຶກສຳເລັດ' : 'ບັນທຶກລົ້ມເຫລວ'),
        backgroundColor: ok ? successGreen : accentRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: const Text('ຈັດການສິດທິບົດບາດ', style: TextStyle(color: Colors.white)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accentRed))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('ບົດບາດ: ', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedRole,
                        dropdownColor: cardColor,
                        style: const TextStyle(color: Colors.white),
                        items: roles
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => selectedRole = val);
                          _loadData();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      final key = page['page_key'];
                      final perm = permissions[key]!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                page['page_name_lao'] ?? page['page_name_en'] ?? key,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                              ),
                            ),
                            _permCheckbox('ເບິ່ງ', perm['view']!, (v) {
                              setState(() => permissions[key]!['view'] = v);
                            }),
                            _permCheckbox('ແກ້ໄຂ', perm['edit']!, (v) {
                              setState(() => permissions[key]!['edit'] = v);
                            }),
                            _permCheckbox('ລຶບ', perm['delete']!, (v) {
                              setState(() => permissions[key]!['delete'] = v);
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('ບັນທຶກ', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _permCheckbox(String label, bool value, void Function(bool) onChanged) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Checkbox(
            value: value,
            activeColor: successGreen,
            onChanged: (v) => onChanged(v ?? false),
          ),
        ],
      ),
    );
  }
}
