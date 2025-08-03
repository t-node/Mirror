# Verify OIDC Provider and Role Setup
param(
    [string]$AWS_ACCESS_KEY_ID = $env:AWS_ACCESS_KEY_ID,
    [string]$AWS_SECRET_ACCESS_KEY = $env:AWS_SECRET_ACCESS_KEY,
    [string]$AWS_REGION = "ap-south-1",
    [string]$GITHUB_USERNAME = "t-node"
)

Write-Host "Verifying OIDC Provider and Role Setup..." -ForegroundColor Green

# Set AWS credentials
$env:AWS_ACCESS_KEY_ID = $AWS_ACCESS_KEY_ID
$env:AWS_SECRET_ACCESS_KEY = $AWS_SECRET_ACCESS_KEY
$env:AWS_DEFAULT_REGION = $AWS_REGION

Write-Host "1. Checking OIDC Provider..." -ForegroundColor Yellow
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

Write-Host "`n2. Checking IAM Role..." -ForegroundColor Yellow
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

Write-Host "`n3. Checking attached policies..." -ForegroundColor Yellow
try {
    $attachedPolicies = aws iam list-attached-role-policies --role-name "mirror-deploy-role" --query 'AttachedPolicies[].PolicyName' --output table 2>$null
    if ($attachedPolicies) {
        Write-Host "✅ Attached policies:" -ForegroundColor Green
        Write-Host $attachedPolicies -ForegroundColor Gray
    } else {
        Write-Host "❌ No policies attached" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error checking attached policies: $_" -ForegroundColor Red
}

Write-Host "`n4. Testing role assumption..." -ForegroundColor Yellow
try {
    # Create a test session
    $sessionName = "test-session-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $assumeRole = aws sts assume-role --role-arn "arn:aws:iam::622297126778:role/mirror-deploy-role" --role-session-name $sessionName 2>$null
    
    if ($assumeRole) {
        Write-Host "✅ Role assumption test successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Role assumption test failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error testing role assumption: $_" -ForegroundColor Red
}

Write-Host "`n5. GitHub Variables Check:" -ForegroundColor Yellow
Write-Host "Please verify these variables are set in GitHub:" -ForegroundColor Cyan
Write-Host "  AWS_REGION: ap-south-1" -ForegroundColor Gray
Write-Host "  AWS_ROLE_ARN: arn:aws:iam::622297126778:role/mirror-deploy-role" -ForegroundColor Gray

Write-Host "`n6. GitHub Repository Permissions:" -ForegroundColor Yellow
Write-Host "Go to: Settings → Actions → General" -ForegroundColor Cyan
Write-Host "Set 'Workflow permissions' to 'Read and write permissions'" -ForegroundColor Gray
Write-Host "Enable 'Allow GitHub Actions to create and approve pull requests'" -ForegroundColor Gray

Write-Host "`nVerification complete!" -ForegroundColor Green 