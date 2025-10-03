# 🚀 Complete Setup Guide

This guide will walk you through setting up the entire cloud-native task manager infrastructure from scratch. Follow these steps in order to deploy everything successfully.

## 📋 Prerequisites Checklist

Before starting, ensure you have all required tools and accounts:

### ☁️ **AWS Account Requirements**
- [ ] AWS Account with administrative access
- [ ] AWS CLI v2 installed and configured
- [ ] Valid AWS credentials with permissions for:
  - EKS (Elastic Kubernetes Service)
  - VPC (Virtual Private Cloud)
  - EC2 (Elastic Compute Cloud)
  - RDS (Relational Database Service)
  - ECR (Elastic Container Registry)
  - IAM (Identity and Access Management)
  - Load Balancer (ALB/NLB)

### 🛠️ **Required Tools**

#### **Core Infrastructure Tools**
```bash
# Terraform v1.5+
terraform --version
# Should output: Terraform v1.x.x

# AWS CLI v2
aws --version
# Should output: aws-cli/2.x.x

# kubectl (Kubernetes CLI)
kubectl version --client
# Should output: Client Version: v1.x.x
```

#### **Container and Deployment Tools**
```bash
# Docker Desktop
docker --version
# Should output: Docker version 20.x.x+

# Helm v3
helm version
# Should output: version.BuildInfo{Version:"v3.x.x"}

# Git
git --version
# Should output: git version 2.x.x
```

### 🔧 **Installation Commands** (if tools are missing)

<details>
<summary>📦 <b>macOS Installation (using Homebrew)</b></summary>

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install all required tools
brew install terraform awscli kubectl helm docker git

# Start Docker Desktop
open -a Docker

# Verify installations
terraform --version && aws --version && kubectl version --client && helm version && docker --version && git --version
```
</details>

<details>
<summary>🐧 <b>Linux Installation</b></summary>

```bash
# Update package manager
sudo apt update

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update && sudo apt-get install helm

# Install Docker
sudo apt-get install docker.io
sudo systemctl start docker
sudo systemctl enable docker
```
</details>

<details>
<summary>🪟 <b>Windows Installation</b></summary>

```powershell
# Install Chocolatey (Windows package manager)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install all required tools
choco install terraform awscli kubernetes-cli kubernetes-helm docker-desktop git

# Restart PowerShell and verify installations
terraform --version; aws --version; kubectl version --client; helm version; docker --version; git --version
```
</details>

## 🔑 AWS Configuration

### 1. **Configure AWS CLI**
```bash
# Configure AWS credentials
aws configure

# You'll be prompted for:
# AWS Access Key ID: [Enter your access key]
# AWS Secret Access Key: [Enter your secret key]
# Default region name: us-east-1
# Default output format: json
```

### 2. **Verify AWS Access**
```bash
# Test AWS connection
aws sts get-caller-identity

# Expected output (with your actual account details):
# {
#     "UserId": "AIDACKCEVSQ6C2EXAMPLE",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/YourUsername"
# }
```

### 3. **Set Required Environment Variables**
```bash
# Add to your shell profile (~/.bashrc, ~/.zshrc, etc.)
export AWS_DEFAULT_REGION=us-east-1
export AWS_REGION=us-east-1

# Reload your shell or run:
source ~/.bashrc  # or ~/.zshrc
```

## 📂 Repository Setup

### 1. **Clone the Repository**
```bash
# Clone the repository
git clone git@github.com:EpitechPGE45-2025/G-CLO-900-PAR-9-1-infraascode-4.git

# Navigate to the project directory
cd G-CLO-900-PAR-9-1-infraascode-4

# Verify the directory structure
tree -d -L 2
```

### 2. **Understand the Structure**
```
📁 Root Directory
├── 🏗️ terraform/           # Infrastructure as Code
├── 🐳 applications/        # Source code for microservices
├── ⚓ helm-charts/          # Kubernetes deployment packages
├── 🔧 kubernetes-manifests/# Raw Kubernetes YAML files
├── 📚 docs/                # Documentation
├── ⚙️ configs/             # Configuration files
└── 🤖 scripts/             # Automation scripts
```

## 🚀 Deployment Options

You have three deployment options. Choose the one that best fits your needs:

### 🎯 **Option 1: One-Command Deployment (Recommended for beginners)**

```bash
# Make the deployment script executable
chmod +x scripts/deploy.sh

