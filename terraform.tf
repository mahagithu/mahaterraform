# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}
# Create a VPC
resource "aws_vpc" "mahavpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc"
  }
}
#public subnet
resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.mahavpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public subnet"
  }
}
#private subnet
resource "aws_subnet" "prisub" {
  vpc_id     = aws_vpc.mahavpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private subnet"
  }
}
#igw
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mahavpc.id

  tags = {
    Name = "internet gateway"
  }
}
#public route table
resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.mahavpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public route table"
  }
}
#public route table association 
resource "aws_route_table_association" "pubrta" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id

}
#eip
resource "aws_eip" "eip" {
  vpc      = true


   tags = {
    Name = "eip"
   }
}
#nat
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "gw NAT"
  }
}
#private route table
resource "aws_route_table" "prirt" {
  vpc_id = aws_vpc.mahavpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private route table"
  }
}
#private route table association
resource "aws_route_table_association" "prirta" {
  subnet_id      = aws_subnet.prisub.id
  route_table_id = aws_route_table.prirt.id

}
#public sg
resource "aws_security_group" "pubsg" {
  name        = "pubsg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.mahavpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public sg"
  }
}
#private sg
resource "aws_security_group" "prisg" {
  name        = "prisg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.mahavpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["10.0.1.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private sg"
  }
}
#public instance
resource "aws_instance" "pub_instance" {
  ami                                                     = "ami-06c2ec1ceac22e8d6"
  instance_type                                   = "t2.micro"
  availability_zone                              = "ap-south-1b"
  associate_public_ip_address         = "true"
  vpc_security_group_ids                 = [aws_security_group.pubsg.id]
  subnet_id                                          = aws_subnet.pubsub.id 
  key_name                                         = "30/03"
  
    tags = {
    Name = "pub WEBSERVER"
  }
}
#private instance
resource "aws_instance" "pri_instance" {
  ami                                                     = "ami-06c2ec1ceac22e8d6"
  instance_type                                   = "t3.micro"
  availability_zone                              = "ap-south-1c"
  associate_public_ip_address         = "false"
  vpc_security_group_ids                 = [aws_security_group.prisg.id]
  subnet_id                                          = aws_subnet.prisub.id 
  key_name                                         = "30/03"
  
    tags = {
    Name = "pri APPSERVER"
  }
}
