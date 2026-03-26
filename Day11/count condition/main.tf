resource "aws_instance" "optional_server" {
  count = var.create_instance ? 1 : 0

  ami           = "ami-02dfbd4ff395f2a1b" 
  instance_type = "t2.micro"

  tags = {
    Name = "conditional-instance"
  }
}
output "instance_id" {
  value = var.create_instance ? aws_instance.optional_server[0].id : null
}