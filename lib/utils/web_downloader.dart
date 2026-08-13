// Conditional export: picks the web implementation when compiling for web
// (dart.library.html is available), and falls back to the no-op stub on
// every other platform (Android, iOS, desktop, etc).
export 'web_downloader_stub.dart'
    if (dart.library.html) 'web_downloader_web.dart';
