provider "aws" {
    region = "us-west-1"
}
resource "aws_vpc" "myvpc" {
    cidr_block        = "10.0.0.0/16"
    instance_tenancy = "default"
    
    tags = {
        Name = "terraformvpc"
    }
}
resource "aws_subnet" "pubsub" {
    vpc_id     = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"

    tags = {
        Name = "publicsubnet"
    }
}
resource "aws_subnet" "prisub" {
    vpc_id     = aws_vpc.myvpc.id
    cidr_block = "10.0.2.0/24"

    tags = {
        Name = "privatesubnet"
    }
}
resource "aws_internet_gateway" "tigw" {
    vpc_id = aws_vpc.myvpc.vpc.id

    tags = { 
       Name = "IGW"
    }
}
resource "aws_route_table" "pubrt" {
    vpc_id = aws_vpc.myvpc.id

    route {
        cidr_block ="0.0.0.0/0"
        gateway_id = aws_internet_gateway.tigw.id
    }

    tags = {
        Name = "publicRT"
    }
}
resource "aws_route_table_association" "pubassociation" {
    subnet_id      = aws_subnet.pubsub.id
    route_table_id = aws_route_table.pubrt.id
}
resource "aws_eip" "eip" {
    vpc    = true
}
resource "aws_nat_gateway" "tnat" {s
    allocation_id = aws_eip.eip.id
    subnet_id     = aws_subnet.pubsub.id

    tags = {
        Name = "NGW"
    }
}
resource "aws_route_table" "privrt" {
    vpc_id = aws_vpc.myvpc.id

    route {
        cidr_black = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.tnat.id
    }

    tags = {
        Name ="privateRT"
    }
}
resource "aws_route_table_association" "privassociation" {
    subnet_id      = aws_subnet.prisub.id
    route_table_id = aws_route_table.pubrt.id
}
resource "aws_security_group" "allow_all" {
    name        = "allow_all"
    description = "Allo TLS inbound traffic"
    vpc_id      = aws_vpc.myvpc.id
    
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "allow_all"
    }
}
resource "aws_instance" "publicmachine" {
    ami                         = "ami-051317f1184dd6e92"
    instance_type               = "t2.micro"
    subnet_id                   = aws_subnet.pubsub.id
    key_name                    = "22022022"
    vpc_security_group_ids      = ["${aws_security_group.allow_all.id}"]
    associate_public_ip_address = true
}
resource "aws_instance" "private" {
    ami                         = "ami-051317f1184dd6e92"
    instance_type               = "t2.micro"
    subnet_id                   = aws_subnet.prisub.id
    key_name                    = "22022022"
    vpc_security_group_ids      = ["${aws_security_group.allow_all.id}"]

}