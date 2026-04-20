import { useState } from 'react'

export default function ImageSearch({ word, onSelect, selected }) {
  const [results, setResults]   = useState([])
  const [searching, setSearching] = useState(false)

  function handleSearch() {
    if (!word) return
    setSearching(true)
    fetch('/api/search-images', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query: word }),
    })
      .then(r => r.json())
      .then(data => {
        setResults(data.images || [])
        setSearching(false)
      })
  }

  return (
    <div style={styles.container}>
      <div style={styles.row}>
        <label style={styles.label}>Image</label>
        <button
          type="button"  // important: prevents form submission
          onClick={handleSearch}
          disabled={!word || searching}
          style={styles.searchBtn}
        >
          {searching ? 'Searching...' : `Search Unsplash for "${word}"`}
        </button>
      </div>

      {selected && (
        <div style={styles.selectedRow}>
          <img src={selected.url} alt="" style={styles.selectedThumb} />
          <span style={styles.selectedLabel}>Selected — {selected.credit}</span>
        </div>
      )}

      {results.length > 0 && (
        <div style={styles.grid}>
          {results.map((img, i) => (
            <img
              key={i}
              src={img.url}
              alt={img.credit}
              title={`Photo by ${img.credit}`}
              onClick={() => onSelect(img)}
              style={{
                ...styles.thumb,
                outline: selected?.url === img.url ? '3px solid #1a1a1a' : 'none',
              }}
            />
          ))}
        </div>
      )}
    </div>
  )
}

const styles = {
  container:    { marginBottom: '1.25rem' },
  row:          { display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '0.75rem' },
  label:        { fontWeight: 500, fontSize: '0.9rem', whiteSpace: 'nowrap' },
  searchBtn:    { padding: '0.5rem 1rem', border: '1px solid #ddd', borderRadius: '6px', cursor: 'pointer', fontSize: '0.9rem', background: '#f5f5f5' },
  selectedRow:  { display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.75rem' },
  selectedThumb:{ width: '60px', height: '60px', objectFit: 'cover', borderRadius: '4px' },
  selectedLabel:{ fontSize: '0.85rem', color: '#555' },
  grid:         { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '0.5rem' },
  thumb:        { width: '100%', aspectRatio: '1', objectFit: 'cover', borderRadius: '4px', cursor: 'pointer' },
}