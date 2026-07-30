import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> _settings = {};
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getSettings();
      setState(() { _settings = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadBankQr() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      String url;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        url = await ApiService().uploadBankQrBytes(bytes, picked.name);
      } else {
        url = await ApiService().uploadBankQr(File(picked.path));
      }
      setState(() { _settings['bank_qr_url'] = url; _uploading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ອັບໂຫລດ QR ທະນາຄານສຳເລັດ'),
              backgroundColor: Color(0xFF4CAF50)));
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e'),
              backgroundColor: const Color(0xFFE94560)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF16213E),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            const Text('ຕັ້ງຄ່າຮ້ານ',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bank QR section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Icon(Icons.qr_code, color: Color(0xFFE94560), size: 20),
                              SizedBox(width: 8),
                              Text('QR ທະນາຄານ / ຮູບການຊຳລະ',
                                  style: TextStyle(color: Colors.white,
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                            ]),
                            const SizedBox(height: 6),
                            const Text('ຮູບນີ້ຈະສະແດງໃນໜ້າຊຳລະເງິນ ແລະ ໃບບິນ',
                                style: TextStyle(color: Colors.white54, fontSize: 13)),
                            const SizedBox(height: 16),

                            // Current QR image
                            Row(children: [
                              // Image preview
                              Container(
                                width: 160, height: 160,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F3460),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: _settings['bank_qr_url'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: CachedNetworkImage(
                                          imageUrl: _settings['bank_qr_url'],
                                          fit: BoxFit.contain,
                                          placeholder: (_, __) => const Center(
                                              child: CircularProgressIndicator(
                                                  color: Color(0xFFE94560), strokeWidth: 2)),
                                          errorWidget: (_, __, ___) => const Center(
                                              child: Icon(Icons.broken_image,
                                                  color: Colors.white24, size: 40)),
                                        ),
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.qr_code, color: Colors.white24, size: 48),
                                            SizedBox(height: 8),
                                            Text('ຍັງບໍ່ມີຮູບ',
                                                style: TextStyle(color: Colors.white38, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('ອັບໂຫລດ QR Code ຂອງທ່ານ\n(PromptPay, BCEL, LDB ຫຼື ອື່ນໆ)',
                                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFE94560),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        onPressed: _uploading ? null : _uploadBankQr,
                                        icon: _uploading
                                            ? const SizedBox(width: 18, height: 18,
                                                child: CircularProgressIndicator(
                                                    color: Colors.white, strokeWidth: 2))
                                            : const Icon(Icons.upload, color: Colors.white),
                                        label: Text(
                                          _uploading ? 'ກຳລັງອັບໂຫລດ...' : 'ເລືອກຮູບ QR',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    if (_settings['bank_qr_updated'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'ອັບເດດລ່າສຸດ: ${_settings['bank_qr_updated'].toString().substring(0, 10)}',
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
