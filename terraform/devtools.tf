
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


resource "aws_iam_policy" "get_tag_resources" {
  name_prefix = "get_tag_resources-"
  policy      = data.aws_iam_policy_document.get_tag_resources.json
}

resource "aws_iam_role" "devtools" {
  name_prefix        = "devtools-"
  assume_role_policy = file("ec2_assume_role.json")
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "devtools_rw_pubkey" {
  role       = aws_iam_role.devtools.name
  policy_arn = aws_iam_policy.rw_access_to_ansible_pubkey.arn
}

resource "aws_iam_role_policy_attachment" "devtools_rw_backup" {
  role       = aws_iam_role.devtools.name
  policy_arn = aws_iam_policy.rw_access_to_backup_bucket.arn
}

resource "aws_iam_role_policy_attachment" "devtools_get_tag_resource" {
  role       = aws_iam_role.devtools.name
  policy_arn = aws_iam_policy.get_tag_resources.arn
}

resource "aws_iam_role_policy_attachment" "ec2_ro_for_ansible" {
  role       = aws_iam_role.devtools.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "elastic_cache_ro_for_ansible" {
  role       = aws_iam_role.devtools.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElastiCacheReadOnlyAccess"
}

resource "aws_iam_instance_profile" "devtools" {
  name_prefix = "devtools-"
  role        = aws_iam_role.devtools.name
}

resource "aws_instance" "devtools" {
  ami                         = var.ami_id
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.default_sn.0.id
  key_name                    = var.aws_keypair_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.devtools.name
  lifecycle {
    ignore_changes = [
      user_data,
    ]
  }
  vpc_security_group_ids = [
    aws_security_group.devtools.id,
    aws_security_group.internal_ssh.id,
    aws_security_group.allow_all_outgoing.id,
  ]
  user_data = templatefile(
    "ansible.tt",
    {
      ssh_key      = var.ansible_key_name
      s3_bucket    = aws_s3_bucket.ansible_pubkey.bucket
      distribution = var.ami_distribution
    }
  )
  tags = merge(
    local.common_tags,
    {
      "Name"    = "devtools"
      "jenkins" = ""
      "nexus"   = ""
    }
  )
}

