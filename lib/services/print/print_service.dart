// Public entrypoint. Routes to the right implementation at compile time:
// - web: browser "Open with" / print dialog (dart:html)
// - everything else: runtime-checked, see print_service_stub.dart which
//   detects Sunmi hardware and falls back to the generic PDF dialog.
export 'print_service_stub.dart'
    if (dart.library.html) 'print_service_web.dart';

/// Shared model so callers don't care which backend is used.
class PrintJob {
  final String title;      // e.g. "Table 4" or "Receipt #1029"
  final List<int> qrOrLogoImageBytes; // PNG bytes, optional
  final List<PrintLine> lines;

  const PrintJob({
    required this.title,
    this.qrOrLogoImageBytes = const [],
    this.lines = const [],
  });
}

class PrintLine {
  final String label;
  final String value;
  final bool bold;
  const PrintLine(this.label, this.value, {this.bold = false});
}
