// ✅ 安定していた「翻訳＆音声再生」1ボタン構成の完全復元バージョン
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
  final TextEditingController _textController = TextEditingController();
  String _translatedText = '';
  String _selectedFrom = 'ja';
  String _selectedTo = 'en';
  double _speed = 1.0;
  int _repeat = 1;

  Future<void> _translateAndPlay() async {
    // 翻訳
    final response = await http.post(
      Uri.parse('https://flask-server-beqj.onrender.com/api/translate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': _textController.text,
        'from': _selectedFrom,
        'to': _selectedTo,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _translatedText = data['translated_text'];
      });

      // 翻訳成功後に音声生成リクエスト
      final ttsResponse = await http.post(
        Uri.parse('https://flask-server-beqj.onrender.com/api/tts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _translatedText,
          'lang': _selectedTo,
          'speed': _speed,
          'repeat': _repeat,
        }),
      );

      if (ttsResponse.statusCode == 200) {
        final ttsData = jsonDecode(ttsResponse.body);
        final audioUrl = ttsData['audio_url'];
        if (await canLaunchUrl(Uri.parse(audioUrl))) {
          await launchUrl(Uri.parse(audioUrl));
        }
      }
    } else {
      setState(() {
        _translatedText = '翻訳に失敗しました';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('翻訳 & 音声再生アプリ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _textController,
                decoration: const InputDecoration(labelText: '翻訳する文章を入力'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('From:'),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedFrom,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('英語')),
                      DropdownMenuItem(value: 'ja', child: Text('日本語')),
                      DropdownMenuItem(value: 'zh', child: Text('中国語')),
                      DropdownMenuItem(value: 'fr', child: Text('フランス語')),
                      DropdownMenuItem(value: 'de', child: Text('ドイツ語')),
                      DropdownMenuItem(value: 'es', child: Text('スペイン語')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedFrom = value!);
                    },
                  ),
                  const SizedBox(width: 20),
                  const Text('To:'),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedTo,
                    items: const [
                      DropdownMenuItem(value: 'ja', child: Text('日本語')),
                      DropdownMenuItem(value: 'en', child: Text('英語')),
                      DropdownMenuItem(value: 'zh', child: Text('中国語')),
                      DropdownMenuItem(value: 'fr', child: Text('フランス語')),
                      DropdownMenuItem(value: 'de', child: Text('ドイツ語')),
                      DropdownMenuItem(value: 'es', child: Text('スペイン語')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedTo = value!);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('再生速度:'),
                  Slider(
                    value: _speed,
                    onChanged: (value) {
                      setState(() => _speed = value);
                    },
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: '${_speed.toStringAsFixed(1)}x',
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('リピート回数:'),
                  DropdownButton<int>(
                    value: _repeat,
                    items: List.generate(5, (i) => i + 1)
                        .map((val) => DropdownMenuItem(value: val, child: Text('$val回')))
                        .toList(),
                    onChanged: (val) => setState(() => _repeat = val!),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _translateAndPlay,
                  child: const Text('翻訳＆音声再生'),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('翻訳結果: $_translatedText'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
