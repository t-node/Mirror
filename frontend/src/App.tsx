import { useState } from 'react'
import './App.css'

interface HealthResponse {
  status: string
  service: string
  region: string
  requestId: string
}

function App() {
  const [healthData, setHealthData] = useState<HealthResponse | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

  const pingApi = async () => {
    setLoading(true)
    setError(null)
    setHealthData(null)

    try {
      const response = await fetch(`${apiBaseUrl}/health`)
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      const data: HealthResponse = await response.json()
      setHealthData(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error occurred')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="app">
      <header className="app-header">
        <h1>Mirror v0.0 — Upload coming soon</h1>
        <p>Secure medical audio transcription and analysis platform</p>
      </header>

      <main className="app-main">
        <div className="api-section">
          <h2>API Health Check</h2>
          <p>Test the connection to our backend API</p>
          
          <button 
            onClick={pingApi} 
            disabled={loading}
            className="ping-button"
          >
            {loading ? 'Pinging...' : 'Ping API'}
          </button>

          {error && (
            <div className="error-message">
              <h3>Error</h3>
              <p>{error}</p>
            </div>
          )}

          {healthData && (
            <div className="success-message">
              <h3>✅ API Healthy</h3>
              <div className="health-data">
                <p><strong>Status:</strong> {healthData.status}</p>
                <p><strong>Service:</strong> {healthData.service}</p>
                <p><strong>Region:</strong> {healthData.region}</p>
                <p><strong>Request ID:</strong> <code>{healthData.requestId}</code></p>
              </div>
            </div>
          )}
        </div>

        <div className="info-section">
          <h2>What's Next?</h2>
          <ul>
            <li>🔐 Secure authentication with AWS Cognito</li>
            <li>📁 Audio file upload with S3</li>
            <li>🎤 AI-powered transcription</li>
            <li>📊 Medical analysis and insights</li>
          </ul>
        </div>
      </main>

      <footer className="app-footer">
        <p>Built with React, AWS Lambda, and Terraform</p>
      </footer>
    </div>
  )
}

export default App 