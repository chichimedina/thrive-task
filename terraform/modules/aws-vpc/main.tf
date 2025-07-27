locals {

  tags = jsondecode(var.tags)

}


## VPC 
resource "aws_vpc" "vpc" {

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = local.tags

}

## Internet gateway for the public subnets
resource "aws_internet_gateway" "ig" {

  vpc_id = aws_vpc.vpc.id

  tags = local.tags
}

## Elastic IP for NAT
resource "aws_eip" "nat_eip" {

  domain     = "vpc"
  depends_on = [aws_internet_gateway.ig]

}

## Create a NAT gateway 
resource "aws_nat_gateway" "nat" {

  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(aws_subnet.public_subnet.*.id, 0)}"
  depends_on    = [aws_internet_gateway.ig]

  tags = local.tags

}

## Public subnet(s)
## The number of subnets dependes on the number of elements in the `public_subnets_cidr` variable
resource "aws_subnet" "public_subnet" {

  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(var.public_subnets_cidr)}"
  cidr_block              = "${element(var.public_subnets_cidr, count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true

  tags = local.tags

}

## Private subnet(s)
## The number of subnets dependes on the number of elements in the `private_subnets_cidr` variable
resource "aws_subnet" "private_subnet" {

  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(var.private_subnets_cidr)}"
  cidr_block              = "${element(var.private_subnets_cidr, count.index)}"
  availability_zone       = "${element(var.availability_zones,   count.index)}"
  map_public_ip_on_launch = false

  tags = local.tags

}

## Routing table for private subnet
resource "aws_route_table" "private" {

  vpc_id = aws_vpc.vpc.id
 
  tags = local.tags

}

## Routing table for public subnet
resource "aws_route_table" "public" {

  vpc_id = aws_vpc.vpc.id

  tags = local.tags

}

## Route for outbound traffic via Internet gateway
resource "aws_route" "public_internet_gateway" {

  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ig.id}"

}

## Route for outgoing traffic via Internet gateway
resource "aws_route" "private_nat_gateway" {

  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"

}

## Route table associations for the Public subnets
resource "aws_route_table_association" "public" {

  count          = "${length(var.public_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"

}

## Route table associations for the Private subnets
resource "aws_route_table_association" "private" {

  count          = "${length(var.private_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"

}

## Default Security Group for the VPC
resource "aws_security_group" "default" {

  name        = "${var.name}-sg-${var.environment}"
  description = "Default rules for inbound and outbound traffic"
  vpc_id      = "${aws_vpc.vpc.id}"
  depends_on  = [aws_vpc.vpc]
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }

  tags = local.tags

}

