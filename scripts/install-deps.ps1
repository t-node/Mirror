# Mirror Dependencies Installation Script
# This script installs all dependencies for the Mirror project

Write-Host "Installing Mirror dependencies..." -ForegroundColor Green

# Install root dependencies
Write-Host "Installing root dependencies..." -ForegroundColor Yellow
npm install

# Install frontend dependencies
Write-Host "Installing frontend dependencies..." -ForegroundColor Yellow
Set-Location frontend
npm install
Set-Location ..

# Install backend dependencies
Write-Host "Installing backend dependencies..." -ForegroundColor Yellow
Set-Location backend
npm install
Set-Location ..

Write-Host "All dependencies installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "You can now run:" -ForegroundColor Cyan
Write-Host "  npm run dev:frontend  # Start frontend development server" -ForegroundColor White
Write-Host "  npm run dev:backend   # Build backend" -ForegroundColor White
Write-Host "  npm run build         # Build both frontend and backend" -ForegroundColor White 