import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../models/models.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});
  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  List<MenuCategory> _categories = [];
  bool _loading = true;
  int? _selectedCategoryId;
  final Map<int, bool> _uploadingImage = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cats = await ApiService().getFullMenu();
      setState(() {
        _categories = cats;
        _selectedCategoryId ??= cats.isNotEmpty ? cats.first.id : null;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _showError('ໂຫລດເມນູບໍ່ສຳເລັດ: $e');
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE94560)));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF4CAF50)));

  List<MenuItem> get _currentItems {
    if (_selectedCategoryId == null) return [];
    return _categories
        .firstWhere((c) => c.id == _selectedCategoryId,
            orElse: () => MenuCategory(id: 0, nameLao: '', items: []))
        .items;
  }

  Future<void> _uploadImage(MenuItem item) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null) return;
    setState(() => _uploadingImage[item.id] = true);
    try {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await ApiService().uploadMenuImageBytes(item.id, bytes, picked.name);
      } else {
        await ApiService().uploadMenuImage(item.id, File(picked.path));
      }
      _showSuccess('ອັບໂຫລດຮູບສຳເລັດ · ຮີໄຊ 150×150');
      await _load();
    } catch (e) {
      _showError('ອັບໂຫລດຮູບບໍ່ສຳເລັດ: $e');
    } finally {
      if (mounted) setState(() => _uploadingImage.remove(item.id));
    }
  }

  void _showItemDialog({MenuItem? item}) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?.nameLao ?? '');
    final nameEnCtrl = TextEditingController(text: item?.nameEn ?? '');
    final priceCtrl = TextEditingController(
        text: item?.price != null && item!.price > 0
            ? item.price.toStringAsFixed(0) : '');
    int categoryId = _selectedCategoryId ?? _categories.first.id;
    bool isAvailable = item?.isAvailable ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'ແກ້ໄຂເມນູ' : 'ເພີ່ມເມນູໃໝ່',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dlgField('ຊື່ (ລາວ)', nameCtrl, Icons.restaurant_menu),
              const SizedBox(height: 12),
              _dlgField('ຊື່ (ອັງກິດ)', nameEnCtrl, Icons.translate),
              const SizedBox(height: 12),
              _dlgField('ລາຄາ (ກີບ)', priceCtrl, Icons.attach_money,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: categoryId,
                dropdownColor: const Color(0xFF0F3460),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco('ໝວດໝູ່', Icons.category),
                items: _categories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.nameLao, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => setDlg(() => categoryId = v!),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.visibility, color: Colors.white54, size: 18),
                  const SizedBox(width: 8),
                  const Text('ມີຂາຍ', style: TextStyle(color: Colors.white70)),
                  const Spacer(),
                  Switch(value: isAvailable, activeColor: const Color(0xFF4CAF50),
                      onChanged: (v) => setDlg(() => isAvailable = v)),
                ]),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  if (isEdit) {
                    await ApiService().updateMenuItem(item!.id, {
                      'name_lao': nameCtrl.text.trim(),
                      'name_en': nameEnCtrl.text.trim(),
                      'price': double.tryParse(priceCtrl.text) ?? 0,
                      'is_available': isAvailable ? 1 : 0,
                      'category_id': categoryId,
                    });
                    _showSuccess('ແກ້ໄຂສຳເລັດ');
                  } else {
                    await ApiService().createMenuItem(
                      categoryId: categoryId,
                      nameLao: nameCtrl.text.trim(),
                      nameEn: nameEnCtrl.text.trim(),
                      price: double.tryParse(priceCtrl.text) ?? 0,
                    );
                    _showSuccess('ເພີ່ມເມນູສຳເລັດ');
                  }
                  setState(() => _selectedCategoryId = categoryId);
                  await _load();
                } catch (e) {
                  _showError('ເກີດຂໍ້ຜິດພາດ: $e');
                }
              },
              child: Text(isEdit ? 'ບັນທຶກ' : 'ເພີ່ມ',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAvailable(MenuItem item) async {
    try {
      await ApiService().updateMenuItem(item.id, {'is_available': item.isAvailable ? 0 : 1});
      await _load();
    } catch (e) {
      _showError('ເກີດຂໍ້ຜິດພາດ: $e');
    }
  }

  Future<void> _showCategoryDialog({MenuCategory? category}) async {
    final nameLaoCtrl = TextEditingController(text: category?.nameLao ?? '');
    final nameEnCtrl = TextEditingController(text: category?.nameEn ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(category == null ? 'ເພີ່ມໝວດໝູ່' : 'ແກ້ໄຂໝວດໝູ່',
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dlgField('ຊື່ໝວດໝູ່ (ລາວ)', nameLaoCtrl, Icons.category),
            const SizedBox(height: 12),
            _dlgField('ຊື່ໝວດໝູ່ (English)', nameEnCtrl, Icons.language),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('ບັນທຶກ', style: TextStyle(color: Color(0xFFE94560))),
          ),
        ],
      ),
    );

    if (result != true || nameLaoCtrl.text.trim().isEmpty) return;

    try {
      if (category == null) {
        await ApiService().createCategory(nameLao: nameLaoCtrl.text.trim(), nameEn: nameEnCtrl.text.trim());
        _showSuccess('ເພີ່ມໝວດໝູ່ສຳເລັດ');
      } else {
        await ApiService().updateCategory(category.id, {
          'name_lao': nameLaoCtrl.text.trim(),
          'name_en': nameEnCtrl.text.trim(),
        });
        _showSuccess('ແກ້ໄຂໝວດໝູ່ສຳເລັດ');
      }
      await _load();
    } catch (e) {
      _showError('ເກີດຂໍ້ຜິດພາດ: $e');
    }
  }

  Future<void> _confirmDeleteCategory(MenuCategory category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('ລຶບໝວດໝູ່?', style: TextStyle(color: Colors.white)),
        content: Text('ຕ້ອງການລຶບ "${category.nameLao}" ອອກແທ້ບໍ?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ລຶບ', style: TextStyle(color: Color(0xFFE94560))),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService().deleteCategory(category.id);
      if (_selectedCategoryId == category.id) _selectedCategoryId = null;
      await _load();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      _showError('$msg');
    } catch (e) {
      _showError('ເກີດຂໍ້ຜິດພາດ: $e');
    }
  }

  Future<void> _confirmDelete(MenuItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('ລຶບເມນູ?', style: TextStyle(color: Colors.white)),
        content: Text('ຕ້ອງການລຶບ "${item.nameLao}" ອອກຈາກເມນູແທ້ບໍ?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ລຶບ', style: TextStyle(color: Color(0xFFE94560))),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService().deleteMenuItem(item.id);
      await _load();
    } catch (e) {
      _showError('ເກີດຂໍ້ຜິດພາດ: $e');
    }
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0F3460),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE94560))),
      );

  Widget _dlgField(String label, TextEditingController ctrl, IconData icon,
          {TextInputType? keyboardType}) =>
      TextField(controller: ctrl, keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco(label, icon));

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        color: const Color(0xFF16213E),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          const Text('ຈັດການເມນູ',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: _categories.isNotEmpty ? () => _showItemDialog() : null,
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: const Text('ເພີ່ມເມນູ', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
        ]),
      ),

      if (_loading)
        const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFFE94560))))
      else
        Expanded(child: Row(children: [
          // Category sidebar
          Container(
            width: 190,
            decoration: const BoxDecoration(
              color: Color(0xFF0F3460),
              border: Border(right: BorderSide(color: Colors.white10)),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('ໝວດໝູ່',
                          style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
                    ),
                    GestureDetector(
                      onTap: () => _showCategoryDialog(),
                      child: const Icon(Icons.add_circle_outline, color: Colors.white38, size: 18),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final selected = cat.id == _selectedCategoryId;
                    final withImg = cat.items.where((it) => it.imageUrl != null).length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFE94560).withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: selected ? Border.all(color: const Color(0xFFE94560).withValues(alpha: 0.4)) : null,
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        title: Text(cat.nameLao,
                            style: TextStyle(
                                color: selected ? const Color(0xFFE94560) : Colors.white70,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13)),
                        subtitle: Text('$withImg/${cat.items.length} ມີຮູບ',
                            style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        onTap: () => setState(() => _selectedCategoryId = cat.id),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _showCategoryDialog(category: cat),
                              child: const Icon(Icons.edit, color: Colors.white38, size: 14),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _confirmDeleteCategory(cat),
                              child: const Icon(Icons.delete_outline, color: Color(0xFFE94560), size: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),

          // Items grid
          Expanded(
            child: _currentItems.isEmpty
                ? const Center(child: Text('ບໍ່ມີເມນູໃນໝວດນີ້',
                    style: TextStyle(color: Colors.white54, fontSize: 16)))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _currentItems.length,
                    itemBuilder: (_, i) {
                      final item = _currentItems[i];
                      final uploading = _uploadingImage[item.id] == true;
                      return _MenuCard(
                        item: item,
                        uploading: uploading,
                        onUpload: () => _uploadImage(item),
                        onEdit: () => _showItemDialog(item: item),
                        onToggle: () => _toggleAvailable(item),
                        onDelete: () => _confirmDelete(item),
                      );
                    },
                  ),
          ),
        ])),
    ]);
  }
}

