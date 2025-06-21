from flask import Flask, request, jsonify
from flask_cors import CORS
from google.cloud import translate_v2 as translate
import os
import uuid
import edge_tts
import asyncio

app = Flask(__name__)
CORS(app)

# 認証情報
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "/etc/secrets/credentials.json"
translator = translate.Client()

# 翻訳API
@app.route('/api/translate', methods=['POST'])
def translate_text():
    data = request.get_json()
    text = data['text']
    source = data['from']
    target = data['to']

    try:
        result = translator.translate(text, source_language=source, target_language=target)
        return jsonify({'translated_text': result['translatedText']})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# 音声生成API
@app.route('/api/tts', methods=['POST'])
def tts():
    data = request.get_json()
    text = data['text']
    lang = data['lang']
    rate = float(data.get('rate', 1.0))
    repeat = int(data.get('repeat', 1))

    # 音声ファイル生成用のファイル名
    filename = f"{uuid.uuid4()}.mp3"
    filepath = os.path.join("static", "audio", filename)

    voice_map = {
        'en': 'en-US-AriaNeural',
        'ja': 'ja-JP-NanamiNeural',
        'es': 'es-ES-ElviraNeural',
        'fr': 'fr-FR-DeniseNeural',
        'de': 'de-DE-KatjaNeural',
        'zh-CN': 'zh-CN-XiaoxiaoNeural',
    }

    voice = voice_map.get(lang, 'en-US-AriaNeural')
    rate_pct = int((rate - 1.0) * 100)
    rate_str = f"+{rate_pct}%" if rate_pct >= 0 else f"{rate_pct}%"
    text_repeated = (text + " ") * repeat

    async def generate():
        communicate = edge_tts.Communicate(text_repeated.strip(), voice, rate=rate_str)
        await communicate.save(filepath)

    try:
        asyncio.run(generate())
        return jsonify({'audio_url': f"https://flask-server-beqj.onrender.com/static/audio/{filename}"})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
