terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "ecr" {
  source = "../.."

  # AWS recommended defaults enabled:
  # - Lifecycle policy expires untagged images after 30 days
  # - Keeps last 10 tagged images
  # - Image scanning on push enabled
  enable_default_lifecycle_policy = true
  default_lifecycle_policy_days   = 30
  default_lifecycle_policy_count  = 10

  repositories = [
    {
      name                 = "${var.project_name}-web-app"
      image_tag_mutability = "IMMUTABLE"
      # scan_on_push defaults to true
    },
    {
      name                 = "${var.project_name}-api-server"
      image_tag_mutability = "MUTABLE"
    },
    {
      name                 = "${var.project_name}-worker"
      image_tag_mutability = "MUTABLE"
    }
  ]

  pull_through_cache_rules = [
    {
      ecr_repository_prefix = "dockerhub"
      upstream_registry_url = "registry-1.docker.io"
      upstream_registry     = "docker-hub"
    }
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
