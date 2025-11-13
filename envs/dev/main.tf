provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project = var.project
      Env     = "dev"
    }
  }
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-dev-vpc"
  cidr = "10.0.0.0/16"

  azs                = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.100.0/24", "10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name = "${var.project}-dev-vpc"
    Env  = "dev"
  }
}

locals {
  addons = {
    coredns    = { most_recent = true, use_lockfile = false }
    kube-proxy = { most_recent = true, use_lockfile = false }
    vpc-cni    = { most_recent = true, use_lockfile = false }
  }

  node_groups = {
    default = {
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "${var.project}-dev"
  cluster_version = "1.32"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  node_groups = local.node_groups
  addons      = local.addons

  tags = {
    Project = var.project
    Env     = "dev"
  }
}
