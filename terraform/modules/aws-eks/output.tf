output "eks_id" {
   value = aws_eks_cluster.eks_cluster.id
}

output "eks_name" {
   value = aws_eks_cluster.eks_cluster.name
}

output "eks_certificate_authority" {
   value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "eks_endpoint" {
   value = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_oidc_id" {
   value = local.eks_oidc_id
}

output "eks_oidc_issuer" {
   value = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}
