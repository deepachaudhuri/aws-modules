output "repository_names" {
  description = "Names of the ECR repositories"
  value       = { for key, repo in aws_ecr_repository.this : key => repo.repository_name }
}

output "repository_arns" {
  description = "ARNs of the ECR repositories"
  value       = { for key, repo in aws_ecr_repository.this : key => repo.arn }
}

output "repository_urls" {
  description = "URLs of the ECR repositories"
  value       = { for key, repo in aws_ecr_repository.this : key => repo.repository_url }
}

output "repository_registry_id" {
  description = "Registry ID of the ECR repositories"
  value       = { for key, repo in aws_ecr_repository.this : key => repo.registry_id }
}

output "pull_through_cache_rule_arns" {
  description = "ARNs of the ECR pull-through cache rules"
  value       = { for key, rule in aws_ecr_pull_through_cache_rule.this : key => rule.arn }
}
