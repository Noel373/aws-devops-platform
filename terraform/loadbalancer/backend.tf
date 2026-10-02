terraform {
  backend "s3" {
    bucket = "noel-petclinic1"
    key    = "loadbalancer/terraform.tfstate"
    region = "eu-north-1"
  }
}