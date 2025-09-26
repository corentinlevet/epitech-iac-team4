# Infrastructure as Code - Team 4 Project

This project demonstrates the Infrastructure as Code (IaC) principles and GitOps concepts covered in Course 1 (C1.md), implemented for a team of 4 students using AWS and Terraform.

## 🏗️ Project Structure

```
.
├── .github/
│   └── workflows/
│       └── terraform.yml          # GitOps CI/CD pipeline
├── terraform/
│   ├── modules/
│   │   └── vpc/                   # Reusable VPC module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── environments/              # Environment configurations
│   │   ├── main.tf               # Main Terraform configuration
│   │   ├── variables.tf          # Variable definitions
│   │   ├── outputs.tf            # Output definitions
│   │   ├── dev.tfvars            # Development environment values
│   │   └── prod.tfvars           # Production environment values
│   └── backends/                 # Backend configurations
│       ├── dev.config            # Development backend config
│       └── prod.config           # Production backend config
├── C1.md                         # Course 1 content (theory)
├── C2.md                         # Course 2 content (hands-on)
└── README.md                     # This file
```

## 🎯 Terraform Principles Implementation

This project demonstrates the three core Terraform principles from C1.md:

### 1. **Reproducibility** 
- ✅ Same Terraform configuration creates identical infrastructure across environments
- ✅ Modular design allows consistent VPC deployment in dev/prod
- ✅ Environment-specific variable files ensure predictable outcomes

### 2. **Idempotence**
- ✅ Running `terraform apply` multiple times produces the same result
- ✅ Terraform state tracks actual infrastructure vs. desired state
- ✅ Drift detection identifies manual changes and corrects them

### 3. **Versioning**
- ✅ All Terraform code is stored in Git
- ✅ Backend state is versioned and locked
- ✅ GitOps workflow enforces code review and approval process

## 🔄 GitOps Workflow Implementation

The project implements GitOps principles from C1.md:

### Declarative Configuration
- Infrastructure defined in Terraform HCL (declarative language)
- No imperative scripts or manual processes

### Git as Single Source of Truth
- All infrastructure changes must be committed to Git
- Pull requests required for code review
- Git history provides full audit trail

### Automated Delivery
- GitHub Actions CI/CD pipeline automatically deploys changes
- Different workflows for dev (on push to main) and prod (on release)
- Automated planning, validation, and deployment

## 🚀 Getting Started

### Prerequisites (for Team of 4 students)

1. **AWS Account Setup**
   ```bash
   # One AWS account per team
   # Recommended: student-team4-dev and student-team4-prd projects
   ```

2. **Local Tools Installation**
   ```bash
   # Terraform CLI
   brew install terraform
   
   # AWS CLI
   brew install awscli
   
   # Git CLI (usually pre-installed)
   git --version
   
   # Optional: GPG for credential encryption
   brew install gnupg
   ```

3. **AWS Credentials Configuration**
   ```bash
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Default region: us-east-1
   # Default output format: json
   ```

4. **GitHub Token (for C3.md IAM management)**
   ```bash
   export GITHUB_TOKEN=your_github_personal_access_token
   # Required for GitHub repository permission management
   ```

   ⚠️ **Security Note**: Never hardcode credentials in Terraform files or commit them to Git.

### Quick Start - Full Implementation (C1 + C2 + C3)

For complete Infrastructure as Code learning experience:

```bash
# 1. Validate entire setup
./scripts/validate.sh

# 2. Setup backend infrastructure
./scripts/setup-backend.sh

# 3. Test C2.md hands-on workflow
./scripts/test-c2.sh dev

# 4. Test C3.md multi-environment setup
./scripts/test-c3.sh

# 5. Set up IAM and team permissions
./scripts/manage-iam.sh
```

### Course-Specific Quick Starts

#### C1.md - IaC Fundamentals & GitOps
```bash
# Learn core concepts and principles
./scripts/validate.sh
cat C1_IMPLEMENTATION.md
```

#### C2.md - Hands-On Implementation  
```bash
# Complete hands-on Terraform experience
./scripts/test-c2.sh dev
./scripts/test-import.sh
./scripts/demo-state.sh
```

#### C3.md - Multi-Environment & Team Collaboration
```bash
# Advanced multi-environment setup
export GITHUB_TOKEN=your_token
./scripts/test-c3.sh
./scripts/manage-iam.sh
```

### Manual Backend Setup

