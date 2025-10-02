#!/bin/bash

# C4 Implementation Deployment Script
# Complete cloud-native Kubernetes architecture with FastAPI, self-hosted runners, and monitoring

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."

echo "🚀 C4 Implementation - Cloud-Native Kubernetes Architecture"
echo "==========================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if required tools are installed
    for tool in terraform kubectl helm docker aws; do
        if ! command -v $tool &> /dev/null; then
            print_error "$tool is not installed. Please install it first."
            exit 1
        fi
    done
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Deploy infrastructure
deploy_infrastructure() {
    local environment=$1
    print_info "Deploying infrastructure for environment: $environment"
    
    cd "$PROJECT_DIR/terraform/environments"
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_info "Planning Terraform deployment..."
    terraform plan -var-file="${environment}.tfvars" -out="${environment}.tfplan"
    
    # Apply deployment
    print_info "Applying Terraform deployment..."
    terraform apply "${environment}.tfplan"
    
    # Get cluster credentials
    print_info "Configuring kubectl..."
    local cluster_name=$(terraform output -raw cluster_name)
    local region=$(terraform output -raw region)
    aws eks update-kubeconfig --region $region --name $cluster_name
    
    print_status "Infrastructure deployed successfully"
}

# Build and push application image
build_application() {
    print_info "Building Task Manager application..."
    
    cd "$PROJECT_DIR/applications/task-manager"
    
    # Get AWS account ID and region for ECR
    local aws_account_id=$(aws sts get-caller-identity --query Account --output text)
    local aws_region=$(aws configure get region)
    local ecr_repo="$aws_account_id.dkr.ecr.$aws_region.amazonaws.com/task-manager"
    
    # Create ECR repository if it doesn't exist
    aws ecr describe-repositories --repository-names task-manager --region $aws_region 2>/dev/null || \
        aws ecr create-repository --repository-name task-manager --region $aws_region
    
    # Login to ECR
    aws ecr get-login-password --region $aws_region | docker login --username AWS --password-stdin $ecr_repo
    
    # Build and tag image
    docker build -t task-manager:latest .
    docker tag task-manager:latest $ecr_repo:latest
    docker tag task-manager:latest $ecr_repo:$(git rev-parse --short HEAD)
    
    # Push to ECR
    docker push $ecr_repo:latest
    docker push $ecr_repo:$(git rev-parse --short HEAD)
    
    print_status "Application built and pushed to ECR"
}

# Deploy applications via Helm
deploy_applications() {
    print_info "Deploying applications with Helm..."
    
    cd "$PROJECT_DIR"
    
    # Add Helm repositories
    print_info "Adding Helm repositories..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
    helm repo update
    
    # Deploy AWS Load Balancer Controller
    print_info "Deploying AWS Load Balancer Controller..."
    kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
    
    # Wait for CRDs to be ready
    sleep 10
    
    # Create namespace for monitoring
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy monitoring stack
    print_info "Deploying monitoring stack..."
    helm upgrade --install monitoring ./helm-charts/monitoring \
        --namespace monitoring \
        --values ./helm-charts/monitoring/values.yaml \
        --wait --timeout=10m
    
    # Deploy task manager (will be done by Terraform)
    print_info "Task Manager will be deployed via Terraform"
    
    print_status "Applications deployed successfully"
}

# Setup GitHub runner authentication
setup_github_auth() {
    print_info "Setting up GitHub Actions authentication..."
    
    # This would require GitHub App setup - instructions only
    print_warning "Manual step required: Set up GitHub App for self-hosted runners"
    print_info "1. Go to GitHub Settings > Developer Settings > GitHub Apps"
    print_info "2. Create a new GitHub App with repository permissions"
    print_info "3. Generate and download private key"
    print_info "4. Create Kubernetes secret with GitHub App credentials"
    
    cat << EOF
Example command to create GitHub auth secret:
kubectl create secret generic github-auth \\
  --from-literal=app_id=YOUR_APP_ID \\
  --from-literal=app_installation_id=YOUR_INSTALLATION_ID \\
  --from-file=app_private_key=path/to/private-key.pem \\
  --namespace=github-runners
EOF
}

# Verify deployment
verify_deployment() {
    print_info "Verifying deployment..."
    
    # Check cluster status
    kubectl get nodes
    
    # Check running pods
    kubectl get pods --all-namespaces
    
    # Check services
    kubectl get services --all-namespaces
    
    # Check ingresses
    kubectl get ingress --all-namespaces
    
    # Get application URLs
    print_info "Application URLs:"
    cd "$PROJECT_DIR/terraform/environments"
    echo "Task Manager API: $(terraform output -raw task_manager_url)"
    echo "Grafana Dashboard: $(terraform output -raw grafana_url)"
    
    print_status "Deployment verification completed"
}

# Cleanup function
cleanup() {
    local environment=$1
    print_warning "Cleaning up environment: $environment"
    
    cd "$PROJECT_DIR/terraform/environments"
    
    # Delete Helm releases first
    helm uninstall monitoring --namespace monitoring 2>/dev/null || true
    
    # Destroy Terraform infrastructure
    terraform destroy -var-file="${environment}.tfvars" -auto-approve
    
    print_status "Cleanup completed"
}

# Main script
main() {
    case "${1:-}" in
        "deploy")
            local environment="${2:-dev}"
            check_prerequisites
            build_application
            deploy_infrastructure $environment
            deploy_applications
            setup_github_auth
            verify_deployment
            ;;
        "build")
            build_application
            ;;
        "cleanup")
            local environment="${2:-dev}"
            cleanup $environment
            ;;
        "verify")
            verify_deployment
            ;;
        *)
            echo "Usage: $0 {deploy|build|cleanup|verify} [environment]"
            echo ""
            echo "Commands:"
            echo "  deploy [env]   - Deploy complete C4 infrastructure (default: dev)"
            echo "  build          - Build and push application image"
            echo "  cleanup [env]  - Destroy infrastructure (default: dev)"
            echo "  verify         - Verify deployment status"
            echo ""
            echo "Environments: dev, prod"
            echo ""
            echo "Example:"
            echo "  $0 deploy dev    # Deploy to development"
            echo "  $0 deploy prod   # Deploy to production"
            echo "  $0 cleanup dev   # Cleanup development"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"