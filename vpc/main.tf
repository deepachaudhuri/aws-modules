terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  public_subnet_names  = [for subnet in var.subnets : subnet.name if subnet.type == "public"]
  private_subnet_names = [for subnet in var.subnets : subnet.name if subnet.type == "private"]
  nat_gateway_subnet   = var.nat_gateway_subnet_name != null ? var.nat_gateway_subnet_name : (length(local.public_subnet_names) > 0 ? local.public_subnet_names[0] : null)
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_internet_gateway" "this" {
  count  = var.create_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_subnet" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.type == "public"

  tags = merge(var.tags, {
    Name = each.value.name
    Type = each.value.type
  })
}

resource "aws_route_table" "public" {
  count  = length(local.public_subnet_names) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.create_internet_gateway ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.this[0].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-route-table"
  })
}

resource "aws_route_table" "private" {
  count  = length(local.private_subnet_names) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[0].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-private-route-table"
  })
}

resource "aws_route_table_association" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = each.value.type == "public" ? aws_route_table.public[0].id : aws_route_table.private[0].id
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway && local.nat_gateway_subnet != null ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway && local.nat_gateway_subnet != null ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.this[local.nat_gateway_subnet].id

  tags = merge(var.tags, {
    Name = "${var.name}-nat-gateway"
  })

  depends_on = [aws_internet_gateway.this]
}