class _MenuCard extends StatelessWidget {
  final MenuItem item;
  final bool uploading;
  final VoidCallback onUpload;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _MenuCard({
    required this.item,
    required this.uploading,
    required this.onUpload,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isAvailable ? Colors.white10 : Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image area
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onUpload,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Stack(fit: StackFit.expand, children: [
                  // Image or placeholder
                  item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFF0F3460),
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFE94560), strokeWidth: 2)),
                          ),
                          errorWidget: (_, __, ___) => _imgPlaceholder(),
                        )
                      : _imgPlaceholder(),

                  // Upload overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),

                  // Camera icon
                  if (uploading)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)),
                    )
                  else
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.imageUrl != null ? Icons.edit : Icons.add_a_photo,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),

                  // Unavailable overlay
                  if (!item.isAvailable)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: Text('ປິດຂາຍ',
                            style: TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ]),
              ),
            ),
          ),

          // Info area
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.nameLao,
                      style: TextStyle(
                          color: item.isAvailable ? Colors.white : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    item.price > 0
                        ? '${item.price.toStringAsFixed(0)} ກີບ'
                        : 'ຍັງບໍ່ກຳນົດລາຄາ',
                    style: TextStyle(
                        color: item.price > 0
                            ? const Color(0xFFE94560)
                            : Colors.white24,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  // Action buttons
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onToggle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: item.isAvailable
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(
                              item.isAvailable ? Icons.visibility : Icons.visibility_off,
                              color: item.isAvailable ? const Color(0xFF4CAF50) : Colors.white38,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.isAvailable ? 'ມີຂາຍ' : 'ປິດຂາຍ',
                              style: TextStyle(
                                  color: item.isAvailable
                                      ? const Color(0xFF4CAF50)
                                      : Colors.white38,
                                  fontSize: 10),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.edit, color: Color(0xFF2196F3), size: 14),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE94560).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.delete_outline, color: Color(0xFFE94560), size: 14),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: const Color(0xFF0F3460),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_a_photo, color: Colors.white24, size: 36),
          const SizedBox(height: 8),
          Text('ແຕະເພື່ອເພີ່ມຮູບ',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
        ]),
      );
}
