terraform {
  backend "s3" {
    bucket         = "chessy-terraform-state-bucket-456789"
    key            = "environments/production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
