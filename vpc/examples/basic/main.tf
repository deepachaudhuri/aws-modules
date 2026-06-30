provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../.."

  name       = "demo-vpc"
  cidr_block = "10.30.0.0/16"

  subnets = [
    {
      name              = "public-a"
      cidr_block        = "10.30.1.0/24"
      availability_zone = "us-east-1a"
      type              = "public"
    },
    {
      name              = "public-b"
      cidr_block        = "10.30.2.0/24"
      availability_zone = "us-east-1b"
      type              = "public"
    },
    {
      name              = "private-a"
      cidr_block        = "10.30.11.0/24"
      availability_zone = "us-east-1a"
      type              = "private"
    },
    {
      name              = "private-b"
      cidr_block        = "10.30.12.0/24"
      availability_zone = "us-east-1b"
      type              = "private"
    }
  ]

  create_internet_gateway = true
  enable_nat_gateway      = true
  nat_gateway_subnet_name = "public-a"

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
