########################################
# RDS PostgreSQL (private, simple)    #
########################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}

resource "random_password" "master" {
  length           = 20
  special          = true
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "!@#%^*-_=+?.,~"
}


resource "aws_db_subnet_group" "this" {
  name       = "${var.cluster_name}-rds-subnets"
  subnet_ids = var.private_subnet_ids
  tags = {
    Name = "${var.cluster_name}-rds-subnets"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}


resource "aws_db_instance" "this" {
  identifier                 = "${var.cluster_name}-postgres"
  engine                     = "postgres"
  engine_version             = "16.3"
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage
  db_name                    = var.db_name
  username                   = var.master_username
  password                   = random_password.master.result
  port                       = 5432

  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  publicly_accessible        = false
  multi_az                   = false
  storage_encrypted          = true
  deletion_protection        = false
  skip_final_snapshot        = true
  apply_immediately          = true

  tags = {
    Name = "${var.cluster_name}-postgres"
  }
}
