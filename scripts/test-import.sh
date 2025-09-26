#!/bin/bash

# Terraform Import Testing Script
# Demonstrates import functionality as required in C2.md
# "Learn to import, destroy, and redeploy your infrastructure with just a few commands"

set -e

ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="terraform/environments"

echo "📥 Terraform Import Testing Script"
echo "=================================="
echo "Environment: $ENVIRONMENT"
echo ""

# Check if we're in the right directory
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

cd "$TERRAFORM_DIR"

# Verify Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Terraform not initialized. Run 'terraform init' first."
    exit 1
fi

echo "🔍 Current Terraform State:"
terraform state list
echo ""

# Check if infrastructure exists
if ! terraform output vpc_id &> /dev/null; then
    echo "❌ No infrastructure deployed. Deploy first with:"
    echo "   terraform apply -var-file=${ENVIRONMENT}.tfvars"
    exit 1
fi

# Get current resource IDs
VPC_ID=$(terraform output -raw vpc_id)
SUBNET_ID=$(terraform output -raw subnet_id)
IGW_ID=$(terraform output -raw internet_gateway_id)
RT_ID=$(terraform output -raw route_table_id)

echo "📋 Current Resource IDs:"
echo "VPC ID: $VPC_ID"
echo "Subnet ID: $SUBNET_ID" 
echo "Internet Gateway ID: $IGW_ID"
echo "Route Table ID: $RT_ID"
echo ""

# Test 1: Import VPC
echo "🧪 Test 1: VPC Import/Re-import"
echo "================================"
echo "Removing VPC from Terraform state..."
terraform state rm module.vpc.aws_vpc.main

echo "State after removal:"
terraform state list | grep -v aws_vpc || echo "✅ VPC removed from state"

echo "Verifying VPC still exists in AWS..."
if aws ec2 describe-vpcs --vpc-ids "$VPC_ID" &> /dev/null; then
    echo "✅ VPC still exists in AWS (as expected)"
else
    echo "❌ VPC missing from AWS (unexpected!)"
    exit 1
fi

echo "Re-importing VPC..."
if terraform import module.vpc.aws_vpc.main "$VPC_ID"; then
    echo "✅ VPC successfully imported"
else
    echo "❌ VPC import failed"
    exit 1
fi

echo "Verifying plan shows no changes after import..."
if terraform plan -var-file="${ENVIRONMENT}.tfvars" | grep -q "No changes"; then
    echo "✅ Import successful - no configuration drift"
else
    echo "⚠️  Configuration drift detected after import"
    terraform plan -var-file="${ENVIRONMENT}.tfvars"
fi
echo ""

# Test 2: Import Subnet
echo "🧪 Test 2: Subnet Import/Re-import"
echo "=================================="
echo "Removing Subnet from Terraform state..."
terraform state rm module.vpc.aws_subnet.main

echo "State after removal:"
terraform state list | grep -v aws_subnet || echo "✅ Subnet removed from state"

echo "Verifying Subnet still exists in AWS..."
if aws ec2 describe-subnets --subnet-ids "$SUBNET_ID" &> /dev/null; then
    echo "✅ Subnet still exists in AWS (as expected)"
else
    echo "❌ Subnet missing from AWS (unexpected!)"
    exit 1
fi

echo "Re-importing Subnet..."
if terraform import module.vpc.aws_subnet.main "$SUBNET_ID"; then
    echo "✅ Subnet successfully imported"
else
    echo "❌ Subnet import failed"
    exit 1
fi

echo "Verifying plan shows no changes after import..."
if terraform plan -var-file="${ENVIRONMENT}.tfvars" | grep -q "No changes"; then
    echo "✅ Import successful - no configuration drift"
else
    echo "⚠️  Configuration drift detected after import"
    terraform plan -var-file="${ENVIRONMENT}.tfvars"
fi
echo ""

# Test 3: Import Internet Gateway
echo "🧪 Test 3: Internet Gateway Import/Re-import"
echo "============================================="
echo "Removing Internet Gateway from Terraform state..."
terraform state rm module.vpc.aws_internet_gateway.main

echo "State after removal:"
terraform state list | grep -v aws_internet_gateway || echo "✅ IGW removed from state"

echo "Verifying Internet Gateway still exists in AWS..."
if aws ec2 describe-internet-gateways --internet-gateway-ids "$IGW_ID" &> /dev/null; then
    echo "✅ Internet Gateway still exists in AWS (as expected)"
else
    echo "❌ Internet Gateway missing from AWS (unexpected!)"
    exit 1
fi

echo "Re-importing Internet Gateway..."
if terraform import module.vpc.aws_internet_gateway.main "$IGW_ID"; then
    echo "✅ Internet Gateway successfully imported"
else
    echo "❌ Internet Gateway import failed"
    exit 1
fi

