output "o_vpc" {
    value = aws_vpc.hs_vpc
}

output "o_pub_subnets" {
    value = aws_subnet.hs_pub_subnet
}

output "o_pvt_subnets" {
    value = aws_subnet.hs_pvt_subnet
}