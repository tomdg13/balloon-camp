import 'package:intl/intl.dart';

final _fmt = NumberFormat.decimalPattern();

/// Format a number with commas e.g. 120000 -> 120,000
String fmtNum(num value) => _fmt.format(value);

/// Format a double that might be null
String fmtNumSafe(dynamic value, {String fallback = '0'}) {
  if (value == null) return fallback;
  final d = double.tryParse(value.toString()) ?? 0;
  return _fmt.format(d);
}
