#!/bin/bash

# 🔐 IAM Management Deployment Script
# This script manages IAM users, roles, and GitHub OIDC configuration
# Separate from main infrastructure as per C3.md recommendations

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

# Function to check GitHub token
check_github_token() {
    print_status "Checking GitHub token..."
    if [ -z "$GITHUB_TOKEN" ]; then
        print_error "GITHUB_TOKEN environment variable not set."
        print_error "Please export your GitHub personal access token:"
        print_error "  export GITHUB_TOKEN='your_github_token_here'"
        exit 1
    fi
    
    # Verify token works
    if ! curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | grep -q login; then
        print_error "Invalid GitHub token. Please check your GITHUB_TOKEN."
        exit 1
    fi
    
    print_success "GitHub token verified!"
}

# Function to ensure S3 backend exists
ensure_backend() {
    print_header "📦 ENSURING S3 BACKEND"
    
    print_status "Checking if S3 backend exists..."
    BUCKET_NAME="student-team4-iac-tfstate-2025-v2"
    
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        print_success "S3 backend already exists: $BUCKET_NAME"
    else
        print_warning "S3 backend does not exist. Running init-backend.sh..."
        if [ -f "../scripts/init-backend.sh" ]; then
            ../scripts/init-backend.sh
        else
            print_error "init-backend.sh not found. Please run it manually first."
            exit 1
        fi
    fi
}

# Function to deploy IAM resources
deploy_iam() {
    print_header "🔐 DEPLOYING IAM RESOURCES"
    
    cd terraform/iam
    
    print_status "Initializing Terraform with IAM backend configuration..."
    terraform init -backend-config="../backends/iam.config" -reconfigure
    
    # Check for and release any stale locks
    print_status "Checking for stale Terraform locks..."
    LOCK_OUTPUT=$(terraform plan -var-file="iam.tfvars" -var "github_token=$GITHUB_TOKEN" 2>&1 || true)
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
    
    print_status "Planning IAM deployment..."
    terraform plan -var-file="iam.tfvars" -var "github_token=$GITHUB_TOKEN"
    
    print_warning "This will create IAM users, roles, and GitHub OIDC configuration."
    print_warning "These resources will NOT be destroyed with the main infrastructure."
    wait_for_confirmation
    
    print_status "Deploying IAM resources..."
    terraform apply -var-file="iam.tfvars" -var "github_token=$GITHUB_TOKEN" -auto-approve
    
    print_success "IAM resources deployed successfully!"
    
    cd ../../
}

