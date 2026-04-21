import pytest
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

os.environ.setdefault("UNSPLASH_ACCESS_KEY", 'test')

from app import app, db

@pytest.fixture
def client():
    app.config["TESTING"] = True
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:" #potential change
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
        yield client
        db.session.remove()
        db.drop_all()

def test_get_words_returns_list(client):
    res = client.get("/api/words")
    assert res.status_code == 200
    assert isinstance(res.get_json(), list)

def test_word_not_found_returns_404(client):
    res = client.get("/api/words/nonexistentword")
    assert res.status_code == 404

def test_create_and_get_word(client):
    res = client.post("/api/words", json={
        "word": "serendipity",
        "definition": "Finding something good without looking for it",
        "image_url": "https://example.com/image.jpg",
        "image_credit": "Test credit"
    })
    assert res.status_code == 201

    res = client.get("/api/words/serendipity")
    assert res.status_code == 200
    data = res.get_json()
    assert data["word"] == "serendipity"

def test_duplicate_word_rejected(client):
    client.post("/api/words", json={
        "word": "test",
        "definition": "A test word",
        "image_url": "https://example.com/image.jpg",
        "image_credit": "Test credit"
    })
    res = client.post("/api/words", json={
        "word": "test",
        "definition": "Duplicate word",
        "image_url": "https://example.com/image.jpg",
        "image_credit": "Test credit"
    })
    assert res.status_code == 409

def test_delete_word(client):
    client.post("/api/words", json={
        "word": "ephemeral",
        "definition": "Lasting for a very short time",
        "image_url": "https://example.com/image.jpg",
        "image_credit": "Test credit"
    })
    res = client.delete("/api/words/ephemeral")
    assert res.status_code == 200