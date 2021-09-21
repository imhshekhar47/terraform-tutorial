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

    hs_common_tags = {
        maintainer = "imhshekhar47"
        site = var.env
    }

    aws_region_dtl = {
      availability_zones = [ 
          "us-west-2a", 
          "us-west-2b", 
          "us-west-2c", 
          "us-west-2d" 
        ]
      region = "us-west-2"
    }

    hs_environment_tag = var.env

    hs_vpc_dtl = {
        cidr_block = "10.0.0.0/16",
        subnet_count = 4
    }

    hs_vpc_subnets_dtl = [ 
        {
            isPublic = true
            name = "pub-hs-subnet",
            availability_zone = "us-west-2a"
        },
        {
            isPublic = false
            name = "pvt-hs-subnet",
            availability_zone = "us-west-2b"
        },
        {
            isPublic = false
            name = "pvt-hs-subnet",
            availability_zone = "us-west-2c"
        },
        {
            isPublic = false
            name = "pvt-hs-subnet",
            availability_zone = "us-west-2d"
        }      
    ]
}

