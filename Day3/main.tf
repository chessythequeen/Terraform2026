provider "aws" {
  region = "us-east-1"
}

#Creates a security group
resource "aws_security_group" "webserver_sg" {
  name = "webserver_sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Creates EC2 Webserver
resource "aws_instance" "Webserver" {
  ami           = "ami-02dfbd4ff395f2a1b"  
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              echo "<h1>We made it!! terraform challenge day 3</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "Webserver"
}
}