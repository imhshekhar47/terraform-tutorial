variable "environment_tag" {
    description = "Environment tag (example dev/prod/test)."

    type = string

    default = "dev"
}

variable "common_tags" {
    description = "Common tags"

    type = map(string) 

    default = {
        maintainer = "imhshekhar47"
    }
}

variable "aws_region_dtl" {
    description = "AWS Region details."

    type = object({
        region = string
        availability_zones = list(string)
    })
}

variable "vpc_dtl" {
    description = "Details for the vpc."
    type = object({
        name = string
        cidr_block = string
    })
}

variable "pub_subnets_dtl" {
    description = "Public subnet details"
    
    type = list(object({
        name = string
        cidr_block = string
        availability_zone = string
    }))
}

variable "pvt_subnets_dtl" {
    description = "Private subnet details"
    
    type = list(object({
        name = string
        cidr_block = string
        availability_zone = string
    }))
}

variable "enable_nat_gateway" {
    description = "Should the NAT gateway be created"
    type = bool
    default = false
}

variable "enable_cw_flow_logs" {
    description = "Enable cloudwatch flow logs for VPC"
    type = bool
    default = false
  
}