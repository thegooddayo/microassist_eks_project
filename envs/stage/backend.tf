terraform {
  backend "s3" {
    bucket         = "dayo-eks-upgrade-demo-terraform-state"
    key            = "stage/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
