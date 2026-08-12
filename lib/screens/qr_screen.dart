import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';
import '../services/api_config.dart';

class QrScreen extends StatefulWidget {
  final RestaurantTable table;

  const QrScreen({super.key, required this.table});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isPrinting = false;

  RestaurantTable get table => widget.table;

  String get _qrData =>
      'https://balloon-camp-api.sabaiapp.com/customer/?table=${table.tableNumber}&token=${table.qrToken}';

  Future<Uint8List> _captureQrImage() async {
    final boundary =
        _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _printQr() async {
    setState(() => _isPrinting = true);
    try {
      final qrBytes = await _captureQrImage();
      final qrImage = pw.MemoryImage(qrBytes);

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a6,
          build: (context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Image(qrImage, width: 220, height: 220),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'Table ${table.tableNumber}',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${table.capacity} seats',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: 'QR_Table_${table.tableNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ພິມບໍ່ສຳເລັດ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text('QR Code · ໂຕະ ${table.tableNumber}',
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.print, color: Colors.white),
            onPressed: _isPrinting ? null : _printQr,
            tooltip: 'ພິມ QR Code',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Card
            RepaintBoundary(
              key: _qrKey,
              child: Container(
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
            ),
            const SizedBox(height: 24),

            // Print button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isPrinting ? null : _printQr,
                  icon: const Icon(Icons.print),
                  label: Text(_isPrinting ? 'ກຳລັງພິມ...' : 'ພິມ QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

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
