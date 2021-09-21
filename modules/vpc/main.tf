# Create hs-vpc
resource "aws_vpc" "hs_vpc" {
    cidr_block = var.hs_vpc_dtl.cidr_block

    tags = merge( var.hs_common_tags, {
        Name = "${var.hs_environment_tag}-hs-vpc",
    })
}


resource "aws_subnet" "hs_subnet" {
    count = var.hs_vpc_dtl.subnet_count
    
    vpc_id = aws_vpc.hs_vpc.id
    cidr_block = cidrsubnet(var.hs_vpc_dtl.cidr_block, 8, count.index)
    availability_zone = var.hs_vpc_subnets_dtl[count.index].availability_zone

    tags = merge(var.hs_common_tags, {
        Name = "${var.hs_environment_tag}-${var.hs_vpc_subnets_dtl[count.index].name}-${count.index}"
    })

}

