#!/bin/bash

# Terraform State Management Demonstration
# Covers C2.md Section 5: "Terraform State Management"
# Demonstrates local vs remote state, locking, and best practices

set -e

ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="terraform/environments"

echo "🗂️  Terraform State Management Demo"
echo "===================================="
echo "Environment: $ENVIRONMENT"
echo ""

# Check if we're in the right directory
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

cd "$TERRAFORM_DIR"

echo "📍 Working directory: $(pwd)"
echo ""

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "⚠️  Terraform not initialized. Initializing now..."
    terraform init -backend-config="../backends/${ENVIRONMENT}.config"
fi

echo "🔍 State Management Overview"
echo "============================"
echo ""

# Show backend configuration
echo "1️⃣  Backend Configuration:"
echo "------------------------"
echo "Current backend type:"
terraform version | head -1
echo ""

if [ -f "../backends/${ENVIRONMENT}.config" ]; then
    echo "Backend config file (../backends/${ENVIRONMENT}.config):"
    cat "../backends/${ENVIRONMENT}.config"
else
    echo "❌ Backend config file not found"
fi
echo ""

# Show current state location
echo "2️⃣  State File Location:"
echo "----------------------"
echo "This configuration uses REMOTE state (S3 backend)"
echo "State file location: s3://student-team4-terraform-state/${ENVIRONMENT}/vpc/terraform.tfstate"
echo ""

# Check if local state exists (it shouldn't)
if [ -f "terraform.tfstate" ]; then
    echo "⚠️  WARNING: Local state file found! This should not exist with remote backend."
    echo "Local state file: terraform.tfstate"
else
    echo "✅ No local state file found (correct for remote backend)"
fi
echo ""

# Show state locking configuration
echo "3️⃣  State Locking:"
echo "-----------------"
LOCK_TABLE="terraform-locks"
echo "DynamoDB table for locking: $LOCK_TABLE"

if aws dynamodb describe-table --table-name "$LOCK_TABLE" --region us-east-1 &> /dev/null; then
    echo "✅ DynamoDB lock table exists"
    echo "Lock table status:"
    aws dynamodb describe-table --table-name "$LOCK_TABLE" --region us-east-1 --query 'Table.TableStatus' --output text
else
    echo "❌ DynamoDB lock table does not exist"
    echo "This means no state locking protection!"
fi
echo ""

# Check if infrastructure exists
if ! terraform state list &> /dev/null || [ "$(terraform state list | wc -l)" -eq 0 ]; then
    echo "⚠️  No infrastructure in state. Deploying minimal infrastructure for demo..."
    terraform apply -var-file="${ENVIRONMENT}.tfvars" -auto-approve
fi

# Show current state
echo "4️⃣  Current State Contents:"
echo "-------------------------"
echo "Resources in state:"
terraform state list
echo ""

echo "State file summary:"
terraform show -json | jq -r '.values.root_module.resources | length' 2>/dev/null || echo "Unable to parse state (jq not installed)"
echo ""

# Demonstrate state commands
echo "5️⃣  State Management Commands:"
echo "-----------------------------"

echo "📋 terraform state list (all resources):"
terraform state list
echo ""

echo "🔍 terraform state show (first resource):"
FIRST_RESOURCE=$(terraform state list | head -1)
if [ -n "$FIRST_RESOURCE" ]; then
    terraform state show "$FIRST_RESOURCE" | head -10
    echo "... (truncated)"
else
    echo "No resources to show"
fi
echo ""

echo "📊 terraform output (all outputs):"
terraform output
echo ""

# Demonstrate state inspection
echo "6️⃣  State Inspection:"
echo "-------------------"
echo "Backend configuration:"
terraform init -backend=false 2>&1 | grep -A 10 "Backend configuration" || echo "Backend info not available in output"
echo ""

# Check state file remotely
echo "7️⃣  Remote State Verification:"
echo "-----------------------------"
BUCKET_NAME="student-team4-terraform-state"
STATE_KEY="${ENVIRONMENT}/vpc/terraform.tfstate"

echo "Checking remote state file..."
if aws s3 ls "s3://$BUCKET_NAME/$STATE_KEY" &> /dev/null; then
    echo "✅ Remote state file exists: s3://$BUCKET_NAME/$STATE_KEY"
    
    # Show state file info
    echo "State file details:"
    aws s3 ls "s3://$BUCKET_NAME/$STATE_KEY" --human-readable
else
    echo "❌ Remote state file not found"
fi
echo ""

# Check versioning
echo "Checking S3 versioning (for state history):"
if aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" --query 'Status' --output text 2>/dev/null | grep -q "Enabled"; then
    echo "✅ S3 versioning enabled (state history preserved)"
else
    echo "⚠️  S3 versioning not enabled (no state history)"
fi
echo ""

