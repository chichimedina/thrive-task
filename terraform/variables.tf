variable "name" {
  type        = string
  default     = "thrive"
  description = "Name to apply to resources"
}

variable "region" {
  type        = string
  default     = "us-east-2"
  description = "AWS region to create this VPC in"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "tags" {
  type        = string
  default     = ""
  description = "Tags to apply to resources"
}


##   --------------------
##   VPC Settings

variable "vpc_cidr" {
  type        = string
  description = "CIDR to use for this VPC"
}

variable "public_subnets_cidr" {
  type        = list(string)
  description = "List of CIDR for the public subnets"
}

variable "private_subnets_cidr" {
  type        = list(string)
  description = "List of CIDR for the private subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones to host the public and private sunets"
}

variable "enable_dns_hostnames" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable DNS hostnames in the VPC"
}

variable "enable_dns_support" {
  type        = bool
  default     = true
  description = "Whether or not the VPC has DNS support (true|false)"
}


##   --------------------
##   EKS Settings

variable "eks_version" {
  type        = string
  default     = "1.32"
  description = "Default EKS Kubernetes version to provision"
}

variable "authentication_method" {
  type        = string
  default     = "API_AND_CONFIG_MAP"
  description = "EKS authentication method"
}

variable "endpoint_private_access" {
  type        = bool
  default     = false
  description = "Whether or not enable private access for the EKS API"
}

variable "endpoint_public_access" {
  type        = bool
  default     = true
  description = "Whether or not enable public access for the EKS API"
}


##   --------------------
##   EKS Add-on Settings

variable "eks_addon_repo_number" {
  type        = number
  default     = "602401143452"
  description = "Identifier region-specific number of the EKS add-on repository"
}

variable "eks_addon_to_install" {
  type = list(object({
    name    = string
  }))

  default = [
    {
      name    = "kube-proxy"
    },
    {
      name    = "vpc-cni"
    }
  ]
}


##   --------------------
##   EKS Add-on Settings

variable "lb_controller_vpc_id" {
  type        = string
  default     = ""
  description = "ID of the VPC"
}

variable "lb_controller_oidc_id" {
  type        = string
  default     = ""
  description = "EKS cluster's OIDC provider ID" 
}

variable "lb_controller_oidc_issuer" {
  type        = string
  default     = ""
  description = "EKS cluster's OIDC provider URL"
}

variable "lb_controller_policy_file" {
  type        = string
  default     = "configs/aws-lb-controller-iam-policy.json"
  description = "EKS cluster's OIDC provider URL"
}

variable "eks_cluster_name" {
  type        = string
  default     = ""
  description = "Name of the EKS cluster"
}


##   --------------------
##   AWS IAM user to grant access to the EKS cluster 

variable "aws_user" {
  type        = string
  description = "Default AWS user to provision these EKS resources as"
}
