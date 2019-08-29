
variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "ami_id" {
  type = string
  #	default = "ami-0cc293023f983ed53" # Amazon linux 2
  default = "ami-0badcc5b522737046" # RHEL 8
}

variable "ami_distribution" {
  type    = string
  default = "RHEL"
}

variable "aws_keypair_name" {
  type    = string
  default = "graduate_work"
}

variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "vpc_subnets_availability_zones" {
  type = map(string)
  default = {
    "0" = "eu-central-1a",
  }
}

variable "ansible_key_name" {
  type    = string
  default = "ansible.rsa"
}


locals {
  common_tags = {
    Project = "graduate_work"
  }
}