# Run the complete deployment
./scripts/deploy.sh

# This script will:
# 1. Deploy infrastructure with Terraform
# 2. Configure kubectl for EKS
# 3. Deploy monitoring stack
# 4. Deploy applications
# 5. Show access URLs
```

### 🔧 **Option 2: Step-by-Step Manual Deployment (Recommended for learning)**

Follow the sections below for complete control over each step.

### 🏃‍♂️ **Option 3: Quick Development Setup (Local testing)**

```bash
# Start local development environment
docker-compose up -d

# Access local services:
echo "Frontend: http://localhost:3000"
echo "Backend: http://localhost:8000"
echo "Grafana: http://localhost:3001"
```

---

## 🏗️ Manual Step-by-Step Deployment

### Step 1: Infrastructure Deployment

#### 1.1 **Initialize Terraform**
```bash
# Navigate to Terraform directory
cd terraform/environments

# Initialize Terraform (downloads providers and modules)
terraform init

# You should see:
# ✅ Terraform has been successfully initialized!
```

#### 1.2 **Plan Infrastructure**
```bash
# Review what will be created
terraform plan -var-file="dev.tfvars"

# This will show:
# - VPC with public/private subnets
# - EKS cluster with node groups
# - Security groups and IAM roles
# - RDS PostgreSQL instance
# - Load balancer controller setup
```

#### 1.3 **Deploy Infrastructure**
```bash
# Deploy infrastructure (this takes 15-20 minutes)
terraform apply -var-file="dev.tfvars"

# Type 'yes' when prompted
# ⏱️ Wait for completion...
# ✅ Apply complete! Resources: XX added, 0 changed, 0 destroyed.
```

#### 1.4 **Configure kubectl**
```bash
# Configure kubectl to access your new EKS cluster
aws eks update-kubeconfig --region us-east-1 --name student-team4-iac-dev-cluster

# Verify connection
kubectl get nodes

# You should see 3 nodes in Ready state:
# NAME                          STATUS   ROLES    AGE   VERSION
# ip-10-0-1-xxx.ec2.internal    Ready    <none>   2m    v1.28.x
# ip-10-0-2-xxx.ec2.internal    Ready    <none>   2m    v1.28.x
# ip-10-0-3-xxx.ec2.internal    Ready    <none>   2m    v1.28.x
```

### Step 2: Deploy Monitoring Stack

#### 2.1 **Deploy Prometheus**
```bash
# Navigate back to project root
cd ../../

# Deploy Prometheus for metrics collection
kubectl apply -f kubernetes-manifests/monitoring/final-prometheus.yaml

# Verify Prometheus is running
kubectl get pods -n monitoring | grep prometheus

# Expected output:
# prometheus-xxx-xxx    1/1     Running   0          2m
```

#### 2.2 **Deploy Grafana**
```bash
# Deploy Grafana for dashboards
kubectl apply -f kubernetes-manifests/monitoring/final-grafana.yaml

# Verify Grafana is running
kubectl get pods -n monitoring | grep grafana

# Expected output:
# grafana-xxx-xxx       1/1     Running   0          1m
```

### Step 3: Deploy Applications

#### 3.1 **Deploy Task Manager Backend**
```bash
# Deploy the FastAPI backend with Prometheus metrics
helm install task-manager helm-charts/task-manager/

# Verify deployment
kubectl get pods | grep task-manager

# Expected output:
# task-manager-xxx-xxx           1/1     Running   0          2m
```

#### 3.2 **Deploy Task Manager Frontend**
```bash
# Deploy the React frontend
helm install task-manager-frontend helm-charts/task-manager-frontend/

# Verify deployment
kubectl get pods | grep frontend

