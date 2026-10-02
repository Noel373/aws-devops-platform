variable "project_name" {
  description = "Project name"
  type        = string
  default     = "petclinic-devops"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)

  default = [
    "eu-north-1a",
    "eu-north-1b"
  ]
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)

  default = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
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