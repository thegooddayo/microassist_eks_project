# CI/CD Setup Guide

This document explains how to set up GitHub Actions CI/CD pipelines for the EKS upgrade demo project.

## Architecture Overview

The project uses **branch-based deployments** with separate pipelines for each environment:

- **`dev` branch** → Dev environment (auto-deploy)
- **`uat` branch** → Stage environment (auto-deploy)
- **`main` branch** → Production environment (manual approval required)

## Prerequisites

### 1. Create S3 Bucket for Terraform State

Create an S3 bucket and DynamoDB table for remote state management:

```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket eks-upgrade-demo-terraform-state \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket eks-upgrade-demo-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket eks-upgrade-demo-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name eks-upgrade-demo-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 2. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |

**⚠️ Security Best Practice:** Use an IAM user with minimal required permissions or use OIDC (OpenID Connect) for GitHub Actions.

### 3. Set Up Production Environment Protection

For manual approval on production deployments:

1. Go to **Settings → Environments**
2. Click **New environment**
3. Name it `production`
4. Enable **Required reviewers**
5. Add team members who can approve production deployments
6. (Optional) Set deployment branch to `main` only

## Workflows

### Dev Environment (`.github/workflows/dev.yml`)

**Trigger:** Push to `dev` branch or PR against `dev`

**Behavior:**
- ✅ Runs `terraform plan` on every push/PR
- ✅ Auto-applies on push to `dev` branch
- ✅ Comments plan results on PRs

**Usage:**
```bash
git checkout dev
# Make changes to envs/dev/
git add .
git commit -m "Update dev EKS to 1.31"
git push origin dev
```

### Stage Environment (`.github/workflows/stage.yml`)

**Trigger:** Push to `uat` branch or PR against `uat`

**Behavior:**
- ✅ Runs `terraform plan` on every push/PR
- ✅ Auto-applies on push to `uat` branch
- ✅ Comments plan results on PRs

**Usage:**
```bash
git checkout uat
# Make changes to envs/stage/
git add .
git commit -m "Upgrade stage to match dev"
git push origin uat
```

### Production Environment (`.github/workflows/prod.yml`)

**Trigger:** Push to `main` branch or PR against `main`

**Behavior:**
- ✅ Runs `terraform plan` on every push/PR
- ⚠️ **Requires manual approval** before apply
- ✅ Uploads plan artifact for review
- ✅ Comments plan results on PRs

**Usage:**
```bash
git checkout main
# Make changes to envs/prod/
git add .
git commit -m "Upgrade prod to 1.29"
git push origin main
# GitHub will run plan, then wait for manual approval
# Go to Actions tab → Click on the workflow → Click "Review deployments" → Approve
```

## Workflow Features

### Common Features (All Environments)

- ✅ **Terraform Format Check** - Validates code formatting
- ✅ **Terraform Validation** - Checks configuration syntax
- ✅ **Terraform Plan** - Shows what will change
- ✅ **PR Comments** - Automatically comments plan output on PRs
- ✅ **Path Filtering** - Only runs when relevant files change

### Production-Specific Features

- 🔒 **Manual Approval** - Requires human approval before apply
- 📦 **Plan Artifacts** - Saves plan for review before apply
- 🔗 **Environment URL** - Direct link to EKS console after deployment

## Branch Strategy

```
main (prod)
  ↑
  | merge after testing
  |
uat (stage)
  ↑
  | merge after testing
  |
dev (development)
  ↑
  | feature branches merge here
  |
feature/* (feature branches)
```

### Recommended Workflow

1. Create feature branch from `dev`
2. Make changes and test locally
3. Create PR to `dev` branch
4. Review Terraform plan in PR comments
5. Merge to `dev` → Auto-deploys to dev environment
6. Test in dev, then create PR from `dev` to `uat`
7. Merge to `uat` → Auto-deploys to stage environment
8. Test in stage, then create PR from `uat` to `main`
9. Merge to `main` → Triggers plan, then manual approval needed
10. Approve → Deploys to production

## Migrating Existing State to S3 Backend

If you already have local state files, migrate them:

```bash
# For each environment
cd envs/dev
terraform init -migrate-state
# Answer "yes" when prompted

cd ../stage
terraform init -migrate-state

cd ../prod
terraform init -migrate-state
```

## Troubleshooting

### Workflow Not Triggering

- Check that your changes are in the correct paths (`envs/dev/**`, `envs/stage/**`, `envs/prod/**`, or `modules/**`)
- Ensure you're pushing to the correct branch

### AWS Credentials Error

- Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set in GitHub Secrets
- Check that the IAM user has sufficient permissions

### State Lock Error

- Ensure DynamoDB table `eks-upgrade-demo-terraform-locks` exists
- Check that the table name matches in all `backend.tf` files

### Production Approval Not Working

- Verify the `production` environment is configured in GitHub Settings → Environments
- Ensure required reviewers are added

## Security Considerations

1. **Never commit state files** - State is stored in S3
2. **Enable MFA for production approvers**
3. **Use least-privilege IAM policies** for GitHub Actions
4. **Rotate AWS credentials regularly**
5. **Enable S3 bucket versioning** for state rollback capability
6. **Use DynamoDB for state locking** to prevent concurrent modifications

## Monitoring

Monitor your pipelines:

1. **GitHub Actions Tab** - View workflow runs
2. **CloudWatch Logs** - View Terraform execution logs (if configured)
3. **S3 Bucket** - Check state file versions
4. **DynamoDB** - Monitor lock status

## Cost Optimization

- GitHub Actions: Free for public repos, ~2000 minutes/month for private repos
- S3: ~$0.023/GB/month
- DynamoDB: Pay-per-request (minimal cost for state locking)
- EKS: Actual infrastructure costs (clusters, nodes, etc.)

## Next Steps

After setup:

1. Create `dev`, `uat`, and `main` branches
2. Push this code to GitHub
3. Test the pipeline with a small change to dev
4. Progressively roll out to stage and prod
