# Test AWS Setup Locally
# This script tests your AWS credentials and OIDC setup

Write-Host "Testing AWS Setup..." -ForegroundColor Green

# Set your AWS credentials (replace with your actual credentials)
$env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
$env:AWS_DEFAULT_REGION = "ap-south-1"
$env:AWS_ACCOUNT_ID = "YOUR_ACCOUNT_ID"

Write-Host "1. Testing AWS CLI..." -ForegroundColor Yellow
try {
    $awsVersion = aws --version
    Write-Host "✅ AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not found. Please install AWS CLI v2." -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Testing AWS Credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --query "Account" --output text
    Write-Host "✅ AWS credentials valid. Account: $identity" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS credentials invalid: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n3. Checking OIDC Provider..." -ForegroundColor Yellow
try {
    $oidcProvider = aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::622297126778:oidc-provider/token.actions.githubusercontent.com" 2>$null
    if ($oidcProvider) {
        Write-Host "✅ OIDC Provider exists" -ForegroundColor Green
    } else {
        Write-Host "❌ OIDC Provider not found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error checking OIDC Provider: $_" -ForegroundColor Red
}

Write-Host "`n4. Checking IAM Role..." -ForegroundColor Yellow
try {
    $role = aws iam get-role --role-name "mirror-deploy-role" 2>$null
    if ($role) {
        Write-Host "✅ IAM Role exists" -ForegroundColor Green
        
        # Check trust policy
        $trustPolicy = aws iam get-role --role-name "mirror-deploy-role" --query 'Role.AssumeRolePolicyDocument' --output json 2>$null
        Write-Host "Trust Policy:" -ForegroundColor Cyan
        Write-Host $trustPolicy -ForegroundColor Gray
    } else {
        Write-Host "❌ IAM Role not found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error checking IAM Role: $_" -ForegroundColor Red
}

Write-Host "`n5. GitHub Variables Check:" -ForegroundColor Yellow
Write-Host "Please verify these variables are set in GitHub:" -ForegroundColor Cyan
Write-Host "  AWS_REGION: ap-south-1" -ForegroundColor Gray
Write-Host "  AWS_ROLE_ARN: arn:aws:iam::622297126778:role/mirror-deploy-role" -ForegroundColor Gray

Write-Host "`n6. GitHub Repository Permissions:" -ForegroundColor Yellow
Write-Host "Go to: Settings → Actions → General" -ForegroundColor Cyan
Write-Host "Set 'Workflow permissions' to 'Read and write permissions'" -ForegroundColor Gray
Write-Host "Enable 'Allow GitHub Actions to create and approve pull requests'" -ForegroundColor Gray

Write-Host "`n7. To allow secrets temporarily:" -ForegroundColor Yellow
Write-Host "Visit these URLs and click 'Allow secret':" -ForegroundColor Cyan
Write-Host "  Access Key: https://github.com/t-node/Mirror/security/secret-scanning/unblock-secret/30mwXGOUsup7Oiq4WVupq8ySZQI" -ForegroundColor Gray
Write-Host "  Secret Key: https://github.com/t-node/Mirror/security/secret-scanning/unblock-secret/30mwXDrTXTDnLKn17z9dfj7nRng" -ForegroundColor Gray

Write-Host "`nTest completed!" -ForegroundColor Green 