terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # this defaults to registry.terraform.io/hashicorp/aws
      version = "~> 3.0"
    }
  }

  required_version = ">= 0.14.9"
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create S3 bucket to store the terraform state file
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "terraform-wordpress-state-bucket-210222"
  acl    = "private"

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Create dynamodb table to create a lock on the terraform state file
module "dynamodb_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name         = "terraform-wordpess-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "development"
  }
}
