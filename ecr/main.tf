terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Recommended Default Lifecycle Policy
# Keeps tagged images for retention, expires untagged images after specified days
locals {
  default_lifecycle_policy = {
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.default_lifecycle_policy_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.default_lifecycle_policy_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last ${var.default_lifecycle_policy_count} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest", "prod", "stage", "dev"]
          countType     = "imageCountMoreThan"
          countNumber   = var.default_lifecycle_policy_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Expire old untagged images"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 90
        }
        action = {
          type = "expire"
        }
      }
    ]
  }
}

# ECR Repository
resource "aws_ecr_repository" "this" {
  for_each = { for repo in var.repositories : repo.name => repo }

  name                     = each.value.name
  image_tag_mutability     = each.value.image_tag_mutability
  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }
  encryption_configuration {
    encryption_type = each.value.encryption_type
    kms_key         = each.value.kms_key
  }

  tags = merge(var.tags, {
    Name = each.value.name
  })
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = { for repo in var.repositories : repo.name => repo }

  repository = aws_ecr_repository.this[each.key].name
  policy = jsonencode(
    each.value.lifecycle_policy != null ? each.value.lifecycle_policy : (
      var.enable_default_lifecycle_policy ? local.default_lifecycle_policy : null
    )
  )
}

# ECR Repository Policy (optional - for cross-account access)
resource "aws_ecr_repository_policy" "this" {
  for_each = { for repo in var.repositories : repo.name => repo if repo.repository_policy != null }

  repository = aws_ecr_repository.this[each.key].name
  policy     = jsonencode(each.value.repository_policy)
}

# ECR Pull-Through Cache Rule (optional)
resource "aws_ecr_pull_through_cache_rule" "this" {
  for_each = { for rule in var.pull_through_cache_rules : rule.ecr_repository_prefix => rule }

  ecr_repository_prefix = each.value.ecr_repository_prefix
  upstream_registry_url = each.value.upstream_registry_url
  credential_arn        = each.value.credential_arn
}
