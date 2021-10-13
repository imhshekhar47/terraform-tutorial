variable "environment_tag" {
    description = "Environment tag"
    type = string
}

variable "common_tags" {
    description = "Common tags"
    type = map(string)
}

variable "uiapp_launch_tmpl_dtl" {
    description = "Launch template details for UI app"

    type = object({
        name: string
        vpc_id: string
        vpc_cidr_blocks: list(string)
        subnet_id: string
        ami_image: string
        instance_type: string
        availability_zones: list(string)
        allowed_ssh_sgs: list(string)
        alb_arn: string
    })
}

resource "tls_private_key" "ec2_pvt_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "ec2_app_key" {
  key_name = "app-key"
  public_key = tls_private_key.ec2_pvt_key.public_key_openssh

  tags = merge(var.common_tags, {
    Name = "app-key"
  })
}

# Generate key-pair file bastion-key.pem
resource "local_file" "ec2_app_key_file" {
  content = "${tls_private_key.ec2_pvt_key.private_key_pem}"
  filename = "app-key.pem"
  #file_permission = "0400"
  # provisioner "local-exec" {
  #   command = "chmod 400 bastion-key.pem"
  # }
}

resource "aws_security_group" "app_ui_sg" {
  name = "app-ui-sg"
  description = "Security group for app-ui"
  vpc_id = var.uiapp_launch_tmpl_dtl.vpc_id

  ingress {
    description = "Allow ssh from Bastion host"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = var.uiapp_launch_tmpl_dtl.allowed_ssh_sgs
  }

  ingress {
    description = "Allow http from VPC"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = var.uiapp_launch_tmpl_dtl.vpc_cidr_blocks
  }

  egress {
    description = "Allow all traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = merge(var.common_tags, {
    Name = "app-ui-sg"
  })
}

# resource "aws_security_group_rule" "app_ui_sg_ssh_rule" {
#     type = "ingress"
#     security_group_id = aws_security_group.app_ui_sg.id
#     description = "SSH from bastion"
#     from_port = 22
#     to_port = 22
#     protocol = "tcp"
#     #source_security_group_id = var.uiapp_launch_tmpl_dtl.allowed_ssh_sg
#     cidr_blocks = [ "0.0.0.0/0" ]
# }

# resource "aws_security_group_rule" "app_ui_sg_http_rule" {
#     type = "ingress"
#     security_group_id = aws_security_group.app_ui_sg.id
#     description = "HTTP from ALB"
#     from_port = 80
#     to_port = 80
#     protocol = "tcp"
#     source_security_group_id = var.uiapp_launch_tmpl_dtl.allowed_http_sg
# }

resource "aws_launch_template" "app_ui_launch_tmpl" {
    name_prefix = "app-ui-"   
    #name = var.uiapp_launch_tmpl_dtl.name
    image_id = var.uiapp_launch_tmpl_dtl.ami_image
    instance_type = var.uiapp_launch_tmpl_dtl.instance_type
    description = "This is launch template for app UI"
    key_name = aws_key_pair.ec2_app_key.key_name

    user_data = filebase64("${path.module}/boot.sh")

    network_interfaces {
        subnet_id = var.uiapp_launch_tmpl_dtl.subnet_id
        security_groups = [ aws_security_group.app_ui_sg.id ]
    }


    tags = merge(var.common_tags, {
        Name = "${var.environment_tag}-app-ui-tmpl"
    })   
}

resource "aws_lb_target_group" "app_ui_lb_tg" {
  name     = "app-ui-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.uiapp_launch_tmpl_dtl.vpc_id
}

resource "aws_lb_listener" "app_ui_listen_http" {
  load_balancer_arn = var.uiapp_launch_tmpl_dtl.alb_arn 
  port = 80
  protocol = "HTTP" 
  default_action {
    target_group_arn = aws_lb_target_group.app_ui_lb_tg.arn
    type = "forward"
  }
}

resource "aws_autoscaling_group" "app_ui_asg" {
    #availability_zones = var.uiapp_launch_tmpl_dtl.availability_zones
    desired_capacity = 2
    min_size = 2
    max_size = 4

    health_check_type = "ELB"

    target_group_arns = [ aws_lb_target_group.app_ui_lb_tg.arn ]

    launch_template {
        id = aws_launch_template.app_ui_launch_tmpl.id
        version = "$Latest"
    }

    lifecycle {
      create_before_destroy = true
    }

    tag {
      key = "Name"
      value = "${var.environment_tag}-app-ui-asg"
      propagate_at_launch = true
    }
}