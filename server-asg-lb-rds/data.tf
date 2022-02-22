data "terraform_remote_state" "network-config" {
  backend = "s3"
  config = {
    bucket = "terraform-wordpress-state-bucket-210222"
    key    = "network-config/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Below is the policy document which autoscaling and EC2 instance will assume
# This will not define any permissions, just the trust policy
# Need to provide both EC2 & Autoscaling group in the trust policy otherwise it won't work
data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "autoscaling.amazonaws.com"]
    }
  }
}

# This data resource will fetch the zone_id of the cloud99.click domain
data "aws_route53_zone" "cloud99" {
  name         = "cloud99.click"
  private_zone = false
}

# Fetch the database username & password from secrets manager
data "aws_secretsmanager_secret" "db" {
  name = "FirstDatabasepassword"
}

data "aws_secretsmanager_secret_version" "secret_version" {
  secret_id = data.aws_secretsmanager_secret.db.id
}