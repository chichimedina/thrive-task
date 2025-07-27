locals {

  tags = jsondecode(var.tags)

}


## ----------------------------
## AWS VPC

## `aws-vpc` module call to create network resources for Thrive's EKS cluster (private and public subnets, Internet gateway, NAT getway, S3 gateway endpoint)
module "eks_network" {

  source = "./modules/aws-vpc"

  name                 = "${var.name}-eks-network"
  region               = var.region
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  availability_zones   = var.availability_zones
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags                 = var.tags

}


## Let's query AWS to get the IDs of the newly created VPC `private` subnets
data "aws_subnets" "eks_subnets" {
  filter {
    name = "cidr-block"
    values = var.private_subnets_cidr
  }

  depends_on = [module.eks_network]
}



## ----------------------------
## AWS EKS

## `aws-eks` module call to create the actual EKS cluster
module "eks_cluster" {

   source = "./modules/aws-eks"

   name                    = "${var.name}-eks-cluster"
   region                  = var.region
   eks_version             = var.eks_version
   authentication_method   = var.authentication_method
   private_subnets_cidr    = data.aws_subnets.eks_subnets.ids
   endpoint_private_access = var.endpoint_private_access
   endpoint_public_access  = var.endpoint_public_access
   tags                    = var.tags

}



## ---------------------------
## AWS EKS ADD-ONS

## Here we install some EKS add-on specified on the `var.eks_addon_to_install` variable
resource "aws_eks_addon" "addons" {
  for_each     = { for addon in var.eks_addon_to_install : addon.name => addon }
  cluster_name = module.eks_cluster.eks_id
  addon_name   = each.value.name
  resolve_conflicts_on_create = "OVERWRITE"
}


## ---------------------------


data "aws_iam_user" "aws_user" {
  user_name = var.aws_user
}

resource "aws_eks_access_entry" "aws_user" {
  cluster_name  = module.eks_cluster.eks_name
  principal_arn = data.aws_iam_user.aws_user.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "aws_user_admin_policy" {
  cluster_name  = module.eks_cluster.eks_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = aws_eks_access_entry.aws_user.principal_arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "aws_user_cluster_admin_policy" {
  cluster_name  = module.eks_cluster.eks_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.aws_user.principal_arn

  access_scope {
    type = "cluster"
  }
}



## ----------------------------
## AWS Load Balancer Controller

module "eks_lb_controller" {

   source = "./modules/aws-eks-lb-controller"

   name                        = "${var.name}-eks-lb"
   region                      = var.region
   eks_cluster_name            = module.eks_cluster.eks_name
   lb_controller_vpc_id        = module.eks_network.vpc_id
   lb_controller_oidc_id       = module.eks_cluster.eks_oidc_id
   lb_controller_oidc_issuer   = module.eks_cluster.eks_oidc_issuer
   lb_controller_policy_file   = "${path.module}/${var.lb_controller_policy_file}"
   eks_addon_repo_number       = var.eks_addon_repo_number
   tags                        = var.tags 

}
