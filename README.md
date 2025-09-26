# 🚀 Terraform Project with AWS Backend (S3 + DynamoDB) — Updated

## 📌 Objective
Set up a shared Terraform infrastructure on **AWS**, including:
- **IAM**: manage users and permissions
- **AWS CLI**: configure local access to AWS
- **S3**: store `terraform.tfstate`
- **DynamoDB**: manage Terraform locks
- **Terraform**: provision and manage VPC + Subnet collaboratively

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

---

## 3️⃣ Backend Setup (S3 + DynamoDB)

Create S3 bucket:
```bash
aws s3api create-bucket   --bucket terraform-backend-epitech-2025   --region eu-west-3   --create-bucket-configuration LocationConstraint=eu-west-3
```

Enable versioning:
```bash
aws s3api put-bucket-versioning   --bucket terraform-backend-epitech-2025   --versioning-configuration Status=Enabled   --region eu-west-3
```

Create DynamoDB table:
```bash
aws dynamodb create-table   --table-name terraform-locks   --attribute-definitions AttributeName=LockID,AttributeType=S   --key-schema AttributeName=LockID,KeyType=HASH   --billing-mode PAY_PER_REQUEST   --region eu-west-3
```

---

## 4️⃣ Terraform Project Structure

```
terraform-vpc/
 ├── main.tf
 ├── networking.tf
 ├── variables.tf
 ├── outputs.tf
 ├── dev.tfvars
 └── backends/dev.config
```

Initialize Terraform:
```bash
terraform init -backend-config=backends/dev.config
```

Plan and apply:
```bash
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

Check outputs:
```bash
terraform output
```

---

## 5️⃣ Import Backend Resources (if created manually)

```bash
terraform import -var-file=dev.tfvars aws_s3_bucket.backend terraform-backend-epitech-2025
terraform import -var-file=dev.tfvars aws_dynamodb_table.terraform_locks terraform-locks
```

Recheck plan:
```bash
terraform plan -var-file=dev.tfvars
```

Expected: no changes.

---

## 6️⃣ Safe Destroy & Recreate Cycle

Because the backend has `prevent_destroy = true` for safety, you should only destroy **VPC and Subnet**, not the backend.

### Destroy only VPC and Subnet
```bash
terraform destroy -var-file=dev.tfvars   -target=aws_subnet.main   -target=aws_vpc.main
```

### Or quicker (destroy VPC → subnet goes with it)
```bash
terraform destroy -var-file=dev.tfvars -target=aws_vpc.main
```

### Recreate
```bash
terraform apply -var-file=dev.tfvars
```

---

## ✅ Checklist

- [x] IAM group & users created  
- [x] AWS CLI configured with IAM keys  
- [x] S3 backend bucket + DynamoDB table created  
- [x] Terraform initialized with remote backend  
- [x] VPC + Subnet provisioned  
- [x] Backend imported & protected (`prevent_destroy`)  
- [x] Safe destroy/recreate workflow tested  
