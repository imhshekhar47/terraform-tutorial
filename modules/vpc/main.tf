# Create hs-vpc
resource "aws_vpc" "hs_vpc" {
    cidr_block = var.hs_vpc_dtl.cidr_block

    tags = merge( var.hs_common_tags, {
        Name = var.hs_vpc_dtl.name,
    })
}

# Create hs-igw
resource "aws_internet_gateway" "hs_igw" {
    vpc_id = aws_vpc.hs_vpc.id 

    tags = merge(var.hs_common_tags, {
        Name = "${var.hs_environment_tag}-igw"
    })
}

resource "aws_subnet" "hs_pub_subnet" {
    count = length(var.hs_vpc_pub_subnets_dtl)
    
    vpc_id = aws_vpc.hs_vpc.id
    cidr_block = var.hs_vpc_pub_subnets_dtl[count.index].cidr_block
    availability_zone = var.hs_vpc_pub_subnets_dtl[count.index].availability_zone

    tags = merge(var.hs_common_tags, {
        Name = var.hs_vpc_pub_subnets_dtl[count.index].name
    })
}

# Create hs-natgw-eip
resource "aws_eip" "hs_natgw_eip" {
    count = var.hs_vpc_enable_nat_gateway ? length(var.hs_vpc_pub_subnets_dtl) : 0

    tags = merge(var.hs_common_tags, {
        Name = "${var.hs_environment_tag}-eip-${count.index}"
    })
}

# Create hs-nat-gw
resource "aws_nat_gateway" "hs_nat_gw" {
    count = var.hs_vpc_enable_nat_gateway ? length(var.hs_vpc_pub_subnets_dtl) : 0

    subnet_id = aws_subnet.hs_pub_subnet[count.index].id
    allocation_id = aws_eip.hs_natgw_eip[count.index].id

    tags = merge(var.hs_common_tags, {
        Name = "${var.hs_environment_tag}-nat-gw-${count.index}"
    })
}

resource "aws_subnet" "hs_pvt_subnet" {
    count = length(var.hs_vpc_pvt_subnets_dtl)
    
    vpc_id = aws_vpc.hs_vpc.id
    cidr_block = var.hs_vpc_pvt_subnets_dtl[count.index].cidr_block
    availability_zone = var.hs_vpc_pvt_subnets_dtl[count.index].availability_zone

    tags = merge(var.hs_common_tags, {
        Name = var.hs_vpc_pvt_subnets_dtl[count.index].name
    })
}

# Create a route table for public subnets
resource "aws_route_table" "hs_pub_route_table" {
    vpc_id = aws_vpc.hs_vpc.id

    tags = merge(var.hs_common_tags, {
        Name = "${var.hs_environment_tag}-pub-rt"
    })
}

# Add routes to hs_pub_route_table 
resource "aws_route" "hs_pub_route" {
    route_table_id = aws_route_table.hs_pub_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hs_igw.id
}

resource "aws_route_table_association" "hs_pub_subnet_association" {
    count = length(var.hs_vpc_pub_subnets_dtl)

    subnet_id = aws_subnet.hs_pub_subnet[count.index].id
    route_table_id = aws_route_table.hs_pub_route_table.id
}


# Create route tables for private subnets
resource "aws_route_table" "hs_pvt_route_table" {
    count = length(var.hs_vpc_pvt_subnets_dtl)

    vpc_id = aws_vpc.hs_vpc.id

    tags = merge(var.hs_common_tags, {
        Name = "${var.hs_environment_tag}-pvt-rt-${count.index}"
    })
}

# Add route to hs_pvt_route_table[*]
resource "aws_route" "hs_pvt_route" {
    count = var.hs_vpc_enable_nat_gateway ? length(var.hs_vpc_pvt_subnets_dtl) : 0

    route_table_id = aws_route_table.hs_pvt_route_table[count.index].id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hs_nat_gw[count.index].id
}

resource "aws_route_table_association" "hs_pvt_subnet_association" {
    count = length(var.hs_vpc_pvt_subnets_dtl)

    subnet_id = aws_subnet.hs_pvt_subnet[count.index].id
    route_table_id = aws_route_table.hs_pvt_route_table[count.index].id
}




