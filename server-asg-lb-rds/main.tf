###########################################################################################################################
# Creating the Auto Scaling Group
###########################################################################################################################
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  # Autoscaling group
  name = "asg-wordpress"

  min_size                  = 2
  max_size                  = 10
  desired_capacity          = 2
  wait_for_capacity_timeout = 0
  health_check_type         = "ELB"
  vpc_zone_identifier       = data.terraform_remote_state.network-config.outputs.private_subnets
  target_group_arns         = module.alb.target_group_arns
  # target_group_arns = module.alb.http_tcp_listener_arns # Medha


  # Launch template
  lc_name                = "wordpress-asg"
  description            = "Launch template example"
  update_default_version = true

  use_lc    = true
  create_lc = true

  image_id                    = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  security_groups             = [module.web_server_sg.security_group_id]
  iam_instance_profile_name   = aws_iam_instance_profile.session_manager_access.name

  user_data = templatefile("./user_data.tftpl",
    {
      db_username      = "mysqluser"
      db_user_password = jsondecode(data.aws_secretsmanager_secret_version.secret_version.secret_string)["MyPassword"]
      db_name          = "demodb"
      db_RDS           = module.db.db_instance_endpoint
    }
  )

  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "megasecret"
      propagate_at_launch = true
    },
  ]
}

###########################################################################################################################
# Creating the Application Load Balancer
# ###########################################################################################################################
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "wordpress-alb"

  # load_balancer_type = "application"
  load_balancer_type = "application" # Medha

  vpc_id          = data.terraform_remote_state.network-config.outputs.vpc_id
  subnets         = data.terraform_remote_state.network-config.outputs.public_subnets
  security_groups = [module.elb_sg.security_group_id] #Medha

  target_groups = [
    {
      name_prefix = "pref-"
      backend_protocol = "HTTP"
      backend_port = 80 # Medha
      health_check = {
        matcher = "200,302"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "Test"
  }
}

###########################################################################################################################
# Creating the RDS Database
# #########################################################################################################################
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 3.0"

  identifier = "mysql-db"

  engine              = "mysql"
  engine_version      = "5.7.19"
  instance_class      = "db.t2.micro"
  allocated_storage   = 5
  skip_final_snapshot = true

  name     = "demodb"
  username = "mysqluser"
  password = jsondecode(data.aws_secretsmanager_secret_version.secret_version.secret_string)["MyPassword"]
  port     = "3306"

  vpc_security_group_ids = [module.rds_sg.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"


  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  # DB subnet group
  subnet_ids = data.terraform_remote_state.network-config.outputs.private_subnets

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

}

###########################################################################################################################
# Creating the Route53 Record for the Domain
# ###########################################################################################################################
resource "aws_route53_record" "dns_val" {
  for_each = {
    for dvo in aws_acm_certificate.cloud99_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.cloud99.zone_id
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.cloud99.zone_id
  name    = "cloud99.click"
  type    = "A"

  alias {
    name                   = module.alb.lb_dns_name
    zone_id                = module.alb.lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "cloud99_cert" {
  domain_name       = "cloud99.click"
  validation_method = "DNS"

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cloud99_cert_val" {
  certificate_arn         = aws_acm_certificate.cloud99_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.dns_val : record.fqdn]
}
