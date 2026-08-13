// Real implementation, only compiled in when targeting web.
import 'dart:html' as html show AnchorElement, Blob, Url;

void downloadCsv(List<int> bytes, String filename) {
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
