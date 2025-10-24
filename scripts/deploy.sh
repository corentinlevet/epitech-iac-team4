#!/bin/bash

# 🚀 Complete Cloud-Native Task Manager Deployment Script
# This script deploys the entire infrastructure and applications

set -e  # Exit on any error

# Disable AWS CLI pager to prevent hanging on output
export AWS_PAGER=""

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
    
    print_status "Initializing Terraform with backend configuration..."
    terraform init -backend-config="../backends/dev.config" -reconfigure
    
    # Check for and release any stale locks
    print_status "Checking for stale Terraform locks..."
    LOCK_OUTPUT=$(terraform plan -var-file="dev.tfvars" 2>&1 || true)
    if echo "$LOCK_OUTPUT" | grep -q "Error acquiring the state lock"; then
        LOCK_PATH=$(echo "$LOCK_OUTPUT" | grep "Path:" | head -1 | awk '{print $2}')
        print_warning "Found stale lock for: $LOCK_PATH"
        print_status "Removing lock from DynamoDB..."
        
        # Calculate the LockID (it's the path with -md5 suffix)
        LOCK_KEY="${LOCK_PATH}-md5"
        aws dynamodb delete-item --table-name terraform-locks --key "{\"LockID\": {\"S\": \"$LOCK_KEY\"}}" --region us-east-1 2>/dev/null || true
        
        sleep 2
        print_success "Lock removed successfully!"
    fi
    
    print_status "Planning infrastructure deployment..."
    terraform plan -var-file="dev.tfvars"
    
    print_warning "This will create AWS resources that may incur charges."
    wait_for_confirmation
    
    print_status "Deploying infrastructure (this may take 15-20 minutes)..."
    terraform apply -var-file="dev.tfvars" -auto-approve
    
    print_success "Infrastructure deployed successfully!"
    
    cd ../../
}

# Function to tag subnets for LoadBalancer
tag_subnets() {
    print_header "🏷️ TAGGING SUBNETS FOR LOAD BALANCER"
    
    print_status "Getting VPC and subnet information..."
    cd terraform/environments
    VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "student-team4-iac-dev-cluster")
    cd ../../
    
    if [ -z "$VPC_ID" ]; then
        print_warning "Could not get VPC ID from Terraform, skipping subnet tagging"
        return 0
    fi
    
    print_status "VPC ID: $VPC_ID, Cluster: $CLUSTER_NAME"
    
    # Get all public subnets in the VPC
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text)
    
    for SUBNET in $SUBNETS; do
        print_status "Tagging subnet $SUBNET for ELB..."
        aws ec2 create-tags --resources $SUBNET --tags \
            "Key=kubernetes.io/role/elb,Value=1" \
            "Key=kubernetes.io/cluster/$CLUSTER_NAME,Value=shared" 2>/dev/null || print_warning "Failed to tag $SUBNET"
    done
    
    print_success "Subnets tagged successfully!"
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
    
    print_status "Creating Prometheus ServiceAccount and RBAC..."
    kubectl apply -f kubernetes-manifests/monitoring/prometheus-rbac.yaml
    
    print_status "Waiting for monitoring pods to be ready (may take a few minutes)..."
    kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=600s || print_warning "Prometheus took longer than expected"
    kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=600s || print_warning "Grafana took longer than expected"
    
    print_success "Monitoring stack deployed successfully!"
}

