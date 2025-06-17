from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import uuid
import os
import asyncio
import edge_tts
from google.cloud import translate_v2 as translate

# Google翻訳APIの認証情報ファイルを指定
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "flask_server/credentials.json"

app = Flask(__name__)
CORS(app)

# Google Cloud Translation クライアント初期化
translate_client = translate.Client()

# 音声保存ディレクトリ
SAVE_DIR = "static/audio"
os.makedirs(SAVE_DIR, exist_ok=True)

# 言語コードに対応する音声（必要に応じて追加）
VOICE_MAP = {
    "en": "en-US-GuyNeural",
    "ja": "ja-JP-NanamiNeural",
    "fr": "fr-FR-DeniseNeural",
    "es": "es-ES-AlvaroNeural",
    "pt": "pt-BR-AntonioNeural",
    "de": "de-DE-ConradNeural"
}

# 翻訳だけのAPI
@app.route("/api/translate", methods=["POST"])
def translate_text():
    data = request.get_json()
    print("✅ 翻訳リクエスト:", data)

    text = data.get("text")
    from_lang = data.get("from_lang")
    to_lang = data.get("to_lang")

    if not text or not from_lang or not to_lang:
        return jsonify({"error": "Missing required parameters"}), 400

    try:
        result = translate_client.translate(
            text,
            source_language=from_lang,
            target_language=to_lang
        )
        translated = result["translatedText"]
        print("✅ 翻訳成功:", translated)
        return jsonify({"translated_text": translated})
    except Exception as e:
        print("❌ 翻訳失敗:", str(e))
        return jsonify({"error": "Translation failed", "details": str(e)}), 500

# 音声だけのAPI
@app.route("/api/tts", methods=["POST"])
def generate_audio():
    data = request.get_json()
    print("✅ 音声生成リクエスト:", data)

    text = data.get("text")
    lang = data.get("lang")
    rate = data.get("rate", "1.0")
    repeat = int(data.get("repeat", 1))

    if not text or not lang:
        return jsonify({"error": "Missing required parameters"}), 400

    voice = VOICE_MAP.get(lang, lang)
    file_id = str(uuid.uuid4())
    file_path = os.path.join(SAVE_DIR, f"{file_id}.mp3")

    try:
        full_text = (text + " ") * repeat
        communicate = edge_tts.Communicate(full_text.strip(), voice)

        # 修正済み：読み上げ速度（1.5 → +50%、0.8 → -20%）
        rate_percent = int((float(rate) - 1.0) * 100)
        if rate_percent > 0:
            communicate.rate = f"+{rate_percent}%"
        elif rate_percent < 0:
            communicate.rate = f"{rate_percent}%"
        else:
            communicate.rate = "0%"

        asyncio.run(communicate.save(file_path))
        print("✅ 音声生成成功:", file_path)
        return jsonify({
            "audio_url": f"https://flask-server-beqj.onrender.com/static/audio/{file_id}.mp3"
        })
    except Exception as e:
        print("❌ 音声生成失敗:", str(e))
        return jsonify({"error": "Audio synthesis failed", "details": str(e)}), 500

# 音声ファイルの配信
@app.route("/static/audio/<filename>")
def serve_audio(filename):
    return send_from_directory(SAVE_DIR, filename)

if __name__ == "__main__":
    print("🚀 Flaskサーバー起動中 http://0.0.0.0:5001")
    app.run(debug=True, port=5001, host="0.0.0.0")
