variable "region" {
	type = string
	default = "eu-central-1"
}

variable "ami_id" {
	type = string
	default = "ami-0cc293023f983ed53"
}

variable "vpc_cidr" {
	type = string
	default = "172.16.0.0/16"
}

variable "vpc_subnets_availability_zones" {
	type = map(string)
	default = {
		"0" = "eu-central-1a",
	}
}

provider "aws" {
	region = var.region
}

locals {
	common_tags = {
		Project = "graduate_work"
	}
}

resource "aws_vpc" "graduate_work_vpc" {
	cidr_block = "${var.vpc_cidr}"
	tags = local.common_tags
}

resource "aws_internet_gateway" "igw" {
	vpc_id = aws_vpc.graduate_work_vpc.id
	tags = local.common_tags
}

resource "aws_subnet" "default_sn" {
	count = "1"
	vpc_id = aws_vpc.graduate_work_vpc.id
	cidr_block = "${cidrsubnet(aws_vpc.graduate_work_vpc.cidr_block,8,count.index)}"
	availability_zone = "${lookup(var.vpc_subnets_availability_zones, count.index)}"
	tags = local.common_tags
}

resource "aws_security_group" "allow_ssh" {
	vpc_id = aws_vpc.graduate_work_vpc.id
	name = "allow ssh"
	ingress {
		cidr_blocks = ["0.0.0.0/0"]
		protocol = "tcp"
		from_port = "22"
		to_port = "22"
	}
}

resource "aws_security_group" "allow_http" {
	vpc_id = aws_vpc.graduate_work_vpc.id
	name = "allow http"
	ingress {
		cidr_blocks = ["0.0.0.0/0"]
		protocol = "tcp"
		from_port = "80"
		to_port = "80"
	}
}

resource "aws_security_group" "allow_all_outgoing" {
	vpc_id = aws_vpc.graduate_work_vpc.id
	name = "allow all outgoing"
	egress {
		cidr_blocks = ["0.0.0.0/0"]
		protocol = "-1"
		from_port = "0"
		to_port = "0"
	}
}
