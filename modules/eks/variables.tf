variable "cluster_name" { type = string }
variable "cluster_version" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }

# Map of managed node groups, passed through to the upstream module
variable "node_groups" {
  type        = map(any)
  description = "EKS managed node groups configuration"
  default     = {}
}

# Cluster add-ons, passed through to the upstream module
variable "addons" {
  type        = map(any)
  description = "EKS cluster addons configuration"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
