terraform {
  // Terraform本体に対するバージョン制約
  required_version = "~> 1.3.0"
}

provider "aws" {
  region = var.region
}