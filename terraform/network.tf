
provider "aws" {
  region = var.region
}

resource "aws_vpc" "graduate_work_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags                 = local.common_tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.graduate_work_vpc.id
  tags   = local.common_tags
}

resource "aws_subnet" "default_sn" {
  count             = "1"
  vpc_id            = aws_vpc.graduate_work_vpc.id
  cidr_block        = "${cidrsubnet(aws_vpc.graduate_work_vpc.cidr_block, 8, count.index)}"
  availability_zone = "${lookup(var.vpc_subnets_availability_zones, count.index)}"
  tags              = local.common_tags
}
resource "aws_route" "default_route" {
  route_table_id         = aws_vpc.graduate_work_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_security_group" "devtools" {
  vpc_id = aws_vpc.graduate_work_vpc.id
  name   = "devtools_sg"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = "22"
    to_port     = "22"
    description = "public ssh"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = "8080"
    to_port     = "8080"
    description = "public jenkins"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = "8081"
    to_port     = "8081"
    description = "public nexus"
  }
  tags = local.common_tags
}

resource "aws_security_group" "internal_ssh" {
  vpc_id = aws_vpc.graduate_work_vpc.id
  name   = "internal_ssh"
  ingress {
    self      = true
    protocol  = "tcp"
    from_port = "22"
    to_port   = "22"
  }
  tags = local.common_tags
}

resource "aws_security_group" "allow_http" {
  vpc_id = aws_vpc.graduate_work_vpc.id
  name   = "allow http"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = "80"
    to_port     = "80"
  }
  tags = local.common_tags
}

resource "aws_security_group" "allow_all_outgoing" {
  vpc_id = aws_vpc.graduate_work_vpc.id
  name   = "allow all outgoing"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = "0"
    to_port     = "0"
  }
  tags = local.common_tags
}
