locals {
  public_by_az = {
    for idx, az in var.availability_zones :
    az => {
      cidr = var.public_subnets[idx]
    }
  }

  private_by_az = {
    for idx, az in var.availability_zones :
    az => {
      cidr = var.private_subnets[idx]
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.vpc_name }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.vpc_name}-igw" }
}

# ---------- Public subnets (keyed by AZ) ----------
resource "aws_subnet" "public" {
  for_each = local.public_by_az

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = { Name = "${var.vpc_name}-public-${each.key}" }
}

# ---------- Private subnets (keyed by AZ) ----------
resource "aws_subnet" "private" {
  for_each = local.private_by_az

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.key

  tags = { Name = "${var.vpc_name}-private-${each.key}" }
}

# ---------- One EIP + NAT per public AZ ----------
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags     = { Name = "${var.vpc_name}-eip-${each.key}" }
}

resource "aws_nat_gateway" "nat" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  tags          = { Name = "${var.vpc_name}-nat-${each.key}" }
  depends_on    = [aws_internet_gateway.igw]
}
