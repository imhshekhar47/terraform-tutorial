# Create hs-vpc
resource "aws_vpc" "hs_vpc" {
    cidr_block = var.vpc_dtl.cidr_block

    tags = merge( var.common_tags, {
        Name = var.vpc_dtl.name,
    })
}

# Create hs-igw
resource "aws_internet_gateway" "hs_igw" {
    vpc_id = aws_vpc.hs_vpc.id 

    tags = merge(var.common_tags, {
        Name = "${var.environment_tag}-igw"
    })
}

resource "aws_subnet" "hs_pub_subnet" {
    count = length(var.pub_subnets_dtl)
    
    vpc_id = aws_vpc.hs_vpc.id
    cidr_block = var.pub_subnets_dtl[count.index].cidr_block
    availability_zone = var.pub_subnets_dtl[count.index].availability_zone

    tags = merge(var.common_tags, {
        Name = var.pub_subnets_dtl[count.index].name
    })
}

# Create hs-natgw-eip
resource "aws_eip" "hs_natgw_eip" {
    count = var.enable_nat_gateway ? length(var.pub_subnets_dtl) : 0

    tags = merge(var.common_tags, {
        Name = "${var.environment_tag}-eip-${count.index}"
    })
}

# Create hs-nat-gw
resource "aws_nat_gateway" "hs_nat_gw" {
    count = var.enable_nat_gateway ? length(var.pub_subnets_dtl) : 0

    subnet_id = aws_subnet.hs_pub_subnet[count.index].id
    allocation_id = aws_eip.hs_natgw_eip[count.index].id

    tags = merge(var.common_tags, {
        Name = "${var.environment_tag}-nat-gw-${count.index}"
    })
}

resource "aws_subnet" "hs_pvt_subnet" {
    count = length(var.pvt_subnets_dtl)
    
    vpc_id = aws_vpc.hs_vpc.id
    cidr_block = var.pvt_subnets_dtl[count.index].cidr_block
    availability_zone = var.pvt_subnets_dtl[count.index].availability_zone

    tags = merge(var.common_tags, {
        Name = var.pvt_subnets_dtl[count.index].name
    })
}

# Create a route table for public subnets
resource "aws_route_table" "hs_pub_route_table" {
    vpc_id = aws_vpc.hs_vpc.id

    tags = merge(var.common_tags, {
        Name = "${var.environment_tag}-pub-rt"
    })
}

# Add routes to hs_pub_route_table 
resource "aws_route" "hs_pub_route" {
    route_table_id = aws_route_table.hs_pub_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hs_igw.id
}

resource "aws_route_table_association" "hs_pub_subnet_association" {
    count = length(var.pub_subnets_dtl)

    subnet_id = aws_subnet.hs_pub_subnet[count.index].id
    route_table_id = aws_route_table.hs_pub_route_table.id
}


# Create route tables for private subnets
resource "aws_route_table" "hs_pvt_route_table" {
    count = length(var.pvt_subnets_dtl)

    vpc_id = aws_vpc.hs_vpc.id

    tags = merge(var.common_tags, {
        Name = "${var.environment_tag}-pvt-rt-${count.index}"
    })
}

# Add route to hs_pvt_route_table[*]
resource "aws_route" "hs_pvt_route" {
    count = var.enable_nat_gateway ? length(var.pvt_subnets_dtl) : 0

    route_table_id = aws_route_table.hs_pvt_route_table[count.index].id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hs_nat_gw[count.index].id
}

resource "aws_route_table_association" "hs_pvt_subnet_association" {
    count = length(var.pvt_subnets_dtl)

    subnet_id = aws_subnet.hs_pvt_subnet[count.index].id
    route_table_id = aws_route_table.hs_pvt_route_table[count.index].id
}

resource "aws_iam_role" "cw_access_role" {
    name = "cw-access-role"
    description = "The IAM role created to give access of Cloudwatch"

    assume_role_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "",
                "Effect" : "Allow",
                "Principal": {
                    "Service": "vpc-flow-logs.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    })
}

resource "aws_iam_role_policy" "cw_access_role_policy" {
    name = "cw-access-role-policy"
    role = aws_iam_role.cw_access_role.id

    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents",
                    "logs:DescribeLogGroups",
                    "logs:DescribeLogStreams"
                ],
                "Resource": "*"
            }
        ]
    })
}

resource "aws_cloudwatch_log_group" "vpc-cw-log-group" {
    name = "vpc-cw-log"

    tags = merge(var.common_tags, {
        Name = "vpc-cw-log"
    })
}


resource "aws_flow_log" "vpc-flow-log" {
    count = var.enable_cw_flow_logs ? 1 : 0

    iam_role_arn = aws_iam_role.cw_access_role.arn
    log_destination = aws_cloudwatch_log_group.vpc-cw-log-group.arn
    traffic_type = "ALL"
    vpc_id = aws_vpc.hs_vpc.id
}

resource "aws_security_group" "pub_alb_sg" {
    name = "${var.environment_tag}-pub-alb-sg"
    description = "Security group for the ALB"
    vpc_id = aws_vpc.hs_vpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    tags = merge(var.common_tags,  {
        Name = "${var.environment_tag}-pub-alb-sg"
    })
}

resource "aws_lb" "pub_alb" {
    count = var.enable_pub_alb ? 1 : 0

    name = "${var.environment_tag}-alb"
    internal = false
    load_balancer_type = "application"

    security_groups = [
        aws_security_group.pub_alb_sg.id
    ]

    subnets = aws_subnet.hs_pub_subnet[*].id

    # TODO: Add access log monitorng

    tags = merge(var.common_tags, {
        "Name" = "${var.environment_tag}-pub-alb"
    })
}

