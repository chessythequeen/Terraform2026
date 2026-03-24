variable "cluster_name" {
description = "The name to use for all the cluster resources"
type = string
}

variable "instance_type" {
description = "The type of EC2 Instances to run (e.g. t2.micro)"
type = string
}

variable "min_size" {
description = "The minimum number of EC2 Instances in the ASG"
type = number
}
variable "max_size" {
description = "The maximum number of EC2 Instances in the ASG"
type = number
}

locals {
http_port = 80
any_port = 0
any_protocol = "-1"
tcp_protocol = "tcp"
all_ips = ["0.0.0.0/0"]
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instances"
  type        = string
  default     = "ami-02dfbd4ff395f2a1b"  
}

