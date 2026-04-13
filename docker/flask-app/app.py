import os
import requests
from flask import Flask, render_template, request, jsonify, redirect, url_for
from database import db, init_db
from models import Word
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = "sqlite:///dictionary.db"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

init_db(app)

UNSPLASH_ACCESS_KEY = os.environ.get('UNSPLASH_ACCESS_KEY')

# ------- Page Routes -------

@app.route("/")
def index():
    words = Word.query.order_by(Word.created_at.desc()).all()
    return render_template("index.html", words=words)

@app.route("/add")
def add():
    return render_template("add.html")

@app.route("/words/<string:word>")
def word_detail(word):
    entry = Word.query.filter_by(word=word.lower()).first_or_404()
    return render_template("word.html", entry=entry)

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
    data = request.get_json()
    query = data.get("query", "")
    if not query:
        return jsonify({"error": "No search query provided"}), 400

    response = requests.get(
        "https://api.unsplash.com/search/photos",
        params={"query": query, "per_page": 9, "orientation": "landscape"},
        headers={"Authorization": f"Client-ID {UNSPLASH_ACCESS_KEY}"}
    )

    if response.status_code != 200:
        return jsonify({"error": f"Error getting results"}), 500

    results = response.json()
    images = [
        {
            "url": photo["urls"]["regular"],
            "thumb": photo["urls"]["small"],
            "credit": f"Photo by {photo['user']['name'],} on Unsplash"
        }
        for photo in results["results"]
    ]
    return jsonify({"images": images})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)