#!/bin/bash

# Setup script for Terraform backend infrastructure
# This script creates the S3 bucket and DynamoDB table needed for remote state management
# Follows the manual setup instructions from C2.md

set -e

# Configuration
BUCKET_NAME="student-team4-terraform-state"
REGION="us-east-1"
DYNAMODB_TABLE="terraform-locks"

echo "🚀 Setting up Terraform backend infrastructure..."
echo "Bucket: $BUCKET_NAME"
echo "Region: $REGION"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS CLI is configured"

# Create S3 bucket
echo "📦 Creating S3 bucket for Terraform state..."
if aws s3 mb "s3://$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
    echo "✅ S3 bucket created successfully"
else
    echo "⚠️  S3 bucket might already exist or there was an error"
fi

# Enable versioning on S3 bucket
echo "🔄 Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo "✅ Versioning enabled on S3 bucket"

# Enable server-side encryption
echo "🔐 Enabling server-side encryption on S3 bucket..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

echo "✅ Server-side encryption enabled on S3 bucket"

# Create DynamoDB table for state locking
echo "🔒 Creating DynamoDB table for state locking..."
if aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region "$REGION" &> /dev/null; then
    
    echo "⏳ Waiting for DynamoDB table to be ready..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"
    echo "✅ DynamoDB table created successfully"
else
    echo "⚠️  DynamoDB table might already exist or there was an error"
fi

echo ""
echo "🎉 Backend setup complete!"
echo ""
echo "Next steps:"
echo "1. cd terraform/environments"
echo "2. terraform init -backend-config=\"../backends/dev.config\""
echo "3. terraform plan -var-file=\"dev.tfvars\""
echo "4. terraform apply -var-file=\"dev.tfvars\""
echo ""
echo "To import the backend bucket into Terraform state (optional):"
echo "terraform import aws_s3_bucket.terraform_state $BUCKET_NAME"