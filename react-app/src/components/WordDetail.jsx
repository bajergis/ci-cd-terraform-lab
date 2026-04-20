import { useState, useEffect } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'

export default function WordDetail() {
  const { word }        = useParams()   // pulls :word from the URL
  const navigate        = useNavigate() // for redirect after delete
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch(`/api/words/${word}`)
      .then(r => r.json())
      .then(data => {
        setData(data)
        setLoading(false)
      })
  }, [word])  // re-run if the word in the URL changes

  function handleDelete() {
    if (!confirm(`Delete "${word}"?`)) return
    fetch(`/api/words/${word}`, { method: 'DELETE' })
      .then(() => navigate('/'))  // go back to word list
  }

  if (loading) return <p>Loading...</p>
  if (!data)   return <p>Word not found. <Link to="/">Go back</Link></p>

  return (
    <div>
      <Link to="/" style={styles.back}>← All words</Link>

      <div style={styles.card}>
        {data.image_url && (
          <img src={data.image_url} alt={word} style={styles.image} />
        )}
        {data.image_credit && (
          <p style={styles.credit}>Photo by {data.image_credit} on Unsplash</p>
        )}
        <h1 style={styles.word}>{data.word}</h1>
        <p style={styles.definition}>{data.definition}</p>
        <button onClick={handleDelete} style={styles.deleteBtn}>
          Delete word
        </button>
      </div>
    </div>
  )
}

const styles = {
  back:       { color: '#854F0B', fontSize: '0.9rem', display: 'inline-block', margin: '1.25rem 0 1rem' },
  card:       { background: '#fff', border: '1px solid #e8e0d6', borderRadius: '12px', overflow: 'hidden' },
  image:      { width: '100%', maxHeight: '380px', objectFit: 'cover', display: 'block' },
  credit:     { padding: '0.6rem 1.5rem 0', fontSize: '0.8rem', color: '#BA7517' },
  word:       { padding: '1.25rem 1.5rem 0', fontSize: '2rem', fontWeight: 700, color: '#412402' },
  definition: { padding: '0.75rem 1.5rem 1.5rem', color: '#633806', lineHeight: 1.75, fontSize: '1rem' },
  actions:    { padding: '0 1.5rem 1.5rem', display: 'flex', gap: '8px', flexWrap: 'wrap' },
  deleteBtn:  {
    background: '#FCEBEB', color: '#A32D2D',
    border: '1px solid #F7C1C1', borderRadius: '20px',
    padding: '7px 18px', fontSize: '0.85rem',
  },
}