// Stub implementation used on non-web platforms (Android, iOS, desktop).
// The real implementation lives in web_downloader_web.dart and is only
// compiled in when targeting web, via the conditional import in
// web_downloader.dart.

void downloadCsv(List<int> bytes, String filename) {
  // No-op on non-web platforms. Callers should check kIsWeb before
  // relying on this, or handle the unsupported case themselves.
  throw UnsupportedError('downloadCsv is only supported on web');
}
