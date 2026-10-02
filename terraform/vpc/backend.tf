terraform {
  backend "s3" {
    bucket = "noel-petclinic1"
    key    = "vpc/terraform.tfstate"
    region = "eu-north-1"
  }
}