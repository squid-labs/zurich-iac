terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.68.0"
    }
  }

  # This adds backend terraform state to s3 bucket
  backend "s3" {
    bucket               = "dev-terraform-remote-backend-state-kl"
    key                  = "dev/core-services/ecs/terraform.tfstate"
    region               = "ap-southeast-5"
    profile              = "default"
    skip_region_validation = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  profile = "default"
}