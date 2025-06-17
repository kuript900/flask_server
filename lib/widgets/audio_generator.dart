import 'dart:convert';
import 'package:http/http.dart' as http;

class AudioGenerator {
  static Future<String?> generateAndPlayAudio({
    required String text,
    required String langCode,
    required int repeatCount,
  }) async {
    try {
      final url = Uri.parse('https://YOUR_FLASK_SERVER_URL/generate_audio');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'lang': langCode,
          'repeat': repeatCount,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['audio_url']; // 再生やCSV記録に使える
      } else {
        print('❌ 音声生成エラー: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ エラー: $e');
      return null;
    }
  }
}
