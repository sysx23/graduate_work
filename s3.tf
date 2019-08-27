
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

resource "aws_iam_policy" "rw_access_to_ansible_pubkey" {
  name_prefix = "write_access_to_ansible_pubkey-"
  policy      = data.aws_iam_policy_document.rw_access_to_ansible_pubkey.json
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
  policy      = data.aws_iam_policy_document.rw_access_to_backup_bucket.json
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
  policy      = data.aws_iam_policy_document.read_access_to_ansible_pubkey.json
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
