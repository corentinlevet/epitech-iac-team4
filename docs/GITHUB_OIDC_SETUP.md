# 🔐 GitHub Actions OIDC Setup for AWS - Complete Guide

## Step 1: Get Your AWS Account ID

First, get your AWS account ID:

```bash
# Try with your working profile
AWS_PROFILE=corentin-levet aws sts get-caller-identity --query 'Account' --output text
```

If this doesn't work, you can find your Account ID in the AWS Console:
- Go to AWS Console → Support → Support Center
- Your Account ID is displayed at the top right

## Step 2: Update Trust Policy Files

Replace `YOUR_ACCOUNT_ID` in both files with your actual AWS Account ID:

- `github-trust-policy-dev.json`
- `github-trust-policy-prod.json`

Example: If your Account ID is `123456789012`, replace:
```
"arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
```
with:
```
"arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
```

## Step 3: Create OIDC Identity Provider (One-time setup)

```bash
# Set your profile
export AWS_PROFILE=corentin-levet

# Create OIDC provider
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
    --client-id-list sts.amazonaws.com
```

## Step 4: Create IAM Roles

### Development Role:
```bash
# Create development role
aws iam create-role \
    --role-name GitHubActions-Dev-Role \
    --assume-role-policy-document file://github-trust-policy-dev.json

# Attach PowerUser policy for development
aws iam attach-role-policy \
    --role-name GitHubActions-Dev-Role \
    --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Get the role ARN (save this for GitHub secrets)
aws iam get-role \
    --role-name GitHubActions-Dev-Role \
    --query 'Role.Arn' \
    --output text
```

### Production Role:
```bash
# Create production role
aws iam create-role \
    --role-name GitHubActions-Prod-Role \
    --assume-role-policy-document file://github-trust-policy-prod.json

# Attach PowerUser policy for production (you might want more restrictive policies)
aws iam attach-role-policy \
    --role-name GitHubActions-Prod-Role \
    --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Get the role ARN (save this for GitHub secrets)
aws iam get-role \
    --role-name GitHubActions-Prod-Role \
    --query 'Role.Arn' \
    --output text
```

## Step 5: GitHub Repository Secrets Setup

Go to your repository: https://github.com/corentinlevet/epitech-iac-team4

1. Click **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add these secrets:

### Required Secrets:

**AWS_ROLE_ARN**
- Name: `AWS_ROLE_ARN`
- Value: `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-Dev-Role`

**AWS_PROD_ROLE_ARN**
- Name: `AWS_PROD_ROLE_ARN`
- Value: `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-Prod-Role`

## Step 6: Test the Setup

1. **Create a Pull Request** to trigger the development workflow
2. **Push to main branch** to trigger dev deployment
3. **Create a release** to trigger production deployment

## Alternative: Simpler Setup with Access Keys (Less Secure)

If OIDC setup is problematic, you can use access keys temporarily:

1. Create an AWS user with programmatic access
2. Generate access keys
3. Add these secrets to GitHub:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
4. Modify the workflow to use these instead of roles

## Troubleshooting

### Common Issues:

1. **OIDC Provider Already Exists**: This is fine, skip the creation step
2. **Role Already Exists**: Delete and recreate, or update the trust policy
3. **Permission Denied**: Ensure your AWS user has IAM permissions
4. **Workflow Fails**: Check the GitHub Actions logs for specific error messages

### Verification Commands:

```bash
# Check if OIDC provider exists
aws iam list-open-id-connect-providers

# Check if roles exist
aws iam get-role --role-name GitHubActions-Dev-Role
aws iam get-role --role-name GitHubActions-Prod-Role

# Test role assumption (this should work from GitHub Actions)
aws sts assume-role-with-web-identity \
    --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-Dev-Role \
    --role-session-name test-session \
    --web-identity-token TOKEN_FROM_GITHUB
```

## Security Best Practices

1. **Least Privilege**: Consider creating custom policies instead of PowerUserAccess
2. **Environment Separation**: Use different AWS accounts for dev/prod if possible
3. **Regular Rotation**: Periodically review and rotate credentials
4. **Monitoring**: Set up CloudTrail to monitor API usage

## Next Steps

After completing this setup:
1. Test with a simple pull request
2. Verify deployments work correctly
3. Consider implementing more granular permissions
4. Set up monitoring and alerting