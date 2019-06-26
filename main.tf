variable "region" {
	type = string
	default = "eu-central-1"
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

resource "aws_vpc" "graduate-work-vpc" {
	cidr_block = "${var.vpc_cidr}"
}

resource "aws_subnet" "graduate-work-sn-a" {
	count = "1"
	vpc_id = aws_vpc.graduate-work-vpc.id
	cidr_block = "${cidrsubnet(aws_vpc.graduate-work-vpc.cidr_block,8,count.index)}"
	availability_zone = "${lookup(var.vpc_subnets_availability_zones, count.index)}"
}

