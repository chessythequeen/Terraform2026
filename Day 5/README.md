# Managing High Traffic Applications with AWS Elastic Load Balancer and Terraform

Day 5 of learning. Today, I will deploy a load balancer to my already existing infrastructure consisting of EC2 and Auto Scaling. This setup gave me redundancy, but users still needed a single entry point. That’s where the Application Load Balancer comes in.

# What the ALB Does
- Distributes incoming traffic across multiple EC2 instances
- Performs health checks to ensure only healthy instances receive traffic
- Automatically adapts as instances scale up or down

With this setup, my application is now, highly available, Fault tolerant and Scalable

# Terraform Code to Provision a Load balancer to my simple website

```
 resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}
```
This creates the application Load balancer.

```
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = var.server_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
 resource "aws_lb_target_group" "web_tg" {  #
  name     = "web-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id
  

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

```
A Listener sits on the Load Balancer and waits for incoming traffic.

A Target Group is a collection of servers (EC2 instances), where traffic from the Load balancer is directed.


## Terraform state files
The terraform.tfstate file is acts as the source of truth for your managed infrastructure. It maps the resources defined in your Terraform configuration to the real world resources they represent. 

Without it terraform would not know what already exists, what needs to change or what to delete.

## Explore and Understand the State File
After experimenting with the Terraform state file, I observed the following:
1. Manual Modification of the State File
I manually edited the state file by adding a value to the security group configuration. When I ran terraform apply, Terraform returned an error (operation error).
Finding: Directly modifying the state file can corrupt it or create inconsistencies between the actual infrastructure and Terraform’s understanding of it. This leads to failures during execution. The state file should not be manually edited unless absolutely necessary and done with extreme caution."
2. Infrastructure Drift (Changes via AWS Console)
I added an additional rule to the security group directly from the AWS Management Console instead of updating the Terraform code.
Finding: Terraform detected this as drift—a difference between the real infrastructure and the state file. When I ran terraform plan, it showed that Terraform intended to revert the changes and restore the configuration to match what is defined in the code.