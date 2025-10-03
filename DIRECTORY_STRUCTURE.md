# 📁 Repository Directory Structure

This document describes the organized structure of the Infrastructure as Code (IaC) repository.

## 🏗️ Root Structure

```
IaC/
├── 📁 applications/           # Application source code
│   ├── task-manager/         # FastAPI backend application
│   └── task-manager-frontend/ # React frontend application
├── 📁 configs/               # Configuration files
│   ├── aws-iam/             # AWS IAM policies and trust relationships
│   └── helm-values/         # Helm chart values files
├── 📁 docs/                 # Documentation files
├── 📁 helm-charts/          # Helm charts for deployments
│   ├── monitoring/          # Monitoring stack charts
│   ├── task-manager/        # Backend application chart
│   └── task-manager-frontend/ # Frontend application chart
├── 📁 kubernetes-manifests/ # Raw Kubernetes YAML manifests
│   ├── database/           # Database-related manifests
│   └── monitoring/         # Monitoring stack manifests
├── 📁 scripts/             # Automation and setup scripts
├── 📁 terraform/           # Infrastructure as Code
│   ├── environments/       # Environment-specific configurations
│   └── modules/            # Reusable Terraform modules
├── 📁 .github/             # GitHub Actions workflows
├── docker-compose.yml      # Local development setup
├── README.md              # Main project documentation
└── terraform.tfstate     # Terraform state file
```

## 📂 Directory Descriptions

### `/applications/`
Contains the source code for all applications:
- **task-manager/**: FastAPI backend with Prometheus metrics
- **task-manager-frontend/**: React frontend application

### `/configs/`
Configuration files organized by type:
- **aws-iam/**: AWS IAM policies, trust policies, and GitHub OIDC setup
- **helm-values/**: Values files for Helm chart customization

### `/docs/`
Comprehensive documentation:
- Implementation guides (C1, C2, C3, C4)
- Setup instructions
- Demo guides
- Access documentation

### `/helm-charts/`
Kubernetes applications packaged as Helm charts:
- **monitoring/**: Prometheus, Grafana, and observability stack
- **task-manager/**: Backend API Helm chart
- **task-manager-frontend/**: Frontend application Helm chart

### `/kubernetes-manifests/`
Raw Kubernetes YAML files for direct deployment:
- **database/**: PostgreSQL and database-related manifests
- **monitoring/**: Prometheus, Grafana configurations

### `/scripts/`
Automation and utility scripts:
- GitHub OIDC setup
- Deployment automation
- Environment configuration

### `/terraform/`
Infrastructure as Code using Terraform:
- **environments/**: Dev, staging, production configurations
- **modules/**: Reusable infrastructure components (VPC, EKS, RDS)

## 🎯 Usage Guidelines

### For Development
1. Use `docker-compose.yml` for local development
2. Refer to `/docs/` for setup instructions
3. Use `/scripts/` for automation

### For Deployment
1. Use `/terraform/` for infrastructure provisioning
2. Use `/helm-charts/` for application deployment
3. Use `/kubernetes-manifests/` for raw Kubernetes deployments

### For Configuration
1. Customize `/configs/helm-values/` for different environments
2. Update `/configs/aws-iam/` for permission changes
3. Refer to `/docs/` for configuration guidance

## 🔄 Migration Notes

This structure was created to organize files that were previously scattered in the root directory:
- Monitoring YAML files → `/kubernetes-manifests/monitoring/`
- Database manifests → `/kubernetes-manifests/database/`
- Helm values → `/configs/helm-values/`
- IAM configurations → `/configs/aws-iam/`
- Documentation → `/docs/`
- Scripts → `/scripts/`