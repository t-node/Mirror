# Mirror v0.0 — Upload coming soon

A secure, scalable platform for medical audio transcription and analysis.

## Region
- **AWS Region**: ap-south-1 (Mumbai)
- **Infrastructure**: CloudFront + S3 (frontend), API Gateway + Lambda (backend)

## Quick Start

### Prerequisites
1. AWS account with region set to `ap-south-1`
2. GitHub repository with OIDC setup (see below)
3. IAM role `mirror-deploy-role` with required permissions

### AWS Setup (One-time)
1. Create IAM OIDC provider for GitHub (`token.actions.githubusercontent.com`)
2. Create IAM role `mirror-deploy-role` with trust policy for your GitHub org/repo
3. Attach policies: `AmazonS3FullAccess`, `CloudFrontFullAccess`, `CloudWatchLogsFullAccess`, `AWSLambda_FullAccess`, `AmazonAPIGatewayAdministrator`

### GitHub Setup
Add these variables in **Settings → Actions → Variables**:
- `AWS_REGION=ap-south-1`
- `AWS_ROLE_ARN=arn:aws:iam::<account-id>:role/mirror-deploy-role`

## Deployment

### 1. Deploy Infrastructure
1. Go to **Actions → infra.yaml**
2. Click **Run workflow** → **Run workflow**
3. Wait for Terraform to create all resources

### 2. Deploy Application
1. Push to `main` branch
2. GitHub Actions will automatically build and deploy frontend + backend
3. Or manually trigger **Actions → app.yaml**

## Access Your Application

After deployment, find your URLs in:
- **GitHub Actions → infra.yaml → Run details** (terraform outputs)
- **AWS Console → CloudFront → Distributions**
- **AWS Console → API Gateway → HTTP APIs**

## Monitoring & Logs

### Lambda Logs
- **AWS Console → CloudWatch → Log groups → /aws/lambda/mirror-api-<id>**
- Contains request processing logs with request IDs

### API Gateway Logs
- **AWS Console → CloudWatch → Log groups → API Gateway access logs**
- Contains HTTP request/response logs

### Frontend Logs
- Check browser developer tools for API calls
- CloudFront access logs (if enabled)

## Project Structure

```
mirror/
├── frontend/           # React (Vite) application
├── backend/            # Node.js Lambda function
├── infra/              # Terraform infrastructure
│   └── modules/
│       ├── frontend/   # S3 + CloudFront
│       └── backend/    # API Gateway + Lambda
└── .github/workflows/  # CI/CD pipelines
```

## Development

### Frontend
```bash
cd frontend
npm install
npm run dev
```

### Backend
```bash
cd backend
npm install
npm run build
```

### Infrastructure
```bash
cd infra
terraform init
terraform plan
terraform apply
```

## Cost Optimization
- Uses S3/CloudFront + API Gateway + Lambda + CloudWatch only
- No custom domains, Secrets Manager, or databases in this story
- Estimated cost: <$5/month for low traffic 