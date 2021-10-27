terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Configure Common variables for reusability
variable "env" {
  default = "dev"
}

variable "config" {
  type = object({
    is_vpc_flow_logs_enabled = bool
    is_vpc_nat_gw_enabled    = bool
    is_vpc_alb_enabled       = bool
  })

  default = {
    is_vpc_flow_logs_enabled = false
    is_vpc_nat_gw_enabled    = true
    is_vpc_alb_enabled       = true
  }
}


# Create VPC and networking
module "vpc" {
  source = "./modules/vpc"

  common_tags = {
    maintainer = "imhshekhar47"
    site       = var.env
  }

  aws_region_dtl = {
    region = "us-west-2"

    availability_zones = [
      "us-west-2a",
      "us-west-2b",
      "us-west-2c",
      "us-west-2d"
    ]
  }

  environment_tag = var.env

  vpc_dtl = {
    name       = "${var.env}-primary-vpc"
    cidr_block = "10.0.0.0/16"
  }

  pub_subnets_dtl = [
    {
      name              = "${var.env}-pub-subnet-a",
      availability_zone = "us-west-2a",
      cidr_block        = "10.0.1.0/24"
    },
    {
      name              = "${var.env}-pub-subnet-b",
      availability_zone = "us-west-2b",
      cidr_block        = "10.0.2.0/24"
    }
  ]

  pvt_subnets_dtl = [
    {
      name              = "${var.env}-pvt-subnet-a",
      availability_zone = "us-west-2a",
      cidr_block        = "10.0.11.0/24"
    },
    {
      name              = "${var.env}-pvt-subnet-b",
      availability_zone = "us-west-2b",
      cidr_block        = "10.0.21.0/24"
    }
  ]


  enable_nat_gateway = var.config.is_vpc_nat_gw_enabled
  enable_pub_alb     = var.config.is_vpc_alb_enabled

  enable_cw_flow_logs = var.config.is_vpc_flow_logs_enabled
}

# Create a bastion host
# module "bastion" {
#   source = "./modules/instances/bastion"

#   environment_tag = var.env
#   common_tags = {
#     maintainer = "imhshekhar47"
#     site       = var.env
#   }
#   ec2_bastion_dtl = {
#     name      = "bastion-host-1"
#     vpc_id    = module.vpc.o_vpc.id
#     subnet_id = module.vpc.o_pub_subnets[0].id

#     ami  = "ami-03d5c68bab01f3496"
#     type = "t2.micro"
#   }
# }


# Create autoscalable application 
/*
module "app-ui" {
    source          = "./modules/instances/app-ui"
    environment_tag = var.env
    
    common_tags = {
        maintainer = "imhhekhar47"
        site       = var.env
    }

    uiapp_launch_tmpl_dtl = {
        name              = "api-629"
        vpc_id            = module.vpc.o_vpc.id
        vpc_cidr_blocks   = [module.vpc.o_vpc.cidr_block]
        subnet_id         =  module.vpc.o_pub_subnets[0].id
        availability_zones = [  module.vpc.o_pub_subnets[0].availability_zone_id ]
        ami_image         = "ami-09ff48b076eaf6a2b"
        instance_type     = "t2.micro"
        allowed_ssh_sgs    = tolist(module.bastion.o_bastion_instance.security_groups)
        alb_arn           = module.vpc.o_pub_alb.arn
    }
}
*/

module "eks" {
  depends_on = [
    module.vpc,
  ]
  source = "./modules/eks"

  common_tags = {
    "module" = "eks"
    "site"   = var.env
  }

  eks_dtl = {
    name       = "eks-cluster"
    vpc_id     = module.vpc.o_vpc.id
    subnet_ids = module.vpc.o_pvt_subnets[*].id
  }

}

variable "db_password" {
  type = string
}

module "db" {
  source = "./modules/db"

  common_tags = {
    module = "db"
    site  = var.env
  }

  db_dtl = {
    availability_zone = "us-west-2a"
    subnet_ids = module.vpc.o_pvt_subnets[*].id
    db_password = var.db_password
  }
}