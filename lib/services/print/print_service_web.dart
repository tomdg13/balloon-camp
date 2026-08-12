import 'dart:html' as html;
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'print_service.dart';

/// Web: builds a PDF in-memory and opens it in a new tab. From there the
/// browser's native viewer gives the user Print / Download / "Open with"
/// (Preview, Acrobat, etc. depending on OS) — this is effectively the
/// closest equivalent to a native share sheet on the web platform.
Future<void> printJob(PrintJob job) async {
  final doc = pw.Document();

  pw.MemoryImage? image;
  if (job.qrOrLogoImageBytes.isNotEmpty) {
    image = pw.MemoryImage(Uint8List.fromList(job.qrOrLogoImageBytes));
  }

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a6,
      build: (context) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            if (image != null) pw.Image(image, width: 220, height: 220),
            pw.SizedBox(height: 12),
            pw.Text(job.title,
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...job.lines.map(
              (l) => pw.Text(
                '${l.label}: ${l.value}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: l.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  final bytes = await doc.save();
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Opens the browser's native PDF viewer in a new tab — from there the
  // user gets Print (Ctrl/Cmd+P), Download, and OS-level "Open with".
  html.window.open(url, '_blank');

  // Revoke after a delay so the new tab has time to load the blob.
  Future.delayed(const Duration(minutes: 1), () => html.Url.revokeObjectUrl(url));
}
