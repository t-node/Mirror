# Backend Build Script
Write-Host "Building backend..." -ForegroundColor Green

Set-Location backend
npm run build

# Create ZIP file for Lambda deployment
Write-Host "Creating Lambda deployment package..." -ForegroundColor Yellow
if (Test-Path function.zip) { Remove-Item function.zip -Force }
Compress-Archive -Path "dist\*" -DestinationPath "function.zip" -Force
Write-Host "ZIP file created: function.zip" -ForegroundColor Green

Set-Location .. 