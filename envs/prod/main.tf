provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project = var.project
      Env     = "prod"
    }
  }
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-prod-vpc"
  cidr = "10.2.0.0/16"

  azs              = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets   = ["10.2.0.0/24", "10.2.1.0/24", "10.2.2.0/24"]
  private_subnets  = ["10.2.100.0/24", "10.2.101.0/24", "10.2.102.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name = "${var.project}-prod-vpc"
    Env  = "prod"
  }
}

locals {
  addons = {
    coredns   = { most_recent = true, use_lockfile = false }
    kube-proxy = { most_recent = true, use_lockfile = false }
    vpc-cni   = { most_recent = true, use_lockfile = false }
  }

  node_groups = {
    default = {
      min_size      = 2
      max_size      = 6
      desired_size  = 3
      instance_types = ["t3.large"]
      capacity_type = "ON_DEMAND"
    }
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "${var.project}-prod"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  node_groups = local.node_groups
  addons      = local.addons

  tags = {
    Project = var.project
    Env     = "prod"
  }
}
