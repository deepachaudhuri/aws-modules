output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "ECR repository ARNs"
  value       = module.ecr.repository_arns
}

output "ecr_registry_id" {
  description = "ECR registry ID"
  value       = module.ecr.repository_registry_id
}
