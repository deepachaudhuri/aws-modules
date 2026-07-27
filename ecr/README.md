# AWS ECR Module

This Terraform module creates and manages AWS Elastic Container Registry (ECR) repositories with AWS recommended best practices including automatic lifecycle policies, image scanning, and encryption.

## Features

- **AWS Recommended Defaults**: Built-in lifecycle policy that expires untagged images and retains tagged versions
- Create multiple ECR repositories
- Configure image tag mutability (MUTABLE or IMMUTABLE)
- Enable image scanning on push (enabled by default)
- Encryption configuration (AES256 or KMS)
- **Automatic lifecycle policies**: Expires untagged images after 30 days, keeps last 10 tagged images, expires all images after 90 days
- Repository policies for access control
- Pull-through cache rules for upstream registry integration
- Comprehensive tagging support
- Easy override of default lifecycle policies with custom ones

## Usage

### Basic Usage - Single Repository

```hcl
module "ecr" {
  source = "./aws-modules/ecr"

  repositories = [
    {
      name = "my-app"
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

This will automatically apply AWS recommended lifecycle policy that:
- Keeps the last 10 tagged images
- Expires untagged images after 30 days
- Expires all images after 90 days
- Enables image scanning on push

### Disable Default Lifecycle Policy

```hcl
module "ecr" {
  source = "./aws-modules/ecr"

  enable_default_lifecycle_policy = false

  repositories = [
    {
      name = "my-app"
    }
  ]

  tags = {
    Environment = "dev"
  }
}
```

### Customize Default Lifecycle Policy Settings

```hcl
module "ecr" {
  source = "./aws-modules/ecr"

  # Keep untagged images for 60 days instead of default 30
  default_lifecycle_policy_days = 60
  
  # Keep last 20 tagged images instead of default 10
  default_lifecycle_policy_count = 20

  repositories = [
    {
      name = "my-app"
    }
  ]

  tags = {
    Environment = "prod"
  }
}
```

### Override with Custom Lifecycle Policy

```hcl
module "ecr" {
  source = "./aws-modules/ecr"

  repositories = [
    {
      name         = "my-app"
      lifecycle_policy = {
        rules = [
          {
            rulePriority = 1
            description  = "Keep only last 5 images"
            selection = {
              tagStatus     = "any"
              countType     = "imageCountMoreThan"
              countNumber   = 5
            }
            action = {
              type = "expire"
            }
          }
        ]
      }
    }
  ]

  tags = {
    Environment = "prod"
  }
}
```



```hcl
module "ecr" {
  source = "./aws-modules/ecr"

  repositories = [
    {
      name                 = "web-app"
      image_tag_mutability = "IMMUTABLE"
      scan_on_push         = true
      lifecycle_policy = {
        rules = [
          {
            rulePriority = 1
            description  = "Keep last 10 images"
            selection = {
              tagStatus     = "any"
              countType     = "imageCountMoreThan"
              countNumber   = 10
            }
            action = {
              type = "expire"
            }
          }
        ]
      }
    },
    {
      name                 = "api-server"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "my-project"
  }
}
```

### With KMS Encryption

```hcl
module "ecr" {
  source = "./aws-modules/ecr"

  repositories = [
    {
      name            = "secure-app"
      encryption_type = "KMS"
      kms_key         = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      scan_on_push    = true
    }
  ]

  tags = {
    Environment = "prod"
  }
}
```

### With Pull-Through Cache Rules

```hcl
module "ecr" {
  source = "./aws-modules/ecr"

  repositories = [
    {
      name         = "my-app"
      scan_on_push = true
    }
  ]

  pull_through_cache_rules = [
    {
      ecr_repository_prefix = "dockerhub"
      upstream_registry_url = "registry-1.docker.io"
      upstream_registry     = "docker-hub"
    },
    {
      ecr_repository_prefix = "ghcr"
      upstream_registry_url = "ghcr.io"
      upstream_registry     = "github-container-registry"
    }
  ]

