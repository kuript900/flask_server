// lib/screens/translator_screen.dart
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
  String? _selectedFromLang = 'en';
  String? _selectedToLang = 'ja';
  double _speechRate = 1.0;
  int _repeatCount = 1;

  final List<Map<String, String>> _languageOptions = [
    {'code': 'en', 'label': 'English'},
    {'code': 'ja', 'label': 'Japanese'},
    {'code': 'es', 'label': 'Spanish'},
    {'code': 'fr', 'label': 'French'},
    {'code': 'de', 'label': 'German'},
    {'code': 'zh-CN', 'label': 'Chinese'},
  ];

  Future<void> _translateText() async {
    final response = await http.post(
      Uri.parse('https://flask-server-beqj.onrender.com/api/translate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': _textController.text,
        'from': _selectedFromLang,
        'to': _selectedToLang,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        translatedText = data['translated_text'];
      });
    } else {
      setState(() {
        translatedText = 'Translation failed';
      });
    }
  }

  Future<void> _playAudio() async {
    final response = await http.post(
      Uri.parse('https://flask-server-beqj.onrender.com/api/tts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': translatedText,
        'lang': _selectedToLang,
        'rate': _speechRate,
        'repeat': _repeatCount,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final url = data['audio_url'];
      if (await canLaunch(url)) {
        await launch(url);
      }
    } else {
      print('TTS failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translator & Repeater'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(labelText: 'Enter text'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildLanguageDropdown('From', true)),
                const SizedBox(width: 8),
                Expanded(child: _buildLanguageDropdown('To', false)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Speed:'),
                Expanded(
                  child: Slider(
                    value: _speechRate,
                    min: 0.5,
                    max: 1.5,
                    divisions: 10,
                    label: _speechRate.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() => _speechRate = value);
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Repeat:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _repeatCount,
                  items: List.generate(10, (i) => i + 1)
                      .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _repeatCount = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _translateText,
              child: const Text('Translate'),
            ),
            const SizedBox(height: 8),
            Text(translatedText, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _playAudio,
              child: const Text('Play Audio'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(String label, bool isFrom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        DropdownButton<String>(
          value: isFrom ? _selectedFromLang : _selectedToLang,
          isExpanded: true,
          items: _languageOptions.map((lang) {
            return DropdownMenuItem<String>(
              value: lang['code'],
              child: Text(lang['label']!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              if (isFrom) {
                _selectedFromLang = value;
              } else {
                _selectedToLang = value;
              }
            });
          },
        ),
      ],
    );
  }
}
