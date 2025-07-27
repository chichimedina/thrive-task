variable "name" {
  type        = string
  description = "Name to apply to resources"
}

variable "region" {
  type        = string
  description = "AWS region to create this VPC in"
}

variable "environment" {
  type        = string
  description = "Environment"
}

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

variable "tags" {
  type        = string
  default     = ""
  description = "Tags to apply to resources"
}

