terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}
# create vpc 
resource "aws_vpc" "mounikavpc" {
  cidr_block = "10.0.0.0/16"
}
# Create an internet gateway
resource "aws_internet_gateway" "mounikagw" {
  vpc_id = aws_vpc.mounikavpc.id
  tags = {
    Name = "gateway1"
  }
}
# Create a custom Route Table
resource "aws_route_table" "mounika-rt" {
  vpc_id = aws_vpc.mounikavpc.id
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mounikagw.id
}
    tags = {
     Name = "mounika-rt1"
    }
}
# Create a Subnet
resource "aws_subnet" "mounika-subnet" {
  vpc_id     = aws_vpc.mounikavpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "subnet1"
  }
}
# Associate the Subnet with the Route Table
resource "aws_route_table_association" "mounika-rt-sub-assoc" {
  subnet_id      = aws_subnet.mounika-subnet.id
  route_table_id = aws_route_table.mounika-rt.id
}
# Create a security group 
resource "aws_security_group" "mounika-sg" {
  name        = "mounika-sg"
  description = "Enable web traffic for the project"
  vpc_id      = aws_vpc.mounikavpc.id
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
}
 egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
}
  ingress {
    description = "HTTPS traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
 }
  ingress {
    description = "HTTPS traffic"
    from_port        = 0
    to_port          = 6500
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
 }
  ingress {
    description = "HTTPS traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
 }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 tags = {
    Name = "mounika-sg1"
  }
}
 # Network Interface Setup
resource "aws_network_interface" "mounika-ni" {
  subnet_id       = aws_subnet.mounika-subnet.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.mounika-sg.id]
 }
 # Attach an elastic Ip to network interface 
resource "aws_eip" "mounika-eip" {
 vpc = true
network_interface = aws_network_interface.mounika-ni.id
associate_with_private_ip ="10.0.1.10"
 }
 # Creating an ubuntu EC2 instance
resource "aws_instance" "prod-server" {
  ami = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1b"
  key_name = "project"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.mounika-ni.id
  }
  user_data = <<-EOF
  #!/bin/bash
     sudo apt-get update -y
     sudo apt install docker.io -y
   https://docs.google.com/document/d/1nn6X6jSoZvDc_WXRtuqeiS1kJSOj1SJH/edit?usp=drive_link&ouid=103157204066713600014&rtpof=true&sd=true
  sudo systemctl enable docker
     sudo docker run -itd -p 8085:8081 thtmounikadocker/mentorbank:1
     sudo docker start $(docker ps -aq)
  EOF
  tags = {
    Name = "prod-server"
  }
  }
