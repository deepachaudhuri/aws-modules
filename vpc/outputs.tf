output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = var.create_internet_gateway ? aws_internet_gateway.this[0].id : null
}

output "subnet_ids" {
  description = "Map of subnet names to subnet IDs"
  value       = { for key, subnet in aws_subnet.this : key => subnet.id }
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : null
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = length(aws_route_table.private) > 0 ? aws_route_table.private[0].id : null
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway"
  value       = length(aws_nat_gateway.this) > 0 ? aws_nat_gateway.this[0].id : null
}
