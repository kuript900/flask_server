# flask_server/app.py

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import uuid
import os
import asyncio
import edge_tts
from deep_translator import GoogleTranslator

app = Flask(__name__)
CORS(app)

# 保存ディレクトリ
SAVE_DIR = "static/audio"
os.makedirs(SAVE_DIR, exist_ok=True)

# 言語コードに対応する音声
VOICE_MAP = {
    "en": "en-US-GuyNeural",
    "ja": "ja-JP-NanamiNeural",
    "fr": "fr-FR-DeniseNeural",
    "es": "es-ES-AlvaroNeural",
    "pt": "pt-BR-AntonioNeural",
    "de": "de-DE-ConradNeural"
}

@app.route("/api/translate", methods=["POST"])
def translate_and_generate():
    data = request.get_json()
    print("✅ リクエスト受信:", data)

    text = data.get("text")
    source_lang = data.get("from_lang")
    target_lang = data.get("to_lang")
    repeat = data.get("repeat", 1)
    rate = data.get("rate", "1.0")

    if not text or not source_lang or not target_lang:
        print("❌ パラメータ不足")
        return jsonify({"error": "Missing required parameters"}), 400

    # 翻訳
    try:
        translated = GoogleTranslator(source=source_lang, target=target_lang).translate(text)
        print("✅ 翻訳成功:", translated)
    except Exception as e:
        print("❌ 翻訳エラー:", str(e))
        return jsonify({"error": "Translation failed", "details": str(e)}), 500

    # 音声ファイル名生成
    file_id = str(uuid.uuid4())
    file_name = f"{file_id}.mp3"
    save_path = os.path.join(SAVE_DIR, file_name)

    # 音声合成
    voice = VOICE_MAP.get(target_lang, target_lang)
    try:
        print(f"🔄 音声生成開始: {voice}, rate={rate}, repeat={repeat}")
        full_text = (" " + translated) * int(repeat)
        asyncio.run(synthesize_audio(full_text.strip(), voice, save_path, rate))
        print("✅ 音声生成完了:", save_path)
    except Exception as e:
        print("❌ 音声生成エラー:", str(e))
        return jsonify({"error": "Audio synthesis failed", "details": str(e)}), 500

    return jsonify({
        "translated_text": translated,
        "audio_url": f"https://flask-server-beqj.onrender.com/static/audio/{file_name}"
    })

async def synthesize_audio(text, voice_name, save_path, rate):
    communicate = edge_tts.Communicate(text, voice_name)
    await communicate.save(save_path, rate=rate)

@app.route("/static/audio/<filename>")
def serve_audio(filename):
    return send_from_directory(SAVE_DIR, filename)

if __name__ == "__main__":
    print("🚀 Flaskサーバー起動中 http://0.0.0.0:5001")
    app.run(debug=True, port=5001, host="0.0.0.0")
