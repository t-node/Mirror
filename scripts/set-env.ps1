# Set AWS Environment Variables
# Run this script to set your AWS credentials as environment variables

Write-Host "Setting AWS Environment Variables..." -ForegroundColor Green

# Set your AWS credentials here
# Replace these with your actual AWS credentials
$env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
$env:AWS_ACCOUNT_ID = "YOUR_ACCOUNT_ID"
$env:AWS_DEFAULT_REGION = "ap-south-1"

Write-Host "AWS credentials set as environment variables" -ForegroundColor Green
Write-Host "You can now run: npm run setup-aws" -ForegroundColor Yellow

# Test the credentials
Write-Host "Testing AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --query "Account" --output text
    Write-Host "AWS credentials are valid. Account: $identity" -ForegroundColor Green
} catch {
    Write-Host "AWS credentials test failed: $($_.Exception.Message)" -ForegroundColor Red
} 