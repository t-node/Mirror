import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda'

interface HealthResponse {
  status: string
  service: string
  region: string
  requestId: string
  timestamp: string
}

export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  const requestId = context.awsRequestId
  const timestamp = new Date().toISOString()
  const region = process.env.AWS_REGION || 'ap-south-1'

  // Log the request
  console.log(`[${timestamp}] Request received`, {
    path: event.path,
    method: event.httpMethod,
    requestId,
    userAgent: event.headers['User-Agent'] || 'Unknown',
    sourceIp: event.requestContext.identity.sourceIp
  })

  try {
    // Handle health check endpoint
    if (event.path === '/health' && event.httpMethod === 'GET') {
      const response: HealthResponse = {
        status: 'ok',
        service: 'mirror-api',
        region,
        requestId,
        timestamp
      }

      console.log(`[${timestamp}] Health check successful`, { requestId })

      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
          'Access-Control-Allow-Methods': 'GET,OPTIONS'
        },
        body: JSON.stringify(response)
      }
    }

    // Handle OPTIONS requests for CORS
    if (event.httpMethod === 'OPTIONS') {
      return {
        statusCode: 200,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
          'Access-Control-Allow-Methods': 'GET,OPTIONS'
        },
        body: ''
      }
    }

    // Handle unknown routes
    console.log(`[${timestamp}] Route not found`, { 
      path: event.path, 
      method: event.httpMethod, 
      requestId 
    })

    return {
      statusCode: 404,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        error: 'Not Found',
        message: `Route ${event.httpMethod} ${event.path} not found`,
        requestId
      })
    }

  } catch (error) {
    console.error(`[${timestamp}] Error processing request`, { 
      error: error instanceof Error ? error.message : 'Unknown error',
      requestId 
    })

    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        error: 'Internal Server Error',
        message: 'An unexpected error occurred',
        requestId
      })
    }
  }
} 