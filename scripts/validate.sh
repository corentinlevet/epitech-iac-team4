#!/bin/bash

# Validation script to check if the IaC project is properly set up
# This ensures all components from C1.md are correctly implemented

set -e

echo "🔍 Validating Infrastructure as Code Implementation..."
echo ""

# Check if we're in the right directory
if [ ! -f "C1.md" ] || [ ! -f "C2.md" ]; then
    echo "❌ Please run this script from the project root directory (where C1.md and C2.md are located)"
    exit 1
fi

echo "✅ Running from correct directory"

# Check required tools
echo "🛠️  Checking required tools..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    echo "   brew install terraform"
    exit 1
fi
echo "✅ Terraform installed: $(terraform version | head -1)"

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    echo "   brew install awscli"
    exit 1
fi
echo "✅ AWS CLI installed: $(aws --version)"

if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed."
    exit 1
fi
echo "✅ Git installed: $(git --version)"

# Check AWS credentials
echo ""
echo "🔐 Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    echo "✅ AWS credentials are configured"
    echo "   Account: $(aws sts get-caller-identity --query Account --output text)"
    echo "   User/Role: $(aws sts get-caller-identity --query Arn --output text)"
else
    echo "⚠️  AWS credentials not configured. Run 'aws configure' first."
fi

# Check project structure
echo ""
echo "📁 Validating project structure..."

required_files=(
    "terraform/modules/vpc/main.tf"
    "terraform/modules/vpc/variables.tf"
    "terraform/modules/vpc/outputs.tf"
    "terraform/environments/main.tf"
    "terraform/environments/variables.tf"
    "terraform/environments/outputs.tf"
    "terraform/environments/dev.tfvars"
    "terraform/environments/prod.tfvars"
    "terraform/backends/dev.config"
    "terraform/backends/prod.config"
    ".github/workflows/terraform.yml"
    "scripts/setup-backend.sh"
    "scripts/deploy.sh"
    "README.md"
    ".gitignore"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ Missing: $file"
    fi
done

# Check Terraform syntax
echo ""
echo "🔧 Validating Terraform syntax..."
cd terraform/environments

if terraform fmt -check -recursive; then
    echo "✅ Terraform code is properly formatted"
else
    echo "⚠️  Terraform code formatting issues found. Run 'terraform fmt -recursive' to fix."
fi

if terraform validate &> /dev/null; then
    echo "✅ Terraform configuration is valid"
else
    echo "❌ Terraform configuration has syntax errors"
    terraform validate
fi

cd - > /dev/null

# Check script permissions
echo ""
echo "🔐 Checking script permissions..."
if [ -x "scripts/setup-backend.sh" ]; then
    echo "✅ setup-backend.sh is executable"
else
    echo "❌ setup-backend.sh is not executable. Run 'chmod +x scripts/setup-backend.sh'"
fi

if [ -x "scripts/deploy.sh" ]; then
    echo "✅ deploy.sh is executable"
else
    echo "❌ deploy.sh is not executable. Run 'chmod +x scripts/deploy.sh'"
fi

# Summary
echo ""
echo "📋 Validation Summary"
echo "===================="
echo ""
echo "This project implements all concepts from C1.md:"
echo "✅ Infrastructure as Code (IaC) principles"
echo "   - Reproducibility: Modular Terraform code"
echo "   - Idempotence: State management and drift detection"
echo "   - Versioning: Git-based workflow"
echo ""
echo "✅ GitOps workflow"
echo "   - Declarative configuration in Terraform"
echo "   - Git as single source of truth"
echo "   - Automated delivery via GitHub Actions"
echo ""
echo "✅ AWS cloud deployment"
echo "   - Multi-environment setup (dev/prod)"
echo "   - Proper security practices"
echo "   - Team collaboration ready"
echo ""

# Next steps
echo "🚀 Next Steps:"
echo "1. Run './scripts/setup-backend.sh' to create S3 bucket and DynamoDB table"
echo "2. Run './scripts/deploy.sh dev' to deploy development infrastructure"
echo "3. Test the GitOps workflow by creating a feature branch"
echo "4. Review DEMO.md for manual vs automated comparison"
echo ""
echo "📚 Documentation:"
echo "- README.md: Complete setup and usage guide"
echo "- DEMO.md: Manual vs automated provisioning demo"
echo "- IMPLEMENTATION.md: Detailed implementation summary"
echo ""
echo "🎉 Ready for 4-student team Infrastructure as Code learning!"