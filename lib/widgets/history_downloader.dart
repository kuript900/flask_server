import 'package:flutter/foundation.dart' show kIsWeb;

import 'history_downloader_web.dart' if (dart.library.io) 'history_downloader_dummy.dart';

class HistoryDownloader {
  static void downloadCsvFromHistory(List<Map<String, String>> history) {
    if (kIsWeb) {
      downloadFileWeb(history);
    } else {
      print('📥 ダウンロード機能は Web のみ対応です');
    }
  }
}
