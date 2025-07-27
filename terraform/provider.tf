provider "aws" {
   region = "us-east-2"
}

provider "kubernetes" {
  ###host = aws_eks_cluster.thrive_eks_cluster.endpoint
  ###cluster_ca_certificate = base64decode(aws_eks_cluster.thrive_eks_cluster.certificate_authority[0].data)
  host = module.eks_cluster.eks_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.eks_certificate_authority)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.eks_name]
  }
}

provider "helm" {
  kubernetes = {
    ###host = aws_eks_cluster.thrive_eks_cluster.endpoint
    ###cluster_ca_certificate = base64decode(aws_eks_cluster.thrive_eks_cluster.certificate_authority[0].data)
    host = module.eks_cluster.eks_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.eks_certificate_authority)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.eks_name]
    }
  }
}
