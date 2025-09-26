# Outputs for IAM Management Module
# Provides secure credential information for team access

output "instructor_credentials" {
  description = "Instructor credentials - stored in encrypted file"
  value = {
    message             = "Credentials saved to encrypted file: credentials/instructor_credentials.json.gpg"
    file_location       = abspath(local_file.instructor_credentials.filename)
    encryption_required = true
    distribution_method = "GPG encrypted file"
    recipient           = "jeremie@jjaouen.com"
  }
  sensitive = false # This is just metadata, not actual credentials
}

output "team_member_credentials" {
  description = "Team member credentials - stored in individual files"
  value = {
    message = "Credentials saved to individual JSON files in credentials/ directory"
    file_locations = {
      for member in var.team_members :
      member.username => abspath(local_file.team_member_credentials[member.username].filename)
    }
    distribution_method = "Individual JSON files"
  }
  sensitive = false # This is just metadata, not actual credentials
}

output "credential_distribution_guide" {
  description = "Complete guide for secure credential distribution"
  sensitive   = false
  value       = <<-EOT
    🔐 SECURE CREDENTIAL DISTRIBUTION SYSTEM
    =======================================
    
    📂 Credential Files Created:
    • Instructor: credentials/instructor_credentials.json (→ will be GPG encrypted)
    • Students: credentials/*_credentials.json (4 files)
    
    🔑 GPG Encryption for Instructor:
    1. Run: ./scripts/encrypt-instructor-credentials.sh
    2. This creates: instructor_credentials.json.gpg
    3. Send encrypted file to: jeremie@jjaouen.com
    4. Instructor decrypts: gpg --decrypt instructor_credentials.json.gpg
    
    👥 Student Distribution:
    • Send individual JSON files to each team member
    • Files contain AWS access keys for PowerUser access
    
    🚀 Quick Start:
    ./scripts/distribute-credentials.sh
    
    ⚠️  Security: NEVER commit credential files to Git!
  EOT
}

output "github_collaborators_added" {
  description = "GitHub collaborators that were added"
  value = {
    instructor = {
      username   = "Kloox"
      permission = "admin"
    }
    team_members = [
      for username, member in github_repository_collaborator.team_members : {
        username   = username
        permission = member.permission
      }
    ]
  }
}

output "aws_console_links" {
  description = "Direct links to AWS Console sections"
  value = {
    iam_dashboard     = "https://console.aws.amazon.com/iam/home"
    billing_dashboard = "https://console.aws.amazon.com/billing/home"
    cost_explorer     = "https://console.aws.amazon.com/cost-reports/home"
    users_list        = "https://console.aws.amazon.com/iam/home#/users"
  }
}

# Instructor PGP key from C3.md appendix
