import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// The page lives at sandbox.descentintoart.com/ulid/, and /api goes to the Lambda.
// In development, /api is passed to a small local server that runs the real handler.
export default defineConfig({
  plugins: [react()],
  base: '/ulid/',
  server: {
    proxy: {
      '/api': 'http://127.0.0.1:5281',
    },
  },
})