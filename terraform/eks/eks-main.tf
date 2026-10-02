data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "vpc/terraform.tfstate"
    region = var.aws_region
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  control_plane_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  # enabled for testing purposes, but should be disabled in production
  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns = {}

    eks-pod-identity-agent = {
      before_compute = true
    }

    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    main = {
      ami_type = "AL2023_x86_64_STANDARD"

      instance_types = ["t3.small"]

      min_size     = 2
      max_size     = 4
      desired_size = 2
    }
  }

  tags = var.tags
}