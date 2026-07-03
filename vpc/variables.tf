variable "name" {
  description = "Name prefix for the VPC and related resources"
  type        = string
  default    = "my-vpc"
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnets" {
  description = "List of subnet definitions to create"
  type = list(object({
    name              = string
    cidr_block        = string
    availability_zone = string
    type              = string
  }))
}

variable "enable_dns_support" {
  description = "Enable DNS support for the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames for the VPC"
  type        = bool
  default     = true
}

variable "create_internet_gateway" {
  description = "Create an internet gateway for the VPC"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway for private subnets"
  type        = bool
  default     = false
}

variable "nat_gateway_subnet_name" {
  description = "Optional subnet name used for the NAT gateway. Defaults to the first public subnet"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
