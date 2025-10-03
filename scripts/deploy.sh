#!/bin/bash

# 🚀 Complete Cloud-Native Task Manager Deployment Script
# This script deploys the entire infrastructure and applications

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

# Function to wait for user input
wait_for_confirmation() {
    read -p "Press [Enter] to continue or [Ctrl+C] to abort..."
}

# Function to check AWS credentials
check_aws_credentials() {
    print_status "Checking AWS credentials..."
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REGION=$(aws configure get region)
    print_success "AWS credentials configured for account: $ACCOUNT_ID in region: $REGION"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_header "🏗️ DEPLOYING INFRASTRUCTURE"
    
    cd terraform/environments
    
    print_status "Initializing Terraform..."
    terraform init
    
    print_status "Planning infrastructure deployment..."
    terraform plan -var-file="dev.tfvars"
    
    print_warning "This will create AWS resources that may incur charges."
    wait_for_confirmation
    
    print_status "Deploying infrastructure (this may take 15-20 minutes)..."
    terraform apply -var-file="dev.tfvars" -auto-approve
    
    print_success "Infrastructure deployed successfully!"
    
    cd ../../
}

# Function to configure kubectl
configure_kubectl() {
    print_header "⚓ CONFIGURING KUBERNETES ACCESS"
    
    print_status "Updating kubeconfig for EKS cluster..."
    aws eks update-kubeconfig --region us-east-1 --name student-team4-iac-dev-cluster
    
    print_status "Verifying cluster access..."
    kubectl get nodes
    
    print_success "Kubernetes access configured successfully!"
}

# Function to deploy monitoring
deploy_monitoring() {
    print_header "📊 DEPLOYING MONITORING STACK"
    
    print_status "Creating monitoring namespace..."
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    print_status "Deploying Prometheus..."
    kubectl apply -f kubernetes-manifests/monitoring/final-prometheus.yaml
    
    print_status "Deploying Grafana..."
    kubectl apply -f kubernetes-manifests/monitoring/final-grafana.yaml
    
    print_status "Waiting for monitoring pods to be ready..."
    kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=300s
    kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s
    
    print_success "Monitoring stack deployed successfully!"
}

# Function to deploy applications
deploy_applications() {
    print_header "🚀 DEPLOYING APPLICATIONS"
    
    print_status "Deploying Task Manager Backend..."
    helm install task-manager helm-charts/task-manager/ --wait
    
    print_status "Deploying Task Manager Frontend..."
    helm install task-manager-frontend helm-charts/task-manager-frontend/ --wait
    
    print_status "Waiting for applications to be ready..."
    kubectl wait --for=condition=ready pod -l app=task-manager --timeout=300s
    kubectl wait --for=condition=ready pod -l app=task-manager-frontend --timeout=300s
    
    print_success "Applications deployed successfully!"
}