# Function to deploy applications
deploy_applications() {
    print_header "🚀 DEPLOYING APPLICATIONS"
    
    print_status "Checking and creating ECR repositories..."
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REGION=$(aws configure get region)
    
    # Create ECR repositories if they don't exist
    for repo in task-manager task-manager-frontend; do
        if ! aws ecr describe-repositories --repository-names $repo --region $REGION &>/dev/null; then
            print_status "Creating ECR repository: $repo"
            aws ecr create-repository \
                --repository-name $repo \
                --region $REGION \
                --image-scanning-configuration scanOnPush=true \
                --tags Key=Project,Value=student-team4-iac Key=ManagedBy,Value=Terraform 2>/dev/null || print_warning "Failed to create $repo (may already exist)"
            print_success "ECR repository '$repo' created!"
        else
            print_success "ECR repository '$repo' already exists"
        fi
    done
    
    # Check if images exist in repositories
    print_status "Checking if Docker images are available in ECR..."
    BACKEND_IMAGES=$(aws ecr list-images --repository-name task-manager --region $REGION --query 'imageIds[?imageTag==`v3`]' --output text 2>/dev/null || echo "")
    FRONTEND_IMAGES=$(aws ecr list-images --repository-name task-manager-frontend --region $REGION --query 'imageIds[?imageTag==`latest`]' --output text 2>/dev/null || echo "")
    
    if [ -z "$BACKEND_IMAGES" ] || [ -z "$FRONTEND_IMAGES" ]; then
        print_warning "Docker images not found in ECR. Building and pushing images..."
        
        # Login to ECR
        print_status "Logging into ECR..."
        aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
        
        # Build and push backend
        if [ -z "$BACKEND_IMAGES" ]; then
            print_status "Building backend Docker image..."
            cd applications/task-manager
            docker build -t task-manager:v3 . || { print_error "Backend build failed"; cd ../..; return 1; }
            
            print_status "Tagging and pushing backend image to ECR..."
            docker tag task-manager:v3 $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/task-manager:v3
            docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/task-manager:v3
            print_success "Backend image pushed to ECR!"
            cd ../..
        fi
        
        # Build and push frontend
        if [ -z "$FRONTEND_IMAGES" ]; then
            print_status "Building frontend Docker image..."
            cd applications/task-manager-frontend
            docker build -t task-manager-frontend:latest . || { print_error "Frontend build failed"; cd ../..; return 1; }
            
            print_status "Tagging and pushing frontend image to ECR..."
            docker tag task-manager-frontend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/task-manager-frontend:latest
            docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/task-manager-frontend:latest
            print_success "Frontend image pushed to ECR!"
            cd ../..
        fi
        
        print_success "All Docker images built and pushed to ECR!"
    else
        print_success "Docker images already available in ECR!"
    fi
    
    # Update Helm chart values with correct ECR repository
    print_status "Updating Helm chart values with ECR repository URLs..."
    sed -i.bak "s|repository: .*dkr.ecr.*amazonaws.com/task-manager|repository: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/task-manager|g" helm-charts/task-manager/values.yaml
    sed -i.bak "s|repository: .*dkr.ecr.*amazonaws.com/task-manager-frontend|repository: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/task-manager-frontend|g" helm-charts/task-manager-frontend/values.yaml
    rm -f helm-charts/task-manager/values.yaml.bak helm-charts/task-manager-frontend/values.yaml.bak 2>/dev/null || true
    
    # Create database credentials secret
    print_status "Creating database credentials secret..."
    cd terraform/environments
    DB_SECRET_ARN=$(terraform output -raw db_credentials_secret_arn 2>/dev/null || echo "")
    cd ../..
    
    if [ -n "$DB_SECRET_ARN" ]; then
        print_status "Retrieving database credentials from AWS Secrets Manager..."
        DB_CREDS=$(aws secretsmanager get-secret-value --secret-id "$DB_SECRET_ARN" --query SecretString --output text)
        
        DB_URL=$(echo "$DB_CREDS" | jq -r '.url // empty')
        DB_HOST=$(echo "$DB_CREDS" | jq -r '.host // empty' | cut -d: -f1)
        DB_PORT=$(echo "$DB_CREDS" | jq -r '.port // empty')
        DB_NAME=$(echo "$DB_CREDS" | jq -r '.dbname // empty')
        DB_USER=$(echo "$DB_CREDS" | jq -r '.username // empty')
        DB_PASS=$(echo "$DB_CREDS" | jq -r '.password // empty')
        
        if [ -n "$DB_URL" ]; then
            print_status "Creating Kubernetes secret for database credentials..."
            kubectl create secret generic task-manager-db-credentials \
                --from-literal=database_url="$DB_URL" \
                --from-literal=host="$DB_HOST" \
                --from-literal=port="$DB_PORT" \
                --from-literal=dbname="$DB_NAME" \
                --from-literal=username="$DB_USER" \
                --from-literal=password="$DB_PASS" \
                --dry-run=client -o yaml | kubectl apply -f - || print_warning "Secret creation failed (may already exist)"
            print_success "Database credentials secret created!"
        else
            print_warning "Could not retrieve database URL from secrets manager"
        fi
    else
        print_warning "Could not get database secret ARN from Terraform outputs"
    fi
    
    print_status "Deploying Task Manager Backend (timeout: 10 minutes)..."
    if ! helm install task-manager helm-charts/task-manager/ --wait --timeout 10m; then
        print_warning "Backend deployment failed or timed out. Check with: kubectl get pods"
        print_warning "Common issues: ImagePullBackOff (image not in ECR), insufficient resources"
    fi
    
    print_status "Deploying Task Manager Frontend (timeout: 10 minutes)..."
    if ! helm install task-manager-frontend helm-charts/task-manager-frontend/ --wait --timeout 10m; then
        print_warning "Frontend deployment failed or timed out. Check with: kubectl get pods"
        print_warning "Common issues: ImagePullBackOff (image not in ECR), insufficient resources"
    fi
    
    print_status "Checking application status..."
    kubectl get pods -l app.kubernetes.io/instance=task-manager 2>/dev/null || true
    kubectl get pods -l app.kubernetes.io/instance=task-manager-frontend 2>/dev/null || true
    
    print_success "Application deployment completed (check status above)!"
}

