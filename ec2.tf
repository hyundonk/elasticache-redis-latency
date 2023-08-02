data "aws_ami" "al2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
        name   = "virtualization-type"
        values = ["hvm"]
  }

  filter {
        name   = "architecture"
        values = ["x86_64"]
  }

  owners = ["amazon"]
}

resource "random_string" "random_suffix" {
  length  = 3
  special = false
  upper   = false
}

resource "aws_key_pair" "deployer" {
  key_name    = "demo-key${random_string.random_suffix.result}"
  public_key  = var.public_key
}

resource "aws_security_group" "jumpbox" {
  lifecycle {
    ignore_changes = [
      ingress,
    ]
  }
 
  name = "jumpbox-sg"
  vpc_id = module.vpc-a.id

  egress {
    description = "ssh out"
    cidr_blocks = [
      var.vpc1.address_range,
      var.vpc2.address_range
    ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  tags = {
    name = "jumpbox securty_group"
  }
}


resource "aws_instance" "jumpbox" {
  lifecycle {
    ignore_changes = [
      security_groups,
    ]
  }


  ami           = data.aws_ami.al2023.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.jumpbox.id]

  subnet_id     = module.vpc-a.public_subnet_id[0]
  tags = {
    Name = "Demo jumpbox instance"
  }
}

resource "aws_eip" "jumpbox" {
  domain   = "vpc"
  instance                  = aws_instance.jumpbox.id
}

output "bastion_ip" {
  value = aws_eip.jumpbox.public_ip
}

resource "aws_security_group" "region1" {
  lifecycle {
    ignore_changes = [
 //     ingress,
    ]
  }

  name = "region1-sg"
  vpc_id = module.vpc-a.id

  ingress {
    description = "ssh in"
    cidr_blocks = [
      var.vpc1.address_range
    ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  egress {
    description = "ssh out"
    cidr_blocks = [
      var.vpc1.address_range
    ]
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
  }

  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    to_port   = 0
    protocol  = -1
  }

  ingress {
    cidr_blocks = [
      var.vpc1.address_range
    ]
    from_port = 8
    to_port   = 0
    protocol  = "icmp"
  }


  egress {
    cidr_blocks = [
      var.vpc2.address_range
      //"0.0.0.0/0"
    ]
    from_port = 8
    to_port   = 0
    protocol  = "icmp"
  }


  tags = {
    name = "sg for same region instances"
  }
}

resource "aws_instance" "instance" {
  count = length(var.vpc1.availability_zones)

  lifecycle {
    ignore_changes = [
      security_groups,
    ]
  }

  ami           = data.aws_ami.al2023.id
  instance_type = "m5.xlarge"
  key_name      = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.region1.id]

  subnet_id     = module.vpc-a.private_subnet_id[count.index]

  tags = {
    Name = "ec2 in private region1 in ${var.vpc1.availability_zones[count.index]} "
  }
}

/*
# resources in different region

resource "aws_key_pair" "deployer-us-east-2" {
  provider = aws.useast2
  key_name    = "demo-key${random_string.random_suffix.result}"
  public_key  = var.public_key
}


data "aws_ami" "al2023-us-east-2" {
  provider = aws.useast2
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
        name   = "virtualization-type"
        values = ["hvm"]
  }

  filter {
        name   = "architecture"
        values = ["x86_64"]
  }

  owners = ["amazon"]
}


resource "aws_security_group" "us-east-2" {
  provider = aws.useast2
  
  lifecycle {
    ignore_changes = [
    ]
  }

  name = "us-east-2-sg"
  vpc_id = module.vpc-b.id

  ingress {
    description = "ssh in"
    cidr_blocks = [
      var.vpc1.address_range,
      var.vpc2.address_range
    ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  egress {
    description = "ssh out"
    cidr_blocks = [
      var.vpc1.address_range
    ]
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
  }

  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    to_port   = 0
    protocol  = -1
  }

  ingress {
    cidr_blocks = [
      var.vpc1.address_range,
      var.vpc2.address_range
    ]
    from_port = 8
    to_port   = 0
    protocol  = "icmp"
  }


  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 8
    to_port   = 0
    protocol  = "icmp"
  }


  tags = {
    name = "sg for different region instances"
  }
}

resource "aws_instance" "different-region" {
  provider = aws.useast2
  
  lifecycle {
    ignore_changes = [
      security_groups,
    ]
  }

  ami           = data.aws_ami.al2023-us-east-2.id
  instance_type = "m5.xlarge"
  key_name      = aws_key_pair.deployer-us-east-2.key_name
  security_groups = [aws_security_group.us-east-2.id]

  subnet_id     = module.vpc-b.private_subnet_id[0]

  tags = {
    Name = "ec2 in private us-east-2a"
  }
}

resource "aws_security_group" "jumpbox-us-east-2" {
  provider = aws.useast2

  lifecycle {
    ignore_changes = [
    ]
  }
 
  name = "jumpbox-sg"
  vpc_id = module.vpc-b.id

  egress {
    description = "ssh out"
    cidr_blocks = [
      var.vpc1.address_range,
      var.vpc2.address_range
    ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  tags = {
    name = "jumpbox securty_group"
  }
}


resource "aws_instance" "jumpbox-us-east-2" {
  provider = aws.useast2
  lifecycle {
    ignore_changes = [
      security_groups,
    ]
  }


  ami           = data.aws_ami.al2023-us-east-2.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer-us-east-2.key_name
  security_groups = [aws_security_group.jumpbox-us-east-2.id]

  subnet_id     = module.vpc-b.public_subnet_id[0]
  tags = {
    Name = "Demo jumpbox instance"
  }
}

resource "aws_eip" "jumpbox-us-east-2" {
  provider = aws.useast2
  
  domain   = "vpc"
  instance                  = aws_instance.jumpbox-us-east-2.id
}

output "bastion_ip-us-east-2" {
  value = aws_eip.jumpbox-us-east-2.public_ip
}

*/
