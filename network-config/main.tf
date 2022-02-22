module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  name                   = "wordpress-first-vpc"
  cidr                   = "10.0.0.0/16"
  azs                    = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  private_subnets        = [cidrsubnet("10.0.0.0/16", 8, 1), cidrsubnet("10.0.0.0/16", 8, 2)]
  public_subnets         = [cidrsubnet("10.0.0.0/16", 8, 101), cidrsubnet("10.0.0.0/16", 8, 102)]
  enable_nat_gateway     = true
  enable_vpn_gateway     = false
  one_nat_gateway_per_az = true
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
