# Terraform AWS EKS Multi-Environment Upgrade Demo

This project provisions Amazon EKS clusters for dev, stage, and prod using Terraform. It is structured modularly and is designed to demonstrate safe upgrades of:
- The EKS cluster version (e.g., 1.28 -> 1.29 -> 1.30)
- Core EKS add-ons (coredns, kube-proxy, vpc-cni)

The module wraps the official `terraform-aws-modules/eks/aws` and exposes `cluster_version`, `node_groups`, and `addons` so you can demo upgrades simply by changing inputs and running `terraform plan`/`apply`.

## Layout

- `modules/eks/` – Thin wrapper around the official EKS module with a stable input surface
- `envs/dev` – Dev environment (own VPC + EKS)
- `envs/stage` – Stage environment
- `envs/prod` – Prod environment

## Prerequisites

- Terraform >= 1.6
- AWS CLI configured (or environment variables) with credentials and default region

## Quickstart

Dev:

```bash
cd envs/dev
terraform init
terraform apply
```

Stage:

```bash
cd ../stage
terraform init
terraform apply
```

Prod:

```bash
cd ../prod
terraform init
terraform apply
```

## Demonstrating an Upgrade

1) Cluster version upgrade:
   - In `envs/<env>/main.tf`, edit the `cluster_version` value (e.g., from `"1.29"` to `"1.30"`).
   - Run `terraform plan` to preview changes, then `terraform apply`.

2) Add-on upgrade:
   - In `envs/<env>/main.tf`, update the `addons` map.
     - For deterministic demos, pin a specific version, e.g. `coredns = { version = "v1.x.y-eksbuild.z" }`.
     - Or set `most_recent = true` to always adopt the latest compatible version.
   - Run `terraform plan` then `terraform apply`.

Notes:
- The VPC is created per environment for isolation.
- The `.terraform.lock.hcl` file should be committed once created by `terraform init`.