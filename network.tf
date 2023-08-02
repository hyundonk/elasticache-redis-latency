
module vpc-a {
  source = "./vpc/"

  vpc_address_range = var.vpc1.address_range
  availability_zones = var.vpc1.availability_zones
  
  name = var.vpc1.name
}

module vpc-b {
  source = "./vpc/"

  providers = {
    aws = aws.useast2
  }

  vpc_address_range = var.vpc2.address_range
  availability_zones = var.vpc2.availability_zones
  
  name = var.vpc2.name
}

resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = module.vpc-a.id
  peer_vpc_id = module.vpc-b.id

  peer_region = "us-east-2"
  auto_accept = false
}

resource "aws_route" "vpc-a" {
  count = length(var.vpc1.availability_zones)
  
  route_table_id = module.vpc-a.private_route_table_id[count.index]
  destination_cidr_block = var.vpc2.address_range

  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "vpc-a-public" {
  route_table_id = module.vpc-a.public_route_table_id
  destination_cidr_block = var.vpc2.address_range

  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}



resource "aws_vpc_peering_connection_accepter" "peer" {
  provider = aws.useast2

  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

resource "aws_route" "vpc-b" {
  provider = aws.useast2
  count = length(var.vpc2.availability_zones)

  route_table_id = module.vpc-b.private_route_table_id[count.index]
  
  destination_cidr_block = var.vpc1.address_range
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "vpc-b-public" {
  provider = aws.useast2

  route_table_id = module.vpc-b.public_route_table_id
  
  destination_cidr_block = var.vpc1.address_range
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