# Function to display IAM outputs
display_iam_info() {
    print_header "📋 IAM RESOURCES CREATED"
    
    cd terraform/iam
    
    print_status "Fetching IAM outputs..."
    echo ""
    
    # Display created users
    echo -e "${GREEN}👥 IAM Users Created:${NC}"
    terraform output -json team_member_users 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "  No team members found"
    echo ""
    
    # Display instructor
    INSTRUCTOR=$(terraform output -raw instructor_user 2>/dev/null || echo "")
    if [ ! -z "$INSTRUCTOR" ]; then
        echo -e "${GREEN}👨‍🏫 Instructor User:${NC} $INSTRUCTOR"
        echo ""
    fi
    
    # Display OIDC provider
    OIDC=$(terraform output -raw github_oidc_provider_arn 2>/dev/null || echo "")
    if [ ! -z "$OIDC" ]; then
        echo -e "${GREEN}🔐 GitHub OIDC Provider:${NC}"
        echo "  $OIDC"
        echo ""
    fi
    
    # Display GitHub secrets
    echo -e "${GREEN}🔑 GitHub Secrets to Configure:${NC}"
    echo "  The following secrets should be set in your GitHub repository:"
    echo ""
    
    AWS_ROLE_DEV=$(terraform output -raw github_actions_role_dev_arn 2>/dev/null || echo "")
    AWS_ROLE_PROD=$(terraform output -raw github_actions_role_prod_arn 2>/dev/null || echo "")
    
    if [ ! -z "$AWS_ROLE_DEV" ]; then
        echo -e "  ${BLUE}AWS_ROLE_DEV:${NC} $AWS_ROLE_DEV"
    fi
    
    if [ ! -z "$AWS_ROLE_PROD" ]; then
        echo -e "  ${BLUE}AWS_ROLE_PROD:${NC} $AWS_ROLE_PROD"
    fi
    
    echo ""
    
    # Display credentials location
    echo -e "${GREEN}📁 Credentials Location:${NC}"
    echo "  User credentials are stored in: terraform/iam/credentials/"
    echo ""
    echo "  Files created:"
    if [ -d "credentials" ]; then
        ls -1 credentials/*.json 2>/dev/null | while read file; do
            echo "    - $(basename $file)"
        done
    fi
    echo ""
    
    cd ../../
    
    print_success "IAM deployment completed!"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT SECURITY NOTES:${NC}"
    echo "  1. Distribute credentials securely to team members"
    echo "  2. Credentials are encrypted with the instructor's PGP key"
    echo "  3. Configure the GitHub secrets in your repository settings"
    echo "  4. These IAM resources persist independently of main infrastructure"
    echo ""
}

# Function to verify prerequisites
verify_prerequisites() {
    print_header "🔍 VERIFYING PREREQUISITES"
    
    print_status "Checking required tools..."
    check_command "aws"
    check_command "terraform"
    check_command "jq"
    check_command "curl"
    
    print_success "All required tools are installed!"
    
    check_aws_credentials
    check_github_token
}

# Function to show help
show_help() {
    echo ""
    echo "🔐 IAM Management Deployment Script"
    echo ""
    echo "This script manages IAM users, roles, and GitHub OIDC configuration."
    echo "IAM resources are managed separately from infrastructure as per C3.md."
    echo ""
    echo "Usage:"
    echo "  $0                 Deploy IAM resources"
    echo "  $0 --help         Show this help message"
    echo "  $0 --check-only   Only verify prerequisites"
    echo "  $0 --destroy      Destroy IAM resources"
    echo ""
    echo "Prerequisites:"
    echo "  • AWS CLI configured with admin credentials"
    echo "  • Terraform installed"
    echo "  • GITHUB_TOKEN environment variable set"
    echo "  • S3 backend initialized (runs automatically if missing)"
    echo ""
    echo "What gets created:"
    echo "  • IAM users for team members (4 students)"
    echo "  • IAM user for instructor (Jérémie Jaouen)"
    echo "  • GitHub OIDC provider for CI/CD"
    echo "  • IAM roles for GitHub Actions (dev & prod)"
    echo "  • Access keys and credentials (encrypted)"
    echo ""
    echo "Environment variables:"
    echo "  GITHUB_TOKEN       GitHub personal access token (required)"
    echo ""
}

# Function to destroy IAM resources
destroy_iam() {
    print_header "🗑️  DESTROYING IAM RESOURCES"
    
    cd terraform/iam
    
    print_status "Initializing Terraform..."
    terraform init -backend-config="../backends/iam.config" -reconfigure
    
    print_warning "This will delete all IAM users, roles, and OIDC configuration!"
    print_warning "Team members will lose access to AWS resources!"
    wait_for_confirmation
    
    print_status "Destroying IAM resources..."
    terraform destroy -var-file="iam.tfvars" -var "github_token=$GITHUB_TOKEN" -auto-approve
    
    print_success "IAM resources destroyed!"
    
    cd ../../
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
        --destroy)
            print_header "🔐 IAM MANAGEMENT - DESTROY MODE"
            echo ""
            echo "⚠️  WARNING: This will destroy all IAM resources!"
            echo ""
            
            verify_prerequisites
            destroy_iam
            ;;
        "")
            print_header "🔐 IAM MANAGEMENT DEPLOYMENT"
            echo ""
            echo "This script will create and manage IAM resources."
            echo ""
            echo "⏱️  Estimated time: 5-10 minutes"
            echo "🌍 Target region: us-east-1"
            echo ""
            
            verify_prerequisites
            wait_for_confirmation
            
            ensure_backend
            deploy_iam
            display_iam_info
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
