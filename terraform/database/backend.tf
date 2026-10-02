terraform {
  backend "s3" {
    bucket = "noel-petclinic1"
    key    = "database/terraform.tfstate"
    region = "eu-north-1"
  }
}