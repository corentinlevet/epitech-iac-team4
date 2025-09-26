#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CREDENTIALS_DIR="$PROJECT_DIR/credentials"
INSTRUCTOR_EMAIL="jeremie@jjaouen.com"

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

# Validation function
validate_files() {
    print_header "VALIDATING CREDENTIAL FILES"
    
    if [[ ! -d "$CREDENTIALS_DIR" ]]; then
        print_error "Credentials directory not found: $CREDENTIALS_DIR"
        print_info "Please run 'terraform apply' first to create credential files."
        exit 1
    fi
    
    # Check instructor credentials
    if [[ ! -f "$CREDENTIALS_DIR/instructor_credentials.json" ]]; then
        print_error "Instructor credentials file not found!"
        exit 1
    fi
    print_status "Instructor credentials file exists"
    
    # Check GPG key file
    if [[ ! -f "$CREDENTIALS_DIR/jeremie_public_key.asc" ]]; then
        print_error "Instructor GPG public key not found!"
        exit 1
    fi
    print_status "Instructor GPG public key exists"
    
    # Check team member credentials
    local team_files=0
    for file in "$CREDENTIALS_DIR"/student*_credentials.json; do
        if [[ -f "$file" ]]; then
            ((team_files++))
            print_status "Found: $(basename "$file")"
        fi
    done
    
    if [[ $team_files -eq 0 ]]; then
        print_error "No team member credential files found!"
        exit 1
    fi
    
    print_status "Found $team_files team member credential files"
}

# GPG encryption function
encrypt_instructor_credentials() {
    print_header "ENCRYPTING INSTRUCTOR CREDENTIALS"
    
    cd "$CREDENTIALS_DIR"
    
    # Import GPG key
    print_info "Importing instructor's GPG public key..."
    if ! gpg --import jeremie_public_key.asc 2>/dev/null; then
        print_warning "GPG key might already be imported"
    fi
    
    # Encrypt the file
    print_info "Encrypting instructor credentials..."
    gpg --trust-model always --armor --encrypt \
        --recipient "$INSTRUCTOR_EMAIL" \
        --output instructor_credentials.json.gpg \
        instructor_credentials.json
    
    if [[ -f instructor_credentials.json.gpg ]]; then
        print_status "Instructor credentials encrypted successfully!"
        
        # Remove plain text file for security
        print_info "Removing plain text instructor credentials for security..."
        rm instructor_credentials.json
        
        print_status "Plain text instructor file removed"
    else
        print_error "Encryption failed!"
        exit 1
    fi
}

# Generate distribution instructions
generate_instructions() {
    print_header "CREDENTIAL DISTRIBUTION INSTRUCTIONS"
    
    local instruction_file="$CREDENTIALS_DIR/DISTRIBUTION_INSTRUCTIONS.md"
    
    cat > "$instruction_file" << 'EOF'
# 🔐 SECURE CREDENTIAL DISTRIBUTION GUIDE

## Overview
This guide provides step-by-step instructions for securely distributing AWS access credentials to team members and the instructor for the EPITECH Infrastructure as Code module.

## 📧 For the Instructor (Jérémie JAOUEN)

### Encrypted Credentials
- **File**: `instructor_credentials.json.gpg`
- **Recipient**: jeremie@jjaouen.com
- **Content**: AWS access keys with ReadOnly + Billing access

### Decryption Instructions
```bash
# Decrypt the file (you'll be prompted for your GPG passphrase)
gpg --decrypt instructor_credentials.json.gpg > instructor_credentials.json

# View the credentials
cat instructor_credentials.json
```

### Credential Format
```json
{
  "username": "jeremie-jaouen",
  "access_key_id": "AKIA...",
  "secret_access_key": "...",
  "aws_console_url": "https://console.aws.amazon.com/",
  "permissions": [
    "ReadOnlyAccess",
    "Billing and Cost Management"
  ],
  "usage_instructions": {
    "cli": "aws configure --profile instructor",
    "console": "Use IAM user credentials to login"
  }
}
```

## 👥 For Team Members

### Distribution Method
Each team member receives their individual credential file:

- **student1-team4**: `student1-team4_credentials.json`
- **student2-team4**: `student2-team4_credentials.json` 
- **student3-team4**: `student3-team4_credentials.json`
- **student4-team4**: `student4-team4_credentials.json`

### Team Member Permissions
- **AWS Policy**: PowerUserAccess
- **Capabilities**: Full AWS service access (except IAM user management)
- **GitHub Access**: Push access to repository

### Setup Instructions for Team Members
```bash
# Configure AWS CLI (replace with your credentials)
aws configure --profile student
# When prompted:
# AWS Access Key ID: [from your JSON file]
# AWS Secret Access Key: [from your JSON file]  
# Default region: us-east-1
# Default output format: json

# Test access
aws sts get-caller-identity --profile student
```

## 🔗 GitHub Repository Access

### Repository
- **Name**: epitech-iac-team4
- **Owner**: corentinlevet
- **URL**: https://github.com/corentinlevet/epitech-iac-team4

### Access Levels
- **Instructor (Kloox)**: Admin access
- **Team Members**: Push access
  - GriselHugo
  - RomainOeil  
  - gwen24112003

## 🚨 SECURITY REMINDERS

### For Everyone
1. **NEVER** commit credential files to Git
2. **NEVER** share credentials via unsecured channels (email, Slack, etc.)
3. **ROTATE** credentials if compromised
4. **DELETE** credential files after local setup
5. **USE** AWS CLI profiles instead of hardcoded credentials

### Credential File Security
- Files are created with `0600` permissions (owner read/write only)
- Plain text instructor file is automatically removed after encryption
- Add `credentials/` to `.gitignore` (already done)

### Best Practices
- Use AWS CLI profiles: `aws configure --profile [name]`
- Set environment variables for automation: 
  ```bash
  export AWS_PROFILE=student
  # or
  export AWS_ACCESS_KEY_ID=...
  export AWS_SECRET_ACCESS_KEY=...
  ```
- Regularly audit AWS usage in Cost Explorer
- Monitor CloudTrail for unusual activity

## 📊 AWS Console Quick Links

### For Monitoring & Learning
- **IAM Dashboard**: https://console.aws.amazon.com/iam/
- **Billing Dashboard**: https://console.aws.amazon.com/billing/
- **Cost Explorer**: https://console.aws.amazon.com/cost-reports/
- **CloudTrail**: https://console.aws.amazon.com/cloudtrail/

## 🛠 Troubleshooting

### Common Issues
1. **Access Denied**: Check if using correct profile/credentials
2. **MFA Required**: Some actions may require MFA (instructor account)
3. **Region Issues**: Ensure correct region selection (us-east-1)
4. **Permission Issues**: Verify policy attachments in IAM console

### Getting Help
- Check AWS CloudTrail for detailed error logs
- Verify IAM policy attachments
- Ensure credentials are properly configured
- Contact repository owner for GitHub access issues

---
*Generated by EPITECH IAC Secure Distribution System*
*Last Updated: $(date)*
EOF

    print_status "Distribution instructions created: $(basename "$instruction_file")"
}

