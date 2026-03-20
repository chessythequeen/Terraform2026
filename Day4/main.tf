provider "aws" {
  region = var.region
}

data "aws_availability_zones" "all" {}
data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "webserver_sg" {
  name = "webserver_sg"
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "alb_sg" {
  name = "alb-sg"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "web_lt" {
  name          = "web-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]

  user_data = base64encode(<<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable httpd
systemctl start httpd
echo "Hello, Terraform Day 4! We made it, Guys" > /var/www/html/index.html
EOF
)
}

resource "aws_lb_target_group" "web_tg" {
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

resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = var.server_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_autoscaling_group" "web_asg" {
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier = data.aws_subnets.default.ids
  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 30
  force_delete              = true
}