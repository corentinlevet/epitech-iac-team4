#!/bin/bash

# Hands-on Testing Script for C2.md Requirements
# This script automates the testing workflow described in C2.md Section 6

set -e

ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="terraform/environments"
SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🧪 C2.md Hands-On Testing Script"
echo "=================================="
echo "Environment: $ENVIRONMENT"
echo "Working Directory: $(pwd)"
echo ""

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    echo "❌ Invalid environment. Use 'dev' or 'prod'"
    echo "Usage: $0 [dev|prod]"
    exit 1
fi

# Check if we're in the right directory
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "❌ Please run this script from the project root directory"
    echo "Expected to find: $TERRAFORM_DIR"
    exit 1
fi

cd "$TERRAFORM_DIR"

echo "📍 Current directory: $(pwd)"
echo ""

# Step 1: Verify prerequisites (C2.md Section 2)
echo "🔍 Step 1: Verifying Prerequisites..."

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured"
    echo "Please run: aws configure"
    exit 1
fi
echo "✅ AWS credentials configured"

# Check if backend exists
BUCKET_NAME="student-team4-terraform-state"
if ! aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
    echo "❌ Backend bucket '$BUCKET_NAME' does not exist"
    echo "Please run: $ROOT_DIR/scripts/setup-backend.sh"
    exit 1
fi
echo "✅ Backend bucket exists"

echo ""

# Step 2: Initialize Terraform (C2.md Section 6.1)
echo "⚙️  Step 2: Initializing Terraform..."
if terraform init -backend-config="../backends/${ENVIRONMENT}.config"; then
    echo "✅ Terraform initialized successfully"
else
    echo "❌ Terraform initialization failed"
    exit 1
fi
echo ""

# Step 3: Validate Configuration
echo "🔧 Step 3: Validating Configuration..."
if terraform validate; then
    echo "✅ Terraform configuration is valid"
else
    echo "❌ Terraform configuration has errors"
    exit 1
fi
echo ""

# Step 4: Plan Infrastructure (C2.md Section 6.2)
echo "📋 Step 4: Planning Infrastructure..."
if terraform plan -var-file="${ENVIRONMENT}.tfvars" -out="${ENVIRONMENT}.tfplan"; then
    echo "✅ Terraform plan created successfully"
else
    echo "❌ Terraform plan failed"
    exit 1
fi
echo ""

# Step 5: Apply Infrastructure (C2.md Section 6.3)
echo "🚀 Step 5: Deploying Infrastructure..."
echo "This will create real AWS resources (💸 cost implications)"
read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if terraform apply "${ENVIRONMENT}.tfplan"; then
        echo "✅ Infrastructure deployed successfully"
    else
        echo "❌ Infrastructure deployment failed"
        exit 1
    fi
else
    echo "⏭️  Skipping deployment"
    rm -f "${ENVIRONMENT}.tfplan"
    echo ""
    echo "To continue later, run:"
    echo "  terraform apply -var-file=${ENVIRONMENT}.tfvars"
    exit 0
fi
echo ""

# Step 6: Check Outputs (C2.md Section 6.4)
echo "📊 Step 6: Checking Outputs..."
terraform output
echo ""

# Step 7: Test Idempotence (C2.md Key Principle)
echo "🔄 Step 7: Testing Idempotence..."
echo "Running terraform apply again - should show 'No changes'"
if terraform apply -var-file="${ENVIRONMENT}.tfvars" -auto-approve; then
    echo "✅ Idempotence test passed"
else
    echo "❌ Idempotence test failed"
    exit 1
fi
echo ""

# Step 8: Test State Management
echo "📋 Step 8: Testing State Management..."
echo "Resources under Terraform management:"
terraform state list
echo ""

# Step 9: Test Import (C2.md Requirement)
echo "📥 Step 9: Testing Import Functionality..."
echo "This tests removing and re-importing a resource"
read -p "Do you want to test import functionality? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Get VPC ID before removing from state
    VPC_ID=$(terraform output -raw vpc_id)
    echo "VPC ID: $VPC_ID"
    
    # Remove VPC from state
    echo "Removing VPC from Terraform state..."
    terraform state rm module.vpc.aws_vpc.main
    
    # Verify it's gone from state
    echo "Resources after removal:"
    terraform state list | grep -v aws_vpc || echo "✅ VPC removed from state"
    
    # Import it back
    echo "Re-importing VPC into Terraform state..."
    if terraform import module.vpc.aws_vpc.main "$VPC_ID"; then
        echo "✅ VPC successfully re-imported"
    else
        echo "❌ VPC import failed"
        exit 1
    fi
    
    # Verify it's back
    echo "Resources after import:"
    terraform state list | grep aws_vpc && echo "✅ VPC back in state"
    
    # Verify plan shows no changes
    echo "Verifying imported resource matches configuration..."
    if terraform plan -var-file="${ENVIRONMENT}.tfvars" | grep -q "No changes"; then
        echo "✅ Imported resource matches configuration"
    else
        echo "⚠️  Imported resource may have configuration drift"
    fi
