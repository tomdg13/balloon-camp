import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/models.dart';
import '../services/api_config.dart';

class QrScreen extends StatelessWidget {
  final RestaurantTable table;

  const QrScreen({super.key, required this.table});

  String get _qrData =>
      'https://balloon-camp-api.sabaiapp.com/customer/?table=${table.tableNumber}&token=${table.qrToken}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text('QR Code · ໂຕະ ${table.tableNumber}',
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE94560).withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ໂຕະ ${table.tableNumber}',
                    style: const TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${table.capacity} ທີ່ນັ່ງ',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFE94560), size: 18),
                      SizedBox(width: 8),
                      Text('ຂໍ້ມູນ QR Code',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _infoRow('ໂຕະ', table.tableNumber),
                  _infoRow('Token', table.qrToken ?? '-'),
                  const SizedBox(height: 8),
                  const Text(
                    'QR Code ນີ້ຈະໝົດອາຍຸໂດຍອັດຕະໂນມັດເມື່ອລູກຄ້າຊຳລະເງິນແລ້ວ',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}
