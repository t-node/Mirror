# Mirror AWS Deployment Script
# This script helps deploy the Mirror application to AWS

param(
    [string]$Action = "deploy",
    [string]$AWSRegion = "ap-south-1",
    [string]$Environment = "dev"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "Mirror AWS Deployment Script" -ForegroundColor Green
Write-Host "Action: $Action" -ForegroundColor Yellow
Write-Host "Region: $AWSRegion" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host ""

# Check if AWS CLI is installed
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "❌ AWS CLI is not installed. Please install AWS CLI v2." -ForegroundColor Red
    Write-Host "Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check if Node.js is installed
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js is not installed. Please install Node.js 20 or later." -ForegroundColor Red
    exit 1
}

# Check Node.js version
$nodeVersion = node -v
$nodeMajorVersion = $nodeVersion.Split('.')[0].TrimStart('v')
if ([int]$nodeMajorVersion -lt 20) {
    Write-Host "❌ Node.js version 20 or later is required. Current version: $nodeVersion" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Node.js version: $nodeVersion" -ForegroundColor Green
Write-Host "✅ AWS CLI version: $(aws --version)" -ForegroundColor Green

# Check if AWS credentials are configured
try {
    $awsIdentity = aws sts get-caller-identity 2>$null
    if (-not $awsIdentity) {
        Write-Host "❌ AWS credentials not configured. Please run 'aws configure' first." -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ AWS credentials configured" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS credentials not configured. Please run 'aws configure' first." -ForegroundColor Red
    exit 1
}

# Function to build frontend
function Build-Frontend {
    Write-Host "Building frontend..." -ForegroundColor Cyan
    Set-Location frontend
    
    # Install dependencies
    Write-Host "Installing frontend dependencies..." -ForegroundColor Yellow
    npm ci
    
    # Create .env file with API URL placeholder
    if (-not (Test-Path .env)) {
        Write-Host "Creating .env file..." -ForegroundColor Yellow
        "VITE_API_BASE_URL=https://your-api-gateway-url.execute-api.$AWSRegion.amazonaws.com" | Out-File -FilePath .env -Encoding UTF8
    }
    
    # Build the application
    Write-Host "Building React application..." -ForegroundColor Yellow
    npm run build
    
    Set-Location ..
    Write-Host "✅ Frontend built successfully" -ForegroundColor Green
}

# Function to build backend
function Build-Backend {
    Write-Host "Building backend..." -ForegroundColor Cyan
    Set-Location backend
    
    # Install dependencies
    Write-Host "Installing backend dependencies..." -ForegroundColor Yellow
    npm ci
    
    # Build TypeScript
    Write-Host "Building TypeScript..." -ForegroundColor Yellow
    npm run build
    
    # Create ZIP file
    Write-Host "Creating Lambda deployment package..." -ForegroundColor Yellow
    if (Test-Path function.zip) {
        Remove-Item function.zip -Force
    }
    
    # Use PowerShell Compress-Archive (built into PowerShell 5.0+)
    try {
        Compress-Archive -Path "dist\*" -DestinationPath "function.zip" -Force
        Write-Host "Lambda package created using PowerShell Compress-Archive" -ForegroundColor Green
    } catch {
        Write-Host "PowerShell Compress-Archive failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please manually create function.zip from the dist/ directory using Windows Explorer" -ForegroundColor Yellow
    }
    
    Set-Location ..
    Write-Host "✅ Backend built successfully" -ForegroundColor Green
}

# Function to deploy infrastructure
function Deploy-Infrastructure {
    Write-Host "Deploying infrastructure with Terraform..." -ForegroundColor Cyan
    Set-Location infra
    
    # Check if Terraform is installed
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Terraform is not installed. Please install Terraform." -ForegroundColor Red
        Write-Host "Download from: https://www.terraform.io/downloads.html" -ForegroundColor Yellow
        Set-Location ..
        exit 1
    }
    
    Write-Host "✅ Terraform version: $(terraform version)" -ForegroundColor Green
    
    # Initialize Terraform
    Write-Host "Initializing Terraform..." -ForegroundColor Yellow
    terraform init
    
    # Validate configuration
    Write-Host "Validating Terraform configuration..." -ForegroundColor Yellow
    terraform validate
    
    # Plan deployment
    Write-Host "Planning Terraform deployment..." -ForegroundColor Yellow
    terraform plan -out=tfplan
    
    # Apply deployment
    Write-Host "Applying Terraform configuration..." -ForegroundColor Yellow
    terraform apply tfplan
    
    # Get outputs
    Write-Host "Getting Terraform outputs..." -ForegroundColor Yellow
    $outputs = terraform output -json | ConvertFrom-Json
    
    # Save outputs to file for other scripts
    terraform output -json | Out-File -FilePath terraform_outputs.json -Encoding UTF8
    
    Set-Location ..
    Write-Host "✅ Infrastructure deployed successfully" -ForegroundColor Green
    return $outputs
}

# Function to deploy application
function Deploy-Application {
    param($TerraformOutputs)
    
    Write-Host "Deploying application..." -ForegroundColor Cyan
    
    # Extract values from Terraform outputs
    $cloudfrontUrl = $TerraformOutputs.cloudfront_url.value
    $apiBaseUrl = $TerraformOutputs.api_base_url.value
    $frontendBucket = $TerraformOutputs.frontend_bucket_name.value
    $lambdaFunctionName = $TerraformOutputs.lambda_function_name.value
    $cloudfrontDistributionId = $TerraformOutputs.cloudfront_distribution_id.value
    
    Write-Host "CloudFront URL: $cloudfrontUrl" -ForegroundColor Yellow
    Write-Host "API Base URL: $apiBaseUrl" -ForegroundColor Yellow
    Write-Host "Frontend Bucket: $frontendBucket" -ForegroundColor Yellow
    Write-Host "Lambda Function: $lambdaFunctionName" -ForegroundColor Yellow
    
    # Update frontend .env with actual API URL
    Write-Host "Updating frontend environment..." -ForegroundColor Yellow
    Set-Location frontend
    "VITE_API_BASE_URL=$apiBaseUrl" | Out-File -FilePath .env -Encoding UTF8
    
    # Rebuild frontend with correct API URL
    Write-Host "Rebuilding frontend with correct API URL..." -ForegroundColor Yellow
    npm run build
    Set-Location ..
    
    # Deploy frontend to S3
    Write-Host "Deploying frontend to S3..." -ForegroundColor Yellow
    aws s3 sync frontend/dist/ s3://$frontendBucket --delete
    
    # Invalidate CloudFront cache
    Write-Host "Invalidating CloudFront cache..." -ForegroundColor Yellow
    aws cloudfront create-invalidation --distribution-id $cloudfrontDistributionId --paths "/*"
    
    # Deploy backend to Lambda
    Write-Host "Deploying backend to Lambda..." -ForegroundColor Yellow
    aws lambda update-function-code --function-name $lambdaFunctionName --zip-file fileb://backend/function.zip
    
    Set-Location ..
    Write-Host "✅ Application deployed successfully" -ForegroundColor Green
    
    # Display final URLs
    Write-Host ""
    Write-Host "Deployment Complete!" -ForegroundColor Green
    Write-Host "Frontend URL: $cloudfrontUrl" -ForegroundColor Cyan
    Write-Host "API URL: $apiBaseUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Test your deployment:" -ForegroundColor Yellow
    Write-Host "1. Open $cloudfrontUrl in your browser" -ForegroundColor White
    Write-Host "2. Click the 'Ping API' button" -ForegroundColor White
    Write-Host "3. Check CloudWatch logs for verification" -ForegroundColor White
}

# Function to destroy infrastructure
function Destroy-Infrastructure {
    Write-Host "Destroying infrastructure..." -ForegroundColor Red
    Set-Location infra
    
    Write-Host "WARNING: This will permanently delete all resources!" -ForegroundColor Red
    $confirmation = Read-Host "Are you sure you want to continue? (yes/no)"
    
    if ($confirmation -eq "yes") {
        Write-Host "Destroying Terraform resources..." -ForegroundColor Yellow
        terraform destroy -auto-approve
        Write-Host "✅ Infrastructure destroyed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Destruction cancelled" -ForegroundColor Yellow
    }
    
    Set-Location ..
}

# Main execution logic
try {
    switch ($Action.ToLower()) {
        "deploy" {
            Build-Frontend
            Build-Backend
            $outputs = Deploy-Infrastructure
            Deploy-Application -TerraformOutputs $outputs
        }
        "infra" {
            Deploy-Infrastructure
        }
        "app" {
            # Load outputs from file
            if (Test-Path "infra/terraform_outputs.json") {
                $outputs = Get-Content "infra/terraform_outputs.json" | ConvertFrom-Json
                Build-Frontend
                Build-Backend
                Deploy-Application -TerraformOutputs $outputs
            } else {
                Write-Host "❌ Terraform outputs not found. Run 'infra' action first." -ForegroundColor Red
                exit 1
            }
        }
        "destroy" {
            Destroy-Infrastructure
        }
        "build" {
            Build-Frontend
            Build-Backend
        }
        default {
            Write-Host "❌ Invalid action: $Action" -ForegroundColor Red
            Write-Host "Valid actions: deploy, infra, app, destroy, build" -ForegroundColor Yellow
            exit 1
        }
    }
} catch {
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green 