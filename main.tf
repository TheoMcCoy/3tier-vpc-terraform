terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  project = var.project_name
  env = var.environment
  common_tags = {
    Project = local.project
    Environment = local.env
    ManagedBy = "Terraform"
    Owner = "Lereko Mohlomi"
  }
}