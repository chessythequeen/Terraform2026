# Deploying a Highly Available Web App on AWS Using Terraform

On Day 4 of my Terraform journey, I took a single, hardcoded web server and transformed it into a load balanced, auto scaling cluster on AWS.

# From Single Server to Configurable Infrastructure
On Day 3, I deployed a single EC2 instance with a simple Apache web server. 

It was fine for testing, but a single server is a single point of failure. 

To make my web app resilient, I needed:
- Multiple EC2 instances
- Automatic scaling
- A load balancer to distribute traffic
- Configurable input variables

# Why Input Variables Matter
Terraform variables are the key to reusability. Hardcoding values is easy, but not flexible.

Variables allow you to change instance types, regions, or ports without touching the main configuration. 

If tomorrow you need a t3.medium server or want to deploy in us-west-2, a single variable change updates your entire setup.


# My Terraform Code 
**Provider Configuration**

Instead of hardcoding the region, this time I captured it in variable.tf

 ```
 provider "aws" {
  region = var.region
}
```


 **Getting Default VPC and Subnets**
 
 This dynamically fetch the default VPC and its public subnets. Makes the deployment portable, avoiding hardcoded subnet IDs
```
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
```



**Security Group**
 
 Controls network traffic for EC2 instances.
 - Ingress rule: Allows HTTP (port 80) traffic from anywhere.
 - Egress rule: Allows all outgoing traffic.
 ```
resource "aws_security_group" "web_sg" {
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

 **Launch Template**
 
 Launch templates are required for auto-scaling groups, they standardize instance creation.
 ```
resource "aws_launch_template" "web_lt" {
  name          = "web-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
}
```

 **Auto Scaling Group**
 
 Ensures your app runs on multiple EC2 instances and can scale automatically. ASG provides high availability and automatic scaling.
```
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier = data.aws_subnets.default.ids
  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

 
```
 **Load Balancer**

 Distributes incoming traffic across all healthy EC2 instances.
 ```
resource "aws_lb" "web_alb" {
  load_balancer_type = "application"
}
```

 **Target Group + Listener**

 Connects the ALB to the target group so it knows where to forward requests.
 Without a listener, the ALB won’t route traffic to the instances
 ```
resource "aws_lb_target_group" "web_tg" {}
resource "aws_lb_listener" "web_listener" {}
```

# Issues Encountered
Issue:
The EC2 instances launched, Apache was installed, but visiting the ALB or public IP didn’t show the expected “Hello, Terraform Day 4!” message.

Cause:
The user_data script wasn’t executed correctly because of improper heredoc syntax in Terraform or missing #!/bin/bash shebang.

Solution:
Updated the user data script.

