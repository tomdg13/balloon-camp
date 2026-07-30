import 'dart:html' as html_lib;

void openHtmlInNewTab(String html) {
  final blob = html_lib.Blob([html], 'text/html');
  final url = html_lib.Url.createObjectUrlFromBlob(blob);
  html_lib.window.open(url, '_blank');
}
