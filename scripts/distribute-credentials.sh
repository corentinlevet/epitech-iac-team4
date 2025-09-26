#!/bin/bash

# Secure Credential Distribution Script
# Creates individual credential files and encrypts instructor credentials

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."
CREDENTIALS_DIR="${PROJECT_DIR}/terraform/iam/credentials"

echo "🔐 Secure Credential Distribution System"
echo "======================================="

# Check if credentials directory exists
if [[ ! -d "$CREDENTIALS_DIR" ]]; then
    echo "❌ Credentials directory not found"
    echo "Run 'terraform apply' first to generate credential files"
    exit 1
fi

cd "$CREDENTIALS_DIR"

echo "📂 Credential files in: $CREDENTIALS_DIR"
echo ""

# List all credential files
echo "📋 Generated Credential Files:"
echo "=============================="

STUDENT_FILES=($(find . -name "*student*_credentials.json" -type f))
INSTRUCTOR_FILE="instructor_credentials.json"

# Show student credential files
if [[ ${#STUDENT_FILES[@]} -gt 0 ]]; then
    echo "👥 Student Credentials (plain text - for internal use):"
    for file in "${STUDENT_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            username=$(jq -r '.display_name' "$file" 2>/dev/null || echo "Unknown")
            github_user=$(jq -r '.github_username' "$file" 2>/dev/null || echo "Unknown")
            echo "  • $(basename "$file") → $username (@$github_user)"
        fi
    done
else
    echo "❌ No student credential files found"
fi

echo ""

# Check instructor file
if [[ -f "$INSTRUCTOR_FILE" ]]; then
    echo "👨‍🏫 Instructor Credentials:"
    echo "  • $INSTRUCTOR_FILE → Ready for GPG encryption"
    echo ""
    
    # Encrypt instructor credentials
    echo "🔐 Encrypting instructor credentials..."
    if bash "${SCRIPT_DIR}/encrypt-instructor-credentials.sh"; then
        echo "✅ Instructor credentials encrypted successfully"
    else
        echo "❌ Failed to encrypt instructor credentials"
        exit 1
    fi
elif [[ -f "${INSTRUCTOR_FILE}.gpg" ]]; then
    echo "👨‍🏫 Instructor Credentials:"
    echo "  • ${INSTRUCTOR_FILE}.gpg → Already encrypted ✅"
else
    echo "❌ Instructor credentials not found"
    exit 1
fi

echo ""
echo "📊 Distribution Summary:"
echo "======================="

# Count files
STUDENT_COUNT=${#STUDENT_FILES[@]}
echo "• Student credential files: $STUDENT_COUNT"
echo "• Instructor encrypted file: 1"
echo "• Total files for distribution: $((STUDENT_COUNT + 1))"

echo ""
echo "📤 Distribution Instructions:"
echo "============================"

echo ""
echo "🎓 For Students (Internal Team Distribution):"
echo "---------------------------------------------"
for file in "${STUDENT_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        username=$(jq -r '.display_name' "$file" 2>/dev/null || echo "Unknown")
        email=$(jq -r '.email' "$file" 2>/dev/null || echo "Unknown")
        echo "  📧 Send $(basename "$file") to $username ($email)"
    fi
done

echo ""
echo "👨‍🏫 For Instructor (Secure GPG Distribution):"
echo "---------------------------------------------"
if [[ -f "${INSTRUCTOR_FILE}.gpg" ]]; then
    echo "  📧 Send instructor_credentials.json.gpg to jeremie@jjaouen.com"
    echo "  🔓 Decryption: gpg --decrypt instructor_credentials.json.gpg"
fi

echo ""
echo "⚠️  Security Reminders:"
echo "======================"
echo "• ❌ NEVER commit credential files to Git"
echo "• ❌ NEVER send plain text credentials via email/Slack"
echo "• ✅ Use secure channels for credential distribution"
echo "• ✅ Students should run 'aws configure' to set up credentials"
echo "• ✅ Instructor uses GPG to decrypt their credentials"

echo ""
echo "🔧 AWS Setup Instructions (for recipients):"
echo "==========================================="
echo "1. Install AWS CLI: https://aws.amazon.com/cli/"
echo "2. Run: aws configure"
echo "3. Enter Access Key ID from the JSON file"
echo "4. Enter Secret Access Key from the JSON file"
echo "5. Default region: us-east-1"
echo "6. Default output format: json"

echo ""
echo "🌐 AWS Console Access:"
echo "====================="
echo "• URL: https://console.aws.amazon.com/"
echo "• Sign-in: Use IAM user credentials"
echo "• Instructor: ReadOnly + Billing access"
echo "• Students: PowerUser access"

echo ""
if [[ -f "encryption_summary.txt" ]]; then
    echo "📋 Detailed encryption summary available in: encryption_summary.txt"
fi

echo "🎉 Credential distribution preparation complete!"