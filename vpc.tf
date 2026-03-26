resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = merge(local.common_tags, {Name = "${local.project}-vpc"})
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.common_tags, {Name = "${local.project}-igw"})
}

# Public Subnet (Web Tier - AZ1 and AZ2)
resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {Name = "${local.project}-public-subnet-${count.index + 1}"
  Tier = "Web"})
}

# Private Subnet (App Tier - AZ1 and AZ2)
resource "aws_subnet" "private_app" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {Name = "${local.project}-private-app-subnet-${count.index + 1}"
  Tier = "App"})
}

# Private Subnet (DB Tier)
resource "aws_subnet" "private_db" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_db_subnet_cidr[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {Name = "${local.project}-private-db-subnet-${count.index + 1}"
  Tier = "Database"})
}

# Public route table - Internet Gateway
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = merge(local.common_tags, {Name = "${local.project}-public-rt"})
}

resource "aws_route_table_association" "public" {
    count = 2
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.common_tags, {Name = "${local.project}-private-rt"})
}

resource "aws_route_table_association" "private_app" {
    count = 2
    subnet_id = aws_subnet.private_app[count.index].id
    route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_db" {
    count = 2
    subnet_id = aws_subnet.private_db[count.index].id
    route_table_id = aws_route_table.private.id
}