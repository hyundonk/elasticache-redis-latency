
resource "aws_vpc" "demo" {
  cidr_block = var.vpc_address_range
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.demo.id
  cidr_block = cidrsubnet(aws_vpc.demo.cidr_block, 8, count.index + 1)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name} public subnet for ${var.availability_zones[count.index]}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  cidr_block = cidrsubnet(aws_vpc.demo.cidr_block, 8, count.index + 101)
  vpc_id = aws_vpc.demo.id
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name} private subnet for ${var.availability_zones[count.index]}"
  }

}

resource "aws_eip" "nat" {
  count = length(var.availability_zones)
  domain   = "vpc"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name} eip for NAT gateway in ${var.availability_zones[count.index]}"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count = length(var.availability_zones)
  
  allocation_id = element(aws_eip.nat.*.id, count.index)

  subnet_id = element(aws_subnet.public.*.id, count.index)

  tags = {
    Name = "${var.name} nat-gateway in ${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table" "private" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "${var.name} route table for private subnets"
  }
}

resource "aws_route" "private" {
  count = length(var.availability_zones)

  route_table_id              = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block      = "0.0.0.0/0"
  nat_gateway_id              = element(aws_nat_gateway.nat_gateway.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.demo.id
  tags = {
    Name = "${var.name} Internet Gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.demo.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo.id
  }
  tags = {
    Name = "${var.name} route table for public subnets"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}
