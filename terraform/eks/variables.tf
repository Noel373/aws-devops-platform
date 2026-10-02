variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "petclinic-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.33"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "state_bucket" {
  description = "S3 bucket containing Terraform state"
  type        = string
  default     = "noel-petclinic1"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)

  default = {
    Project     = "petclinic-eks"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}