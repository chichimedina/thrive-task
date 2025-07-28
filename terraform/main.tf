locals {

  amazon_cloudwatch_observability_config = file("${path.module}/configs/amazon-cloudwatch-observability.json")

  tags = jsondecode(var.tags)

}

data "aws_caller_identity" "current" {}

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





## ---------------------------
## AWS Cloudwatch Observability Add-On

resource "aws_eks_addon" "amazon_cloudwatch_observability" {

  cluster_name  = module.eks_cluster.eks_name
  addon_name    = "amazon-cloudwatch-observability"

  configuration_values = local.amazon_cloudwatch_observability_config

}

resource "aws_cloudwatch_metric_alarm" "eks_apiserver_storage_size_bytes" {
  alarm_name = "${module.eks_cluster.eks_name}-apiserver-storage-size-bytes"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = "300"
  evaluation_periods  = "5"
  threshold           = "6000000000" # 6Gb (max is 8Gb)

  alarm_description = "Detecting high ETCD storage usage when 75%+ is being used in ${module.eks_cluster.eks_name} EKS cluster."
  alarm_actions     = [aws_sns_topic.eks_alerts.arn]

  statistic   = "Maximum"
  namespace   = "ContainerInsights"
  metric_name = "apiserver_storage_size_bytes"

  dimensions = {
    ClusterName = module.eks_cluster.eks_name
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_apiserver_storage_objects" {
  alarm_name = "${module.eks_cluster.eks_name}-apiserver-storage-objects"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = "300"
  evaluation_periods  = "5"
  threshold           = "100000"

  alarm_description = "Detecting 100k+ ETCD storage objects in ${module.eks_cluster.eks_name} EKS cluster."
  alarm_actions     = [aws_sns_topic.eks_alerts.arn]

  statistic   = "Maximum"
  namespace   = "ContainerInsights"
  metric_name = "apiserver_storage_objects"

  dimensions = {
    ClusterName = module.eks_cluster.eks_name
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_apiserver_request_duration_seconds" {
  alarm_name = "${module.eks_cluster.eks_name}-apiserver-request-duration-seconds"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = "300"
  evaluation_periods  = "5"
  threshold           = "1"

  alarm_description = "API server request duration exceeds 1 second in ${module.eks_cluster.eks_name} EKS cluster."
  alarm_actions     = [aws_sns_topic.eks_alerts.arn]

  statistic   = "Average"
  namespace   = "ContainerInsights"
  metric_name = "apiserver_request_duration_seconds"

  dimensions = {
    ClusterName = module.eks_cluster.eks_name
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_rest_client_request_duration_seconds" {
  alarm_name = "${module.eks_cluster.eks_name}-rest-client-request-duration-seconds"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = "300"
  evaluation_periods  = "5"
  threshold           = "1"

  alarm_description = "REST client request duration exceeds 1 second in ${module.eks_cluster.eks_name} EKS cluster."
  alarm_actions     = [aws_sns_topic.eks_alerts.arn]

  statistic   = "Average"
  namespace   = "ContainerInsights"
  metric_name = "rest_client_request_duration_seconds"

  dimensions = {
    ClusterName = module.eks_cluster.eks_name
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_etcd_request_duration_seconds" {
  alarm_name = "${module.eks_cluster.eks_name}-etcd-request-duration-seconds"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = "300"
  evaluation_periods  = "5"
  threshold           = "1"

  alarm_description = "ETCD request duration exceeds 1 second in ${module.eks_cluster.eks_name} EKS cluster."
  alarm_actions     = [aws_sns_topic.eks_alerts.arn]

  statistic   = "Average"
  namespace   = "ContainerInsights"
  metric_name = "etcd_request_duration_seconds"

  dimensions = {
    ClusterName = module.eks_cluster.eks_name
  }
}

resource "aws_sns_topic" "eks_alerts" {
  name = "${module.eks_cluster.eks_name}-alerts"
}

resource "aws_sns_topic_subscription" "email_eks_alerts" {
  topic_arn = aws_sns_topic.eks_alerts.arn
  protocol  = "email"
  endpoint  = "alejandro.medina@gmail.com"
}

resource "aws_cloudwatch_dashboard" "eks_overview_dashboard" {
  dashboard_name = "${module.eks_cluster.eks_name}-dashboard"
  dashboard_body = file("${path.module}/configs/amazon-cloudwatch-widgets.json")
}

resource "aws_iam_role" "eks_cloudwatch_addon" {
  name = "${var.name}-cloudwatch-addon-role"
  assume_role_policy = jsonencode({
   "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowEksAuthToAssumeRoleForPodIdentity",
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
  })  

  tags = local.tags

}

resource "aws_iam_role_policy_attachment" "eks_cloudwatch_addon_CloudWatchAgentServerPolicy" {
   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
   role = aws_iam_role.eks_cloudwatch_addon.name
}

resource "kubernetes_service_account" "els_cloudwatch_addon_sa" {
  metadata {
    name      = "aws-cloudwatch-addon"
    namespace = "amazon-cloudwatch"
    labels = { 
      "app.kubernetes.io/name"      = "aws-cloudwatch-addon"
      "app.kubernetes.io/component" = "controller"
    }   
    annotations = { 
      "eks.amazonaws.com/role-arn"               = aws_iam_role.eks_cloudwatch_addon.arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }   
  }
}

resource "aws_eks_pod_identity_association" "eks_cloudwatch_addon_association" {
  cluster_name    = module.eks_cluster.eks_name
  namespace       = "amazon-cloudwatch"
  service_account = "aws-cloudwatch-addon"
  role_arn        = aws_iam_role.eks_cloudwatch_addon.arn
}
