#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

print_header() {
    echo
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Configuration
GITHUB_REPO="corentinlevet/epitech-iac-team4"
DEV_ROLE_NAME="GitHubActions-Dev-Role"
PROD_ROLE_NAME="GitHubActions-Prod-Role"
AWS_PROFILE="${AWS_PROFILE:-corentin-levet}"

# Main function
main() {
    print_header "GITHUB ACTIONS OIDC SETUP FOR AWS"
    
    # Step 1: Get AWS Account ID
    print_header "STEP 1: GETTING AWS ACCOUNT INFORMATION"
    
    print_info "Using AWS Profile: $AWS_PROFILE"
    
    if ! AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query 'Account' --output text 2>/dev/null); then
        print_error "Failed to get AWS Account ID. Please check:"
        print_error "1. AWS credentials are configured"
        print_error "2. AWS profile '$AWS_PROFILE' exists"
        print_error "3. Internet connectivity is working"
        echo
        print_info "You can find your Account ID in AWS Console → Support → Support Center"
        print_info "Or try: aws configure list-profiles"
        exit 1
    fi
    
    print_status "AWS Account ID: $AWS_ACCOUNT_ID"
    
    # Step 2: Update trust policy files
    print_header "STEP 2: UPDATING TRUST POLICY FILES"
    
    # Update development trust policy
    if [[ -f "github-trust-policy-dev.json" ]]; then
        sed -i.bak "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" github-trust-policy-dev.json
        print_status "Updated github-trust-policy-dev.json"
    else
        print_error "github-trust-policy-dev.json not found"
        exit 1
    fi
    
    # Update production trust policy
    if [[ -f "github-trust-policy-prod.json" ]]; then
        sed -i.bak "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" github-trust-policy-prod.json
        print_status "Updated github-trust-policy-prod.json"
    else
        print_error "github-trust-policy-prod.json not found"
        exit 1
    fi
    
    # Step 3: Create OIDC Provider
    print_header "STEP 3: CREATING OIDC IDENTITY PROVIDER"
    
    if aws iam get-open-id-connect-provider \
        --open-id-connect-provider-arn "arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com" \
        --profile "$AWS_PROFILE" >/dev/null 2>&1; then
        print_warning "OIDC provider already exists (this is fine)"
    else
        print_info "Creating OIDC identity provider..."
        aws iam create-open-id-connect-provider \
            --url https://token.actions.githubusercontent.com \
            --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
            --client-id-list sts.amazonaws.com \
            --profile "$AWS_PROFILE"
        print_status "OIDC provider created successfully"
    fi
    
    # Step 4: Create Development Role
    print_header "STEP 4: CREATING DEVELOPMENT IAM ROLE"
    
    if aws iam get-role --role-name "$DEV_ROLE_NAME" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
        print_warning "Development role already exists"
        print_info "Updating trust policy..."
        aws iam update-assume-role-policy \
            --role-name "$DEV_ROLE_NAME" \
            --policy-document file://github-trust-policy-dev.json \
            --profile "$AWS_PROFILE"
        print_status "Development role trust policy updated"
    else
        print_info "Creating development role..."
        aws iam create-role \
            --role-name "$DEV_ROLE_NAME" \
            --assume-role-policy-document file://github-trust-policy-dev.json \
            --profile "$AWS_PROFILE"
        print_status "Development role created"
    fi
    
    # Attach policy to development role
    print_info "Attaching PowerUserAccess policy to development role..."
    aws iam attach-role-policy \
        --role-name "$DEV_ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/PowerUserAccess \
        --profile "$AWS_PROFILE" 2>/dev/null || true
    print_status "PowerUserAccess policy attached to development role"
    
    # Get development role ARN
    DEV_ROLE_ARN=$(aws iam get-role \
        --role-name "$DEV_ROLE_NAME" \
        --query 'Role.Arn' \
        --output text \
        --profile "$AWS_PROFILE")
    print_status "Development Role ARN: $DEV_ROLE_ARN"
    
    # Step 5: Create Production Role
    print_header "STEP 5: CREATING PRODUCTION IAM ROLE"
    
    if aws iam get-role --role-name "$PROD_ROLE_NAME" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
        print_warning "Production role already exists"
        print_info "Updating trust policy..."
        aws iam update-assume-role-policy \
            --role-name "$PROD_ROLE_NAME" \
            --policy-document file://github-trust-policy-prod.json \
            --profile "$AWS_PROFILE"
        print_status "Production role trust policy updated"
    else
        print_info "Creating production role..."
        aws iam create-role \
            --role-name "$PROD_ROLE_NAME" \
            --assume-role-policy-document file://github-trust-policy-prod.json \
            --profile "$AWS_PROFILE"
        print_status "Production role created"
    fi
    
    # Attach policy to production role
    print_info "Attaching PowerUserAccess policy to production role..."
    aws iam attach-role-policy \
        --role-name "$PROD_ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/PowerUserAccess \
        --profile "$AWS_PROFILE" 2>/dev/null || true
    print_status "PowerUserAccess policy attached to production role"
    
    # Get production role ARN
    PROD_ROLE_ARN=$(aws iam get-role \
        --role-name "$PROD_ROLE_NAME" \
        --query 'Role.Arn' \
        --output text \
        --profile "$AWS_PROFILE")
    print_status "Production Role ARN: $PROD_ROLE_ARN"
    
    # Step 6: Display final instructions
    print_header "SETUP COMPLETE! NEXT STEPS"
    
    echo
    print_info "🎉 AWS OIDC setup is complete!"
    echo
    print_info "📋 ADD THESE SECRETS TO YOUR GITHUB REPOSITORY:"
    print_info "   Repository: https://github.com/$GITHUB_REPO"
    print_info "   Go to: Settings → Secrets and variables → Actions"
    echo
    print_status "Secret 1:"
    echo -e "   ${YELLOW}Name:${NC} AWS_ROLE_ARN"
    echo -e "   ${YELLOW}Value:${NC} $DEV_ROLE_ARN"
    echo
    print_status "Secret 2:"
    echo -e "   ${YELLOW}Name:${NC} AWS_PROD_ROLE_ARN"  
    echo -e "   ${YELLOW}Value:${NC} $PROD_ROLE_ARN"
    echo
    print_info "📝 TESTING:"
    print_info "   1. Create a Pull Request to test development workflow"
    print_info "   2. Push to main branch to test development deployment"
    print_info "   3. Create a release to test production deployment"
    echo
    print_warning "🔒 SECURITY REMINDERS:"
    print_warning "   • These roles have PowerUserAccess - consider restricting for production"
    print_warning "   • Monitor AWS CloudTrail for usage"
    print_warning "   • Review IAM policies regularly"
    
    # Create summary file
    cat > "github-secrets-summary.txt" << EOF
GitHub Repository Secrets for: $GITHUB_REPO

Add these secrets in GitHub:
Settings → Secrets and variables → Actions

1. AWS_ROLE_ARN
   Value: $DEV_ROLE_ARN

2. AWS_PROD_ROLE_ARN  
   Value: $PROD_ROLE_ARN

Setup completed on: $(date)
AWS Account: $AWS_ACCOUNT_ID
EOF
    
    print_status "Summary saved to: github-secrets-summary.txt"
    
    echo
    print_status "🚀 Setup completed successfully!"
}

# Error handling
trap 'print_error "Script failed on line $LINENO"; exit 1' ERR

# Check dependencies
command -v aws >/dev/null 2>&1 || { print_error "AWS CLI not found. Please install it first."; exit 1; }

# Run main function
main "$@"