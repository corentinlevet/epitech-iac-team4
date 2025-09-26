#!/bin/bash

# GPG Credential Encryption Script
# Encrypts instructor credentials with GPG public key

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREDENTIALS_DIR="${SCRIPT_DIR}/../terraform/iam/credentials"
INSTRUCTOR_CREDS="${CREDENTIALS_DIR}/instructor_credentials.json"
GPG_KEY_FILE="${CREDENTIALS_DIR}/jeremie_public_key.asc"
ENCRYPTED_FILE="${CREDENTIALS_DIR}/instructor_credentials.json.gpg"

echo "🔐 GPG Credential Encryption for Instructor"
echo "=========================================="

# Check if GPG is installed
if ! command -v gpg &> /dev/null; then
    echo "❌ GPG not found. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Install GPG on macOS:"
        echo "brew install gnupg"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Install GPG on Linux:"
        echo "sudo apt-get install gnupg"
    fi
    exit 1
fi

echo "✅ GPG is available"

# Check if credentials directory exists
if [[ ! -d "$CREDENTIALS_DIR" ]]; then
    echo "❌ Credentials directory not found: $CREDENTIALS_DIR"
    echo "Run 'terraform apply' first to generate credentials"
    exit 1
fi

# Check if instructor credentials exist
if [[ ! -f "$INSTRUCTOR_CREDS" ]]; then
    echo "❌ Instructor credentials not found: $INSTRUCTOR_CREDS"
    echo "Run 'terraform apply' first to generate credentials"
    exit 1
fi

# Check if GPG key file exists
if [[ ! -f "$GPG_KEY_FILE" ]]; then
    echo "❌ GPG key file not found: $GPG_KEY_FILE"
    echo "Run 'terraform apply' first to generate GPG key file"
    exit 1
fi

echo "📁 Found credentials: $INSTRUCTOR_CREDS"
echo "🔑 Found GPG key: $GPG_KEY_FILE"

# Import the GPG public key
echo "📥 Importing instructor's GPG public key..."
if gpg --import "$GPG_KEY_FILE" 2>/dev/null; then
    echo "✅ GPG key imported successfully"
else
    echo "⚠️  GPG key might already be imported"
fi

# Get the key fingerprint/email for encryption
GPG_EMAIL="jeremie@jjaouen.com"
echo "🔍 Using GPG recipient: $GPG_EMAIL"

# Encrypt the credentials file
echo "🔐 Encrypting instructor credentials..."
if gpg --trust-model always --armor --encrypt --recipient "$GPG_EMAIL" \
   --output "$ENCRYPTED_FILE" "$INSTRUCTOR_CREDS"; then
    echo "✅ Credentials encrypted successfully"
    echo "📄 Encrypted file: $ENCRYPTED_FILE"
    
    # Remove the plain text file for security
    rm "$INSTRUCTOR_CREDS"
    echo "🗑️  Plain text credentials deleted for security"
    
    echo ""
    echo "📋 Summary:"
    echo "• Encrypted file: $(basename "$ENCRYPTED_FILE")"
    echo "• Recipient: $GPG_EMAIL"
    echo "• Original file: DELETED for security"
    echo ""
    echo "📤 Distribution Instructions:"
    echo "1. Send $ENCRYPTED_FILE to jeremie@jjaouen.com"
    echo "2. He can decrypt with: gpg --decrypt instructor_credentials.json.gpg"
    echo "3. The decrypted JSON contains all AWS access information"
    
else
    echo "❌ Encryption failed"
    echo "Check if GPG key is valid and try again"
    exit 1
fi

# Create a summary file
SUMMARY_FILE="${CREDENTIALS_DIR}/encryption_summary.txt"
cat > "$SUMMARY_FILE" << EOF
GPG Encryption Summary
=====================

Date: $(date)
Encrypted File: instructor_credentials.json.gpg
Recipient: $GPG_EMAIL
Status: Successfully Encrypted

Distribution:
- Send the .gpg file to the instructor
- Instructor can decrypt with: gpg --decrypt instructor_credentials.json.gpg

Security Notes:
- Original plain text file was deleted
- Encrypted file uses GPG armor format (ASCII)
- Only the instructor's private key can decrypt this file

Contents (encrypted):
- AWS Access Key ID
- AWS Secret Access Key  
- AWS Console URL
- Setup instructions
EOF

echo "📋 Summary saved to: $SUMMARY_FILE"
echo ""
echo "🎉 GPG encryption complete!"