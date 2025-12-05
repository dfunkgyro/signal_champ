import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart'
    if (dart.library.io) 'file_download_io.dart';

/// Universal file download helper that works on all platforms
class FileDownloadHelper {
  /// Download a file with the given content and filename
  /// On web: triggers browser download
  /// On desktop/mobile: copies to clipboard
  static Future<void> downloadFile(
    String content,
    String filename,
  ) async {
    await downloadFileImpl(content, filename);
  }

  /// Copy content to clipboard
  static Future<void> copyToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
  }
}
