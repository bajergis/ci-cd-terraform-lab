import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    // During local dev, proxy /api calls to Flask
    // In production on K8s, Nginx handles this instead
    proxy: {
      '/api': 'http://localhost:5000'
    }
  }
})