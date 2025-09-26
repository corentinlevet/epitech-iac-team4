# OPTIONAL: Import existing backend resources into Terraform state
# This lets Terraform be aware of the S3 backend bucket and DynamoDB lock table.
# WARNING: Do not rename/destroy these; they are protecting your state.

resource "aws_s3_bucket" "backend" {
  bucket = "terraform-backend-epitech-2025"
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Project   = var.project_id
    Component = "terraform-backend"
    Env       = "dev"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project   = var.project_id
    Component = "terraform-backend"
    Env       = "dev"
  }
}
