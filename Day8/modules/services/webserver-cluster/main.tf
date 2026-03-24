
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

resource "aws_security_group" "instance_sg" {
  name = "${var.cluster_name}-instance-sg"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type       = "ingress"
  security_group_id = aws_security_group.instance_sg.id
  
  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type        = "egress"
  security_group_id = aws_security_group.instance_sg.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}
  
  
resource "aws_security_group" "alb_sg" {
  name = "${var.cluster_name}-alb-sg"
}
  
resource "aws_security_group_rule" "allow_http_inbound_1" {
  type = "ingress"
  security_group_id = aws_security_group.alb_sg.id
  
  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound_1" {
  type = "egress"
  security_group_id = aws_security_group.alb_sg.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}  


resource "aws_launch_template" "web_lt" {
  name          = "${var.cluster_name}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

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

resource "aws_lb_target_group" "tg" {
  name     = "${var.cluster_name}-tg"
  port     = local.http_port
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

resource "aws_lb" "alb" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_autoscaling_group" "web_asg" {
  max_size             = var.min_size
  min_size             = var.max_size
  vpc_zone_identifier = data.aws_subnets.default.ids
  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 30
  force_delete              = true
}