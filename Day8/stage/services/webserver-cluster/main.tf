provider "aws" {
  region = "us-east-1"
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "web-stage"
  instance_type = "t2.micro"
  min_size = 1
  max_size = 1
}