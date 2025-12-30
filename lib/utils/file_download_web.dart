import 'dart:html' as html;

/// Web implementation for file download using dart:html
Future<void> downloadFileImpl(String content, String filename) async {
  final bytes = content.codeUnits;
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
