# Course 2: Hands-On Testing Guide

This guide implements the practical exercises from C2.md for hands-on Terraform learning.

## 🎯 Learning Objectives (C2.md)

By completing this guide, you will:
- ✅ Deploy a VPC and subnet on AWS using Terraform
- ✅ Use a remote backend for Terraform state management
- ✅ Test your setup locally with reproducible and disposable infrastructure
- ✅ Learn to import, destroy, and redeploy infrastructure with commands

## 📋 Prerequisites Checklist

### Local Tools (Required)
```bash
# Check if tools are installed
terraform version    # Should show v1.0+
git --version        # Any recent version
aws --version        # AWS CLI v2+
```

### AWS Setup
```bash
# Configure AWS credentials (never hardcode!)
aws configure
# Enter your Access Key ID
# Enter your Secret Access Key  
# Default region: us-east-1
# Default output format: json

# Verify credentials work
aws sts get-caller-identity
```

### Project Setup
```bash
# Clone the repository
git clone <repository-url>
cd IaC

# Verify project structure
ls -la terraform/
```

## 🚀 Step-by-Step Implementation

### Step 1: Backend Setup (Manual Creation Required)

As specified in C2.md, the backend bucket must be created before `terraform init`:

```bash
# Option 1: Use our automated script (recommended)
./scripts/setup-backend.sh

# Option 2: Manual creation
aws s3 mb s3://student-team4-terraform-state --region us-east-1
aws s3api put-bucket-versioning \
  --bucket student-team4-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### Step 2: Local Setup Testing (C2.md Section 6)

Navigate to the Terraform environment:
```bash
cd terraform/environments
```

#### 2.1 Initialize Terraform
```bash
terraform init -backend-config="../backends/dev.config"
```

Expected output:
```
Initializing the backend...
Successfully configured the backend "s3"!
Initializing provider plugins...
Terraform has been successfully initialized!
```

#### 2.2 Plan Infrastructure
```bash
terraform plan -var-file=dev.tfvars
```

Expected output shows:
- VPC creation
- Subnet creation  
- Internet Gateway creation
- Route Table creation
- Route Table Association

#### 2.3 Deploy Dev Environment
```bash
terraform apply -var-file=dev.tfvars
```

Type `yes` when prompted. Expected outputs:
```
vpc_id = "vpc-123456789abcdef0"
subnet_id = "subnet-123456789abcdef0" 
internet_gateway_id = "igw-123456789abcdef0"
availability_zone = "us-east-1a"
```

#### 2.4 Verify Infrastructure
```bash
# Check VPC exists
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=student-team4-dev-vpc"

# Check subnet exists  
aws ec2 describe-subnets --filters "Name=tag:Name,Values=student-team4-dev-vpc-subnet"

# View Terraform outputs
terraform output
```

#### 2.5 Test Reproducibility (C2.md Key Principle)
```bash
# Run apply again - should show "No changes"
terraform apply -var-file=dev.tfvars
```

Expected: `No changes. Your infrastructure matches the configuration.`

#### 2.6 Test State Management
```bash
# View state file
terraform show

# List resources under management
terraform state list
```

#### 2.7 Import Testing (C2.md Requirement)

First, let's remove and then re-import a resource:

```bash
# Remove VPC from state (but keep in AWS)
terraform state rm module.vpc.aws_vpc.main

# Verify it's gone from state
terraform state list

# Now import it back
VPC_ID=$(terraform output -raw vpc_id)
terraform import module.vpc.aws_vpc.main $VPC_ID

# Verify it's back in state
terraform state list
```

#### 2.8 Destroy Infrastructure (Disposable Testing)
```bash
terraform destroy -var-file=dev.tfvars
```

Type `yes` when prompted. All resources should be deleted.

#### 2.9 Test Full Reproducibility
```bash
# Deploy again - should create identical infrastructure
terraform apply -var-file=dev.tfvars

# Verify same outputs as before
terraform output
```

## 🔄 Team Workflow Testing

### Multi-Environment Testing
```bash
# Test production environment
terraform plan -var-file=prod.tfvars
# Note: Don't apply prod without team discussion!
```

### State Locking Test
```bash
# In one terminal
terraform apply -var-file=dev.tfvars

# In another terminal (should fail with lock error)
terraform apply -var-file=dev.tfvars
```

## 🛡️ Security & Best Practices Validation

### Credentials Check
```bash
# Verify no hardcoded credentials
grep -r "AKIA\|aws_access_key\|aws_secret" terraform/ || echo "✅ No hardcoded credentials found"

# Check sensitive variables
grep -r "sensitive.*=.*true" terraform/
```

### Backend Security
```bash
# Verify backend encryption
aws s3api get-bucket-encryption --bucket student-team4-terraform-state

# Check versioning
aws s3api get-bucket-versioning --bucket student-team4-terraform-state
```

## 📊 Testing Checklist

- [ ] Local tools installed and configured
- [ ] AWS credentials configured (not hardcoded)
- [ ] Backend bucket created and configured
- [ ] `terraform init` successful
- [ ] `terraform plan` shows expected resources
- [ ] `terraform apply` creates infrastructure
- [ ] Outputs display correct values
- [ ] Infrastructure visible in AWS Console
- [ ] `terraform apply` again shows no changes (idempotence)
- [ ] `terraform import` works for existing resources
- [ ] `terraform destroy` removes all resources
- [ ] Re-apply creates identical infrastructure (reproducibility)
- [ ] State locking prevents concurrent operations

## 🚨 Troubleshooting Common Issues

### Backend Issues
```bash
# Error: S3 bucket does not exist
# Solution: Run setup-backend.sh or create bucket manually

# Error: Access denied to S3 bucket
# Solution: Check AWS credentials and bucket permissions
```

### Provider Issues
```bash
# Error: No valid credential sources found
# Solution: Run 'aws configure' or check environment variables

# Error: The AWS Access Key Id you provided does not exist
# Solution: Verify AWS credentials are correct
```

### State Issues
```bash
# Error: Backend configuration has changed
# Solution: Run 'terraform init -reconfigure'

# Error: State lock error
# Solution: Wait for other operations to complete, or use 'terraform force-unlock'
```

## 🎓 Key Learning Points from C2.md

1. **Infrastructure must be reproducible**: Same code = same infrastructure
2. **Infrastructure must be disposable**: Easy to destroy and recreate  
3. **Remote state is essential**: Never use local state in teams
4. **Backend must exist first**: Manual creation required before init
5. **State locking prevents conflicts**: DynamoDB table provides safety
6. **Import brings existing resources under control**: Useful for migration
7. **Variables enable environment separation**: dev.tfvars vs prod.tfvars

## 📝 Next Steps

After completing this hands-on guide:
1. Practice the destroy/apply cycle multiple times
2. Test with different variable values
3. Try importing other AWS resources
4. Experiment with different regions
5. Set up production environment (carefully!)

---

*This hands-on guide implements all practical requirements from C2.md for learning Infrastructure as Code with Terraform.*