locals {

  tags = jsondecode(var.tags)

}


resource "aws_iam_openid_connect_provider" "lb_controller_oidc_issuer" {
  url = var.lb_controller_oidc_issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

}

resource "aws_iam_policy" "lb_controller_iam_policy" {
  name        = "${var.name}-lb-controller-policy"
  path        = "/"
  description = "AWS Load Balancer IAM policy for Thrive app"

  policy = file(var.lb_controller_policy_file)
}

resource "aws_iam_role" "aws_lb_controller_role" {
  name = "${var.name}-lb-controller-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::642737192615:oidc-provider/oidc.eks.${var.region}.amazonaws.com/id/${var.lb_controller_oidc_id}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.${var.region}.amazonaws.com/id/${var.lb_controller_oidc_id}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
  })

  tags = local.tags

}

resource "aws_iam_role_policy_attachment" "iam_lb_controller_policy_attachment" {
  policy_arn = aws_iam_policy.lb_controller_iam_policy.arn
  role       = aws_iam_role.aws_lb_controller_role.name
}

resource "kubernetes_service_account" "service_account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = aws_iam_role.aws_lb_controller_role.arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.service_account
  ]

  set = [
    {
      name  = "region"
      value = var.region
    },
    {
      name  = "vpcId"
      value = var.lb_controller_vpc_id
    },
    {
      name  = "image.repository"
      value = "${var.eks_addon_repo_number}.dkr.ecr.${var.region}.amazonaws.com/amazon/aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "clusterName"
      value = var.eks_cluster_name
    }
  ]
}
