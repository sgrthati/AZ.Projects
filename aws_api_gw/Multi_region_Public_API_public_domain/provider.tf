terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = var.region.primary
  profile = "default"
}
provider "aws" {
  alias = "secondary"
  region = var.region.secondary
  profile = "default"
}