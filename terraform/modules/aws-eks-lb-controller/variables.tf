variable "name" {
  type        = string
  description = "Name to apply to resources"
}

variable "region" {
  type        = string
  description = "AWS region to create resources in"
}

variable "tags" {
  type        = string
  description = "Tags to apply to resources"
}

variable "lb_controller_vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "lb_controller_oidc_id" {
  type        = string
  description = "EKS cluster's OIDC provider ID"
}

variable "lb_controller_oidc_issuer" {
  type        = string
  description = "EKS cluster's OIDC provider URL"
}

variable "lb_controller_policy_file" {
  type        = string
  description = "EKS cluster's OIDC provider URL"
}

variable "eks_addon_repo_number" {
  type        = string
  description = "ID of the EKS add-on repository to use"
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}
