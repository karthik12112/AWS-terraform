provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
}
#vpc

resource "aws_vpc" "vpc" {
  cidr_block       = "10.1.0.0/16"
}

#internet gateway

resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = "${aws_vpc.vpc.id}"
  }
}

#route table
resource "aws_route_table" "public" {
    vpc_id  = "${aws_vpc.vpc.id}"
    route {
         cidr_block = "10.0.1.0/24"
         gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }
}

#private route table

resource "aws_route_table" "private" {
  default_route_table_id = "${aws_vpc.default_route_table_id}"

  tags {
    Name = "main"
  }
}
#subnet public

resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1d"

  tags {
    Name = "public"
 }
}

resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "10.1.2.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1a"
  tags {
    Name = "private"
  }
}

#aasign route table to subnet

resource "aws_route_table_association" "public_subnet_eu_west_1a_association" {
    subnet_id = "${aws_subnet.public.id}"
    route_table_id = "${aws_route_table.public.id}"
}

#rds subnets group

resource "aws_db_subnet_group" "rds_subnetgroup" {
  name       = "rds_subnetgroup"
  subnet_ids = ["${aws_subnet.rds1.id}", "${aws_subnet.rds2.id}"]

  tags {
    Name = "My DB subnet group"
  }
}

#security group

resource "aws_security_group" "public" {
  name        = "sg_public"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#rds security group


resource "aws_security_group" "rds" {
  name = "sg_rds"
  description = "RDS Security Group"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = ["${aws_security_group.public.id}","${aws_security_group.public.id}"]
  }
}

#rds

resource "aws_db_instance" "db" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.6.17"
  instance_class       = "${var.db_instance_class}"
  name                 = "${var.dbname}"
  username             = "${var.dbname}"
  password             = "${var.dbpassword}"
  db_subnet_group_name = "${aws_db_subnet_group.rds_subnetgroup.name}"
  vpc_security_group_ids = ["${aws_security_group.RDS.id}"]
}


#keypair

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