# Function to wait for load balancers
wait_for_load_balancers() {
    print_header "🌐 WAITING FOR LOAD BALANCERS"
    
    print_status "Waiting for Load Balancers to get external IPs (this may take 2-3 minutes)..."
    
    # Wait for frontend
    print_status "Waiting for frontend Load Balancer..."
    while true; do
        FRONTEND_IP=$(kubectl get svc task-manager-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        if [ ! -z "$FRONTEND_IP" ] && [ "$FRONTEND_IP" != "null" ]; then
            break
        fi
        echo -n "."
        sleep 10
    done
    print_success "Frontend Load Balancer ready!"
    
    # Wait for backend
    print_status "Waiting for backend Load Balancer..."
    while true; do
        BACKEND_IP=$(kubectl get svc task-manager -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        if [ ! -z "$BACKEND_IP" ] && [ "$BACKEND_IP" != "null" ]; then
            break
        fi
        echo -n "."
        sleep 10
    done
    print_success "Backend Load Balancer ready!"
    
    # Wait for monitoring
    print_status "Waiting for monitoring Load Balancers..."
    while true; do
        GRAFANA_IP=$(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        PROMETHEUS_IP=$(kubectl get svc prometheus -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        if [ ! -z "$GRAFANA_IP" ] && [ "$GRAFANA_IP" != "null" ] && [ ! -z "$PROMETHEUS_IP" ] && [ "$PROMETHEUS_IP" != "null" ]; then
            break
        fi
        echo -n "."
        sleep 10
    done
    print_success "Monitoring Load Balancers ready!"
}

# Function to display access information
display_access_info() {
    print_header "🎉 DEPLOYMENT COMPLETED!"
    
    # Get service URLs
    FRONTEND_URL=$(kubectl get svc task-manager-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    BACKEND_URL=$(kubectl get svc task-manager -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    GRAFANA_URL=$(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    PROMETHEUS_URL=$(kubectl get svc prometheus -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    echo ""
    echo -e "${GREEN}🎯 ACCESS YOUR APPLICATIONS:${NC}"
    echo ""
    echo -e "📱 ${BLUE}Task Manager Frontend:${NC} http://$FRONTEND_URL"
    echo -e "   ${YELLOW}→${NC} Main application interface"
    echo ""
    echo -e "🔧 ${BLUE}API Documentation:${NC} http://$BACKEND_URL/docs"
    echo -e "   ${YELLOW}→${NC} Interactive API documentation and testing"
    echo ""
    echo -e "📊 ${BLUE}Prometheus Metrics:${NC} http://$PROMETHEUS_URL:9090"
    echo -e "   ${YELLOW}→${NC} Metrics collection and querying"
    echo ""
    echo -e "📈 ${BLUE}Grafana Dashboards:${NC} http://$GRAFANA_URL"
    echo -e "   ${YELLOW}→${NC} Username: admin | Password: admin (change on first login)"
    echo ""
    echo -e "${GREEN}💡 NEXT STEPS:${NC}"
    echo ""
    echo "1. 🌐 Open the frontend URL to access the Task Manager application"
    echo "2. � Log into Grafana to view monitoring dashboards"
    echo "3. 🔧 Check the API documentation for available endpoints"
    echo "4. 📚 Read the documentation in the docs/ directory"
    echo ""
    echo -e "${YELLOW}💰 COST REMINDER:${NC} This deployment creates AWS resources that incur charges."
    echo "   Run './scripts/cleanup.sh' when you're done to delete everything."
    echo ""
    print_success "Happy cloud-native computing! �"
}

# Function to verify prerequisites
verify_prerequisites() {
    print_header "🔍 VERIFYING PREREQUISITES"
    
    print_status "Checking required tools..."
    check_command "aws"
    check_command "terraform"
    check_command "kubectl"
    check_command "helm"
    check_command "docker"
    
    print_success "All required tools are installed!"
    
    check_aws_credentials
}

# Function to show help
show_help() {
    echo ""
    echo "🚀 Cloud-Native Task Manager Deployment Script"
    echo ""
    echo "This script deploys a complete cloud-native application stack including:"
    echo "  • AWS EKS cluster with auto-scaling"
    echo "  • Task Manager application (FastAPI + React)"
    echo "  • PostgreSQL database"
    echo "  • Prometheus and Grafana monitoring"
    echo ""
    echo "Usage:"
    echo "  $0                 Deploy everything"
    echo "  $0 --help         Show this help message"
    echo "  $0 --check-only   Only verify prerequisites"
    echo ""
    echo "Prerequisites:"
    echo "  • AWS CLI configured with credentials"
    echo "  • Terraform, kubectl, helm, docker installed"
    echo "  • AWS account with admin permissions"
    echo ""
    echo "Estimated deployment time: 20-25 minutes"
    echo "Estimated AWS cost: $5-10 per day"
    echo ""
}

# Main execution
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --check-only)
            verify_prerequisites
            exit 0
            ;;
        "")
            print_header "🚀 CLOUD-NATIVE TASK MANAGER DEPLOYMENT"
            echo ""
            echo "This script will deploy a complete cloud-native application stack."
            echo ""
            echo "⏱️  Estimated time: 20-25 minutes"
            echo "💰 Estimated cost: $5-10 per day"
            echo "🌍 Target region: us-east-1"
            echo ""
            
            verify_prerequisites
            wait_for_confirmation
            
            deploy_infrastructure
            configure_kubectl
            deploy_monitoring
            deploy_applications
            wait_for_load_balancers
            display_access_info
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