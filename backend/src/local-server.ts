import express from 'express'
import cors from 'cors'
import { handler } from './handler'

const app = express()
const PORT = process.env.PORT || 3001

// Middleware
app.use(cors({
  origin: 'http://localhost:5173', // Vite dev server
  credentials: true
}))
app.use(express.json())

// Convert Lambda handler to Express middleware
const lambdaToExpress = (lambdaHandler: any) => {
  return async (req: express.Request, res: express.Response) => {
    // Convert Express request to Lambda event
    const event = {
      path: req.path,
      httpMethod: req.method,
      headers: req.headers,
      queryStringParameters: req.query,
      body: req.body,
      requestContext: {
        identity: {
          sourceIp: req.ip || '127.0.0.1'
        }
      }
    }

    // Create mock Lambda context
    const context = {
      awsRequestId: `local-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
    }

    try {
      // Call Lambda handler
      const result = await lambdaHandler(event, context)
      
      // Set response headers
      if (result.headers) {
        Object.entries(result.headers).forEach(([key, value]) => {
          res.setHeader(key, value as string)
        })
      }
      
      // Send response
      res.status(result.statusCode || 200).send(result.body)
    } catch (error) {
      console.error('Error in Lambda handler:', error)
      res.status(500).json({ error: 'Internal server error' })
    }
  }
}

// Routes
app.get('/health', lambdaToExpress(handler))
app.options('*', lambdaToExpress(handler)) // Handle CORS preflight

// Catch-all route for other paths
app.all('*', lambdaToExpress(handler))

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Local API server running on http://localhost:${PORT}`)
  console.log(`📡 Health endpoint: http://localhost:${PORT}/health`)
  console.log(`🌐 Frontend should connect to: http://localhost:${PORT}`)
}) 