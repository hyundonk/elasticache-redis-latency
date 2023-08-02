resource "aws_elasticache_subnet_group" "demo" {
  name       = "demo-subnet-group"
  subnet_ids = module.vpc-a.private_subnet_id
}

resource "aws_security_group" "cache" {
  name = "demo-cache-sg"
  vpc_id = module.vpc-a.id

  ingress {
    description = "allow from vpc"
    cidr_blocks = [
      var.vpc1.address_range,
      var.vpc2.address_range
    ]
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
  }
  ingress {
    description = "allow from vpc"
    cidr_blocks = [
      var.vpc1.address_range,
      var.vpc2.address_range
    ]
    from_port = 8
    to_port = 0
    protocol = "icmp"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id              = "demo-redis-cluster"
  engine                  = "redis"
  node_type               = "cache.t4g.micro"
  engine_version          = "5.0.6"
  num_cache_nodes         = 1
  parameter_group_name    = "default.redis5.0"
  port                    = 6379
  subnet_group_name       = aws_elasticache_subnet_group.demo.name
  security_group_ids      = [aws_security_group.cache.id]
  availability_zone      = var.vpc1.availability_zones[1]

  tags = {
    Name = "redis-cluster"
  }
}