# Summary function
print_summary() {
    print_header "DISTRIBUTION SUMMARY"
    
    echo
    print_info "📂 Files created in credentials/ directory:"
    
    # List all files with their purposes
    for file in "$CREDENTIALS_DIR"/*; do
        if [[ -f "$file" ]]; then
            local basename_file=$(basename "$file")
            case "$basename_file" in
                "instructor_credentials.json.gpg")
                    print_status "🔐 $basename_file (encrypted for instructor)"
                    ;;
                "student"*"_credentials.json")
                    print_status "👤 $basename_file (for team member)"
                    ;;
                "jeremie_public_key.asc")
                    print_status "🔑 $basename_file (GPG public key)"
                    ;;
                "DISTRIBUTION_INSTRUCTIONS.md")
                    print_status "📋 $basename_file (detailed instructions)"
                    ;;
                *)
                    print_status "📄 $basename_file"
                    ;;
            esac
        fi
    done
    
    echo
    print_header "NEXT STEPS"
    echo
    print_info "1. Send encrypted file to instructor:"
    echo -e "   ${YELLOW}→${NC} Email: $INSTRUCTOR_EMAIL"
    echo -e "   ${YELLOW}→${NC} File: credentials/instructor_credentials.json.gpg"
    echo
    
    print_info "2. Distribute individual JSON files to team members:"
    for file in "$CREDENTIALS_DIR"/student*_credentials.json; do
        if [[ -f "$file" ]]; then
            local student_name=$(basename "$file" "_credentials.json")
            echo -e "   ${YELLOW}→${NC} $student_name: $(basename "$file")"
        fi
    done
    
    echo
    print_info "3. Share repository access:"
    echo -e "   ${YELLOW}→${NC} Repository: https://github.com/corentinlevet/epitech-iac-team4"
    echo -e "   ${YELLOW}→${NC} All collaborators have been invited"
    
    echo
    print_info "4. Review full instructions:"
    echo -e "   ${YELLOW}→${NC} File: credentials/DISTRIBUTION_INSTRUCTIONS.md"
    
    echo
    print_warning "⚠️  SECURITY REMINDER:"
    print_warning "   • Use secure channels for credential distribution"
    print_warning "   • Never commit credential files to Git"
    print_warning "   • Delete local credential files after distribution"
    
    echo
    print_status "🎉 Secure credential distribution system ready!"
}

# Main execution
main() {
    print_header "EPITECH IAC SECURE CREDENTIAL DISTRIBUTION"
    echo -e "${BLUE}Starting automated credential distribution process...${NC}"
    
    validate_files
    encrypt_instructor_credentials
    generate_instructions
    print_summary
    
    echo
    print_status "All operations completed successfully!"
}

# Error handling
trap 'print_error "Script failed on line $LINENO"; exit 1' ERR

# Run main function
main "$@"