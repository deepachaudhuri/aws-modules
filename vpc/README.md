# Generic VPC Module

This module creates a reusable AWS VPC with:

- VPC
- Internet Gateway
- Public and private subnets
- Public and private route tables
- Route table associations
- Optional NAT Gateway

## Usage

```hcl
module "vpc" {
  source = "./aws-modules/vpc"

  name       = "example"
  cidr_block = "10.20.0.0/16"

  subnets = [
    {
      name              = "public-a"
      cidr_block        = "10.20.1.0/24"
      availability_zone = "us-east-1a"
      type              = "public"
    },
    {
      name              = "private-a"
      cidr_block        = "10.20.11.0/24"
      availability_zone = "us-east-1a"
      type              = "private"
    }
  ]

  create_internet_gateway = true
  enable_nat_gateway      = true
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
```
