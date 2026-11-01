import { useState, type FormEvent } from 'react'
import './App.css'

type Decoded = { ulid: string; valid: boolean; timestamp?: string; unix_ms?: number }

async function getJson<T>(url: string): Promise<T> {
  const res = await fetch(url)
  const data = await res.json()
  if (!res.ok) throw new Error(data.error ?? `Request failed (${res.status})`)
  return data
}

export default function App() {
  const [count, setCount] = useState(1)
  const [ulids, setUlids] = useState<string[]>([])
  const [input, setInput] = useState('')
  const [decoded, setDecoded] = useState<Decoded | null>(null)
  const [error, setError] = useState('')

  async function mint() {
    setError('')
    try {
      const data = await getJson<{ ulids: string[] }>(`/api/ulid?count=${count}`)
      setUlids(data.ulids)
    } catch (err) {
      setError((err as Error).message)
    }
  }

  async function check(event: FormEvent) {
    event.preventDefault()
    setError('')
    const value = input.trim()
    if (!value) return
    try {
      setDecoded(await getJson<Decoded>(`/api/ulid/${encodeURIComponent(value)}`))
    } catch (err) {
      setError((err as Error).message)
    }
  }

  return (
    <main className="app">
      <h1>ULID tool</h1>

      <section>
        <h2>Make ULIDs</h2>
        <label>
          How many (1–100){' '}
          <input
            type="number"
            min={1}
            max={100}
            value={count}
            onChange={(e) => setCount(Number(e.target.value))}
          />
        </label>{' '}
        <button type="button" onClick={mint}>Make</button>
        {ulids.length > 0 && (
          <ol className="ulids">
            {ulids.map((u) => (
              <li key={u}><code>{u}</code></li>
            ))}
          </ol>
        )}
      </section>

      <section>
        <h2>Check a ULID</h2>
        <form onSubmit={check}>
          <input
            type="text"
            value={input}
            placeholder="Paste a ULID"
            spellCheck={false}
            onChange={(e) => setInput(e.target.value)}
          />{' '}
          <button type="submit">Check</button>
        </form>
        {decoded && (
          decoded.valid ? (
            <p>
              Valid. Made{' '}
              {decoded.unix_ms !== undefined
                ? new Date(decoded.unix_ms).toLocaleString()
                : decoded.timestamp}
            </p>
          ) : (
            <p>Not a valid ULID.</p>
          )
        )}
      </section>

      {error && <p className="error" role="alert">{error}</p>}
    </main>
  )
}