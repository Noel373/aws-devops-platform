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