  tags = {
    Environment = "dev"
  }
}
```

## Variables

### enable_default_lifecycle_policy
- **Description**: Enable AWS recommended default lifecycle policy for repositories
- **Type**: Boolean
- **Required**: No
- **Default**: true

### default_lifecycle_policy_days
- **Description**: Number of days to keep untagged images (used in default lifecycle policy)
- **Type**: Number
- **Required**: No
- **Default**: 30

### default_lifecycle_policy_count
- **Description**: Number of tagged images to keep (used in default lifecycle policy)
- **Type**: Number
- **Required**: No
- **Default**: 10

### repositories
- **Description**: List of ECR repositories to create
- **Type**: List of objects
- **Required**: No
- **Default**: []

#### Repository Object Schema:
- `name` (string, required): Name of the repository
- `image_tag_mutability` (string, optional): Tag mutability mode - "MUTABLE" or "IMMUTABLE". Default: "MUTABLE"
- `scan_on_push` (bool, optional): Enable image scanning on push. Default: false
- `encryption_type` (string, optional): Encryption type - "AES256" or "KMS". Default: "AES256"
- `kms_key` (string, optional): ARN of KMS key for encryption (required if encryption_type is "KMS")
- `lifecycle_policy` (any, optional): Lifecycle policy JSON for automatic image cleanup
- `repository_policy` (any, optional): Repository policy for access control

### pull_through_cache_rules
- **Description**: List of ECR pull-through cache rules
- **Type**: List of objects
- **Required**: No
- **Default**: []

#### Pull-Through Cache Rule Object Schema:
- `ecr_repository_prefix` (string, required): Prefix for the ECR repository
- `upstream_registry_url` (string, required): URL of the upstream registry
- `credential_arn` (string, optional): ARN of credentials for private registries
- `upstream_registry` (string, optional): Upstream registry type

### tags
- **Description**: Tags to apply to all ECR resources
- **Type**: Map of strings
- **Required**: No
- **Default**: {}

## Outputs

- `repository_names`: Map of repository keys to repository names
- `repository_arns`: Map of repository keys to ARNs
- `repository_urls`: Map of repository keys to repository URLs
- `repository_registry_id`: Map of repository keys to registry IDs
- `pull_through_cache_rule_arns`: Map of cache rule keys to ARNs

## Example Outputs Usage

```hcl
output "ecr_repository_url" {
  value = module.ecr.repository_urls["my-app"]
}

output "ecr_repository_arn" {
  value = module.ecr.repository_arns["my-app"]
}
```

## AWS Recommended Lifecycle Policy (Default)

By default, the module applies AWS recommended lifecycle policies to all repositories. This policy:

**Rule 1 (Priority 1)**: Expire untagged images after 30 days
- Automatically removes untagged/dangling images to save storage costs
- Configurable via `default_lifecycle_policy_days` variable

**Rule 2 (Priority 2)**: Keep last N tagged images
- Retains images tagged with `v*`, `latest`, `prod`, `stage`, `dev` prefixes
- Ensures you always have recent versions available
- Configurable via `default_lifecycle_policy_count` variable
- Protects production and important images

**Rule 3 (Priority 3)**: Expire all images older than 90 days
- Final safety net to manage storage costs
- Prevents unbounded image accumulation
- Ensures compliance with retention policies

### Benefits

- **Cost Optimization**: Automatically cleans up unused images
- **Storage Management**: Prevents runaway ECR repository sizes
- **Best Practice Compliance**: Follows AWS recommendations
- **Flexibility**: Easy to customize or disable
- **Production Safe**: Protects tagged versions while cleaning old images



### Keep Last 10 Images Only

```hcl
lifecycle_policy = {
  rules = [
    {
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }
  ]
}
```

### Expire Images Older Than 30 Days

```hcl
lifecycle_policy = {
  rules = [
    {
      rulePriority = 1
      description  = "Expire images older than 30 days"
      selection = {
        tagStatus   = "any"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }
  ]
}
```

### Keep Latest Tagged Versions

```hcl
lifecycle_policy = {
  rules = [
    {
      rulePriority = 1
      description  = "Keep last 5 tagged versions"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["v"]
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = {
        type = "expire"
      }
    }
  ]
}
```

## Requirements

- Terraform >= 1.5.0
- AWS Provider >= 5.0

## Author

Infrastructure as Code Team
