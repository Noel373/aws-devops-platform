###############################################################################
# Read VPC outputs
###############################################################################

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "vpc/terraform.tfstate"
    region = "eu-north-1"
  }
}


###############################################################################
# Read EKS outputs
###############################################################################

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "eks/terraform.tfstate"
    region = "eu-north-1"
  }
}


###############################################################################
# Random database password
#
# For this portfolio/dev environment this keeps the setup simple.
#
# IMPORTANT:
# The password will exist in Terraform state.
#
# For a real production environment, use AWS Secrets Manager instead.
###############################################################################

resource "random_password" "db_password" {
  length  = 32

  special = true

  override_special = "!#$%&*()-_=+[]{}<>:?"
}


###############################################################################
# RDS subnet group
#
# Database is placed in private subnets only.
###############################################################################

resource "aws_db_subnet_group" "petclinic" {
  name = "${var.project_name}-db-subnet-group"

  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


###############################################################################
# Security group for PostgreSQL
###############################################################################

resource "aws_security_group" "postgres" {
  name        = "${var.project_name}-postgres"
  description = "Allow PostgreSQL access from EKS nodes only"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description     = "PostgreSQL from EKS worker nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.eks.outputs.node_security_group_id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-postgres"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


###############################################################################
# PostgreSQL RDS
###############################################################################

resource "aws_db_instance" "petclinic" {
  identifier = "${var.project_name}-postgres"

  engine         = "postgres"
  engine_version = var.db_engine_version

  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = 50
  storage_type          = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.petclinic.name
  vpc_security_group_ids = [aws_security_group.postgres.id]

  publicly_accessible = false

  # Encryption should be enabled for production.
  storage_encrypted = true

  # --------------------------------------------------------------------------
  # DEVELOPMENT / PORTFOLIO SETTINGS
  # --------------------------------------------------------------------------

  multi_az = false

  backup_retention_period = 1

  skip_final_snapshot = true

  deletion_protection = false

  delete_automated_backups = true

  # --------------------------------------------------------------------------
  # PRODUCTION SETTINGS
  #
  # For production, I would change these to approximately:
  #
  # multi_az                  = true
  # backup_retention_period   = 7
  # skip_final_snapshot       = false
  # deletion_protection       = true
  # delete_automated_backups  = false
  #
  # Multi-AZ improves availability.
  # Longer backup retention provides better recovery options.
  # Final snapshots protect against accidental deletion.
  # Deletion protection prevents accidental database destruction.
  # --------------------------------------------------------------------------

  copy_tags_to_snapshot = true

  auto_minor_version_upgrade = true

  apply_immediately = true

  tags = {
    Name        = "${var.project_name}-postgres"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}