# Test local setup
Write-Host "Testing local Mirror setup..." -ForegroundColor Green

# Test backend API
Write-Host "Testing backend API..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3001/health" -Method Get
    Write-Host "Backend API is working!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Cyan
} catch {
    Write-Host "Backend API is not responding: $($_.Exception.Message)" -ForegroundColor Red
}

# Test frontend
Write-Host "Testing frontend..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5173" -Method Get
    if ($response.StatusCode -eq 200) {
        Write-Host "Frontend is working!" -ForegroundColor Green
    } else {
        Write-Host "Frontend returned status: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Frontend is not responding: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Open your browser to: http://localhost:5173" -ForegroundColor Cyan
Write-Host "Click the 'Ping API' button to test the connection!" -ForegroundColor Cyan 