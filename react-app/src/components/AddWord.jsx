import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import ImageSearch from './ImageSearch'

export default function AddWord() {
  const navigate = useNavigate()
  const [form, setForm] = useState({ word: '', definition: '' })
  const [selectedImage, setSelectedImage] = useState(null)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)
  const [saved, setSaved] = useState(false)        // NEW

  function handleChange(e) {
    setForm({ ...form, [e.target.name]: e.target.value })
  }

  function handleSubmit(e) {
    e.preventDefault()
    if (!selectedImage) {
      setError('Please search for and select an image.')
      return
    }

    setSubmitting(true)
    fetch('/api/words', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        word:         form.word,
        definition:   form.definition,
        image_url:    selectedImage.url,
        image_credit: selectedImage.credit,
      }),
    })
      .then(r => {
        if (!r.ok) throw new Error('Failed to save word')
        return r.json()
      })
      .then(() => {
        setSaved(true)                                      // NEW — show toast
        setTimeout(() => navigate(`/word/${form.word}`), 800)  // NEW — redirect after 800ms
      })
      .catch(err => {
        setError(err.message)
        setSubmitting(false)
      })
  }

  return (
    <div style={styles.container}>
      <h2 style={styles.heading}>Add a new word</h2>

      <form onSubmit={handleSubmit}>
        <div style={styles.field}>
          <label style={styles.label}>Word</label>
          <input
            name="word"
            value={form.word}
            onChange={handleChange}
            required
            style={styles.input}
          />
        </div>

        <div style={styles.field}>
          <label style={styles.label}>Definition</label>
          <textarea
            name="definition"
            value={form.definition}
            onChange={handleChange}
            required
            rows={4}
            style={{ ...styles.input, resize: 'vertical' }}
          />
        </div>

        <ImageSearch
          word={form.word}
          onSelect={img => setSelectedImage(img)}
          selected={selectedImage}
        />

        {error && <p style={{ color: '#A32D2D', marginBottom: '12px' }}>{error}</p>}

        {/* NEW — toast appears after successful save, before redirect */}
        {saved && (
          <div style={styles.toast}>
            <span style={styles.toastDot}></span> Word saved!
          </div>
        )}

        <button
          type="submit"
          disabled={submitting || saved}
          style={styles.submitBtn}
        >
          {submitting ? 'Saving...' : 'Save word'}
        </button>
      </form>
    </div>
  )
}

const styles = {
  container:  { maxWidth: '580px', paddingTop: '1.5rem' },
  heading:    { marginTop: 0, color: '#412402', fontSize: '1.3rem', fontWeight: 700, marginBottom: '1.5rem' },
  field:      { marginBottom: '1.25rem' },
  label:      { display: 'block', marginBottom: '5px', fontWeight: 600, fontSize: '0.85rem', color: '#633806' },
  input:      {
    width: '100%', padding: '0.6rem 0.85rem',
    border: '1.5px solid #e8e0d6', borderRadius: '8px',
    fontSize: '1rem', boxSizing: 'border-box',
    background: '#fff', color: '#412402',
  },
  submitBtn:  {
    marginTop: '1.25rem', padding: '0.75rem 2rem',
    background: '#EF9F27', color: '#412402',
    border: 'none', borderRadius: '20px',
    fontSize: '1rem', fontWeight: 600, width: '100%',
  },
  toast: {
    display: 'inline-flex', alignItems: 'center', gap: '8px',
    background: '#412402', color: '#FAC775',
    padding: '8px 16px', borderRadius: '20px',
    fontSize: '0.85rem', marginBottom: '12px',
  },
  toastDot: {
    width: '7px', height: '7px',
    background: '#EF9F27', borderRadius: '50%', display: 'inline-block',
  },
}