echo "Verifying plan shows no changes after import..."
if terraform plan -var-file="${ENVIRONMENT}.tfvars" | grep -q "No changes"; then
    echo "✅ Import successful - no configuration drift"
else
    echo "⚠️  Configuration drift detected after import"
    terraform plan -var-file="${ENVIRONMENT}.tfvars"
fi
echo ""

# Test 4: Import Route Table
echo "🧪 Test 4: Route Table Import/Re-import"
echo "========================================"
echo "Removing Route Table from Terraform state..."
terraform state rm module.vpc.aws_route_table.main

echo "State after removal:"
terraform state list | grep -v aws_route_table || echo "✅ Route Table removed from state"

echo "Verifying Route Table still exists in AWS..."
if aws ec2 describe-route-tables --route-table-ids "$RT_ID" &> /dev/null; then
    echo "✅ Route Table still exists in AWS (as expected)"
else
    echo "❌ Route Table missing from AWS (unexpected!)"
    exit 1
fi

echo "Re-importing Route Table..."
if terraform import module.vpc.aws_route_table.main "$RT_ID"; then
    echo "✅ Route Table successfully imported"
else
    echo "❌ Route Table import failed"
    exit 1
fi

echo "Verifying plan shows no changes after import..."
if terraform plan -var-file="${ENVIRONMENT}.tfvars" | grep -q "No changes"; then
    echo "✅ Import successful - no configuration drift"
else
    echo "⚠️  Configuration drift detected after import"
    terraform plan -var-file="${ENVIRONMENT}.tfvars"
fi
echo ""

# Test 5: Multiple Resource Import
echo "🧪 Test 5: Multiple Resource Import Test"
echo "========================================"
echo "This test removes ALL resources from state and imports them back"
read -p "Do you want to proceed with this advanced test? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing ALL resources from state..."
    
    # Store all current resource addresses and IDs
    declare -A RESOURCES
    RESOURCES["module.vpc.aws_vpc.main"]="$VPC_ID"
    RESOURCES["module.vpc.aws_subnet.main"]="$SUBNET_ID"
    RESOURCES["module.vpc.aws_internet_gateway.main"]="$IGW_ID"
    RESOURCES["module.vpc.aws_route_table.main"]="$RT_ID"
    
    # Get route table association ID
    RTA_ID=$(aws ec2 describe-route-tables --route-table-ids "$RT_ID" --query 'RouteTables[0].Associations[0].RouteTableAssociationId' --output text)
    if [ "$RTA_ID" != "None" ] && [ "$RTA_ID" != "null" ]; then
        RESOURCES["module.vpc.aws_route_table_association.main"]="$RTA_ID"
    fi
    
    # Remove all from state
    for resource in "${!RESOURCES[@]}"; do
        echo "Removing $resource from state..."
        terraform state rm "$resource" || echo "Resource $resource not in state"
    done
    
    echo "State after mass removal:"
    terraform state list || echo "No resources in state"
    
    # Re-import all resources
    echo ""
    echo "Re-importing all resources..."
    for resource in "${!RESOURCES[@]}"; do
        resource_id="${RESOURCES[$resource]}"
        echo "Importing $resource with ID $resource_id..."
        
        if terraform import "$resource" "$resource_id"; then
            echo "✅ $resource imported successfully"
        else
            echo "❌ $resource import failed"
        fi
    done
    
    echo ""
    echo "Final state verification:"
    terraform state list
    
    echo ""
    echo "Final plan check (should show no changes):"
    if terraform plan -var-file="${ENVIRONMENT}.tfvars" | grep -q "No changes"; then
        echo "✅ ALL imports successful - infrastructure matches configuration"
    else
        echo "⚠️  Some configuration drift detected"
        echo "Running plan to show details:"
        terraform plan -var-file="${ENVIRONMENT}.tfvars"
    fi
else
    echo "⏭️  Skipping multiple resource import test"
fi

echo ""
echo "🎉 Import Testing Complete!"
echo "==========================="
echo ""
echo "✅ Key learnings from import testing:"
echo "   • Resources can be removed from state without AWS deletion"
echo "   • Import syntax: terraform import <resource_address> <resource_id>"
echo "   • Successful imports should show 'No changes' in plan"
echo "   • Import is useful for bringing existing infrastructure under Terraform control"
echo ""
echo "📋 Final state:"
terraform state list
echo ""
echo "📊 Final outputs:"
terraform output
echo ""
echo "💡 Import use cases:"
echo "   • Bringing manually-created resources under Terraform"
echo "   • Recovering from accidental state deletion"
echo "   • Migrating from other IaC tools"
echo "   • Fixing state inconsistencies"
echo ""
echo "📚 Import documentation:"
echo "   • AWS Provider docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs"
echo "   • Each resource type documents its import syntax"
echo "   • Always verify with 'terraform plan' after import"