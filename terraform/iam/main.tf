# IAM Management - Separate Terraform Stack
# As recommended in C3.md: "You may not want to remove these permissions when destroying your infra, 
# do a separate terraform stack to manage the permissions"

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  # Separate backend for IAM management
  backend "s3" {
    # Configuration loaded via -backend-config flag
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Purpose   = "IAM-Management"
      Team      = "Student-Team4"
    }
  }
}

# Configure GitHub Provider (optional - only needed for collaborator management)
provider "github" {
  token = var.github_token != "" ? var.github_token : null
  owner = var.github_organization
}

# ============================================================================
# OIDC Provider for GitHub Actions (Required for CI/CD)
# ============================================================================

# Create OpenID Connect provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # GitHub's OIDC thumbprint - this is the official GitHub thumbprint
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name      = "GitHub Actions OIDC Provider"
    ManagedBy = "Terraform"
    Purpose   = "CI/CD Authentication"
  }
}

# ============================================================================
# IAM Users
# ============================================================================

# Create IAM user for instructor (Jeremie)
resource "aws_iam_user" "instructor" {
  name = "jeremie-jaouen"
  path = "/instructors/"

  tags = {
    Name      = "Jeremie JAOUEN - Instructor"
    Purpose   = "Course Assessment"
    Email     = "jeremie@jjaouen.com"
    CreatedBy = "Terraform"
    Course    = "IaC-Module"
  }
}

# Create access key for instructor
resource "aws_iam_access_key" "instructor" {
  user = aws_iam_user.instructor.name
}

# Attach appropriate policy to instructor
# Using viewer role as suggested in C3.md comment: "I will never edit your resources, so which role should I have?"
resource "aws_iam_user_policy_attachment" "instructor_readonly" {
  user       = aws_iam_user.instructor.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Additional policy for billing access (optional)
resource "aws_iam_user_policy" "instructor_billing" {
  name = "InstructorBillingAccess"
  user = aws_iam_user.instructor.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "budgets:ViewBudget",
          "ce:GetCostAndUsage",
          "ce:GetReservationCoverage",
          "ce:GetReservationPurchaseRecommendation",
          "ce:GetReservationUtilization",
          "ce:GetUsageReport",
          "ce:ListCostCategoryDefinitions",
          "support:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create IAM users for team members
resource "aws_iam_user" "team_members" {
  count = length(var.team_members)
  name  = var.team_members[count.index].username
  path  = "/students/"

  tags = {
    Name      = var.team_members[count.index].display_name
    Purpose   = "Student Access"
    Email     = var.team_members[count.index].email
    CreatedBy = "Terraform"
    Course    = "IaC-Module"
  }
}

# Create access keys for team members
resource "aws_iam_access_key" "team_members" {
  count = length(var.team_members)
  user  = aws_iam_user.team_members[count.index].name
}

# Attach policies to team members
resource "aws_iam_user_policy_attachment" "team_members_power_user" {
  count      = length(var.team_members)
  user       = aws_iam_user.team_members[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# GitHub repository collaborators
resource "github_repository_collaborator" "instructor" {
  repository = var.github_repository
  username   = "Kloox"
  permission = "admin"
}

resource "github_repository_collaborator" "team_members" {
  # Only add team members who are not the repository owner
  for_each = {
    for idx, member in var.team_members :
    member.github_username => member
    if member.github_username != var.github_organization
  }

  repository = var.github_repository
  username   = each.value.github_username
  permission = "push"
}

# Create individual credential files for secure distribution
# Instructor credentials (plain text - will be encrypted by script)
resource "local_file" "instructor_credentials" {
  filename = "${path.module}/credentials/instructor_credentials.json"
  content = jsonencode({
    user_type    = "instructor"
    username     = aws_iam_user.instructor.name
    display_name = "Jeremie JAOUEN - Instructor"
    email        = "jeremie@jjaouen.com"
    aws = {
      access_key_id     = aws_iam_access_key.instructor.id
      secret_access_key = aws_iam_access_key.instructor.secret
      region            = var.region
      console_url       = "https://console.aws.amazon.com/"
    }
    permissions = [
      "ReadOnlyAccess",
      "Billing Dashboard Access",
      "Cost Explorer Access"
    ]
    setup_instructions = "Import this file into AWS CLI: aws configure"
  })

  file_permission = "0600" # Readable only by owner
}

# Team member credential files (one per student)
resource "local_file" "team_member_credentials" {
  for_each = {
    for idx, member in var.team_members : member.username => {
      member     = member
      access_key = aws_iam_access_key.team_members[idx]
      iam_user   = aws_iam_user.team_members[idx]
    }
  }

  filename = "${path.module}/credentials/${each.value.member.username}_credentials.json"
  content = jsonencode({
    user_type       = "student"
    username        = each.value.iam_user.name
    display_name    = each.value.member.display_name
    email           = each.value.member.email
    github_username = each.value.member.github_username
    aws = {
      access_key_id     = each.value.access_key.id
      secret_access_key = each.value.access_key.secret
      region            = var.region
      console_url       = "https://console.aws.amazon.com/"
    }
    permissions = [
      "PowerUserAccess"
    ]
    setup_instructions = "Import this file into AWS CLI: aws configure"
  })

  file_permission = "0600" # Readable only by owner
}

# Create instructor's GPG public key file for encryption
resource "local_file" "instructor_gpg_key" {
  filename        = "${path.module}/credentials/jeremie_public_key.asc"
  content         = var.instructor_pgp_key
  file_permission = "0644"
}

# ============================================================================
# GitHub Actions Roles for CI/CD (OIDC)
# ============================================================================

# IAM Role for GitHub Actions - Development Environment
resource "aws_iam_role" "github_actions_dev" {
  name        = "GitHubActionsRole-dev"
  description = "Role for GitHub Actions to deploy to development environment"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_organization}/${var.github_repository}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "GitHub Actions - Development"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Purpose     = "CI/CD"
  }
}

# IAM Role for GitHub Actions - Production Environment
resource "aws_iam_role" "github_actions_prod" {
  name        = "GitHubActionsRole-prod"
  description = "Role for GitHub Actions to deploy to production environment"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_organization}/${var.github_repository}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "GitHub Actions - Production"
    Environment = "prod"
    ManagedBy   = "Terraform"
    Purpose     = "CI/CD"
  }
}

# Attach Administrator Access to both GitHub Actions roles
# Required for full infrastructure deployment (VPC, EKS, RDS, ECR, etc.)
resource "aws_iam_role_policy_attachment" "github_actions_dev_admin" {
  role       = aws_iam_role.github_actions_dev.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "github_actions_prod_admin" {
  role       = aws_iam_role.github_actions_prod.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
