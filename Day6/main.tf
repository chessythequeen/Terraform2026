provider "aws" {
  region = var.region
}

resource "aws_instance" "test_server" {
  ami           = "ami-02dfbd4ff395f2a1b"  
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.test_sg.id]
}

resource "aws_security_group" "test_sg" {
  name = "test_sg"

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
