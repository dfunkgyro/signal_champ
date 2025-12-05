import 'package:flutter/services.dart';

/// IO implementation for file download (desktop/mobile)
/// Copies to clipboard since file_picker requires user interaction
Future<void> downloadFileImpl(String content, String filename) async {
  await Clipboard.setData(ClipboardData(text: content));
  print('Content copied to clipboard: $filename');
}
