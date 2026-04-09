
provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name = "secure-rds-credentials"
}

resource "random_password" "db_password" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret_version" "rds_secret_value" {
  secret_id = aws_secretsmanager_secret.rds_secret.id

  secret_string = jsonencode({
    username = "adminuser"
    password = random_password.db_password.result
  })
}

data "aws_secretsmanager_secret_version" "rds_secret" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
}


resource "aws_security_group" "rds_sg" {
  name        = "rds-secure-sg"
  description = "Restrict DB access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow PostgreSQL from app only"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.app_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-default-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "RDS Default Subnet Group"
  }
}



resource "aws_db_instance" "secure_rds" {
  identifier        = "secure-rds-instance"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name = "securedb"

  username = jsondecode(
    data.aws_secretsmanager_secret_version.rds_secret.secret_string
  )["username"]

  password = jsondecode(
    data.aws_secretsmanager_secret_version.rds_secret.secret_string
  )["password"]

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  storage_encrypted   = true   # Uses default AWS-managed key

  multi_az                = true
  backup_retention_period = 7

  deletion_protection = true
  skip_final_snapshot = false

  performance_insights_enabled = true

  enabled_cloudwatch_logs_exports = ["postgresql"]

  auto_minor_version_upgrade = true

  tags = {
    Environment = "production"
    Security    = "enforced"
  }
}

############################################
output "db_endpoint" {
  value = aws_db_instance.secure_rds.endpoint
}

output "db_password" {
  value = jsondecode(
    data.aws_secretsmanager_secret_version.rds_secret.secret_string
  )["password"]

  sensitive = true
}