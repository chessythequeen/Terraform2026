# Deploying an EC2 Server with Terraform

Terraform Challenge Day 3.  Today, we go hands on. 
- Tasks:
- Spin up a webserver with Terraform 
- Master Terraform commands (init, apply, destroy) 
- Explain open Provider & Resource blocks – the heart of your infrastructure 

---

## 1. Project Overview
We will create:
- An **AWS EC2 instance** running a simple Apache web server  
- A **security group** allowing HTTP (port 80) traffic  
- A basic **user_data script** to install and start Apache automatically  

---

## 2. Terraform Code with Explanations
- **terraform init**- Initializes the working directory and downloads necessary provider plugins.
- **terraform plan**- Shows a preview of resources Terraform will create, modify, or destroy.
- **terraform apply**- Deploys the resources to AWS.
- **terraform destroy**- Removes all resources created by Terraform.

## 4. Provider Block & Resourse block
In Terraform, Provider blocks and Resource blocks are two fundamental building blocks that work together to manage infrastructure
- **Provider block**: configures the specific cloud provider or infrastructure platform you want to interact with (AWS, Azure, GCP, Kubernetes, etc.)
- **Resource blocks**: define the actual infrastructure components you want to create and manage (EC2 instances, databases, VPCs, etc.).

## 4. Challenges & Solutions
- Issue: EC2 failed to deploy because security group was not found
- Solution: Declared the security group before referencing it in the instance resource.

## 5. Code with Explanations

```hcl
# Provider block tells Terraform which cloud provider to use and the region
provider "aws" {
  region = "us-east-1"
}

# Security Group to allow incoming HTTP traffic
resource "aws_security_group" "webserver_sg" {
  name        = "webserver-sg"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # allows traffic from any IP
  }
}

# EC2 Instance
resource "aws_instance" "webserver" {
  ami           = "ami-0c94855ba95c71c99" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  security_groups = [aws_security_group.webserver_sg.id] # attach the SG

  # user_data runs commands on instance startup
  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello Terraform!" > /var/www/html/index.html
              EOF
}
---