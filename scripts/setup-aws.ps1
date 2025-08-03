# Automated AWS Setup Script for Mirror
# This script sets up all AWS resources needed for Mirror deployment

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

# Check if AWS CLI is installed
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "AWS CLI is not installed. Please install AWS CLI v2." -ForegroundColor Red
    Write-Host "Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
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
    aws iam create-open-id-connect-provider --url "https://token.actions.githubusercontent.com" --client-id-list "sts.amazonaws.com" --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" --query "OpenIDConnectProviderArn" --output text
    Write-Host "OIDC provider created" -ForegroundColor Green
} catch {
    Write-Host "OIDC provider may already exist, continuing..." -ForegroundColor Yellow
}

# Create trust policy for GitHub Actions
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

$trustPolicy | Out-File -FilePath "trust-policy.json" -Encoding UTF8

# Create IAM role for GitHub Actions
Write-Host "Creating IAM role for GitHub Actions..." -ForegroundColor Yellow
try {
    aws iam create-role --role-name "mirror-deploy-role" --assume-role-policy-document "trust-policy.json" --description "Role for Mirror GitHub Actions deployment" --query "Role.Arn" --output text
    Write-Host "IAM role created" -ForegroundColor Green
} catch {
    Write-Host "IAM role may already exist, continuing..." -ForegroundColor Yellow
}

# Attach required policies
$policies = @("AmazonS3FullAccess", "CloudFrontFullAccess", "CloudWatchLogsFullAccess", "AWSLambda_FullAccess", "AmazonAPIGatewayAdministrator")

foreach ($policy in $policies) {
    Write-Host "Attaching policy: $policy" -ForegroundColor Yellow
    try {
        aws iam attach-role-policy --role-name "mirror-deploy-role" --policy-arn "arn:aws:iam::aws:policy/$policy"
        Write-Host "$policy attached" -ForegroundColor Green
    } catch {
        Write-Host "$policy may already be attached" -ForegroundColor Yellow
    }
}

# Get the role ARN
$roleArn = "arn:aws:iam::$AWS_ACCOUNT_ID:role/mirror-deploy-role"

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

# Clean up temporary file
if (Test-Path "trust-policy.json") {
    Remove-Item "trust-policy.json" -Force
} 