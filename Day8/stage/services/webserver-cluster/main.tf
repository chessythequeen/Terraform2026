provider "aws" {
  region = "us-east-1"
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster"

  ami_id = "ami-0c3389a4fa5bddaad"
  cluster_name = "web-stage"
  instance_type = "t2.micro"
  min_size = 1
  max_size = 1
}