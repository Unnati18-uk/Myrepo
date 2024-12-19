resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_subnet" "private_sub_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_sub_a_cidr
  availability_zone = var.az1
  tags = {
    Name = "${var.name}-private-sub-a"
  }
}

resource "aws_subnet" "private_sub_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_sub_b_cidr
  availability_zone = var.az2
  tags = {
    Name = "${var.name}-private-sub-b"
  }
}

resource "aws_subnet" "public_sub_a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_sub_a_cidr
  availability_zone       = var.az1
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-public-sub-a"
  }
}

resource "aws_subnet" "public_sub_b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_sub_b_cidr
  availability_zone       = var.az2
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-public-sub-b"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_default_route_table" "rt1" {
  default_route_table_id = aws_vpc.my_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "${var.name}-route-table"
  }
}

resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.name}-sg"
  }

  ingress {
    description = "allow SSH protocol"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow HTTP protocol"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


