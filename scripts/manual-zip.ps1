# Manual ZIP creation using PowerShell Compress-Archive
Write-Host "Creating ZIP file manually..." -ForegroundColor Green

Set-Location backend

# Remove existing ZIP if it exists
if (Test-Path "function.zip") {
    Remove-Item "function.zip" -Force
    Write-Host "Removed existing function.zip" -ForegroundColor Yellow
}

# Create ZIP using PowerShell Compress-Archive
try {
    Compress-Archive -Path "dist\*" -DestinationPath "function.zip" -Force
    Write-Host "ZIP file created successfully: function.zip" -ForegroundColor Green
    Write-Host "Size: $((Get-Item function.zip).Length) bytes" -ForegroundColor Cyan
} catch {
    Write-Host "Failed to create ZIP file: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please create the ZIP file manually using Windows Explorer" -ForegroundColor Yellow
}

Set-Location .. 