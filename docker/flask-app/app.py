import os
import json
import redis
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS
from database import db, init_db
from models import Word
from dotenv import load_dotenv

load_dotenv()

redis_client = redis.from_url(os.environ.get("REDIS_URL", "redis://localhost:6379"))

DATABASE_URL = (
    f"postgresql://{os.environ.get('POSTGRES_USER')}"
    f":{os.environ.get('POSTGRES_PASSWORD')}"
    f"@{os.environ.get('POSTGRES_HOST')}"
    f":{os.environ.get('POSTGRES_PORT')}"
    f"/{os.environ.get('POSTGRES_DB')}"
)

app = Flask(__name__)
app.url_map.strict_slashes = False
app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
CORS(app)
init_db(app)

UNSPLASH_ACCESS_KEY = os.environ.get('UNSPLASH_ACCESS_KEY')

# ------- API Routes -------

@app.route("/api/words/", methods=["GET"])
def get_words():
    words = Word.query.order_by(Word.created_at.desc()).all()
    return jsonify([w.to_dict() for w in words])

@app.route("/api/words/<string:word>", methods=["GET"])
def get_word(word):
    entry = Word.query.filter_by(word=word.lower()).first_or_404()
    return jsonify(entry.to_dict())

@app.route("/api/words", methods=["POST"])
def create_word():
    data = request.get_json()
    if not data or not all(k in data for k in ["word", "definition", "image_url", "image_credit"]):
        return jsonify({"error": "Missing required fields"}), 400

    existing = Word.query.filter_by(word=data["word"].lower()).first()
    if existing:
        return jsonify({"error": "Word already exists"}), 409

    entry = Word(
        word=data["word"].lower(),
        definition=data["definition"],
        image_url=data["image_url"],
        image_credit=data["image_credit"],
    )
    db.session.add(entry)
    db.session.commit()
    return jsonify(entry.to_dict()), 201

@app.route("/api/words/<string:word>", methods=["DELETE"])
def delete_word(word):
    entry = Word.query.filter_by(word=word.lower()).first_or_404()
    db.session.delete(entry)
    db.session.commit()
    return jsonify({"message": f"'{word}' deleted successfully"}), 200

@app.route("/api/search-images", methods=["POST"])
def search_images():
    query = request.json.get("query", "").strip().lower()
    if not query:
        return jsonify({"error": "query required"}), 400

    cache_key = f"unsplash_{query}"

    # check cache first
    cached = redis_client.get(cache_key)
    if cached:
        return jsonify(json.loads(cached))

    # cache miss - call Unsplash
    unsplash_access_key = os.environ.get("UNSPLASH_ACCESS_KEY")
    response = requests.get(
        'https://api.unsplash.com/search/photos',
        params={'query': query, 'per_page': 9},
        headers={'Authorization': f'Client-ID {unsplash_access_key}'}
    )
    data = response.json()

    images = [
        {
            'url':    photo['urls']['small'],
            'credit': photo['user']['name']
        }
        for photo in data.get('results', [])
    ]
    result = {'images': images}

    # write cache with 1 hour TTL
    redis_client.setex(cache_key, 3600, json.dumps(result))
    return jsonify(result)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)