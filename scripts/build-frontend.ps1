# Frontend Build Script
Write-Host "Building frontend..." -ForegroundColor Green

Set-Location frontend
npm run build
Set-Location .. 