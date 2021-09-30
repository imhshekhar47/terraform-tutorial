variable "hs_environment_tag" {
    description = "Environment details."

    type = string

    default = "dev"
}

variable "hs_common_tags" {
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

variable "hs_vpc_dtl" {
    description = "Details for the vpc."
    type = object({
        name = string
        cidr_block = string
    })
}

variable "hs_vpc_pub_subnets_dtl" {
    description = "Public subnet details"
    
    type = list(object({
        name = string
        cidr_block = string
        availability_zone = string
    }))
}

variable "hs_vpc_pvt_subnets_dtl" {
    description = "Private subnet details"
    
    type = list(object({
        name = string
        cidr_block = string
        availability_zone = string
    }))
}

variable "hs_vpc_enable_nat_gateway" {
    description = "Should the NAT gateway be created"

    type = bool

    default = false
}