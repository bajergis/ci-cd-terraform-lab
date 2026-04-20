terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
  }
}

provider "aws" {
  region = var.region
}

# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a", "us-east-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.33"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # ADDED — enables the OIDC provider on the cluster, required for IRSA
  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]
      min_size       = 1
      max_size       = 2
      desired_size   = 2
    }
  }

  access_entries = {
    terraform_user = {
      principal_arn = "arn:aws:iam::397845934685:user/terraform-user"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "ci-cd-terraform-lab"
  }
}

# ADDED — IAM role for the EBS CSI driver using IRSA
# IRSA = IAM Roles for Service Accounts
# This lets the CSI driver pod call AWS APIs (create/delete EBS volumes)
# without hardcoding credentials — the pod gets a token via its service account
module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "ebs-csi-controller"
  attach_ebs_csi_policy = true  # attaches the AWS-managed EBS CSI policy

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# ADDED — installs the EBS CSI driver as an EKS managed add-on
# and links it to the IAM role above so it can provision EBS volumes
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = module.ebs_csi_irsa.iam_role_arn

  depends_on = [module.eks]
}

# Kubernetes provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
  }
}

module "k8s" {
  source              = "./k8s"
  ecr_repository_url  = aws_ecr_repository.visual_dictionary.repository_url
  unsplash_access_key = var.unsplash_access_key
  postgres_password   = var.postgres_password
  # UPDATED — k8s module now also depends on the CSI driver being ready
  # so PVCs can be provisioned before pods try to mount them
  depends_on = [module.eks, module.ebs_csi_irsa, aws_eks_addon.ebs_csi, kubernetes_namespace.app]
}