terraform {
  backend "s3" {
    bucket         = "eks-upgrade-demo-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
