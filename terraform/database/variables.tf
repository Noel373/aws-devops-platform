variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "petclinic-eks"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "petclinic"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "petclinicadmin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Initial RDS storage in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17"
}
variable "state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "noel-petclinic1"
}