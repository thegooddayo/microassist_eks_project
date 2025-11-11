provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project = var.project
      Env     = "stage"
    }
  }
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-stage-vpc"
  cidr = "10.1.0.0/16"

  azs              = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets   = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"]
  private_subnets  = ["10.1.100.0/24", "10.1.101.0/24", "10.1.102.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name = "${var.project}-stage-vpc"
    Env  = "stage"
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
      max_size      = 4
      desired_size  = 2
      instance_types = ["t3.medium"]
      capacity_type = "SPOT"
    }
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "${var.project}-stage"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  node_groups = local.node_groups
  addons      = local.addons

  tags = {
    Project = var.project
    Env     = "stage"
  }
}
