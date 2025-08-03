# Create Clean Repository Script
# This script helps create a new repository without credential history

Write-Host "Creating Clean Repository..." -ForegroundColor Green

# Create a new directory for the clean repo
$cleanDir = "../mirror-clean"
if (Test-Path $cleanDir) {
    Remove-Item $cleanDir -Recurse -Force
}

Write-Host "1. Creating clean directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $cleanDir -Force | Out-Null

Write-Host "2. Copying files (excluding .git and credential files)..." -ForegroundColor Yellow
# Copy all files except .git and scripts with credentials
Get-ChildItem -Path "." -Exclude ".git", "scripts/set-env.ps1", "scripts/test-aws-setup.ps1", "scripts/clean-history.ps1" | Copy-Item -Destination $cleanDir -Recurse -Force

Write-Host "3. Creating clean scripts..." -ForegroundColor Yellow

# Create a clean set-env script
$cleanSetEnv = @"
# Set AWS Environment Variables
# Replace these with your actual AWS credentials

Write-Host "Setting AWS Environment Variables..." -ForegroundColor Green

# Set your AWS credentials here
# Replace these with your actual AWS credentials
`$env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY_ID"
`$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
`$env:AWS_ACCOUNT_ID = "YOUR_ACCOUNT_ID"
`$env:AWS_DEFAULT_REGION = "ap-south-1"

Write-Host "AWS credentials set as environment variables" -ForegroundColor Green
Write-Host "You can now run: npm run setup-aws" -ForegroundColor Yellow
"@

$cleanSetEnv | Out-File -FilePath "$cleanDir/scripts/set-env.ps1" -Encoding UTF8

# Create a clean test script
$cleanTestScript = @"
# Test AWS Setup Locally
# This script tests your AWS credentials and OIDC setup

Write-Host "Testing AWS Setup..." -ForegroundColor Green

# Set your AWS credentials (replace with your actual credentials)
`$env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY_ID"
`$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
`$env:AWS_DEFAULT_REGION = "ap-south-1"
`$env:AWS_ACCOUNT_ID = "YOUR_ACCOUNT_ID"

Write-Host "Please replace the placeholder credentials with your actual AWS credentials" -ForegroundColor Yellow
Write-Host "Then run this script to test your setup" -ForegroundColor Yellow
"@

$cleanTestScript | Out-File -FilePath "$cleanDir/scripts/test-aws-setup.ps1" -Encoding UTF8

Write-Host "4. Clean repository created at: $cleanDir" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Create a new GitHub repository" -ForegroundColor Gray
Write-Host "2. Navigate to: $cleanDir" -ForegroundColor Gray
Write-Host "3. Run: git init" -ForegroundColor Gray
Write-Host "4. Run: git add ." -ForegroundColor Gray
Write-Host "5. Run: git commit -m 'Initial commit'" -ForegroundColor Gray
Write-Host "6. Add your GitHub remote and push" -ForegroundColor Gray

Write-Host "`nClean repository ready!" -ForegroundColor Green 