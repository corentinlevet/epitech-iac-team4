#!/bin/bash

# IAM and Credential Management Script
# Handles C3.md requirements for team member and instructor access

set -e

ROOT_DIR="$(dirname "$(dirname "$0")")"

echo "👥 IAM and Credential Management"
echo "==============================="
echo "C3.md Requirements:"
echo "• Add members to GitHub repository"
echo "• Create AWS users for team and instructor"
echo "• Handle credentials securely"
echo "• Separate Terraform stack for IAM"
echo ""

# Check prerequisites
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS Account: $ACCOUNT_ID"

# Check if GPG is available for credential encryption
if command -v gpg &> /dev/null; then
    echo "✅ GPG available for credential encryption"
    HAS_GPG=true
else
    echo "⚠️  GPG not available - credentials will be displayed unencrypted"
    HAS_GPG=false
fi

# Check GitHub token
if [ -n "$GITHUB_TOKEN" ]; then
    echo "✅ GitHub token available"
    HAS_GITHUB_TOKEN=true
else
    echo "⚠️  GITHUB_TOKEN not set - GitHub permissions won't be managed"
    echo "   To manage GitHub repository permissions:"
    echo "   export GITHUB_TOKEN=your_github_personal_access_token"
    HAS_GITHUB_TOKEN=false
fi

echo ""

# Navigate to IAM directory
cd "$ROOT_DIR/terraform/iam"

# Initialize IAM Terraform stack
echo "🔧 Initializing IAM Terraform Stack..."
if terraform init -backend-config="../backends/iam.config"; then
    echo "✅ IAM stack initialized"
else
    echo "❌ IAM stack initialization failed"
    exit 1
fi

# Show what will be created
echo ""
echo "📋 IAM Resources to be Created:"
echo "• IAM user: jeremie-jjaouen (Instructor)"
echo "  - Role: ReadOnlyAccess + Billing"
echo "  - Email: jeremie@jjaouen.com"
echo "• IAM users: student1-team4, student2-team4, student3-team4, student4-team4"
echo "  - Role: PowerUserAccess"
if [ "$HAS_GITHUB_TOKEN" = true ]; then
    echo "• GitHub collaborators: @Kloox (admin), team members (push)"
fi
echo ""

# Plan the IAM deployment
echo "📋 Planning IAM Deployment..."
PLAN_ARGS="-var-file=iam.tfvars"
if [ "$HAS_GITHUB_TOKEN" = true ]; then
    PLAN_ARGS="$PLAN_ARGS -var=github_token=$GITHUB_TOKEN"
fi

if terraform plan $PLAN_ARGS -input=false; then
    echo "✅ IAM plan successful"
else
    echo "❌ IAM plan failed"
    exit 1
fi

# Ask for deployment confirmation
echo ""
echo "⚠️  WARNING: This will create real IAM users and access keys!"
echo "This is a separate stack from VPC infrastructure as recommended in C3.md"
read -p "Deploy IAM stack? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Deploying IAM Stack..."
    
    if terraform apply $PLAN_ARGS -auto-approve; then
        echo "✅ IAM stack deployed successfully"
    else
        echo "❌ IAM deployment failed"
        exit 1
    fi
    
    echo ""
    echo "📊 IAM Deployment Results:"
    terraform state list
    
    echo ""
    echo "🔐 Managing Credentials..."
    
    # Get instructor credentials
    echo "Getting instructor credentials..."
    INSTRUCTOR_ACCESS_KEY=$(terraform output -raw instructor_credentials | jq -r '.access_key')
    INSTRUCTOR_SECRET_KEY=$(terraform output -raw instructor_credentials | jq -r '.secret_key')
    
    if [ -n "$INSTRUCTOR_ACCESS_KEY" ] && [ "$INSTRUCTOR_ACCESS_KEY" != "null" ]; then
        echo "✅ Instructor credentials retrieved"
        
        # Create credentials file
        CREDS_FILE="instructor_credentials_$(date +%Y%m%d_%H%M%S).txt"
        cat > "$CREDS_FILE" <<EOF