# Expected output:
# task-manager-frontend-xxx-xxx  1/1     Running   0          2m
```

### Step 4: Verify Complete Deployment

#### 4.1 **Check All Pods**
```bash
# Verify all pods are running
kubectl get pods --all-namespaces

# All pods should show 'Running' status
```

#### 4.2 **Get Access URLs**
```bash
# Get LoadBalancer external URLs
kubectl get services --all-namespaces | grep LoadBalancer

# Note the EXTERNAL-IP addresses for:
# - task-manager-frontend (your main application)
# - task-manager (API backend)
# - grafana (monitoring dashboard)
# - prometheus (metrics)
```

#### 4.3 **Wait for Load Balancers**
```bash
# Load balancers take 2-3 minutes to become ready
# Check status with:
kubectl get svc -w

# Press Ctrl+C when all show EXTERNAL-IP (not <pending>)
```

## 🌐 Access Your Applications

After deployment completes, you can access:

### 📱 **Task Manager Frontend**
- **URL**: `http://<frontend-external-ip>`
- **Purpose**: Main application interface
- **Features**: Create, update, delete tasks

### 🔧 **API Documentation**
- **URL**: `http://<backend-external-ip>/docs`
- **Purpose**: Interactive API documentation
- **Features**: Test API endpoints, view schemas

### 📊 **Prometheus Metrics**
- **URL**: `http://<prometheus-external-ip>:9090`
- **Purpose**: Metrics collection and querying
- **Features**: Custom application metrics, infrastructure metrics

### 📈 **Grafana Dashboards**
- **URL**: `http://<grafana-external-ip>`
- **Credentials**: admin/admin (change on first login)
- **Purpose**: Beautiful monitoring dashboards
- **Features**: Application metrics, infrastructure monitoring

## 🔍 Verification Checklist

After deployment, verify everything is working:

- [ ] **Infrastructure**: `terraform show` displays all resources
- [ ] **Cluster**: `kubectl get nodes` shows 3 ready nodes
- [ ] **Pods**: `kubectl get pods --all-namespaces` shows all running
- [ ] **Services**: `kubectl get svc` shows LoadBalancer external IPs
- [ ] **Frontend**: Web interface loads and is responsive
- [ ] **Backend**: API documentation accessible at `/docs`
- [ ] **Database**: Backend can connect to PostgreSQL
- [ ] **Metrics**: Prometheus collecting custom metrics
- [ ] **Dashboards**: Grafana shows application metrics

## 🚨 Common Issues and Solutions

### Issue: Terraform fails with permission errors
```bash
# Solution: Verify AWS credentials and permissions
aws sts get-caller-identity
aws iam list-attached-user-policies --user-name $(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)
```

### Issue: Pods stuck in Pending state
```bash
# Solution: Check node capacity and resources
kubectl describe nodes
kubectl get pods --all-namespaces | grep Pending
kubectl describe pod <pod-name>
```

### Issue: LoadBalancer not getting external IP
```bash
# Solution: Verify AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Issue: Application not accessible
```bash
# Solution: Check service status and endpoints
kubectl get svc
kubectl get endpoints
kubectl describe svc <service-name>
```

## 🧹 Cleanup

When you're done testing, clean up resources to avoid charges:

```bash
# Delete applications
helm uninstall task-manager
helm uninstall task-manager-frontend
kubectl delete -f kubernetes-manifests/monitoring/

# Wait for LoadBalancers to be deleted (2-3 minutes)
kubectl get svc -w

# Destroy infrastructure
cd terraform/environments
terraform destroy -var-file="dev.tfvars"

# Type 'yes' when prompted
```

## 🎯 Next Steps

Now that you have everything deployed:

1. **📚 Read Architecture Guide**: Understand the technical design
2. **📊 Explore Monitoring**: Learn about metrics and dashboards  
3. **🔧 Try Development**: Make changes to applications
4. **🛡️ Review Security**: Understand security configurations
5. **🚀 Scale Applications**: Test auto-scaling features

---

<div align="center">

**🎉 Congratulations! You've successfully deployed a complete cloud-native application stack!**

Continue to **[Architecture Guide](ARCHITECTURE.md)** to understand the technical design.

</div>