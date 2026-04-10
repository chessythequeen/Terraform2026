terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default Provider (Region 1)
provider "aws" {
  region = "us-east-1"
}

# Aliased Provider (Region 2)
provider "aws" {
  alias  = "region_2"
  region = "us-west-2"
}

# Get current region info (Region 2)
data "aws_region" "region_2" {
  provider = aws.region_2
}

# Fetch latest Ubuntu AMI (Region 2)
data "aws_ami" "ubuntu_region_2" {
  provider    = aws.region_2
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# EC2 in Default Region
resource "aws_instance" "east_instance" {
  ami           = "ami-0c02fb55956c7d316" 
  instance_type = "t2.micro"
}

# EC2 in Region 2 using fetched Ubuntu AMI
resource "aws_instance" "west_instance" {
  provider      = aws.region_2
  ami           = data.aws_ami.ubuntu_region_2.id
  instance_type = "t2.micro"
}

# Output Region Name
output "region_2_name" {
  value = data.aws_region.region_2.name
}

# Output AMI ID used
output "ubuntu_ami_region_2" {
  value = data.aws_ami.ubuntu_region_2.id
}