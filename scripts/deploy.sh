#!/bin/bash

# Quick deployment script for local testing
# Demonstrates the reproducibility principle from C1.md

set -e

ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="terraform/environments"

echo "🚀 Deploying $ENVIRONMENT environment..."

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    echo "❌ Invalid environment. Use 'dev' or 'prod'"
    exit 1
fi

# Check if we're in the right directory
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

cd "$TERRAFORM_DIR"

echo "📁 Working directory: $(pwd)"
echo "🏗️  Environment: $ENVIRONMENT"

# Initialize Terraform with appropriate backend
echo "⚙️  Initializing Terraform..."
terraform init -backend-config="../backends/${ENVIRONMENT}.config"

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Format check
echo "🖌️  Checking Terraform formatting..."
terraform fmt -check -recursive || {
    echo "⚠️  Code formatting issues found. Running terraform fmt..."
    terraform fmt -recursive
}

# Plan the deployment
echo "📋 Planning deployment..."
terraform plan -var-file="${ENVIRONMENT}.tfvars" -out="${ENVIRONMENT}.tfplan"

# Ask for confirmation
echo ""
read -p "Do you want to apply this plan? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Applying Terraform plan..."
    terraform apply "${ENVIRONMENT}.tfplan"
    
    echo ""
    echo "📊 Infrastructure outputs:"
    terraform output
    
    echo ""
    echo "✅ Deployment completed successfully!"
    echo ""
    echo "To destroy this infrastructure later:"
    echo "terraform destroy -var-file=\"${ENVIRONMENT}.tfvars\""
else
    echo "❌ Deployment cancelled"
    rm -f "${ENVIRONMENT}.tfplan"
fi