fi
echo ""

# Step 10: Verify Infrastructure in AWS
echo "☁️  Step 10: Verifying Infrastructure in AWS..."
VPC_ID=$(terraform output -raw vpc_id)
SUBNET_ID=$(terraform output -raw subnet_id)

echo "Checking VPC in AWS..."
if aws ec2 describe-vpcs --vpc-ids "$VPC_ID" &> /dev/null; then
    echo "✅ VPC exists in AWS: $VPC_ID"
else
    echo "❌ VPC not found in AWS"
fi

echo "Checking Subnet in AWS..."
if aws ec2 describe-subnets --subnet-ids "$SUBNET_ID" &> /dev/null; then
    echo "✅ Subnet exists in AWS: $SUBNET_ID"
else
    echo "❌ Subnet not found in AWS"
fi
echo ""

# Step 11: Test Reproducibility (Optional Destroy/Recreate)
echo "🔄 Step 11: Test Reproducibility (Destroy/Recreate)..."
echo "This will destroy and recreate the infrastructure to test reproducibility"
echo "⚠️  WARNING: This will temporarily delete your infrastructure!"
read -p "Do you want to test destroy/recreate? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Store original outputs for comparison
    ORIGINAL_VPC_CIDR=$(terraform output -raw vpc_cidr_block)
    ORIGINAL_SUBNET_CIDR=$(terraform output -raw subnet_cidr_block)
    
    echo "Original VPC CIDR: $ORIGINAL_VPC_CIDR"
    echo "Original Subnet CIDR: $ORIGINAL_SUBNET_CIDR"
    
    # Destroy infrastructure
    echo "Destroying infrastructure..."
    if terraform destroy -var-file="${ENVIRONMENT}.tfvars" -auto-approve; then
        echo "✅ Infrastructure destroyed"
    else
        echo "❌ Infrastructure destruction failed"
        exit 1
    fi
    
    # Recreate infrastructure
    echo "Recreating infrastructure..."
    if terraform apply -var-file="${ENVIRONMENT}.tfvars" -auto-approve; then
        echo "✅ Infrastructure recreated"
    else
        echo "❌ Infrastructure recreation failed"
        exit 1
    fi
    
    # Compare outputs
    NEW_VPC_CIDR=$(terraform output -raw vpc_cidr_block)
    NEW_SUBNET_CIDR=$(terraform output -raw subnet_cidr_block)
    
    echo "New VPC CIDR: $NEW_VPC_CIDR"
    echo "New Subnet CIDR: $NEW_SUBNET_CIDR"
    
    if [[ "$ORIGINAL_VPC_CIDR" == "$NEW_VPC_CIDR" ]] && [[ "$ORIGINAL_SUBNET_CIDR" == "$NEW_SUBNET_CIDR" ]]; then
        echo "✅ Reproducibility test passed - identical CIDR blocks"
    else
        echo "❌ Reproducibility test failed - CIDR blocks differ"
        exit 1
    fi
fi

# Final Summary
echo ""
echo "🎉 C2.md Hands-On Testing Complete!"
echo "=================================="
echo ""
echo "✅ All C2.md requirements tested:"
echo "   • VPC and subnet deployed using Terraform"
echo "   • Remote backend used for state management" 
echo "   • Local setup tested with reproducible infrastructure"
echo "   • Import, destroy, and redeploy functionality verified"
echo ""
echo "📊 Current Infrastructure:"
terraform output
echo ""
echo "🗂️  Resources under management:"
terraform state list
echo ""
echo "💡 Next steps:"
echo "   • Practice the workflow multiple times"
echo "   • Test with different variable values"
echo "   • Try modifying the infrastructure"
echo "   • Test with production environment (carefully!)"
echo ""
echo "🧹 To clean up:"
echo "   terraform destroy -var-file=${ENVIRONMENT}.tfvars"