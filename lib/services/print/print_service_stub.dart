import 'dart:async';
import 'dart:typed_data';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/src/plugin/sunmi_printer_plus_platform_interface.dart';
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
    final status = await SunmiPrinterPlusPlatform.instance.getStatus();
    return status != null && status.isNotEmpty;
  } catch (_) {
    // Throws on non-Sunmi hardware (e.g. a regular Android phone,
    // emulator, or desktop) via MissingPluginException — safe to
    // treat as "not available".
    return false;
  }
}

Future<void> _printOnSunmi(PrintJob job) async {
  // Logo (or legacy single-image field)
  final logo = job.logoImageBytes ?? job.qrOrLogoImageBytes;
  if (logo.isNotEmpty) {
    await SunmiPrinter.printImage(
      Uint8List.fromList(logo),
      align: SunmiPrintAlign.CENTER,
    );
    await SunmiPrinter.lineWrap(1);
  }

  await SunmiPrinter.printText(
    job.title,
    style: SunmiTextStyle(
      bold: true,
      fontSize: 28,
      align: SunmiPrintAlign.CENTER,
    ),
  );
  await SunmiPrinter.lineWrap(1);
  await SunmiPrinter.line(type: 'dashed');
  await SunmiPrinter.lineWrap(1);

  // Item lines: non-bold lines are left/right item rows, bold lines are totals
  for (final l in job.lines) {
    await SunmiPrinter.printRow(
      cols: [
        SunmiColumn(
          text: l.label,
          width: 2,
          style: SunmiTextStyle(bold: l.bold, fontSize: l.bold ? 22 : 18, align: SunmiPrintAlign.LEFT),
        ),
        SunmiColumn(
          text: l.value,
          width: 1,
          style: SunmiTextStyle(bold: l.bold, fontSize: l.bold ? 22 : 18, align: SunmiPrintAlign.RIGHT),
        ),
      ],
    );
  }

  // Payment QR code
  if (job.qrImageBytes != null && job.qrImageBytes!.isNotEmpty) {
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.line(type: 'dashed');
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.printImage(
      Uint8List.fromList(job.qrImageBytes!),
      align: SunmiPrintAlign.CENTER,
    );
  }

  // Footer text (payment method note, thank-you message, etc.)
  for (final f in job.footerLines) {
    await SunmiPrinter.printText(
      f,
      style: SunmiTextStyle(fontSize: 16, align: SunmiPrintAlign.CENTER),
    );
  }

  await SunmiPrinter.lineWrap(3);
  try {
    await SunmiPrinter.cutPaper();
  } catch (_) {
    // Some Sunmi models (e.g. V2 Pro) don't support auto-cut via this SDK
    // method -- safe to ignore, the receipt still printed successfully.
  }
}

Future<void> _printAsPdf(PrintJob job) async {
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
