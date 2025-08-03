# Local Development Script
# This script runs both frontend and backend locally

Write-Host "Starting Mirror app locally..." -ForegroundColor Green
Write-Host ""

# Check if Node.js is installed
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Node.js is not installed. Please install Node.js 20 or later." -ForegroundColor Red
    exit 1
}

# Install dependencies if needed
Write-Host "Installing dependencies..." -ForegroundColor Yellow
npm run install:all

# Create frontend .env file for local development
Write-Host "Setting up frontend environment..." -ForegroundColor Yellow
Set-Location frontend
if (-not (Test-Path .env)) {
    "VITE_API_BASE_URL=http://localhost:3001" | Out-File -FilePath .env -Encoding UTF8
    Write-Host "Created .env file with local API URL" -ForegroundColor Green
} else {
    Write-Host ".env file already exists" -ForegroundColor Green
}
Set-Location ..

# Start backend server in background
Write-Host "Starting backend server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-Command", "cd backend; npm run start:local" -WindowStyle Minimized

# Wait a moment for backend to start
Start-Sleep -Seconds 3

# Start frontend development server
Write-Host "Starting frontend development server..." -ForegroundColor Yellow
Set-Location frontend
npm run dev 