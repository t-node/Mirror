# Complete AWS Setup Script for Mirror
# This script downloads AWS CLI and sets up all required resources

param(
    [string]$AWS_ACCESS_KEY_ID = $env:AWS_ACCESS_KEY_ID,
    [string]$AWS_SECRET_ACCESS_KEY = $env:AWS_SECRET_ACCESS_KEY,
    [string]$AWS_ACCOUNT_ID = $env:AWS_ACCOUNT_ID,
    [string]$AWS_REGION = "ap-south-1",
    [string]$GITHUB_USERNAME = "t-node"
)

Write-Host "Setting up AWS infrastructure for Mirror..." -ForegroundColor Green
Write-Host "Account ID: $AWS_ACCOUNT_ID" -ForegroundColor Yellow
Write-Host "Region: $AWS_REGION" -ForegroundColor Yellow
Write-Host "GitHub Username: $GITHUB_USERNAME" -ForegroundColor Yellow
Write-Host ""

# Set AWS credentials
$env:AWS_ACCESS_KEY_ID = $AWS_ACCESS_KEY_ID
$env:AWS_SECRET_ACCESS_KEY = $AWS_SECRET_ACCESS_KEY
$env:AWS_DEFAULT_REGION = $AWS_REGION

# Function to download and install AWS CLI
function Install-AWSCLI {
    Write-Host "Installing AWS CLI..." -ForegroundColor Yellow
    
    # Create temp directory
    $tempDir = "$env:TEMP\aws-cli-setup"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Download AWS CLI installer
    $installerUrl = "https://awscli.amazonaws.com/AWSCLIV2.msi"
    $installerPath = "$tempDir\AWSCLIV2.msi"
    
    Write-Host "Downloading AWS CLI installer..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
        Write-Host "Download completed" -ForegroundColor Green
    } catch {
        Write-Host "Failed to download AWS CLI: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    
    # Install AWS CLI silently
    Write-Host "Installing AWS CLI..." -ForegroundColor Yellow
    try {
        Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait
        Write-Host "AWS CLI installation completed" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install AWS CLI: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    
    # Clean up
    Remove-Item $tempDir -Recurse -Force
    
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
}

# Check if AWS CLI is installed
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "AWS CLI not found. Installing..." -ForegroundColor Yellow
    Install-AWSCLI
    
    # Check again after installation
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Host "AWS CLI installation failed. Please install manually from https://aws.amazon.com/cli/" -ForegroundColor Red
        exit 1
    }
}

Write-Host "AWS CLI found: $(aws --version)" -ForegroundColor Green

# Test AWS credentials
Write-Host "Testing AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --query "Account" --output text
    if ($identity -eq $AWS_ACCOUNT_ID) {
        Write-Host "AWS credentials are valid" -ForegroundColor Green
    } else {
        Write-Host "AWS credentials don't match expected account" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "AWS credentials are invalid: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create OIDC provider for GitHub
Write-Host "Creating OIDC provider for GitHub..." -ForegroundColor Yellow
try {
    $oidcResult = aws iam create-open-id-connect-provider `
        --url "https://token.actions.githubusercontent.com" `
        --client-id-list "sts.amazonaws.com" `
        --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" `
        --query "OpenIDConnectProviderArn" `
        --output text 2>$null
    
    if ($oidcResult) {
        Write-Host "OIDC provider created: $oidcResult" -ForegroundColor Green
    } else {
        Write-Host "OIDC provider may already exist" -ForegroundColor Yellow
    }
} catch {
    Write-Host "OIDC provider may already exist, continuing..." -ForegroundColor Yellow
}

# Create trust policy JSON
$trustPolicy = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:$GITHUB_USERNAME/mirror:*"
                }
            }
        }
    ]
}
"@

# Save trust policy to file
$trustPolicy | Out-File -FilePath "trust-policy.json" -Encoding UTF8

# Create IAM role for GitHub Actions
Write-Host "Creating IAM role for GitHub Actions..." -ForegroundColor Yellow
try {
    $roleResult = aws iam create-role `
        --role-name "mirror-deploy-role" `
        --assume-role-policy-document "trust-policy.json" `
        --description "Role for Mirror GitHub Actions deployment" `
        --query "Role.Arn" `
        --output text 2>$null
    
    if ($roleResult) {
        Write-Host "IAM role created: $roleResult" -ForegroundColor Green
    } else {
        Write-Host "IAM role may already exist" -ForegroundColor Yellow
    }
} catch {
    Write-Host "IAM role may already exist, continuing..." -ForegroundColor Yellow
}

# Attach required policies
$policies = @(
    "AmazonS3FullAccess",
    "CloudFrontFullAccess", 
    "CloudWatchLogsFullAccess",
    "AWSLambda_FullAccess",
    "AmazonAPIGatewayAdministrator"
)

Write-Host "Attaching policies to IAM role..." -ForegroundColor Yellow
foreach ($policy in $policies) {
    try {
        aws iam attach-role-policy `
            --role-name "mirror-deploy-role" `
            --policy-arn "arn:aws:iam::aws:policy/$policy" 2>$null
        Write-Host "  $policy attached" -ForegroundColor Green
    } catch {
        Write-Host "  $policy may already be attached" -ForegroundColor Yellow
    }
}

# Get the role ARN
$roleArn = "arn:aws:iam::$AWS_ACCOUNT_ID:role/mirror-deploy-role"

# Clean up temporary file
if (Test-Path "trust-policy.json") {
    Remove-Item "trust-policy.json" -Force
}

Write-Host ""
Write-Host "AWS setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Create GitHub repository: mirror" -ForegroundColor White
Write-Host "2. Add these variables to GitHub repository:" -ForegroundColor White
Write-Host "   - AWS_REGION: $AWS_REGION" -ForegroundColor Yellow
Write-Host "   - AWS_ROLE_ARN: $roleArn" -ForegroundColor Yellow
Write-Host "3. Push your code to GitHub" -ForegroundColor White
Write-Host "4. Run the 'Deploy Infrastructure' workflow" -ForegroundColor White
Write-Host ""
Write-Host "Role ARN for GitHub: $roleArn" -ForegroundColor Cyan
Write-Host ""
Write-Host "All AWS resources have been created automatically!" -ForegroundColor Green 