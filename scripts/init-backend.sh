#!/bin/bash

# Script to initialize Terraform backend (S3 bucket and DynamoDB table)
# This must be run before the first terraform init

set -e

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

# Configuration from backend files
BUCKET_NAME="student-team4-iac-tfstate-2025-v2"
DYNAMODB_TABLE="terraform-locks"
REGION="us-east-1"

print_header "🔧 INITIALIZING TERRAFORM BACKEND"

# Check if AWS CLI is configured
print_status "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_success "Using AWS account: $ACCOUNT_ID"

# Create S3 bucket if it doesn't exist
print_status "Checking if S3 bucket exists: $BUCKET_NAME"
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    print_status "Creating S3 bucket: $BUCKET_NAME"
    
    # Try to create the bucket with retry logic
    MAX_RETRIES=5
    RETRY_COUNT=0
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if aws s3 mb "s3://$BUCKET_NAME" --region "$REGION" 2>&1; then
            print_success "S3 bucket created successfully"
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                print_status "Retrying in 10 seconds... (Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
                sleep 10
            else
                print_error "Failed to create S3 bucket after $MAX_RETRIES attempts"
                exit 1
            fi
        fi
    done
    
    # Wait for bucket to be fully created
    print_status "Waiting for bucket to be fully available..."
    sleep 5
    
    # Enable versioning
    print_status "Enabling versioning on S3 bucket..."
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled \
        --region "$REGION"
    print_success "Versioning enabled"
    
    # Enable encryption
    print_status "Enabling encryption on S3 bucket..."
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }' \
        --region "$REGION"
    print_success "Encryption enabled"
    
    # Block public access
    print_status "Blocking public access to S3 bucket..."
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        --region "$REGION"
    print_success "Public access blocked"
    
else
    print_success "S3 bucket already exists: $BUCKET_NAME"
fi

# Create DynamoDB table if it doesn't exist
print_status "Checking if DynamoDB table exists: $DYNAMODB_TABLE"
if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" &> /dev/null; then
    print_status "Creating DynamoDB table: $DYNAMODB_TABLE"
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$REGION" \
        --tags Key=ManagedBy,Value=Terraform Key=Purpose,Value=StateLocking \
        > /dev/null
    
    print_status "Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"
    print_success "DynamoDB table created successfully"
else
    print_success "DynamoDB table already exists: $DYNAMODB_TABLE"
fi

print_header "✅ BACKEND INITIALIZATION COMPLETE"
echo ""
echo -e "${GREEN}Backend Resources Created:${NC}"
echo -e "  📦 S3 Bucket: ${BLUE}$BUCKET_NAME${NC}"
echo -e "  🔒 DynamoDB Table: ${BLUE}$DYNAMODB_TABLE${NC}"
echo -e "  🌍 Region: ${BLUE}$REGION${NC}"
echo ""
echo -e "${YELLOW}You can now run:${NC}"
echo -e "  ${BLUE}./scripts/deploy.sh${NC}"
echo ""
