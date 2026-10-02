data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "eks/terraform.tfstate"
    region = var.aws_region
  }
}

data "aws_iam_policy_document" "aws_load_balancer_controller" {
  source_policy_documents = [
    file("${path.module}/iam_policy.json")
  ]
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = data.aws_iam_policy_document.aws_load_balancer_controller.json
}

data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        data.terraform_remote_state.eks.outputs.oidc_provider_arn
      ]
    }

    condition {
      test = "StringEquals"

      variable = "${replace(
        data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url,
        "https://",
        ""
      )}:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test = "StringEquals"

      variable = "${replace(
        data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url,
        "https://",
        ""
      )}:sub"

      values = [
        "system:serviceaccount:kube-system:aws-load-balancer-controller"
      ]
    }
  }
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "AmazonEKSLoadBalancerControllerRole"

  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role.json
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}