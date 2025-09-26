# Personal GitHub Repository Setup Guide

## 🎯 Why Use a Personal Repository?

Since you're working within a school organization (`EpitechPGE45-2025`), you don't have admin permissions to manage collaborators. By creating a personal repository, you can:

✅ **Full GitHub Integration**: Complete C3.md implementation with GitHub provider
✅ **Team Collaboration**: Add teammates as collaborators  
✅ **Instructor Access**: Add instructor (@Kloox) with appropriate permissions
✅ **Learning Experience**: Experience real-world GitHub repository management

## 📋 Step-by-Step Setup

### 1. Create Personal Repository

1. Go to: https://github.com/new
2. Repository details:
   - **Name**: `epitech-iac-team4` (or your preference)
   - **Visibility**: **Public** (so teammates can access)
   - **Initialize**: Leave unchecked (we'll push existing code)
3. Click "Create repository"

### 2. Add Personal Remote & Push

```bash
cd /Users/clevet/Documents/Code/EPITECH/delivery2025-2026/IaC

# Add your personal repo as a new remote
git remote add personal git@github.com:YOUR_USERNAME/epitech-iac-team4.git

# Push existing code to personal repo
git push personal main
```

### 3. Create GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Token details:
   - **Note**: `Terraform IAM Management - Epitech IaC`
   - **Expiration**: 30 days (or as needed)
   - **Scopes**: 
     - ✅ `repo` (Full control of repositories)
     - ✅ `admin:org` (Full control of orgs and teams)
4. Click "Generate token"
5. **Copy the token immediately** (starts with `ghp_`)

### 4. Update Terraform Configuration

Edit `terraform/iam/iam.tfvars` to use your personal repository:

```hcl
# IAM Management Environment Variables
region              = "us-east-1"
github_organization = "YOUR_GITHUB_USERNAME"  # e.g., "corentinlevet"
github_repository   = "epitech-iac-team4"     # Your repo name

# Keep existing team member information...
team_members = [
  {
    username        = "student1-team4"
    display_name    = "Corentin Levet"
    email           = "corentin.levet@epitech.eu"
    github_username = "corentinlevet"
  },
  # ... other team members
]
```

### 5. Test the Complete Setup

```bash
# Set your GitHub token
export GITHUB_TOKEN=ghp_your_actual_token_here

# Test the IAM configuration
cd terraform/iam
terraform plan -var-file="iam.tfvars" -var="github_token=${GITHUB_TOKEN}"

# If successful, apply the changes
terraform apply -var-file="iam.tfvars" -var="github_token=${GITHUB_TOKEN}"
```

## 🎉 What This Will Create

### AWS IAM Resources:
- ✅ **Instructor IAM user**: `jeremie-jaouen` with ReadOnly + Billing access
- ✅ **4 Student IAM users**: PowerUserAccess for infrastructure management
- ✅ **Access keys**: For programmatic access to AWS
- ✅ **Proper tagging**: All resources tagged for identification

### GitHub Repository Management:
- ✅ **Instructor collaboration**: @Kloox added as admin
- ✅ **Team collaboration**: All 4 students added with push access
- ✅ **Automated management**: Changes via Terraform, not manual

### Outputs:
- 🔐 **AWS credentials**: Securely generated for all users
- 🔗 **Console links**: Direct links to AWS dashboards
- 📊 **GitHub permissions**: Summary of collaborator access

## 🔄 Switching Between Repositories

You can work with both repositories:

```bash
# Work with school repository (original)
git remote -v  # Shows both remotes
git push origin main  # Push to school repo

# Work with personal repository (for GitHub integration)
git push personal main  # Push to personal repo

# Use personal repo for Terraform GitHub provider
# Use school repo for assignment submission
```

## 🛡️ Security Best Practices

- ✅ **Token security**: Never commit GitHub token to Git
- ✅ **Environment variables**: Use `export GITHUB_TOKEN=...`
- ✅ **Token expiration**: Set reasonable expiration dates
- ✅ **Minimal scopes**: Only required permissions
- ✅ **Credential rotation**: Regularly update access keys

## 🎯 Learning Benefits

This setup provides the **complete C3.md experience**:
- Multi-environment infrastructure management
- Team collaboration with proper access controls
- GitHub integration with Infrastructure as Code
- Security best practices for credential management
- Real-world DevOps workflows and GitOps principles

---

**Ready to experience the full power of Infrastructure as Code! 🚀**