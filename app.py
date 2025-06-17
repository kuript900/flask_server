from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import uuid
import os
import asyncio
import edge_tts
from deep_translator import GoogleTranslator

app = Flask(__name__)
CORS(app)

SAVE_DIR = "static/audio"
os.makedirs(SAVE_DIR, exist_ok=True)

VOICE_MAP = {
    "en": "en-US-GuyNeural",
    "ja": "ja-JP-NanamiNeural",
    "fr": "fr-FR-DeniseNeural",
    "es": "es-ES-AlvaroNeural",
    "pt": "pt-BR-AntonioNeural",
    "de": "de-DE-ConradNeural"
}

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
        translated = GoogleTranslator(source=from_lang, target=to_lang).translate(text)
        return jsonify({"translated_text": translated})
    except Exception as e:
        return jsonify({"error": "Translation failed", "details": str(e)}), 500

@app.route("/api/tts", methods=["POST"])
def generate_audio():
    data = request.get_json()
    print("✅ 音声リクエスト:", data)

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
        communicate.rate = f"+{int((float(rate) - 1) * 100)}%"
        asyncio.run(communicate.save(file_path))
        return jsonify({
            "audio_url": f"https://flask-server-beqj.onrender.com/static/audio/{file_id}.mp3"
        })
    except Exception as e:
        return jsonify({"error": "Audio synthesis failed", "details": str(e)}), 500

@app.route("/static/audio/<filename>")
def serve_audio(filename):
    return send_from_directory(SAVE_DIR, filename)

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5001)
