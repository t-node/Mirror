# Clean Build Artifacts Script
Write-Host "Cleaning build artifacts..." -ForegroundColor Green

if (Test-Path "frontend\dist") {
    Remove-Item "frontend\dist" -Recurse -Force
    Write-Host "Removed frontend\dist" -ForegroundColor Green
}

if (Test-Path "backend\dist") {
    Remove-Item "backend\dist" -Recurse -Force
    Write-Host "Removed backend\dist" -ForegroundColor Green
}

if (Test-Path "backend\function.zip") {
    Remove-Item "backend\function.zip" -Force
    Write-Host "Removed backend\function.zip" -ForegroundColor Green
}

Write-Host "Cleanup completed!" -ForegroundColor Green 