# Demonstrate state locking
echo "8️⃣  State Locking Demonstration:"
echo "-------------------------------"
echo "Testing state lock functionality..."

# Create a background process that holds a lock
echo "Creating a long-running terraform plan to hold state lock..."
terraform plan -var-file="${ENVIRONMENT}.tfvars" -input=false &
PLAN_PID=$!

# Give it time to acquire lock
sleep 3

echo "Attempting another terraform command (should fail with lock error)..."
if terraform plan -var-file="${ENVIRONMENT}.tfvars" -input=false &> /tmp/lock_test.log; then
    echo "⚠️  Second command succeeded (locking may not be working)"
else
    echo "✅ Second command failed as expected (state locking working)"
    echo "Lock error message:"
    grep -i lock /tmp/lock_test.log || echo "No lock message found"
fi

# Clean up background process
echo "Cleaning up lock test..."
kill $PLAN_PID 2>/dev/null || echo "Background process already finished"
wait $PLAN_PID 2>/dev/null || true
rm -f /tmp/lock_test.log
echo ""

# State backup demonstration
echo "9️⃣  State Backup & Recovery:"
echo "---------------------------"
echo "With remote state, backups are handled automatically by S3 versioning"

if aws s3api list-object-versions --bucket "$BUCKET_NAME" --prefix "$STATE_KEY" &> /dev/null; then
    echo "State file versions:"
    aws s3api list-object-versions --bucket "$BUCKET_NAME" --prefix "$STATE_KEY" --query 'Versions[].{Key: Key, VersionId: VersionId, LastModified: LastModified}' --output table 2>/dev/null | head -10
else
    echo "Unable to list state file versions"
fi
echo ""

# Best practices summary
echo "🔟 State Management Best Practices:"
echo "===================================="
echo ""
echo "✅ DO:"
echo "   • Always use remote backend for team collaboration"
echo "   • Enable versioning on S3 bucket for state history"
echo "   • Use DynamoDB for state locking"
echo "   • Never edit state files manually"
echo "   • Use 'terraform state' commands for state manipulation"
echo "   • Regularly backup state files (automatic with S3 versioning)"
echo ""
echo "❌ DON'T:"
echo "   • Don't use local state for team projects"
echo "   • Don't commit state files to version control"
echo "   • Don't manually edit terraform.tfstate"
echo "   • Don't disable locking without good reason"
echo "   • Don't ignore state lock errors"
echo ""

# Troubleshooting guide
echo "🔧 Common State Issues & Solutions:"
echo "=================================="
echo ""
echo "Problem: 'Backend configuration changed'"
echo "Solution: terraform init -reconfigure"
echo ""
echo "Problem: 'Error acquiring the state lock'"
echo "Solution: Wait for other operations, or terraform force-unlock <lock_id>"
echo ""
echo "Problem: 'State file not found'"
echo "Solution: Check backend configuration and AWS credentials"
echo ""
echo "Problem: 'Drift between state and reality'"
echo "Solution: terraform refresh, then terraform plan"
echo ""

# Interactive state exploration
echo "🔍 Interactive State Exploration:"
echo "================================"
read -p "Would you like to explore state interactively? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Available commands:"
    echo "1. terraform state list"
    echo "2. terraform state show <resource>"
    echo "3. terraform output"
    echo "4. terraform show"
    echo ""
    
    while true; do
        read -p "Enter command number (1-4) or 'q' to quit: " -n 1 -r
        echo ""
        
        case $REPLY in
            1)
                echo "Resources in state:"
                terraform state list
                ;;
            2)
                echo "Available resources:"
                terraform state list
                echo ""
                read -p "Enter resource name to show: " RESOURCE
                if [ -n "$RESOURCE" ]; then
                    terraform state show "$RESOURCE" 2>/dev/null || echo "Resource not found"
                fi
                ;;
            3)
                echo "Outputs:"
                terraform output
                ;;
            4)
                echo "Full state (first 50 lines):"
                terraform show | head -50
                echo "... (truncated, use 'terraform show' for full output)"
                ;;
            q)
                break
                ;;
            *)
                echo "Invalid option. Use 1-4 or 'q'"
                ;;
        esac
        echo ""
    done
fi

echo ""
echo "🎉 State Management Demo Complete!"
echo "================================="
echo ""
echo "📚 Key Learnings:"
echo "   • Remote state enables team collaboration"
echo "   • State locking prevents concurrent modifications"
echo "   • S3 versioning provides state history and recovery"
echo "   • Never edit state files manually"
echo "   • Use terraform state commands for state operations"
echo ""
echo "📖 Further Reading:"
echo "   • Terraform State Documentation: https://www.terraform.io/docs/language/state/"
echo "   • AWS S3 Backend: https://www.terraform.io/docs/language/settings/backends/s3.html"
echo "   • State Import Guide: https://www.terraform.io/docs/cli/import/"