import 'dart:async';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'print_service.dart';

/// Non-web platforms (Android/iOS/desktop). If the device is a Sunmi
/// terminal (V2 Pro etc.) with a built-in thermal printer, we print
/// directly via ESC/POS. Otherwise we fall back to the standard PDF
/// print/share dialog (works for any Android printer, AirPrint, etc.).
Future<void> printJob(PrintJob job) async {
  final isSunmi = await _isSunmiPrinterAvailable();

  if (isSunmi) {
    await _printOnSunmi(job);
  } else {
    await _printAsPdf(job);
  }
}

Future<bool> _isSunmiPrinterAvailable() async {
  try {
    final bound = await SunmiPrinter.bindingPrinter();
    return bound == true;
  } catch (_) {
    return false;
  }
}

Future<void> _printOnSunmi(PrintJob job) async {
  await SunmiPrinter.initPrinter();
  await SunmiPrinter.startTransactionPrint(true);

  await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);

  if (job.qrOrLogoImageBytes.isNotEmpty) {
    // Sunmi plugin expects a base64 string or Uint8List depending on
    // version; adjust to match the installed sunmi_printer_plus API.
    await SunmiPrinter.printImage(job.qrOrLogoImageBytes as dynamic);
    await SunmiPrinter.lineWrap(1);
  }

  await SunmiPrinter.setFontSize(28);
  await SunmiPrinter.bold();
  await SunmiPrinter.printText(job.title);
  await SunmiPrinter.resetBold();
  await SunmiPrinter.lineWrap(1);

  await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
  await SunmiPrinter.setFontSize(20);
  for (final l in job.lines) {
    await SunmiPrinter.printText('${l.label}: ${l.value}');
  }

  await SunmiPrinter.lineWrap(3);
  await SunmiPrinter.cutPaper();
  await SunmiPrinter.exitTransactionPrint(true);
}

Future<void> _printAsPdf(PrintJob job) async {
  final doc = pw.Document();
  pw.MemoryImage? image;
  if (job.qrOrLogoImageBytes.isNotEmpty) {
    image = pw.MemoryImage(job.qrOrLogoImageBytes as dynamic);
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
            ...job.lines.map((l) => pw.Text('${l.label}: ${l.value}')),
          ],
        ),
      ),
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => doc.save(),
    name: job.title.replaceAll(' ', '_'),
  );
}
