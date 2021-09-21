variable "hs_environment_tag" {
    description = "Environment details."

    type = string

    default = "dev"
}

variable "hs_common_tags" {
    description = "Common tags"

    type = map(string) 

    default = {
        maintainer = "hshekhar"
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
        cidr_block = string,
        subnet_count = number
    })
}

variable "hs_vpc_subnets_dtl" {
    description = "(optional) describe your variable"
    
    type = list(object({
        isPublic = bool,
        name = string
        availability_zone = string
    }))
}