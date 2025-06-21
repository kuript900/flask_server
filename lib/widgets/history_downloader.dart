import 'dart:convert';
import 'dart:html' as html;
import 'package:intl/intl.dart';

class HistoryDownloader {
  static void downloadCsvFromHistory(List<Map<String, String>> history) {
    if (history.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('日時,翻訳元,翻訳先,原文,翻訳結果,音声ファイル');

    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    for (var item in history) {
      final date = item['timestamp'] ?? now;
      final from = item['from'] ?? '';
      final to = item['to'] ?? '';
      final original = item['original'] ?? '';
      final translated = item['translated'] ?? '';
      final audio = item['audio_file'] ?? '';
      buffer.writeln('"$date","$from","$to","$original","$translated","$audio"');
    }

    final bytes = utf8.encode(buffer.toString());
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'translation_history.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
