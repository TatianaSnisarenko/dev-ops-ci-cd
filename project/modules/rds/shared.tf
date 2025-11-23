# Subnet group (shared for RDS and Aurora)
resource "aws_db_subnet_group" "default" {
  name = "${var.name}-subnet-group"

  # If the database is public — use public subnets, otherwise private subnets
  subnet_ids = var.publicly_accessible ? var.subnet_public_ids : var.subnet_private_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-subnet-group"
    }
  )
}

# Security Group (shared for RDS and Aurora)
resource "aws_security_group" "rds" {
  name        = "${var.name}-sg"
  description = "Security group for RDS/Aurora"
  vpc_id      = var.vpc_id

  # Allow access to the PostgreSQL port from the whole VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-sg"
    }
  )
}