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

# Call module vpc
module "vpc" {
    source = "./modules/vpc"

    common_tags = {
        maintainer = "imhshekhar47"
        site = var.env
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
        name = "${var.env}-primary-vpc"
        cidr_block = "10.0.0.0/16"
    }

    pub_subnets_dtl = [ 
        {
            name = "${var.env}-pub-subnet-a",
            availability_zone = "us-west-2a",
            cidr_block = "10.0.1.0/24"
        },
        {
            name = "${var.env}-pub-subnet-b",
            availability_zone = "us-west-2b",
            cidr_block = "10.0.2.0/24"
        }     
    ]

    pvt_subnets_dtl = [
        {
            name = "${var.env}-pvt-subnet-a",
            availability_zone = "us-west-2a",
            cidr_block = "10.0.11.0/24"
        },
        {
            name = "${var.env}-pvt-subnet-b",
            availability_zone = "us-west-2b",
            cidr_block = "10.0.21.0/24"
        } 
    ]

    enable_nat_gateway = false
    enable_cw_flow_logs = true
}

module "bastion" {
    source = "./modules/instances/bastion"

    environment_tag = var.env
    common_tags =  {
        maintainer = "imhshekhar47"
        site = var.env
    }
    ec2_bastion_dtl = {
        name = "bastion-host-1"
        vpc_id = module.vpc.o_vpc.id
        subnet_id = module.vpc.o_pub_subnets[0].id

        ami = "ami-03d5c68bab01f3496"
        type = "t2.micro"
    }
}


