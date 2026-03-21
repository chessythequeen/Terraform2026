## Configure Remote State Storage with S3 and DynamoDB

Here’s how you can configure a remote backend in Terraform:
```
resource "aws_s3_bucket" "tf_state" {
  bucket = "chessy-terraform-state-bucket-45678"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}
``` 
Create S3 bucket, ensure that versioning in enable. Versioning on the S3  provides a history of all changes to the state file. 

```
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```
Enable Server Side Encryption for the S3 Bucket.It’s important to enable server-side encryption to protect sensitive data such as passwords.

```
resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```
Creates a DynamoDB table that will be used to lock your Terraform state.

Now run terraform init, plan and apply to provision your s3 and Dynamo DB.

## Remote Backend Configuration
backend.tf
```
terraform {
  backend "s3" {
    bucket         = "chessy-terraform-state-bucket-45678"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```
This migrate terraform.tfstate file to the S3 bucket for better security and team collaboration. The backend configuration block , backend.tf is separate from the code used to provision the S3 bucket and DynamoDB table.