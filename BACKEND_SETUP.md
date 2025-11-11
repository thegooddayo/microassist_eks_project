All environments use the same S3 bucket (`eks-upgrade-demo-terraform-state`) with different keys for each environment. Here's the command to create the S3 bucket:

```bash
aws s3api create-bucket \
  --bucket dayo-eks-upgrade-demo-terraform-state \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket dayo-eks-upgrade-demo-terraform-state \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket dayo-eks-upgrade-demo-terraform-state \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'

aws s3api put-public-access-block \
  --bucket dayo-eks-upgrade-demo-terraform-state \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```
This creates a single S3 bucket that all three environments (dev, stage, prod) will share, with:
- Versioning enabled (for state history)
- Encryption enabled (as configured in your backend)
- Public access blocked (security best practice)

Each environment uses a different key path within the bucket:
- Dev: `dev/terraform.tfstate`
- Stage: `stage/terraform.tfstate`
- Prod: `prod/terraform.tfstate`