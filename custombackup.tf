provider "aws" {
  region = "us-east-1"
}

# Create an S3 bucket to store backup files
resource "aws_s3_bucket" "backup_bucket" {
  bucket = "my-backup-bucket"
}

# Create a lifecycle policy for the backup files
resource "aws_s3_bucket_lifecycle_configuration" "backup_lifecycle" {
  rule {
    id      = "move-to-glacier"
    status  = "Enabled"
    prefix  = "backup/"
    enabled = true

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    filter {
      prefix = "backup/"
      tags = {
        "backup-size" = "large"
      }

      filter {
        prefix = ""
        content_length_range {
          min = 100000000 # 100 MB in bytes
        }
      }
    }
  }

  depends_on = [aws_s3_bucket.backup_bucket]
}

# Upload backup files to the S3 bucket
resource "aws_s3_bucket_object" "backup_file" {
  bucket = aws_s3_bucket.backup_bucket.bucket
  key    = "backup/my-backup-file"
  source = "/path/to/local/backup/file"

  tags = {
    "backup-size" = "large"
  }
}

# Keep a copy of the backup file with the highest size
data "aws_s3_bucket_objects" "backup_files" {
  bucket = aws_s3_bucket.backup_bucket.bucket
  prefix = "backup/"

  dynamic "filter" {
    for_each = var.tf
    content {
      prefix = filter.value
    }
  }
}

locals {
  max_size = 0
  max_key = ""

  for obj in data.aws_s3_bucket_objects.backup_files.objects {
    if obj.size > local.max_size {
      local.max_size = obj.size
      local.max_key = obj.key
    }
  }

  large_backups = [for obj in data.aws_s3_bucket_objects.backup_files.objects : obj.key if obj.size > 100000000]
}

}

resource "aws_s3_bucket_object" "backup_file_copy" {
  bucket = aws_s3_bucket.backup_bucket.bucket
  key    = "backup/my-backup-file-copy"
  copy_source = "${aws_s3_bucket_object.backup_file.bucket}/${local.max_key}"

  tags = {
    "backup-size" = "large"
  }
}

# Configure Glacier storage class for the backup files
resource "aws_glacier_vault" "backup_glacier_vault" {
  name = "my-backup-glacier-vault"
}

resource "aws_s3_bucket_object" "backup_file_glacier" {
  bucket = aws_glacier_vault.backup_glacier_vault.arn
  key    = "backup/my-backup-file"
  copy_source = "${aws_s3_bucket_object.backup_file.bucket}/${aws_s3_bucket_object.backup_file.key},${aws_s3_bucket_object.backup_file_copy.bucket}/${aws_s3_bucket_object.backup_file_copy.key}"
  storage_class = "GLACIER"

  depends_on = [aws_s3_bucket_object.backup_file, aws_s3_bucket_object.backup_file_copy]
}

output "large_backup_files" {
  value = local.large_backups
}
