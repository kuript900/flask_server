import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final _textController = TextEditingController();
  String translatedText = '';
  int _repeatCount = 1;
  String _selectedFromLang = '日本語';
  String _selectedToLang = '英語';
  String _selectedRate = '1.0';

  final Map<String, String> langCodeMap = {
    '日本語': 'ja',
    '英語': 'en',
    'フランス語': 'fr',
    'スペイン語': 'es',
    'ドイツ語': 'de',
    'ポルトガル語': 'pt',
  };

  final List<String> speedRates = ['0.8', '1.0', '1.2', '1.5'];

  Future<void> translateText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final from = langCodeMap[_selectedFromLang]!;
    final to = langCodeMap[_selectedToLang]!;

    final uri = Uri.parse('https://flask-server-beqj.onrender.com/api/translate');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'from_lang': from,
          'to_lang': to,
        }),
      );

      final json = jsonDecode(res.body);
      if (json['error'] != null) {
        print('❌ 通信エラー (翻訳): ${json['error']}');
        return;
      }

      setState(() {
        translatedText = json['translated_text'];
      });
    } catch (e) {
      print('❌ 通信エラー (翻訳): $e');
    }
  }

  Future<void> playAudio() async {
    final to = langCodeMap[_selectedToLang]!;
    final uri = Uri.parse('https://flask-server-beqj.onrender.com/api/tts');

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': translatedText,
          'lang': to,
          'repeat': _repeatCount,
          'rate': _selectedRate,
        }),
      );

      final json = jsonDecode(res.body);
      if (json['error'] != null) {
        print('❌ 通信エラー (音声): ${json['error']}');
        return;
      }

      final audioUrl = json['audio_url'];
      if (await canLaunchUrl(Uri.parse(audioUrl))) {
        await launchUrl(Uri.parse(audioUrl));
      } else {
        print('再生できません: $audioUrl');
      }
    } catch (e) {
      print('❌ 通信エラー (音声): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌐 翻訳＆音声再生アプリ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text('翻訳する文章を入力'),
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '入力してください',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedFromLang,
                      items: langCodeMap.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _selectedFromLang = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedToLang,
                      items: langCodeMap.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _selectedToLang = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('🔁 回数:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _repeatCount,
                    items: List.generate(10, (i) => i + 1)
                        .map((e) => DropdownMenuItem(value: e, child: Text('$e回')))
                        .toList(),
                    onChanged: (val) => setState(() => _repeatCount = val!),
                  ),
                  const SizedBox(width: 20),
                  const Text('⏩ 速度:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedRate,
                    items: speedRates
                        .map((e) => DropdownMenuItem(value: e, child: Text('${e}x')))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedRate = val!),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: translateText,
                    child: const Text('翻訳'),
                  ),
                  ElevatedButton(
                    onPressed: playAudio,
                    child: const Text('音声再生'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('翻訳結果: $translatedText'),
            ],
          ),
        ),
      ),
    );
  }
}