Before running Terraform, create the S3 bucket for remote state storage:

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://student-team4-terraform-state --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket student-team4-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking (optional but recommended)
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### Local Development Workflow

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd IaC/terraform/environments
   ```

2. **Initialize Terraform**
   ```bash
   terraform init -backend-config="../backends/dev.config"
   ```

3. **Plan Infrastructure Changes**
   ```bash
   terraform plan -var-file="dev.tfvars"
   ```

4. **Apply Infrastructure**
   ```bash
   terraform apply -var-file="dev.tfvars"
   ```

5. **View Outputs**
   ```bash
   terraform output
   ```

6. **Destroy Infrastructure** (when testing is complete)
   ```bash
   terraform destroy -var-file="dev.tfvars"
   ```

### GitOps Workflow

1. **Feature Development**
   ```bash
   git checkout -b feature/add-security-groups
   # Make changes to Terraform files
   git add .
   git commit -m "Add security groups for web servers"
   git push origin feature/add-security-groups
   ```

2. **Code Review Process**
   - Create Pull Request on GitHub
   - CI pipeline runs `terraform plan`
   - Team reviews changes and plan output
   - Approve and merge to main branch

3. **Automatic Deployment**
   - Push to main triggers dev environment deployment
   - Creating a release tag triggers production deployment

4. **Production Release**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   # Creates GitHub release, triggers prod deployment
   ```

## 📊 Infrastructure Components

The current infrastructure includes:

- **VPC**: Virtual Private Cloud with custom CIDR block
- **Subnet**: Public subnet in first availability zone
- **Internet Gateway**: Enables internet access
- **Route Table**: Routes traffic to internet gateway
- **Security**: All resources tagged for management and cost tracking

### Development Environment
- Region: `us-east-1`
- VPC CIDR: `10.0.0.0/16`
- Subnet CIDR: `10.0.1.0/24`
- Public IP assignment: Enabled
- Use case: Development and testing

### Production Environment  
- Region: `us-west-2`
- VPC CIDR: `10.1.0.0/16`
- Subnet CIDR: `10.1.1.0/24`
- Public IP assignment: Disabled
- Use case: Production workloads

### IAM Management (Separate Stack)
- **Purpose**: Team collaboration and instructor access
- **Instructor Access**: ReadOnly + Billing permissions for course assessment
- **Student Access**: PowerUserAccess for hands-on learning
- **GitHub Integration**: Repository collaborator management
- **Security**: GPG-encrypted credential distribution

## 🔐 Security Best Practices

- ✅ Remote state storage with encryption
- ✅ State locking to prevent concurrent modifications
- ✅ No hardcoded credentials
- ✅ OIDC authentication in CI/CD pipeline
- ✅ Environment-specific AWS roles
- ✅ Resource tagging for governance

## 🌱 Next Steps

This implementation covers Course 1 fundamentals. Future enhancements may include:

- Multi-AZ subnets for high availability
- Security groups and NACLs
- EC2 instances and load balancers
- Database and storage services
- Monitoring and logging setup

## 👥 Team Collaboration

**Team Organization**: 4 students can divide work as follows:
- **Student 1**: VPC module and networking components
- **Student 2**: Backend setup and state management
- **Student 3**: GitOps pipeline and CI/CD configuration
- **Student 4**: Documentation and testing procedures

## 📚 Course References

This implementation directly addresses the concepts from:
- **C1.md**: IaC principles, Terraform concepts, GitOps workflow
- **C2.md**: Hands-on implementation, backend setup, local testing

## 🆘 Troubleshooting

### Common Issues

1. **Backend bucket doesn't exist**
   ```
   Error: Failed to get existing workspaces: S3 bucket does not exist
   ```
   **Solution**: Create the S3 bucket manually first (see setup instructions above)

2. **State locking errors**
   ```
   Error: Error acquiring the state lock
   ```
   **Solution**: Check DynamoDB table exists, or disable locking temporarily

3. **AWS credentials not configured**
   ```
   Error: No valid credential sources found
   ```
   **Solution**: Run `aws configure` or check IAM roles

### Getting Help

- 📖 **Terraform Documentation**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- 📖 **AWS Provider Reference**: All resource types and arguments
- 👥 **Team Communication**: Use Git issues and pull request comments
- 🔍 **RTFM**: HashiCorp and AWS documentation contain all necessary information

---

*This project demonstrates Infrastructure as Code and GitOps principles as taught in the EPITECH IaC course. All resources are managed through Terraform and deployed via automated GitOps workflows.*