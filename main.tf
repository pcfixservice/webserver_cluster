
####### path relative to the module itself - path.module for apache configuration ###############
#  data "template_file" "user_data" {
#  template = file("${path.module}/user-data.sh")
#
#  vars = {
#    server_port = var.server_port
#    db_address  = data.terraform_remote_state.db.outputs.address
#    db_port     = data.terraform_remote_state.db.outputs.port
#  }
#}

#For the User Data script, you need a path relative to the module itself, so you should use 
#path.module in the template_file data

##############################################################################
#this data source is to retrive read  only information from the remote terraform.tfstate

data "terraform_remote_state" "db" {
 backend = "s3"
 config = {
 bucket = var.db_remote_state_bucket
 key = var.db_remote_state_key
 region = "us-east-2"
 }
}


##################################  AUTO SCALING GROUP LAUNCH CONFIGURATION ####################

#ami-096fda3c22c1c990a us-east-1
#ami-0c55b159cbfafe1f0 us-east-2

resource "aws_launch_configuration" "asg_cluster_conf" {
  image_id        = var.image_id 
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.id]
#  user_data       = data.template_file.user_data.rendered
}


data "aws_vpc" "default" {                             #aws_vpc data source to look up the data for your default vpc
  default = true
}

data "aws_subnet_ids" "default" {                      #aws_subnet_ids data source
  vpc_id = data.aws_vpc.default.id
}

##################################  AUTO SCALING GROUP #####################################

resource "aws_autoscaling_group" "asg_cluster" {
  launch_configuration = aws_launch_configuration.asg_cluster_conf.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  target_group_arns    = [aws_lb_target_group.asg.arn]
  health_check_type    = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance" {             #security groups
  name = var.instance_security_group_name

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###############    LOAD BALANCER  to distribute traffic across the servers ###########################

resource "aws_lb" "asg_cluster_lb" {                   #ALB itself
  name               = var.alb_name
  load_balancer_type = "application" 
  subnets            = data.aws_subnet_ids.default.ids #configure the ALB to use all the subnets in the default VPC failover
  security_groups    = [aws_security_group.alb.id]
}


###############    local values to avoid others to override the values and keep the code dry  ###########################
locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}
#Local values allow you to assign a name to any Terraform expression,
#and to use that name throughout the module. These names are only
#visible within the module, so they will have no impact on other
#modules, and you can’t override these values from outside of themodule

################   LISTENER for the ALB on a specific port 80  and protocol 443  #####################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.asg_cluster_lb.arn
  port              = local.http_port
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}
                                  ##########  LISTENERS RULES FOR THE ALB   ##########

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}


######### SECURITY GROUPS by default AWS doesn't allow incoming and outgoing traffic  ###############################
# Their values are taken from the local values #

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}
#use always separate resources insteadof inline block, such as "allow_http_inbound" and "allow_all_outbound"
#this way the the module will be flexible enough to allow users to add custom rules from outside (outputs)

#######   TARGET GROUPS one or more servers that receive requests from the LB  ##########


resource "aws_lb_target_group" "asg" {    #should be in the aws_autoscaling_group resource so target group knows which EC2 Instances to send requests to
  name = var.alb_name
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {                      # the target group performs health check and only sends requests on healthy nodes
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


#  action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.asg.arn
#  }




 
