# Mirror Deployment Guide

This guide walks you through deploying the Mirror application to AWS using GitHub Actions and Terraform.

## Prerequisites

### 1. AWS Account Setup
- AWS account with region set to `ap-south-1` (Mumbai)
- IAM permissions to create the required resources

### 2. AWS IAM Setup (One-time)

#### Create OIDC Provider for GitHub
1. Go to **IAM → Identity providers**
2. Click **Create provider**
3. Provider type: **OpenID Connect**
4. Provider URL: `https://token.actions.githubusercontent.com`
5. Audience: `sts.amazonaws.com`
6. Click **Create provider**

#### Create IAM Role for GitHub Actions
1. Go to **IAM → Roles**
2. Click **Create role**
3. Trusted entity: **Web identity**
4. Identity provider: Select the GitHub OIDC provider you created
5. Audience: `sts.amazonaws.com`
6. GitHub organization: Your GitHub org name
7. Repository: `mirror` (or your repo name)
8. Branch: `main`
9. Click **Next**

#### Attach Required Policies
Attach these policies to the role:
- `AmazonS3FullAccess`
- `CloudFrontFullAccess`
- `CloudWatchLogsFullAccess`
- `AWSLambda_FullAccess`
- `AmazonAPIGatewayAdministrator`

**Note**: These are broad policies for Story #1. We'll tighten them in Story #2.

### 3. GitHub Repository Setup

#### Add Repository Variables
1. Go to your GitHub repository
2. **Settings → Secrets and variables → Actions**
3. Click **Variables** tab
4. Add these variables:
   - `AWS_REGION`: `ap-south-1`
   - `AWS_ROLE_ARN`: `arn:aws:iam::<YOUR-ACCOUNT-ID>:role/<ROLE-NAME>`

## Deployment Steps

### Step 1: Deploy Infrastructure

1. Go to **Actions → Deploy Infrastructure**
2. Click **Run workflow**
3. Select action: **apply**
4. Click **Run workflow**
5. Wait for the workflow to complete (5-10 minutes)

**What this creates:**
- S3 bucket for frontend hosting
- CloudFront distribution
- API Gateway HTTP API
- Lambda function (empty initially)
- CloudWatch log groups
- IAM roles and policies

### Step 2: Deploy Application

1. Push your code to the `main` branch
2. The **Deploy Application** workflow will automatically trigger
3. Or manually trigger it from **Actions → Deploy Application**

**What this does:**
- Builds the React frontend
- Builds and packages the Lambda function
- Deploys frontend to S3
- Updates Lambda function code
- Invalidates CloudFront cache

## Verification

### 1. Check Frontend
- Open the CloudFront URL from the workflow outputs
- You should see "Mirror v0.0 — Upload coming soon"
- Click **Ping API** button
- Should see green "API Healthy" response with request ID

### 2. Check Backend
- Test the API directly: `curl https://<api-gateway-url>/health`
- Should return JSON with status, service, region, and requestId

### 3. Check Logs
- **Lambda logs**: CloudWatch → Log groups → `/aws/lambda/mirror-<id>-api`
- **API Gateway logs**: CloudWatch → Log groups → `/aws/apigateway/mirror-<id>-api`

## Troubleshooting

### Common Issues

#### 1. OIDC Authentication Fails
- Verify the IAM role ARN in GitHub variables
- Check that the OIDC provider is correctly configured
- Ensure the repository name matches the trust policy

#### 2. Terraform Apply Fails
- Check AWS region is set to `ap-south-1`
- Verify IAM permissions are sufficient
- Check for resource naming conflicts

#### 3. Frontend Build Fails
- Ensure Node.js 20 is available
- Check that all frontend dependencies are installed
- Verify the API base URL is correctly set

#### 4. Lambda Deployment Fails
- Check that the backend code builds successfully
- Verify the Lambda function name matches Terraform output
- Ensure the ZIP file is created correctly

### Debugging Commands

#### Check Terraform State
```bash
cd infra
terraform init
terraform plan
terraform output
```

#### Test Lambda Locally
```bash
cd backend
npm run build
# Test the handler function
```

#### Check CloudFront Distribution
```bash
aws cloudfront get-distribution --id <distribution-id>
```

## Cleanup

To destroy all resources:
1. Go to **Actions → Deploy Infrastructure**
2. Click **Run workflow**
3. Select action: **destroy**
4. Click **Run workflow**

**Warning**: This will permanently delete all resources and data.

## Cost Estimation

For low traffic (< 1000 requests/day):
- S3: ~$0.02/month
- CloudFront: ~$0.10/month
- API Gateway: ~$1.00/month
- Lambda: ~$0.01/month
- CloudWatch: ~$0.50/month

**Total**: ~$1.63/month

## Next Steps

After successful deployment, you can proceed to:
- **Story #2**: Harden IAM policies and add remote state
- **Story #3**: Add authentication with Cognito
- **Story #4**: Implement file upload functionality 