import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:multi_translator_app/usage_limiter.dart';
import 'package:translator/translator.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _textController = TextEditingController();
  String _translatedText = '';
  String _selectedFrom = '日本語';
  String _selectedTo = '英語';
  int _repeatCount = 1;
  String _selectedDisplayRate = '1.0倍速';

  final FlutterTts flutterTts = FlutterTts();
  final translator = GoogleTranslator();

  final Map<String, String> _languageMap = {
    '日本語': 'ja',
    '英語': 'en',
    'スペイン語': 'es',
    'フランス語': 'fr',
    'ドイツ語': 'de',
    'ポルトガル語': 'pt',
  };

  final Map<String, String> _ttsLangMap = {
    '日本語': 'ja-JP',
    '英語': 'en-US',
    'スペイン語': 'es-ES',
    'フランス語': 'fr-FR',
    'ドイツ語': 'de-DE',
    'ポルトガル語': 'pt-PT',
  };

  final Map<String, double> _displayRateMap = {
    '0.6倍速': 0.4,
    '0.75倍速': 0.6,
    '1.0倍速': 0.75,
    '1.25倍速': 1.0,
    '1.5倍速': 1.25,
  };

  @override
  void initState() {
    super.initState();
    flutterTts.setSpeechRate(_displayRateMap[_selectedDisplayRate]!);
  }

  Future<void> _translateText() async {
    final inputText = _textController.text.trim();
    if (inputText.isEmpty) return;

    final from = _languageMap[_selectedFrom]!;
    final to = _languageMap[_selectedTo]!;

    try {
      final result = await translator.translate(inputText, from: from, to: to);
      setState(() {
        _translatedText = result.text;
      });

      await flutterTts.setLanguage(_ttsLangMap[_selectedTo]!);
      await flutterTts.setSpeechRate(_displayRateMap[_selectedDisplayRate]!);

      for (int i = 0; i < _repeatCount; i++) {
        await flutterTts.speak(result.text);
      }
    } catch (e) {
      print('❌ エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌐 翻訳＆音声再生アプリ')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('翻訳する文章を入力'),
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '入力してください',
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 500;
                  return isNarrow
                      ? Column(
                    children: [
                      DropdownButton<String>(
                        value: _selectedFrom,
                        isExpanded: true,
                        items: _languageMap.keys.map((lang) {
                          return DropdownMenuItem<String>(
                            value: lang,
                            child: Text(lang),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedFrom = value!);
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: _selectedTo,
                        isExpanded: true,
                        items: _languageMap.keys.map((lang) {
                          return DropdownMenuItem<String>(
                            value: lang,
                            child: Text(lang),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedTo = value!);
                        },
                      ),
                    ],
                  )
                      : Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedFrom,
                          isExpanded: true,
                          items: _languageMap.keys.map((lang) {
                            return DropdownMenuItem<String>(
                              value: lang,
                              child: Text(lang),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedFrom = value!);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedTo,
                          isExpanded: true,
                          items: _languageMap.keys.map((lang) {
                            return DropdownMenuItem<String>(
                              value: lang,
                              child: Text(lang),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedTo = value!);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.repeat, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('リピート再生:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _repeatCount,
                    items: List.generate(20, (i) => i + 1).map((count) {
                      return DropdownMenuItem<int>(
                        value: count,
                        child: Text('$count回'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _repeatCount = value!);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.speed, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('再生速度:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedDisplayRate,
                    items: _displayRateMap.keys.map((rate) {
                      return DropdownMenuItem<String>(
                        value: rate,
                        child: Text(rate),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedDisplayRate = value!);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (await UsageLimiter.canUse()) {
                      await UsageLimiter.incrementUsage();
                      await _translateText();
                    } else {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('使用上限に達しました'),
                          content: const Text('本日の使用回数（100回）を超えました'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            )
                          ],
                        ),
                      );
                    }
                  },
                  child: const Text('翻訳 & 音声再生'),
                ),
              ),
              const SizedBox(height: 16),
              if (_translatedText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
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
