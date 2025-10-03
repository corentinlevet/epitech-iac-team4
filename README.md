# 🚀 Cloud-Native Task Manager - Complete Infrastructure as Code

[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?style=flat-square&logo=amazon-aws)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28-326CE5?style=flat-square&logo=kubernetes)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7C3AED?style=flat-square&logo=terraform)](https://terraform.io/)
[![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?style=flat-square&logo=docker)](https://docker.com/)

> **A complete cloud-native application stack demonstrating Infrastructure as Code, containerization, Kubernetes orchestration, and comprehensive monitoring - deployed on AWS EKS.**

## 📋 Table of Contents

- [� Project Overview](#-project-overview)
- [✨ Features](#-features)
- [🏗️ Architecture](#️-architecture)
- [🚀 Quick Start](#-quick-start)
- [� Documentation](#-documentation)
- [🔧 Development](#-development)
- [🌐 Access Your Deployment](#-access-your-deployment)
- [🛠️ Troubleshooting](#️-troubleshooting)
- [🤝 Contributing](#-contributing)

## 🎯 Project Overview

This repository contains a **production-ready cloud-native task management application** built with modern DevOps practices:

- **🏢 Backend**: FastAPI with Prometheus metrics and PostgreSQL database
- **🎨 Frontend**: React SPA with responsive design and real-time API integration
- **☁️ Infrastructure**: AWS EKS cluster with VPC, Load Balancers, and RDS
- **� Monitoring**: Complete observability stack with Prometheus and Grafana
- **🔄 Automation**: Infrastructure as Code with Terraform and Helm charts
- **🔐 Security**: IAM roles, service accounts, and secure networking

## ✨ Features

### 🎯 **Application Features**
- ✅ **Task Management**: Create, update, delete, and track tasks
- ✅ **User Authentication**: Secure login/logout functionality
- ✅ **Real-time Updates**: Live task status and API health monitoring
- ✅ **Responsive Design**: Works seamlessly on desktop and mobile
- ✅ **API Documentation**: Interactive Swagger/OpenAPI documentation

### 🏗️ **Infrastructure Features**
- ✅ **Auto-scaling EKS Cluster**: Kubernetes v1.28 with node auto-scaling
- ✅ **Load Balancing**: AWS Application Load Balancer with health checks
- ✅ **Database**: PostgreSQL with persistent storage and backups
- ✅ **Monitoring**: Prometheus metrics + Grafana dashboards
- ✅ **Security**: IAM roles, security groups, and encrypted storage
- ✅ **CI/CD Ready**: GitHub Actions integration and GitOps workflows

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           AWS Cloud                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                VPC (10.0.0.0/16)                         │  │
│  │  ┌─────────────────┐  ┌─────────────────────────────────┐ │  │
│  │  │  Public Subnets │  │        Private Subnets          │ │  │
│  │  │                 │  │  ┌───────────────────────────┐  │ │  │
│  │  │ ┌─────────────┐ │  │  │       EKS Cluster         │  │ │  │
│  │  │ │     ALB     │ │  │  │  ┌─────┐ ┌─────┐ ┌─────┐  │  │ │  │
│  │  │ └─────────────┘ │  │  │  │Front│ │ API │ │ DB  │  │  │ │  │
│  │  │ ┌─────────────┐ │  │  │  │ end │ │     │ │     │  │  │ │  │
│  │  │ │ NAT Gateway │ │  │  │  └─────┘ └─────┘ └─────┘  │  │ │  │
│  │  │ └─────────────┘ │  │  │  ┌─────┐ ┌─────┐          │  │ │  │
│  │  └─────────────────┘  │  │  │Prom.│ │Graf.│          │  │ │  │
│  │                       │  │  └─────┘ └─────┘          │  │ │  │
│  │                       │  └───────────────────────────┘  │ │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐                               │
│  │     ECR     │  │     RDS     │                               │
│  │ (Containers)│  │(PostgreSQL) │                               │
│  └─────────────┘  └─────────────┘                               │
└─────────────────────────────────────────────────────────────────┘
        ▲                    ▲
        │                    │
    👤 Users              👨‍💻 Developers
```

## 🚀 Quick Start

### Prerequisites

Before starting, ensure you have:

- ✅ **AWS Account** with administrative access
- ✅ **AWS CLI** configured with your credentials
- ✅ **Docker Desktop** installed and running
- ✅ **Terraform** v1.5+ installed
- ✅ **kubectl** installed
- ✅ **Helm** v3+ installed
- ✅ **Git** with SSH keys configured

### 🎬 One-Command Deployment

```bash
# Clone the repository
git clone git@github.com:EpitechPGE45-2025/G-CLO-900-PAR-9-1-infraascode-4.git
cd G-CLO-900-PAR-9-1-infraascode-4

# Run the complete deployment script
./scripts/deploy.sh

# Access your applications (URLs will be displayed after deployment)
```

### 🔧 Manual Step-by-Step Deployment

If you prefer manual control or need to customize the deployment:

#### 1. **Infrastructure Setup**
```bash
# Initialize and deploy infrastructure
cd terraform/environments
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# Configure kubectl for your new EKS cluster
aws eks update-kubeconfig --region us-east-1 --name student-team4-iac-dev-cluster
```

#### 2. **Application Deployment**
```bash
# Deploy monitoring stack
kubectl apply -f kubernetes-manifests/monitoring/final-prometheus.yaml
kubectl apply -f kubernetes-manifests/monitoring/final-grafana.yaml

# Deploy applications using Helm
helm install task-manager helm-charts/task-manager/
helm install task-manager-frontend helm-charts/task-manager-frontend/
```

#### 3. **Verify Deployment**
```bash
# Check all pods are running
kubectl get pods --all-namespaces

# Get application URLs
kubectl get services --all-namespaces | grep LoadBalancer
```

## � Documentation

Our comprehensive documentation is organized by use case:

| Document | Purpose | Audience |
|----------|---------|----------|
| **[🚀 Setup Guide](docs/SETUP.md)** | Complete installation and configuration | DevOps Engineers |
| **[🏗️ Architecture Guide](docs/ARCHITECTURE.md)** | Technical architecture and design decisions | Solution Architects |
| **[📊 Monitoring Guide](docs/MONITORING.md)** | Observability, metrics, and dashboards | SRE Teams |
| **[🔧 Operations Guide](docs/OPERATIONS.md)** | Day-to-day operations and maintenance | Operations Teams |
| **[🛡️ Security Guide](docs/SECURITY.md)** | Security configurations and best practices | Security Engineers |
| **[🚨 Troubleshooting](docs/TROUBLESHOOTING.md)** | Common issues and solutions | All Users |

## 🔧 Development

### Local Development Environment

```bash
# Start local development environment
docker-compose up -d

# Access local services
echo "Frontend: http://localhost:3000"
echo "Backend: http://localhost:8000"
echo "Grafana: http://localhost:3001"
```

### Making Changes

1. **Infrastructure Changes**: Modify files in `terraform/`
2. **Application Changes**: Update source code in `applications/`
3. **Configuration Changes**: Edit files in `configs/`
4. **Documentation**: Update relevant files in `docs/`

## 🌐 Access Your Deployment

After successful deployment, you can access:

### 🎯 **Applications**
- **📱 Task Manager Frontend**: Main application interface
- **🔧 API Documentation**: Interactive API docs and testing
- **� Prometheus**: Metrics collection and querying
- **📈 Grafana**: Beautiful dashboards and monitoring

> **URLs are displayed after deployment completes!**

### 🔑 **Default Credentials**
- **Grafana**: `admin` / `admin` (change on first login)

## 🛠️ Troubleshooting

### Common Issues

<details>
<summary><b>🚨 Pods stuck in Pending state</b></summary>

**Cause**: Insufficient node capacity
**Solution**:
```bash
# Check node capacity
kubectl describe nodes

# Scale node groups if needed
aws eks update-nodegroup-config --cluster-name <cluster-name> --nodegroup-name <nodegroup-name> --scaling-config desiredSize=3
```
</details>

<details>
<summary><b>🚨 LoadBalancer not getting external IP</b></summary>

**Cause**: AWS Load Balancer Controller not running or misconfigured
**Solution**:
```bash
# Check controller status
kubectl get pods -n kube-system | grep aws-load-balancer

# Restart if needed
kubectl rollout restart deployment aws-load-balancer-controller -n kube-system
```
</details>

<details>
<summary><b>🚨 Terraform state issues</b></summary>

**Cause**: State drift or lock issues
**Solution**:
```bash
# Refresh state
terraform refresh -var-file="dev.tfvars"

# If locked, force unlock (use carefully)
terraform force-unlock <lock-id>
```
</details>

For more detailed troubleshooting, see **[🚨 Troubleshooting Guide](docs/TROUBLESHOOTING.md)**.

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'Add amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

### Development Standards

- ✅ **Code Quality**: Follow language-specific best practices
- ✅ **Documentation**: Update docs for any changes
- ✅ **Testing**: Add tests for new functionality
- ✅ **Security**: Follow security best practices
- ✅ **Infrastructure**: Use Terraform for all infrastructure changes

## 📊 Project Stats

- **📁 Languages**: TypeScript, Python, HCL, YAML
- **🏗️ Infrastructure**: 3 Terraform modules, 4 Helm charts
- **📱 Applications**: 2 containerized microservices
- **☁️ AWS Services**: EKS, VPC, RDS, ECR, ALB, IAM
- **📊 Monitoring**: 15+ custom metrics, 5+ dashboards

---

<div align="center">

**⭐ Star this repository if it helped you!**

Made with ❤️ by **Team 4** | [Report Bug](../../issues) | [Request Feature](../../issues)

</div>
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

## 🔐 GitHub Actions OIDC Integration

This project uses GitHub Actions with AWS OIDC (OpenID Connect) for secure, keyless authentication:

### ✅ **Completed Setup**
- **OIDC Provider**: Configured in AWS for `token.actions.githubusercontent.com`
- **IAM Roles**: 
  - `GitHubActions-Dev-Role` (Development deployments)
  - `GitHubActions-Prod-Role` (Production deployments)
- **Trust Policies**: Restrict access to this specific repository
- **Permissions**: PowerUserAccess for full infrastructure management

### 🔑 **Required GitHub Secrets**
Repository secrets configured for secure AWS authentication:
- `AWS_ROLE_ARN`: Development role ARN
- `AWS_PROD_ROLE_ARN`: Production role ARN

### 🚀 **Workflow Triggers**
- **Pull Requests** → Planning and validation for both environments
- **Push to main** → Deploy to development environment
- **Create Release** → Deploy to production environment

*Setup completed: September 26, 2025*

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