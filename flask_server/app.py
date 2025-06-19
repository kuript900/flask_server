from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import uuid
import edge_tts
import asyncio
from google.cloud import translate_v2 as translate

# 環境変数 GOOGLE_APPLICATION_CREDENTIALS を設定済みであることを想定
# credentials.json へのパスを指定（Renderでは自動設定）

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

translate_client = translate.Client()

@app.route("/api/translate", methods=["POST"])
def translate_text():
    data = request.json
    text = data.get("text", "")
    source_lang = data.get("from", "auto")
    target_lang = data.get("to", "ja")

    result = translate_client.translate(
        text,
        source_language=source_lang,
        target_language=target_lang,
        format_='text'
    )
    return jsonify({"translated_text": result["translatedText"]})

@app.route("/api/tts", methods=["POST"])
def tts():
    data = request.json
    text = data.get("text", "")
    lang = data.get("lang", "en")
    speed = float(data.get("speed", 1.0))
    repeat = int(data.get("repeat", 1))

    voice_map = {
        "ja": "ja-JP-NanamiNeural",
        "en": "en-US-JennyNeural",
        "zh": "zh-CN-XiaoxiaoNeural",
        "fr": "fr-FR-DeniseNeural",
        "de": "de-DE-KatjaNeural",
        "es": "es-ES-ElviraNeural",
    }
    voice = voice_map.get(lang, "en-US-JennyNeural")

    filename = f"{uuid.uuid4().hex}.mp3"
    filepath = os.path.join("static", "audio", filename)
    text_to_speak = (text + "。") * repeat

    async def generate():
        communicate = edge_tts.Communicate(text_to_speak, voice)
        await communicate.save(filepath)

    asyncio.run(generate())

    return jsonify({"audio_url": f"https://flask-server-beqj.onrender.com/static/audio/{filename}"})

if __name__ == "__main__":
    app.run(debug=True)
