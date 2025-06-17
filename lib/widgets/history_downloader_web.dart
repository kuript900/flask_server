import 'dart:convert';
import 'dart:html' as html;

void downloadCsvFromHistory(List<Map<String, String>> history) {
  final csvBuffer = StringBuffer();
  csvBuffer.writeln('Original,Translated,From,To,AudioFilename');

  for (final item in history) {
    final original = item['original'] ?? '';
    final translated = item['translated'] ?? '';
    final from = item['from'] ?? '';
    final to = item['to'] ?? '';
    final audio = item['audio'] ?? '';
    csvBuffer.writeln('"$original","$translated","$from","$to","$audio"');
  }

  final csvContent = csvBuffer.toString();
  final bytes = utf8.encode(csvContent);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', 'translation_history.csv')
    ..click();

  html.Url.revokeObjectUrl(url);
}
