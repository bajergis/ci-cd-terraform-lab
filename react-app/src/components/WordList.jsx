import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import WordCard from './WordCard'

export default function WordList() {
  const [words, setWords]     = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError]     = useState(null)

  useEffect(() => {
    fetch('/api/words')
      .then(r => {
        if (!r.ok) throw new Error('Failed to fetch words')
        return r.json()
      })
      .then(data => {
        setWords(data)
        setLoading(false)
      })
      .catch(err => {
        setError(err.message)
        setLoading(false)
      })
  }, [])  // empty array = run once on mount

  if (loading) return <p>Loading words...</p>
  if (error)   return <p style={{ color: 'red' }}>Error: {error}</p>
  if (words.length === 0) return (
    <div>
      <p>No words yet.</p>
      <Link to="/add">Add the first word</Link>
    </div>
  )

  return (
    <div>
      <div style={styles.hero}>
        <h1 style={styles.heroTitle}>Learn words with pictures</h1>
        <p style={styles.heroSub}>Tap any word to see its meaning and image</p>
      </div>
      <div style={styles.grid}>
        {words.map(word => <WordCard key={word.word} word={word} />)}
      </div>
    </div>
  )
}

const styles = {
  hero: {
    background: '#fff8f0', borderRadius: '12px',
    padding: '1.5rem', margin: '1.5rem 0 1.25rem',
    border: '1px solid #e8e0d6',
  },
  heroTitle: { fontSize: '1.4rem', fontWeight: 700, color: '#412402', marginBottom: '4px' },
  heroSub:   { fontSize: '0.9rem', color: '#854F0B' },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))',
    gap: '1rem',
  },
}