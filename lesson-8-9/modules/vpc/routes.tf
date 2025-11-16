# One public RT for the VPC
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.vpc_name}-rt-public" }
}

# Associate each public subnet to the public route table
resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

# One private RT for each AZ (key - AZ name)
resource "aws_route_table" "private" {
  for_each = aws_nat_gateway.nat
  vpc_id   = aws_vpc.this.id
  tags     = { Name = "${var.vpc_name}-rt-private-${each.key}" }
}

# Each private subnet is associated with its AZ's RT
resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

# Default route 0.0.0.0/0 via IGW for public RT
resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on             = [aws_internet_gateway.igw]
}

# Default route 0.0.0.0/0 via NAT for each private RT (same AZ key)
resource "aws_route" "private_default" {
  for_each               = aws_route_table.private
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
  depends_on             = [aws_nat_gateway.nat]
}
