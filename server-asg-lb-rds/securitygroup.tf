###########################################################################################################################
# Define the Security Group for WordPress Server
# #########################################################################################################################

module "web_server_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "web-server"
  description = "Security group for web-server with HTTP ports open within VPC"
  vpc_id      = data.terraform_remote_state.network-config.outputs.vpc_id

  ingress_cidr_blocks = [data.terraform_remote_state.network-config.outputs.vpc_cidr_blocks]

  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS"
      cidr_blocks = data.terraform_remote_state.network-config.outputs.vpc_cidr_blocks
    },
    {
      from_port   = 80 # Medha
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = data.terraform_remote_state.network-config.outputs.vpc_cidr_blocks
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

}

###########################################################################################################################
# Define the Security Group for Load Balancer
# #########################################################################################################################
module "elb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "elb-service"
  description = "Security group for elastic lb with HTTP port publicly open"
  vpc_id      = data.terraform_remote_state.network-config.outputs.vpc_id

  ingress_cidr_blocks = [data.terraform_remote_state.network-config.outputs.vpc_cidr_blocks]
  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

###########################################################################################################################
# Define the Security Group for RDS Database
# #########################################################################################################################
module "rds_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "rds-service"
  description = "Security group for rds with 3306 port open"
  vpc_id      = data.terraform_remote_state.network-config.outputs.vpc_id

  ingress_cidr_blocks = [data.terraform_remote_state.network-config.outputs.vpc_cidr_blocks]
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "RDS"
      cidr_blocks = data.terraform_remote_state.network-config.outputs.vpc_cidr_blocks
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}
