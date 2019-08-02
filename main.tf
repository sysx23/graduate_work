variable "region" {
	type = string
	default = "eu-central-1"
}

variable "ami_id" {
	type = string
#	default = "ami-0cc293023f983ed53" # Amazon linux 2
	default = "ami-0badcc5b522737046" # RHEL 8
}

variable "ami_distribution" {
	type = string
	default = "RHEL"
}

variable "aws_keypair_name" {
	type = string
	default = "graduate_work"
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

variable "ansible_key_name" {
	type = string
	default = "ansible.rsa"
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
	enable_dns_hostnames = true
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
resource "aws_route" "default_route" {
	route_table_id = aws_vpc.graduate_work_vpc.main_route_table_id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.igw.id
}

resource "aws_s3_bucket" "ansible_pubkey" {
	force_destroy = true
	tags = merge(
		local.common_tags,
		{
			Name = "pubkey"
		}
	)
}

resource "aws_s3_bucket" "backup" {
	force_destroy = true
	tags = merge(
		local.common_tags,
		{
			Name = "backup"
		}
	)
}

resource "aws_security_group" "devtools" {
	vpc_id = aws_vpc.graduate_work_vpc.id
	name = "devtools_sg"
	ingress {
		cidr_blocks = ["0.0.0.0/0"]
		protocol = "tcp"
		from_port = "22"
		to_port = "22"
		description = "public ssh"
	}
	ingress {
		cidr_blocks = ["0.0.0.0/0"]
		protocol = "tcp"
		from_port = "8080"
		to_port = "8080"
		description = "public jenkins"
	}
	ingress {
		cidr_blocks = ["0.0.0.0/0"]
		protocol = "tcp"
		from_port = "8081"
		to_port = "8081"
		description = "public nexus"
	}
	tags = local.common_tags
}

resource "aws_security_group" "internal_ssh" {
	vpc_id = aws_vpc.graduate_work_vpc.id
	name = "internal_ssh"
	ingress {
		self = true
		protocol = "tcp"
		from_port = "22"
		to_port = "22"
	}
	tags = local.common_tags
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
	tags = local.common_tags
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
	tags = local.common_tags
}


data "aws_iam_policy_document" "rw_access_to_ansible_pubkey" {
	statement {
		actions = [
			"s3:GetObject",
			"s3:PutObject",
			"s3:DeleteObject"
		]
		resources = [
			"${aws_s3_bucket.ansible_pubkey.arn}/${var.ansible_key_name}.pub"
		]
	}
}

resource "aws_iam_policy" "rw_access_to_ansible_pubkey" {
	name_prefix = "write_access_to_ansible_pubkey-"
	policy = data.aws_iam_policy_document.rw_access_to_ansible_pubkey.json
}

data "aws_iam_policy_document" "rw_access_to_backup_bucket" {
	statement {
		actions = [
			"s3:Get*",
			"s3:ListBucket",
			"s3:Put*",
			"s3:Delete*"
		]
		resources = [
			"${aws_s3_bucket.backup.arn}/*"
		]
	}
}

resource "aws_iam_policy" "rw_access_to_backup_bucket" {
	name_prefix = "write_access_to_backup_bucket-"
	policy = data.aws_iam_policy_document.rw_access_to_backup_bucket.json
}

data "aws_iam_policy_document" "read_access_to_ansible_pubkey" {
	statement {
		actions = [
			"s3:GetObject"
		]
		resources = [
			"${aws_s3_bucket.ansible_pubkey.arn}/${var.ansible_key_name}.pub"
		]
	}
}

resource "aws_iam_policy" "read_access_to_ansible_pubkey" {
	name_prefix = "read_access_to_ansible_pubkey-"
	policy = data.aws_iam_policy_document.read_access_to_ansible_pubkey.json
}

data "aws_iam_policy_document" "get_tag_resources" {
	statement {
		actions = [
			"tag:getResources"
		]
		resources = [
			"*"
		]
	}
}

resource "aws_iam_policy" "get_tag_resources" {
	name_prefix = "get_tag_resources-"
	policy = data.aws_iam_policy_document.get_tag_resources.json
}
resource "aws_iam_role" "devtools" {
	name_prefix = "devtools-"
	assume_role_policy = file("ec2_assume_role.json")
	tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "devtools_rw_pubkey" {
	role = aws_iam_role.devtools.name
	policy_arn = aws_iam_policy.rw_access_to_ansible_pubkey.arn
}

resource "aws_iam_role_policy_attachment" "devtools_rw_backup" {
	role = aws_iam_role.devtools.name
	policy_arn = aws_iam_policy.rw_access_to_backup_bucket.arn
}

resource "aws_iam_role_policy_attachment" "devtools_get_tag_resource" {
	role = aws_iam_role.devtools.name
	policy_arn = aws_iam_policy.get_tag_resources.arn
}

resource "aws_iam_role_policy_attachment" "ec2_ro_for_ansible" {
	role = aws_iam_role.devtools.name
	policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "elastic_cache_ro_for_ansible" {
	role = aws_iam_role.devtools.name
	policy_arn = "arn:aws:iam::aws:policy/AmazonElastiCacheReadOnlyAccess"
}

resource "aws_iam_role" "qa" {
	name_prefix = "qa-"
	assume_role_policy = file("ec2_assume_role.json")
	tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "qa" {
	role = aws_iam_role.qa.name
	policy_arn = aws_iam_policy.read_access_to_ansible_pubkey.arn
}

resource "aws_iam_role" "ci" {
	name_prefix = "ci-"
	assume_role_policy = file("ec2_assume_role.json")
	tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ci" {
	role = aws_iam_role.ci.name
	policy_arn = aws_iam_policy.read_access_to_ansible_pubkey.arn
}

resource "aws_iam_instance_profile" "devtools" {
	name_prefix = "devtools-"
	role = aws_iam_role.devtools.name
}

resource "aws_iam_instance_profile" "ci" {
	name_prefix = "ci-"
	role = aws_iam_role.ci.name
}

resource "aws_iam_instance_profile" "qa" {
	name_prefix = "qa-"
	role = aws_iam_role.qa.name
}

resource "aws_instance" "devtools" {
	ami = var.ami_id
	instance_type = "t2.small"
	subnet_id = aws_subnet.default_sn.0.id
	key_name = var.aws_keypair_name
	associate_public_ip_address = true
	iam_instance_profile = aws_iam_instance_profile.devtools.name
	lifecycle {
		ignore_changes = [
			security_groups,
			user_data,
		]
	}
	security_groups = [
		aws_security_group.devtools.id,
		aws_security_group.internal_ssh.id,
		aws_security_group.allow_all_outgoing.id,
	]
	user_data = templatefile(
		"ansible.tt",
		{
			ssh_key = var.ansible_key_name
			s3_bucket = aws_s3_bucket.ansible_pubkey.bucket
			distribution = var.ami_distribution
		}
	)
	tags = merge(
		local.common_tags,
		{
			"Name" = "devtools"
			"jenkins" = ""
			"nexus" = ""
		}
	)
}

resource "aws_instance" "ci" {
	ami = var.ami_id
	instance_type = "t2.micro"
	subnet_id = aws_subnet.default_sn.0.id
	key_name = var.aws_keypair_name
	associate_public_ip_address = true
	iam_instance_profile = aws_iam_instance_profile.ci.name
	lifecycle {
		ignore_changes = [
			security_groups,
			user_data,
		]
	}
	security_groups = [
		aws_security_group.allow_http.id,
		aws_security_group.internal_ssh.id,
		aws_security_group.allow_all_outgoing.id,
	]
	user_data = templatefile(
		"node.tt",
		{
			ssh_key = var.ansible_key_name
			s3_bucket = aws_s3_bucket.ansible_pubkey.bucket
			distribution = var.ami_distribution
		}
	)
	tags = merge(
		local.common_tags,
		{
			"Name" = "ci"
		}
	)
}

resource "aws_instance" "qa" {
	ami = var.ami_id
	instance_type = "t2.micro"
	subnet_id = aws_subnet.default_sn.0.id
	key_name = var.aws_keypair_name
	associate_public_ip_address = true
	iam_instance_profile = aws_iam_instance_profile.qa.name
	lifecycle {
		ignore_changes = [
			security_groups,
			user_data,
		]
	}
	security_groups = [
		aws_security_group.allow_http.id,
		aws_security_group.internal_ssh.id,
		aws_security_group.allow_all_outgoing.id,
	]
	user_data = templatefile(
		"node.tt",
		{
			ssh_key = var.ansible_key_name
			s3_bucket = aws_s3_bucket.ansible_pubkey.bucket
			distribution = var.ami_distribution
		}
	)
	tags = merge(
		local.common_tags,
		{
			"Name" = "qa"
		}
	)
}

