import { BrowserRouter, Routes, Route, Link } from 'react-router-dom'
import WordList from './components/WordList'
import WordDetail from './components/WordDetail'
import AddWord from './components/AddWord'
import React from 'react'

export default function App() {
  return (
    <BrowserRouter>
      <nav style={styles.nav}>
        <Link to="/" style={styles.brand}>
          <span style={styles.brandDot}></span>
          Visual Dictionary
        </Link>
        <Link to="/add" style={styles.link}>+ Add word</Link>
      </nav>

      <main style={styles.main}>
        <Routes>
          <Route path="/"           element={<WordList />} />
          <Route path="/word/:word" element={<WordDetail />} />
          <Route path="/add"        element={<AddWord />} />
        </Routes>
      </main>
    </BrowserRouter>
  )
}

const styles = {
  nav: {
    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
    padding: '14px 24px', background: '#fff',
    borderBottom: '1px solid #e8e0d6', position: 'sticky', top: 0, zIndex: 10,
  },
  brand: {
    fontWeight: 700, fontSize: '1.1rem', color: '#633806',
    display: 'flex', alignItems: 'center', gap: '8px',
  },
  brandDot: {
    width: '10px', height: '10px', background: '#EF9F27',
    borderRadius: '50%', display: 'inline-block',
  },
  link: {
    background: '#EF9F27', color: '#412402', fontWeight: 600,
    padding: '7px 16px', borderRadius: '20px', fontSize: '0.85rem',
  },
  main: { maxWidth: '960px', margin: '0 auto', padding: '0 1.5rem 3rem' },
}