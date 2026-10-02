terraform {
  backend "s3" {
    bucket = "noel-petclinic1"
    key    = "eks/terraform.tfstate"
    region = "eu-north-1"
  }
}