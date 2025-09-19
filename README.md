# 🚀 Terraform Project with AWS Backend (S3 + DynamoDB)

## 📌 Objective
Set up a shared Terraform infrastructure on **AWS**, including:
- **IAM**: manage users and permissions
- **AWS CLI**: configure local access to AWS
- **S3**: store `terraform.tfstate`
- **DynamoDB**: manage Terraform locks
- **Terraform**: provision and manage cloud infrastructure as a team

---

## 1️⃣ AWS Preparation

### A. AWS Account
- Create an AWS account if not already done: [https://aws.amazon.com/](https://aws.amazon.com/).
- **Do not use the root account** for this project (only for billing).

### B. Create an IAM Group
1. AWS Console → **IAM → Groups → Create group**  
2. Name: `terraform-team`  
3. Attach a policy:
   - For demo/learning → `AdministratorAccess`  
   - For production → a custom policy restricted to S3 + DynamoDB  

### C. Create IAM Users
1. AWS Console → **IAM → Users → Add user**  
2. Example username: `firstname-lastname`  
3. Check:
   - **Password (AWS Management Console)** for web login  
   - **Access key (CLI)** for Terraform and AWS CLI  
4. Add the user to the `terraform-team` group  
5. Download the `.csv` file containing:
   - **AWS Access Key ID**
   - **AWS Secret Access Key**

---

## 2️⃣ AWS CLI Configuration

### Installation
- Mac/Linux:
  ```bash
  brew install awscli
  ```
- Windows: [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### Configuration
```bash
aws configure --profile firstname
```
Provide:
- Access Key ID → IAM key
- Secret Access Key → IAM secret
- Default region → `eu-west-3` (Paris)
- Default output format → `json`

### Verification
```bash
aws sts get-caller-identity --profile firstname
```
Expected output:
```json
{
  "UserId": "AIDAEXAMPLE12345",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/firstname-lastname"
}
```

---

## 3️⃣ Setting up the Terraform Backend

### A. Create S3 bucket
```bash
aws s3api create-bucket   --bucket terraform-backend-epitech-2025   --region eu-west-3   --create-bucket-configuration LocationConstraint=eu-west-3
```

Enable versioning:
```bash
aws s3api put-bucket-versioning   --bucket terraform-backend-epitech-2025   --versioning-configuration Status=Enabled   --region eu-west-3
```

### B. Create DynamoDB table
```bash
aws dynamodb create-table   --table-name terraform-locks   --attribute-definitions AttributeName=LockID,AttributeType=S   --key-schema AttributeName=LockID,KeyType=HASH   --billing-mode PAY_PER_REQUEST   --region eu-west-3
```

Verify:
```bash
aws dynamodb list-tables --region eu-west-3
```

---

## 4️⃣ Terraform Project Example

### Project structure
```
terraform-demo/
 ├── main.tf
 ├── variables.tf
 └── outputs.tf
```

### `main.tf`
```hcl
terraform {
  required_version = ">= 1.8.0"

  backend "s3" {
    bucket         = "terraform-backend-epitech-2025"
    key            = "state/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "example" {
  bucket = "terraform-demo-bucket-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}
```

### `variables.tf`
```hcl
variable "aws_region" {
  type    = string
  default = "eu-west-3"
}
```

### `outputs.tf`
```hcl
output "bucket_name" {
  value = aws_s3_bucket.example.bucket
}
```

---

## 5️⃣ Terraform Commands

Initialize the project:
```bash
terraform init
```

Check the execution plan:
```bash
terraform plan
```

Apply the configuration:
```bash
terraform apply
```
Confirm with `yes`.

---

## 6️⃣ Verification

- **AWS S3** → bucket `terraform-demo-bucket-xxxx` should be created.  
- **Backend S3** → file `state/terraform.tfstate` should appear in `terraform-backend-epitech-2025`.  
- **DynamoDB** → `terraform-locks` table should show entries during concurrent `apply`.  

---

## 7️⃣ Team Collaboration

1. Each member configures their IAM profile via:
   ```bash
   aws configure --profile firstname
   ```
2. Clone the `terraform-demo/` repo.  
3. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
   👉 Everyone will use the **same shared state**.

---

## ✅ Summary
- IAM: `terraform-team` group + IAM users.  
- AWS CLI: configured with IAM keys.  
- Backend: S3 bucket + DynamoDB table.  
- Terraform: project stores state in S3, manages locks via DynamoDB.  
- Teamwork: all members share the same Terraform state.
