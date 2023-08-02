vpc1 = {
  name = "vpc-a(us-east-1)"
  address_range = "10.10.0.0/16"
  availability_zones = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c", "ap-northeast-2d"]
  #availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
}

vpc2 = {
  name = "vpc-b(us-east-2)"
  address_range = "10.20.0.0/16"
  availability_zones = ["us-east-2a", "us-east-2b"]
}

public_key="paste your ssh public key here"
