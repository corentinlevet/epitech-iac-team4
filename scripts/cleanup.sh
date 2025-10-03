#!/bin/bash

# 🧹 Cleanup Script - Destroys all AWS resources created by this project
# Use this script to completely remove the infrastructure and avoid ongoing charges

set -e  # Exit on any error

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
        print_warning "kubectl not configured or cluster not accessible"
        return 0
    fi
    
    print_status "Uninstalling Helm releases..."
    helm uninstall task-manager 2>/dev/null || print_warning "task-manager release not found"
    helm uninstall task-manager-frontend 2>/dev/null || print_warning "task-manager-frontend release not found"
    
    print_status "Deleting monitoring resources..."
    kubectl delete -f kubernetes-manifests/monitoring/final-grafana.yaml --ignore-not-found=true
    kubectl delete -f kubernetes-manifests/monitoring/final-prometheus.yaml --ignore-not-found=true
    
    print_status "Deleting monitoring namespace..."
    kubectl delete namespace monitoring --ignore-not-found=true
    
    print_status "Waiting for Load Balancers to be deleted (this may take 2-3 minutes)..."
    echo "Checking for remaining LoadBalancer services..."
    
    # Wait for all LoadBalancer services to be deleted
    while true; do
        LB_SERVICES=$(kubectl get svc --all-namespaces --field-selector spec.type=LoadBalancer -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
        if [ -z "$LB_SERVICES" ]; then
            break
        fi
        echo -n "."
        sleep 10
    done
    
    print_success "Kubernetes resources cleaned up!"
}

# Function to destroy infrastructure
destroy_infrastructure() {
    print_header "🏗️ DESTROYING AWS INFRASTRUCTURE"
    
    cd terraform/environments
    
    print_status "Checking Terraform state..."
    if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
        print_warning "No Terraform state found. Infrastructure may already be destroyed."
        cd ../../
        return 0
    fi
    
    print_status "Planning infrastructure destruction..."
    terraform plan -destroy -var-file="dev.tfvars"
    
    print_warning "This will permanently delete all AWS resources!"
    print_warning "This action cannot be undone!"
    wait_for_confirmation
    
    print_status "Destroying infrastructure (this may take 10-15 minutes)..."
    terraform destroy -var-file="dev.tfvars" -auto-approve
    
    print_success "Infrastructure destroyed successfully!"
    
    cd ../../
}

# Function to clean up local files
cleanup_local_files() {
    print_header "🧹 CLEANING UP LOCAL FILES"
    
    print_status "Removing Terraform state files..."
    rm -f terraform/environments/terraform.tfstate*
    rm -f terraform/environments/.terraform.lock.hcl
    rm -rf terraform/environments/.terraform/
    
    print_status "Cleaning kubectl config..."
    kubectl config delete-context arn:aws:eks:us-east-1:*:cluster/student-team4-iac-dev-cluster 2>/dev/null || true
    kubectl config delete-cluster arn:aws:eks:us-east-1:*:cluster/student-team4-iac-dev-cluster 2>/dev/null || true
    
    print_success "Local files cleaned up!"
}

# Function to verify cleanup
verify_cleanup() {
    print_header "✅ VERIFYING CLEANUP"
    
    print_status "Checking for remaining AWS resources..."
    
    # Check for EKS clusters
    CLUSTERS=$(aws eks list-clusters --query 'clusters' --output text 2>/dev/null | grep "student-team4-iac-dev-cluster" || echo "")
    if [ -z "$CLUSTERS" ]; then
        print_success "✅ No EKS clusters found"
    else
        print_warning "⚠️ EKS cluster still exists: $CLUSTERS"
    fi
    
    # Check for VPCs
    VPCS=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=student-team4-iac-dev-vpc" --query 'Vpcs[].VpcId' --output text 2>/dev/null || echo "")
    if [ -z "$VPCS" ]; then
        print_success "✅ No project VPCs found"
    else
        print_warning "⚠️ Project VPC still exists: $VPCS"
    fi
    
    # Check for Load Balancers
    LBS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-`) || contains(LoadBalancerName, `task-manager`)].LoadBalancerName' --output text 2>/dev/null || echo "")
    if [ -z "$LBS" ]; then
        print_success "✅ No Load Balancers found"
    else
        print_warning "⚠️ Load Balancers still exist: $LBS"
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