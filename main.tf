resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = var.env_code
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_cidr[count.index]

  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.env_code}-public-${(count.index)+1}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_cidr)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_cidr[count.index]

  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.env_code}-private-${(count.index)+1}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env_code}-main_GW"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id 
  }

  tags = {
    Name = "${var.env_code}-public_RT"
  }  
}

resource "aws_route_table_association" "public" {
  count = length(var.public_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count = length(var.public_cidr)
  vpc      = true

  tags = {
    Name = "${var.env_code}-nat${(count.index)+1}_eip"
  }  
}

resource "aws_nat_gateway" "nat" {
  count = length(var.public_cidr)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.env_code}-nat${(count.index)+1}_GW"
  }  
}

resource "aws_route_table" "private" {
  count = length(var.private_cidr)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "${var.env_code}-private${(count.index)+1}_RT"
  }  
}

resource "aws_route_table_association" "private" {
  count = length(var.private_cidr)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
