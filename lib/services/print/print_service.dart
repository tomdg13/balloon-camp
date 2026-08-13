// Public entrypoint. Routes to the right implementation at compile time:
// - web: browser "Open with" / print dialog (dart:html)
// - everything else: runtime-checked, see print_service_stub.dart which
//   detects Sunmi hardware and falls back to the generic PDF dialog.
export 'print_service_stub.dart'
    if (dart.library.html) 'print_service_web.dart';

/// Shared model so callers don't care which backend is used.
class PrintJob {
  final String title;      // e.g. "Table 4" or "Receipt #1029"
  final List<int> qrOrLogoImageBytes; // PNG bytes, optional (legacy: printed at top)
  final List<int>? logoImageBytes;    // shop logo, printed at the very top
  final List<int>? qrImageBytes;      // payment QR, printed after the item lines
  final List<PrintLine> lines;
  final List<String> footerLines;     // plain centered text after the QR (e.g. payment method, thank-you note)

  const PrintJob({
    required this.title,
    this.qrOrLogoImageBytes = const [],
    this.logoImageBytes,
    this.qrImageBytes,
    this.lines = const [],
    this.footerLines = const [],
  });
}

class PrintLine {
  final String label;
  final String value;
  final bool bold;
  const PrintLine(this.label, this.value, {this.bold = false});
}
