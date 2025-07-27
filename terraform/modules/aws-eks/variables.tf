variable "name" {
  type        = string
  description = "Name to apply to resources"
}

variable "eks_version" {
  type        = string
  description = "Default EKS Kubernetes version to provision"
}

variable "region" {
  type        = string
  description = "AWS region to create this VPC in"
}

variable "authentication_method" {
  type        = string
  description = "EKS authentication method"
}

variable "private_subnets_cidr" {
  type        = list(string)
  description = "List of CIDR for the private subnets"
}

variable "endpoint_private_access" {
  type        = bool
  description = "Whether or not enable private access for the EKS API"
}

variable "endpoint_public_access" {
  type        = bool
  description = "Whether or not enable public access for the EKS API"
}

variable "tags" {
  type        = string
  default     = ""
  description = "Tags to apply to resources"
}
