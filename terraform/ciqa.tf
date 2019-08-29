
resource "aws_iam_role" "qa" {
  name_prefix        = "qa-"
  assume_role_policy = file("ec2_assume_role.json")
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "qa" {
  role       = aws_iam_role.qa.name
  policy_arn = aws_iam_policy.read_access_to_ansible_pubkey.arn
}

resource "aws_iam_role" "ci" {
  name_prefix        = "ci-"
  assume_role_policy = file("ec2_assume_role.json")
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ci" {
  role       = aws_iam_role.ci.name
  policy_arn = aws_iam_policy.read_access_to_ansible_pubkey.arn
}

resource "aws_iam_instance_profile" "ci" {
  name_prefix = "ci-"
  role        = aws_iam_role.ci.name
}

resource "aws_iam_instance_profile" "qa" {
  name_prefix = "qa-"
  role        = aws_iam_role.qa.name
}

resource "aws_instance" "ci" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.default_sn.0.id
  key_name                    = var.aws_keypair_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ci.name
  lifecycle {
    ignore_changes = [
      security_groups,
      user_data,
    ]
  }
  vpc_security_group_ids = [
    aws_security_group.allow_http.id,
    aws_security_group.internal_ssh.id,
    aws_security_group.allow_all_outgoing.id,
  ]
  user_data = templatefile(
    "ciqa.tt",
    {
      ssh_key      = var.ansible_key_name
      s3_bucket    = aws_s3_bucket.ansible_pubkey.bucket
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
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.default_sn.0.id
  key_name                    = var.aws_keypair_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.qa.name
  lifecycle {
    ignore_changes = [
      security_groups,
      user_data,
    ]
  }
  vpc_security_group_ids = [
    aws_security_group.allow_http.id,
    aws_security_group.internal_ssh.id,
    aws_security_group.allow_all_outgoing.id,
  ]
  user_data = templatefile(
    "ciqa.tt",
    {
      ssh_key      = var.ansible_key_name
      s3_bucket    = aws_s3_bucket.ansible_pubkey.bucket
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

