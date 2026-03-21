terraform {
  backend "s3" {
    bucket         = "chessy-terraform-state-bucket-456789"
    key            = "project-1/day-04/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
