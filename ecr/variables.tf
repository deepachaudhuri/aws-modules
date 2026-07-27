variable "enable_default_lifecycle_policy" {
  description = "Enable AWS recommended default lifecycle policy for repositories"
  type        = bool
  default     = true
}

variable "default_lifecycle_policy_days" {
  description = "Number of days to keep untagged images (used in default lifecycle policy)"
  type        = number
  default     = 30

  validation {
    condition     = var.default_lifecycle_policy_days > 0
    error_message = "default_lifecycle_policy_days must be greater than 0."
  }
}

variable "default_lifecycle_policy_count" {
  description = "Number of tagged images to keep (used in default lifecycle policy)"
  type        = number
  default     = 10

  validation {
    condition     = var.default_lifecycle_policy_count > 0
    error_message = "default_lifecycle_policy_count must be greater than 0."
  }
}

variable "repositories" {
  description = "List of ECR repositories to create"
  type = list(object({
    name                  = string
    image_tag_mutability  = optional(string, "MUTABLE")
    scan_on_push          = optional(bool, true)
    encryption_type       = optional(string, "AES256")
    kms_key               = optional(string)
    lifecycle_policy      = optional(any)
    repository_policy     = optional(any)
  }))
  default = []

  validation {
    condition = alltrue([
      for repo in var.repositories : contains(["MUTABLE", "IMMUTABLE"], repo.image_tag_mutability)
    ])
    error_message = "image_tag_mutability must be either 'MUTABLE' or 'IMMUTABLE'."
  }

  validation {
    condition = alltrue([
      for repo in var.repositories : contains(["AES256", "KMS"], repo.encryption_type)
    ])
    error_message = "encryption_type must be either 'AES256' or 'KMS'."
  }
}

variable "pull_through_cache_rules" {
  description = "List of ECR pull-through cache rules to enable pulling from upstream registries"
  type = list(object({
    ecr_repository_prefix = string
    upstream_registry_url = string
    credential_arn        = optional(string)
    upstream_registry     = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all ECR resources"
  type        = map(string)
  default     = {}
}