AWS Credentials for Jeremie JJAOUEN (@Kloox)
==========================================

AWS_ACCESS_KEY_ID=$INSTRUCTOR_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=$INSTRUCTOR_SECRET_KEY
AWS_DEFAULT_REGION=us-east-1
AWS_ACCOUNT_ID=$ACCOUNT_ID

Console Access: https://console.aws.amazon.com/
IAM Dashboard: https://console.aws.amazon.com/iam/home
Billing Dashboard: https://console.aws.amazon.com/billing/home

Role: ReadOnlyAccess + Billing Access
Created: $(date)
Project: Student Team 4 - IaC Module

Note: These credentials provide read-only access to AWS resources
and billing information for course assessment purposes.
EOF
        
        echo "✅ Credentials file created: $CREDS_FILE"
        
        # Encrypt with GPG if available
        if [ "$HAS_GPG" = true ]; then
            echo ""
            echo "🔐 Encrypting Credentials with GPG..."
            
            # Import instructor's GPG key
            terraform output -raw instructor_pgp_message | grep -A 50 "echo '" | sed "s/echo '//" | sed "s/'$//" > instructor_key.asc
            
            if gpg --import instructor_key.asc 2>/dev/null; then
                echo "✅ Instructor's GPG key imported"
                
                # Encrypt credentials
                if gpg --armor --encrypt --recipient jeremie@jjaouen.com "$CREDS_FILE"; then
                    echo "✅ Credentials encrypted: ${CREDS_FILE}.asc"
                    echo ""
                    echo "📤 Send the encrypted file to instructor:"
                    echo "   File: ${CREDS_FILE}.asc"
                    echo "   Method: Teams private message"
                    echo "   Recipient: @Kloox"
                    
                    # Clean up
                    rm -f "$CREDS_FILE" instructor_key.asc
                    echo "✅ Unencrypted files cleaned up"
                else
                    echo "❌ GPG encryption failed"
                fi
            else
                echo "❌ Failed to import GPG key"
            fi
        else
            echo ""
            echo "⚠️  GPG not available - credentials are unencrypted!"
            echo "📄 Credentials file: $CREDS_FILE"
            echo "🚨 SECURITY: Manually encrypt before sending!"
        fi
    else
        echo "❌ Failed to retrieve instructor credentials"
    fi
    
    # Get team member credentials
    echo ""
    echo "👥 Team Member Credentials:"
    if terraform output team_member_credentials >/dev/null 2>&1; then
        echo "✅ Team member credentials available"
        echo "   Use 'terraform output team_member_credentials' to view"
        echo "   Distribute securely to respective team members"
    else
        echo "⚠️  Team member credentials not available"
    fi
    
    # Show GitHub integration results
    if [ "$HAS_GITHUB_TOKEN" = true ]; then
        echo ""
        echo "🐙 GitHub Integration Results:"
        if terraform output github_collaborators_added >/dev/null 2>&1; then
            terraform output github_collaborators_added
            echo "✅ GitHub repository permissions configured"
        else
            echo "⚠️  GitHub integration may have failed"
        fi
    fi
    
else
    echo "⏭️  IAM deployment cancelled"
    exit 0
fi

echo ""
echo "📋 Next Steps:"
echo "1. Send encrypted credentials to instructor via Teams"
echo "2. Distribute team member credentials securely"
echo "3. Verify GitHub repository access"
echo "4. Test AWS console access"
echo "5. Review IAM dashboard: https://console.aws.amazon.com/iam/home"
echo ""
echo "🚨 Security Reminders:"
echo "• Never commit credentials to Git repositories"
echo "• Use encrypted communication for credential sharing"
echo "• Regularly rotate access keys"
echo "• Monitor AWS usage and costs"
echo ""
echo "🗑️  To remove IAM resources later:"
echo "   terraform destroy -var-file=iam.tfvars"
echo "   (Run from terraform/iam directory)"
echo ""
echo "✅ IAM and Credential Management Complete!"

# Go back to original directory
cd - > /dev/null