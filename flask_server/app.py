# flask_server/app.py
from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import uuid
from edge_tts import Communicate
import asyncio
from google.cloud import translate_v2 as translate

app = Flask(__name__)
CORS(app)

translate_client = translate.Client()

@app.route("/")
def index():
    return "Flask server is running!"

@app.route("/api/translate", methods=["POST"])
def translate_text():
    data = request.json
    text = data["text"]
    source = data["from"]
    target = data["to"]
    result = translate_client.translate(text, source_language=source, target_language=target)
    return jsonify({"translated_text": result["translatedText"]})


@app.route("/api/tts", methods=["POST"])
def generate_tts():
    data = request.json
    text = data["text"]
    lang = data["lang"]
    rate = data.get("rate", 1.0)
    repeat = data.get("repeat", 1)

    output_dir = "static/audio"
    os.makedirs(output_dir, exist_ok=True)
    file_id = str(uuid.uuid4())
    output_path = os.path.join(output_dir, f"{file_id}.mp3")

    voice_map = {
        "en": "en-US-AriaNeural",
        "ja": "ja-JP-NanamiNeural",
        "es": "es-ES-ElviraNeural",
        "fr": "fr-FR-DeniseNeural",
        "de": "de-DE-KatjaNeural",
        "zh-CN": "zh-CN-XiaoxiaoNeural"
    }

    voice = voice_map.get(lang, "en-US-AriaNeural")
    communicate = Communicate(text, voice=voice, rate=f"{int((rate - 1.0) * 100)}%")

    async def save_audio():
        with open(output_path, "wb") as f:
            for _ in range(repeat):
                async for chunk in communicate.stream():
                    if chunk["type"] == "audio":
                        f.write(chunk["data"])

    asyncio.run(save_audio())

    return jsonify({
        "audio_url": f"https://flask-server-beqj.onrender.com/static/audio/{file_id}.mp3"
    })

if __name__ == "__main__":
    app.run(debug=True)
