variable "environment_tag" {
    description = "Environment tag"
    type = string
}

variable "common_tags" {
    description = "Common tags."
    type = map(string)  
}


variable "ec2_bastion_dtl" {
    description = "Bation host details"

    type = object({
        name = string
        vpc_id = string
        subnet_id = string
        ami = string
        type = string
    })
}