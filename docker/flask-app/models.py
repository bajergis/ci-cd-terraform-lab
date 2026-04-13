from database import db
from datetime import datetime

class Word(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    word = db.Column(db.String(100), unique=True, nullable=False)
    definition = db.Column(db.Text, nullable=False)
    image_url = db.Column(db.String(500), nullable=False)
    image_credit = db.Column(db.String(200), nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'word': self.word,
            'definition': self.definition,
            'image_url': self.image_url,
            'image_credit': self.image_credit,
            'created_at': self.created_at
        }