#!/bin/bash

# 🧹 Cleanup Script - Destroys all AWS resources created by this project
# Use this script to completely remove the infrastructure and avoid ongoing charges

# Don't exit on error - we want to continue cleaning up even if some steps fail
set +e

# Disable AWS CLI pager to prevent hanging on output
export AWS_PAGER=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${RED}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  $1${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to wait for confirmation
wait_for_confirmation() {
    read -p "Press [Enter] to continue or [Ctrl+C] to abort..."
}

# Function to clean up Kubernetes resources
cleanup_kubernetes() {
    print_header "⚓ CLEANING UP KUBERNETES RESOURCES"
    
    print_status "Checking if kubectl is configured..."
    if ! kubectl cluster-info &> /dev/null; then
        print_warning "kubectl not configured or cluster not accessible, skipping Kubernetes cleanup"
        return 0
    fi
    
    print_status "Uninstalling Helm releases in all namespaces..."
    helm list -A -o json 2>/dev/null | jq -r '.[] | "\(.namespace) \(.name)"' 2>/dev/null | while read namespace release; do
        if [ ! -z "$release" ]; then
            print_status "Uninstalling $release from namespace $namespace..."
            helm uninstall "$release" -n "$namespace" 2>/dev/null || print_warning "Failed to uninstall $release"
        fi
    done
    
    # Fallback if jq not available
    helm uninstall task-manager 2>/dev/null || true
    helm uninstall task-manager-frontend 2>/dev/null || true
    helm uninstall aws-load-balancer-controller -n kube-system 2>/dev/null || true
    helm uninstall github-runners 2>/dev/null || true
    
    print_status "Deleting monitoring resources..."
    kubectl delete -f kubernetes-manifests/monitoring/final-grafana.yaml --ignore-not-found=true 2>/dev/null || true
    kubectl delete -f kubernetes-manifests/monitoring/final-prometheus.yaml --ignore-not-found=true 2>/dev/null || true
    
    print_status "Deleting monitoring namespace..."
    kubectl delete namespace monitoring --ignore-not-found=true --timeout=60s 2>/dev/null || true
    
    print_status "Waiting for Load Balancers to be deleted (max 3 minutes)..."
    echo "Checking for remaining LoadBalancer services..."
    
    # Wait for all LoadBalancer services to be deleted (with timeout)
    MAX_WAIT=180  # 3 minutes
    ELAPSED=0
    while [ $ELAPSED -lt $MAX_WAIT ]; do
        LB_SERVICES=$(kubectl get svc --all-namespaces --field-selector spec.type=LoadBalancer -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
        if [ -z "$LB_SERVICES" ]; then
            break
        fi
        echo -n "."
        sleep 10
        ELAPSED=$((ELAPSED + 10))
    done
    echo ""
    
    if [ $ELAPSED -ge $MAX_WAIT ]; then
        print_warning "Timeout waiting for Load Balancers, continuing anyway..."
    fi
    
    print_success "Kubernetes resources cleaned up!"
}

# Function to clean VPC dependencies
cleanup_vpc_dependencies() {
    print_header "🧹 CLEANING VPC DEPENDENCIES"
    
    # Get VPC ID from Terraform or find it by tag
    VPC_ID=$(aws ec2 describe-vpcs --region us-east-1 --filters "Name=tag:Project,Values=student-team4-iac" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")
    
    if [ -z "$VPC_ID" ] || [ "$VPC_ID" = "None" ]; then
        print_warning "No VPC found, skipping dependency cleanup"
        return 0
    fi
    
    print_status "Found VPC: $VPC_ID"
    
    # Delete all Load Balancers in the VPC
    print_status "Deleting Application Load Balancers..."
    ALB_ARNS=$(aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text 2>/dev/null || echo "")
    for ALB_ARN in $ALB_ARNS; do
        if [ ! -z "$ALB_ARN" ]; then
            print_status "Deleting ALB: $ALB_ARN"
            aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region us-east-1 2>/dev/null || true
        fi
    done
    
    # Delete Classic Load Balancers
    print_status "Deleting Classic Load Balancers..."
    CLB_NAMES=$(aws elb describe-load-balancers --region us-east-1 --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" --output text 2>/dev/null || echo "")
    for CLB_NAME in $CLB_NAMES; do
        if [ ! -z "$CLB_NAME" ]; then
            print_status "Deleting CLB: $CLB_NAME"
            aws elb delete-load-balancer --load-balancer-name "$CLB_NAME" --region us-east-1 2>/dev/null || true
        fi
    done
    
    # Wait for Load Balancers to be deleted
    print_status "Waiting for Load Balancers to be fully deleted (max 2 minutes)..."
    sleep 30
    MAX_WAIT=120
    ELAPSED=0
    while [ $ELAPSED -lt $MAX_WAIT ]; do
        REMAINING_ALBS=$(aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text 2>/dev/null | wc -w || echo "0")
        if [ "$REMAINING_ALBS" -eq "0" ]; then
            break
        fi
        echo -n "."
        sleep 10
        ELAPSED=$((ELAPSED + 10))
    done
    echo ""
    
    # Delete all Network Interfaces (ENIs) - except those attached to running instances
    print_status "Deleting Network Interfaces..."
    ENI_IDS=$(aws ec2 describe-network-interfaces --region us-east-1 --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkInterfaces[?Status==`available`].NetworkInterfaceId' --output text 2>/dev/null || echo "")
    for ENI_ID in $ENI_IDS; do
        if [ ! -z "$ENI_ID" ]; then
            print_status "Deleting ENI: $ENI_ID"
            aws ec2 delete-network-interface --network-interface-id "$ENI_ID" --region us-east-1 2>/dev/null || print_warning "Failed to delete $ENI_ID (may be in use)"
        fi
    done
    
    # Delete Target Groups
    print_status "Deleting Target Groups..."
    TG_ARNS=$(aws elbv2 describe-target-groups --region us-east-1 --query "TargetGroups[?VpcId=='$VPC_ID'].TargetGroupArn" --output text 2>/dev/null || echo "")
    for TG_ARN in $TG_ARNS; do
        if [ ! -z "$TG_ARN" ]; then
            print_status "Deleting Target Group: $TG_ARN"
            aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region us-east-1 2>/dev/null || true
        fi
    done
    
    # Delete Security Groups (except default)
    print_status "Deleting Security Groups..."
    SG_IDS=$(aws ec2 describe-security-groups --region us-east-1 --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text 2>/dev/null || echo "")
    for SG_ID in $SG_IDS; do
        if [ ! -z "$SG_ID" ]; then
            print_status "Deleting Security Group: $SG_ID"
            
            # First remove all ingress rules
            INGRESS_PERMS=$(aws ec2 describe-security-groups --group-ids "$SG_ID" --region us-east-1 --query 'SecurityGroups[0].IpPermissions' --output json 2>/dev/null)
            if [ "$INGRESS_PERMS" != "[]" ] && [ ! -z "$INGRESS_PERMS" ]; then
                aws ec2 revoke-security-group-ingress --group-id "$SG_ID" --ip-permissions "$INGRESS_PERMS" --region us-east-1 2>/dev/null || true
            fi
            
            # Then remove all egress rules
            EGRESS_PERMS=$(aws ec2 describe-security-groups --group-ids "$SG_ID" --region us-east-1 --query 'SecurityGroups[0].IpPermissionsEgress' --output json 2>/dev/null)
            if [ "$EGRESS_PERMS" != "[]" ] && [ ! -z "$EGRESS_PERMS" ]; then
                aws ec2 revoke-security-group-egress --group-id "$SG_ID" --ip-permissions "$EGRESS_PERMS" --region us-east-1 2>/dev/null || true
            fi
            
            # Finally delete the security group
            aws ec2 delete-security-group --group-id "$SG_ID" --region us-east-1 2>/dev/null || print_warning "Failed to delete $SG_ID (may have dependencies)"
        fi
    done
    
    print_success "VPC dependencies cleaned up!"
}

# Function to destroy infrastructure
destroy_infrastructure() {
    print_header "🏗️ DESTROYING AWS INFRASTRUCTURE"
    
    cd terraform/environments
    
    # Initialize terraform if needed
    print_status "Initializing Terraform..."
    terraform init -backend-config="../backends/dev.config" -reconfigure || terraform init || true
    
    # Try to unlock state if it's locked (check after init)
    print_status "Checking for state locks..."
    LOCK_OUTPUT=$(terraform plan -var-file="dev.tfvars" 2>&1 || true)
    if echo "$LOCK_OUTPUT" | grep -q "Error acquiring the state lock"; then
        LOCK_PATH=$(echo "$LOCK_OUTPUT" | grep "Path:" | head -1 | awk '{print $2}')
        print_warning "Found stale lock for: $LOCK_PATH"
        print_status "Removing lock from DynamoDB..."
        
        # Calculate the LockID (it's the path with -md5 suffix)
        LOCK_KEY="${LOCK_PATH}-md5"
        aws dynamodb delete-item --table-name terraform-locks --key "{\"LockID\": {\"S\": \"$LOCK_KEY\"}}" --region us-east-1 2>/dev/null || true
        
        print_success "Lock removed successfully!"
    fi
    
    print_status "Checking Terraform state..."
    STATE_CHECK=$(terraform state list 2>/dev/null | wc -l)
    if [ "$STATE_CHECK" -eq "0" ]; then
        print_warning "No Terraform state found or state is empty. Infrastructure may already be destroyed."
        cd ../../
        return 0
    fi
    
    print_status "Planning infrastructure destruction..."
    terraform plan -destroy -var-file="dev.tfvars" 2>/dev/null || print_warning "Plan failed, will attempt destroy anyway"
    
    print_warning "This will permanently delete all AWS resources!"
    print_warning "This action cannot be undone!"
    wait_for_confirmation
    
    print_status "Destroying infrastructure with 10-minute timeout per resource..."
    
    # Set timeout environment variable for Terraform
    export TF_CLI_ARGS_destroy="-parallelism=10"
    
    # Try with custom timeouts - destroy with reduced timeout (5 minutes per resource)
    if ! timeout 900 terraform destroy -var-file="dev.tfvars" -auto-approve 2>&1 | tee /tmp/terraform_destroy.log; then
        print_warning "First destroy attempt failed or timed out, retrying with -lock=false..."
        
        # Check if it was a lock issue or timeout
        if grep -q "Error acquiring the state lock" /tmp/terraform_destroy.log; then
            print_status "Removing state lock..."
            LOCK_PATH=$(grep "Path:" /tmp/terraform_destroy.log | head -1 | awk '{print $2}')
            LOCK_KEY="${LOCK_PATH}-md5"
            aws dynamodb delete-item --table-name terraform-locks --key "{\"LockID\": {\"S\": \"$LOCK_KEY\"}}" --region us-east-1 2>/dev/null || true
        fi
        
        if ! timeout 900 terraform destroy -var-file="dev.tfvars" -auto-approve -lock=false; then
            print_error "Destroy failed after retry. Attempting targeted destroy of problematic resources..."
            
            # Try to destroy VPC dependencies separately
            print_status "Destroying specific resources with dependencies first..."
            terraform destroy -var-file="dev.tfvars" -auto-approve -lock=false \
                -target=module.eks.aws_eks_node_group.application \
                -target=module.eks.aws_eks_node_group.github_runners \
                -target=module.eks.aws_eks_cluster.main 2>/dev/null || true
            
            sleep 30
            
            # Final destroy attempt
            timeout 600 terraform destroy -var-file="dev.tfvars" -auto-approve -lock=false || print_error "Final destroy failed, manual cleanup may be required"
        fi
    fi
    
    print_success "Infrastructure destroy command completed!"
    
    cd ../../
}

# Function to clean up local files
cleanup_local_files() {
    print_header "🧹 CLEANING UP LOCAL FILES"
    
    print_status "Removing Terraform local state files (keeping remote state)..."
    rm -f terraform/environments/terraform.tfstate* 2>/dev/null || true
    rm -f terraform/environments/.terraform.lock.hcl 2>/dev/null || true
    rm -rf terraform/environments/.terraform/ 2>/dev/null || true
    
    print_status "Cleaning kubectl config..."
    # Get actual context names
    CONTEXTS=$(kubectl config get-contexts -o name 2>/dev/null | grep "student-team4-iac-dev-cluster" || echo "")
    for ctx in $CONTEXTS; do
        kubectl config delete-context "$ctx" 2>/dev/null || true
    done
    
    # Get actual cluster names
    CLUSTERS=$(kubectl config get-clusters 2>/dev/null | grep "student-team4-iac-dev-cluster" || echo "")
    for cluster in $CLUSTERS; do
        kubectl config delete-cluster "$cluster" 2>/dev/null || true
    done
    
    print_success "Local files cleaned up!"
}

# Function to verify cleanup
verify_cleanup() {
    print_header "✅ VERIFYING CLEANUP"
    
    print_status "Checking for remaining AWS resources..."
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_warning "AWS credentials not configured, skipping verification"
        return 0
    fi
    
    # Check for EKS clusters
    CLUSTERS=$(aws eks list-clusters --region us-east-1 --query 'clusters' --output text 2>/dev/null | grep "student-team4-iac" || echo "")
    if [ -z "$CLUSTERS" ]; then
        print_success "✅ No EKS clusters found"
    else
        print_warning "⚠️ EKS cluster still exists: $CLUSTERS"
    fi
    
    # Check for VPCs
    VPCS=$(aws ec2 describe-vpcs --region us-east-1 --filters "Name=tag:Project,Values=student-team4-iac" --query 'Vpcs[].VpcId' --output text 2>/dev/null || echo "")
    if [ -z "$VPCS" ]; then
        print_success "✅ No project VPCs found"
    else
        print_warning "⚠️ Project VPC still exists: $VPCS"
    fi
    
    # Check for RDS instances
    RDS=$(aws rds describe-db-instances --region us-east-1 --query 'DBInstances[?contains(DBInstanceIdentifier, `student-team4`)].DBInstanceIdentifier' --output text 2>/dev/null || echo "")
    if [ -z "$RDS" ]; then
        print_success "✅ No RDS instances found"
    else
        print_warning "⚠️ RDS instances still exist: $RDS"
    fi
    
    # Check for Load Balancers
    LBS=$(aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-`) || contains(LoadBalancerName, `task-manager`)].LoadBalancerName' --output text 2>/dev/null || echo "")
    if [ -z "$LBS" ]; then
        print_success "✅ No Load Balancers found"
    else
        print_warning "⚠️ Load Balancers still exist: $LBS"
    fi
    
    # Check for EC2 instances
    EC2=$(aws ec2 describe-instances --region us-east-1 --filters "Name=tag:Project,Values=student-team4-iac" "Name=instance-state-name,Values=running,pending,stopping,stopped" --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null || echo "")
    if [ -z "$EC2" ]; then
        print_success "✅ No EC2 instances found"
    else
        print_warning "⚠️ EC2 instances still exist: $EC2"
    fi
    
    print_success "Cleanup verification completed!"
}

# Function to show help
show_help() {
    echo ""
    echo "🧹 Cloud-Native Task Manager Cleanup Script"
    echo ""
    echo "This script completely removes all AWS resources created by this project."
    echo ""
    echo "What gets deleted:"
    echo "  • EKS cluster and node groups"
    echo "  • VPC, subnets, and networking components"
    echo "  • RDS database instance"
    echo "  • Load Balancers and target groups"
    echo "  • IAM roles and policies"
    echo "  • ECR repositories (containers)"
    echo "  • All Kubernetes applications and services"
    echo ""
    echo "Usage:"
    echo "  $0                 Clean up everything"
    echo "  $0 --help         Show this help message"
    echo "  $0 --k8s-only     Only clean up Kubernetes resources"
    echo "  $0 --verify-only  Only verify cleanup status"
    echo ""
    echo "⚠️  WARNING: This action cannot be undone!"
    echo "💰 This will stop all AWS charges for this project."
    echo ""
}

# Main execution
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --k8s-only)
            print_header "🧹 KUBERNETES-ONLY CLEANUP"
            cleanup_kubernetes
            print_success "Kubernetes cleanup completed!"
            ;;
        --verify-only)
            verify_cleanup
            ;;
        "")
            print_header "🧹 COMPLETE INFRASTRUCTURE CLEANUP"
            echo ""
            echo "This will permanently delete ALL AWS resources created by this project."
            echo ""
            echo "⚠️  WARNING: This action cannot be undone!"
            echo "💾 Make sure you have backed up any important data!"
            echo "💰 This will stop all AWS charges for this project."
            echo ""
            
            print_warning "Are you absolutely sure you want to proceed?"
            wait_for_confirmation
            
            cleanup_kubernetes
            cleanup_vpc_dependencies
            destroy_infrastructure
            cleanup_local_files
            verify_cleanup
            
            print_header "🎉 CLEANUP COMPLETED!"
            echo ""
            print_success "All resources have been successfully cleaned up!"
            print_success "AWS charges for this project have been stopped."
            echo ""
            echo "To redeploy, run: ./scripts/deploy.sh"
            echo ""
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"