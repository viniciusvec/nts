################################### VPC 
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  # enable_dns_support   = true
  # enable_dns_hostnames = true
}

# Subnets 
resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = var.availability_zones[2]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.availability_zones[0]
}

resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = var.availability_zones[1]
}

resource "aws_subnet" "private_subnet3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = var.availability_zones[2]
}

################################### Internet Gateway

# Internet Gateway 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}


# Public Route Table 
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
    # nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# Public Route Table Association 
resource "aws_route_table_association" "public_rt_assoc1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc3" {
  subnet_id      = aws_subnet.public_subnet3.id
  route_table_id = aws_route_table.public_rt.id
}

################################### VPC Endpoints

# data "aws_iam_policy_document" "s3_ecr_access" {
#   version = "2012-10-17"
#   statement {
#     sid     = "s3access"
#     effect  = "Allow"
#     actions = ["*"]

#     principals {
#       type        = "*"
#       identifiers = ["ecs-tasks.amazonaws.com"]
#     }
#   }
# }

# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.${var.region}.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = [aws_route_table.private_rt.id]
#   policy            = data.aws_iam_policy_document.s3_ecr_access.json
# # }

# resource "aws_vpc_endpoint" "ecr-dkr-endpoint" {
#   vpc_id              = aws_vpc.main.id
#   private_dns_enabled = true
#   service_name        = "com.amazonaws.${var.region}.ecr.dkr"
#   vpc_endpoint_type   = "Interface"
#   security_group_ids  = [aws_security_group.ecs_sg.id]
#   subnet_ids          = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id, aws_subnet.private_subnet3.id]
# }

# resource "aws_vpc_endpoint" "ecr-api-endpoint" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${var.region}.ecr.api"
#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = true
#   security_group_ids  = [aws_security_group.ecs_sg.id]
#   subnet_ids          = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id, aws_subnet.private_subnet3.id]
# }
# resource "aws_vpc_endpoint" "ecs-agent" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${var.region}.ecs-agent"
#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = true
#   security_group_ids  = [aws_security_group.ecs_sg.id]
#   subnet_ids          = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id, aws_subnet.private_subnet3.id]
# }

# resource "aws_vpc_endpoint" "ecs-telemetry" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${var.region}.ecs-telemetry"
#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = true
#   security_group_ids  = [aws_security_group.ecs_sg.id]
#   subnet_ids          = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id, aws_subnet.private_subnet3.id]

# }


################################### NAT gateway 
# Not needed for for private subnets - but code included for dev.

# Elastic IP for NAT Gateway 
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

# NAT Gateway 
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet1.id
}


# Private Route Table 
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# Private Route Table Association 
resource "aws_route_table_association" "private_rt_assoc1" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_assoc2" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_assoc3" {
  subnet_id      = aws_subnet.private_subnet3.id
  route_table_id = aws_route_table.private_rt.id
}
