import { Link } from 'react-router-dom'
import React from 'react'

export default function WordCard({ word }) {
  return (
    <Link to={`/word/${word.word}`} style={styles.link}>
      <div style={styles.card}>
        {word.image_url && (
          <img
            src={word.image_url}
            alt={word.word}
            style={styles.image}
          />
        )}
        <div style={styles.body}>
          <h3 style={styles.word}>{word.word}</h3>
          <p style={styles.definition}>{word.definition}</p>
        </div>
      </div>
    </Link>
  )
}

const styles = {
  link: { textDecoration: 'none', color: 'inherit' },
  card: {
    background: '#fff', border: '1px solid #e8e0d6',
    borderRadius: '10px', overflow: 'hidden',
    transition: 'border-color 0.15s, transform 0.15s',
  },
  image: { width: '100%', height: '150px', objectFit: 'cover', display: 'block' },
  imagePlaceholder: {
    width: '100%', height: '150px', background: '#faeeda',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    fontSize: '2.5rem',
  },
  body:       { padding: '0.85rem' },
  word:       { fontWeight: 700, fontSize: '1rem', color: '#412402', marginBottom: '4px' },
  definition: {
    fontSize: '0.85rem', color: '#854F0B', lineHeight: 1.5,
    display: '-webkit-box', WebkitLineClamp: 2,
    WebkitBoxOrient: 'vertical', overflow: 'hidden',
  },
}