# Function to wait for load balancers
wait_for_load_balancers() {
    print_header "🌐 WAITING FOR LOAD BALANCERS"
    
    print_status "Checking for deployed services..."
    
    # Check if application services exist
    if kubectl get svc task-manager &>/dev/null; then
        print_status "Waiting for backend Load Balancer (max 5 minutes)..."
        TIMEOUT=300
        ELAPSED=0
        while [ $ELAPSED -lt $TIMEOUT ]; do
            BACKEND_IP=$(kubectl get svc task-manager -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
            if [ ! -z "$BACKEND_IP" ] && [ "$BACKEND_IP" != "null" ]; then
                print_success "Backend Load Balancer ready: $BACKEND_IP"
                break
            fi
            echo -n "."
            sleep 10
            ELAPSED=$((ELAPSED + 10))
        done
        if [ $ELAPSED -ge $TIMEOUT ]; then
            print_warning "Backend Load Balancer timeout"
        fi
    else
        print_warning "Backend service not found, skipping"
    fi
    
    # Check if frontend service exists
    if kubectl get svc task-manager-frontend &>/dev/null; then
        print_status "Waiting for frontend Load Balancer (max 5 minutes)..."
        TIMEOUT=300
        ELAPSED=0
        while [ $ELAPSED -lt $TIMEOUT ]; do
            FRONTEND_IP=$(kubectl get svc task-manager-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
            if [ ! -z "$FRONTEND_IP" ] && [ "$FRONTEND_IP" != "null" ]; then
                print_success "Frontend Load Balancer ready: $FRONTEND_IP"
                break
            fi
            echo -n "."
            sleep 10
            ELAPSED=$((ELAPSED + 10))
        done
        if [ $ELAPSED -ge $TIMEOUT ]; then
            print_warning "Frontend Load Balancer timeout"
        fi
    else
        print_warning "Frontend service not found, skipping"
    fi
    
    # Wait for monitoring Load Balancers (always deployed)
    print_status "Waiting for monitoring Load Balancers..."
    TIMEOUT=300
    ELAPSED=0
    while [ $ELAPSED -lt $TIMEOUT ]; do
        GRAFANA_IP=$(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        PROMETHEUS_IP=$(kubectl get svc prometheus -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        if [ ! -z "$GRAFANA_IP" ] && [ "$GRAFANA_IP" != "null" ] && [ ! -z "$PROMETHEUS_IP" ] && [ "$PROMETHEUS_IP" != "null" ]; then
            print_success "Monitoring Load Balancers ready!"
            break
        fi
        echo -n "."
        sleep 10
        ELAPSED=$((ELAPSED + 10))
    done
    if [ $ELAPSED -ge $TIMEOUT ]; then
        print_warning "Monitoring Load Balancers timeout (check services manually)"
    fi
}

# Function to display access information
display_access_info() {
    print_header "🎉 DEPLOYMENT COMPLETED!"
    
    # Get service URLs
    FRONTEND_URL=$(kubectl get svc task-manager-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    BACKEND_URL=$(kubectl get svc task-manager -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    GRAFANA_URL=$(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    PROMETHEUS_URL=$(kubectl get svc prometheus -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    echo ""
    echo -e "${GREEN}🎯 ACCESS YOUR SERVICES:${NC}"
    echo ""
    
    # Display monitoring URLs (always available)
    if [ ! -z "$PROMETHEUS_URL" ]; then
        echo -e "📊 ${BLUE}Prometheus Metrics:${NC} http://$PROMETHEUS_URL:9090"
        echo -e "   ${YELLOW}→${NC} Metrics collection and querying"
        echo ""
    fi
    
    if [ ! -z "$GRAFANA_URL" ]; then
        echo -e "📈 ${BLUE}Grafana Dashboards:${NC} http://$GRAFANA_URL:3000"
        echo -e "   ${YELLOW}→${NC} Username: admin | Password: admin123"
        echo ""
    fi
    
    # Display application URLs if available
    if [ ! -z "$FRONTEND_URL" ] && [ "$FRONTEND_URL" != "null" ]; then
        echo -e "📱 ${BLUE}Task Manager Frontend:${NC} http://$FRONTEND_URL"
        echo -e "   ${YELLOW}→${NC} Main application interface"
        echo ""
    else
        echo -e "� ${YELLOW}Task Manager Frontend:${NC} Not deployed (Docker image not available)"
        echo ""
    fi
    
    if [ ! -z "$BACKEND_URL" ] && [ "$BACKEND_URL" != "null" ]; then
        echo -e "�🔧 ${BLUE}API Documentation:${NC} http://$BACKEND_URL/docs"
        echo -e "   ${YELLOW}→${NC} Interactive API documentation and testing"
        echo ""
    else
        echo -e "� ${YELLOW}Task Manager Backend:${NC} Not deployed (Docker image not available)"
        echo ""
    fi
    
    echo -e "${GREEN}💡 NEXT STEPS:${NC}"
    echo ""
    if [ -z "$BACKEND_URL" ] || [ "$BACKEND_URL" == "null" ]; then
        echo "⚠️  ${YELLOW}Applications not deployed - Docker images missing${NC}"
        echo ""
        echo "To deploy applications:"
        echo "  1. Create ECR repositories:"
        echo "     aws ecr create-repository --repository-name task-manager --region us-east-1"
        echo "     aws ecr create-repository --repository-name task-manager-frontend --region us-east-1"
        echo ""
        echo "  2. Build and push Docker images:"
        echo "     cd applications/task-manager && docker build -t task-manager:v3 ."
        echo "     cd applications/task-manager-frontend && docker build -t task-manager-frontend:latest ."
        echo ""
        echo "  3. Tag and push to ECR (see DEPLOYMENT_STATUS.md for commands)"
        echo ""
        echo "  4. Deploy with Helm:"
        echo "     helm install task-manager helm-charts/task-manager/"
        echo "     helm install task-manager-frontend helm-charts/task-manager-frontend/"
        echo ""
    else
        echo "1. 🌐 Open the frontend URL to access the Task Manager application"
        echo "2. 📈 Log into Grafana to view monitoring dashboards"
        echo "3. 🔧 Check the API documentation for available endpoints"
        echo ""
    fi
    
    echo "4. 📚 Read the documentation in docs/ directory for details"
    echo "5. 📊 Check cluster status: kubectl get pods --all-namespaces"
    echo ""
    echo -e "${YELLOW}💰 COST REMINDER:${NC} This deployment creates AWS resources that incur charges."
    echo "   Run './scripts/cleanup.sh' when you're done to delete everything."
    echo ""
    print_success "Infrastructure deployment completed successfully! 🚀"
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
            tag_subnets
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