# 🚀 C4 Implementation: Cloud-Native Kubernetes Architecture

**Complete implementation of Course 4 requirements featuring FastAPI Task Manager, GitHub Actions self-hosted runners, and comprehensive monitoring stack.**

## 🏗️ **Architecture Overview**

This implementation provides a production-ready, cloud-native architecture on AWS with:

- **🎯 EKS Kubernetes Cluster** with auto-scaling node groups
- **📱 FastAPI Task Manager** with PostgreSQL backend
- **🤖 GitHub Actions Self-Hosted Runners** with cost optimization
- **📊 Prometheus + Grafana Monitoring** with custom dashboards
- **🔐 OIDC Identity Federation** for secure authentication
- **🚀 Helm Package Management** for all deployments
- **🛡️ Security Best Practices** throughout the entire stack

## 📁 **Project Structure**

```
C4 Implementation/
├── applications/
│   └── task-manager/          # FastAPI application
│       ├── main.py            # REST API implementation
│       ├── requirements.txt   # Python dependencies
│       └── Dockerfile         # Container image
├── helm-charts/
│   ├── task-manager/          # Custom Helm chart
│   ├── github-runners/        # Self-hosted runners chart
│   └── monitoring/            # Prometheus + Grafana stack
├── terraform/
│   ├── modules/
│   │   ├── eks/              # EKS cluster module
│   │   ├── rds/              # PostgreSQL database module
│   │   └── vpc/              # Network infrastructure
│   └── environments/         # Environment-specific configs
└── scripts/
    └── deploy-c4.sh          # Complete deployment script
```

## 🚀 **Quick Start**

### **Prerequisites**
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- kubectl
- Helm >= 3.0
- Docker

### **Deploy Development Environment**
```bash
# Deploy complete infrastructure
./scripts/deploy-c4.sh deploy dev

# Verify deployment
./scripts/deploy-c4.sh verify
```

### **Deploy Production Environment**
```bash
# Deploy to production
./scripts/deploy-c4.sh deploy prod
```

### **Cleanup**
```bash
# Cleanup development environment
./scripts/deploy-c4.sh cleanup dev
```

## 🎯 **Key Components**

### **1. Task Manager API**
- **FastAPI** REST API with async PostgreSQL
- **Authentication** with Bearer tokens
- **Out-of-order request handling** via timestamps
- **Health checks** and observability
- **Horizontal scaling** with load balancing

**API Endpoints:**
```
POST   /tasks      - Create new task
GET    /tasks      - List all tasks
GET    /tasks/{id} - Get specific task
PUT    /tasks/{id} - Update task
DELETE /tasks/{id} - Delete task
GET    /health     - Health check
```

### **2. GitHub Actions Self-Hosted Runners**
- **Auto-scaling** based on job queue (0-10 runners)
- **Spot instances** for cost optimization (up to 90% savings)
- **Automatic cleanup** and registration
- **Resource monitoring** and alerting

### **3. Monitoring Stack**
- **Prometheus** for metrics collection
- **Grafana** for visualization and dashboards
- **AlertManager** for incident management
- **Custom alerts** for applications and infrastructure

### **4. Infrastructure**
- **EKS Cluster** with dedicated node groups
- **RDS PostgreSQL** with encryption and backups
- **VPC** with public/private subnet architecture
- **ALB** with SSL/TLS termination

## 🌍 **Multi-Environment Setup**

### **Development Environment**
```yaml
Region: us-east-1
Cluster: 1-3 nodes (t3.medium)
Database: db.t3.micro
Runners: 0-3 (spot instances)
Retention: 3 days backup
```

### **Production Environment**
```yaml
Region: us-west-2
Cluster: 3-20 nodes (t3.medium/large)
Database: db.t3.small
Runners: 2-10 (spot instances)
Retention: 14 days backup
```

## 🔧 **Configuration**

### **Environment Variables**
Update `terraform/environments/{env}.tfvars` for each environment:

```hcl
# Development example
region = "us-east-1"
environment = "dev"
kubernetes_version = "1.28"

# Scaling configuration
runner_desired_size = 1
runner_max_size = 3
app_desired_size = 2
app_max_size = 5

# Database configuration
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
```

### **Application Configuration**
Customize Helm values in `helm-charts/task-manager/values.yaml`:

```yaml
replicaCount: 3
resources:
  limits:
    cpu: 500m
    memory: 512Mi
ingress:
  enabled: true
  hosts:
    - host: api-prod.student-team4.local
```

## 📊 **Monitoring & Observability**

### **Access Dashboards**
```bash
# Get Grafana URL
terraform output grafana_url

# Default credentials (change in production)
Username: admin
Password: admin123
```

### **Key Metrics Monitored**
- **Application:** HTTP requests, latency, error rates
- **Infrastructure:** CPU, memory, disk, network
- **Database:** Connections, queries, performance
- **Runners:** Job queue, resource usage, costs

### **Alerting Rules**
- **Critical:** Application down, database unreachable
- **Warning:** High resource usage, runner unavailability
- **Info:** Scale events, deployment status

## 🔐 **Security Features**

### **Network Security**
- **VPC isolation** with security groups
- **Private subnets** for databases and internal services
- **NAT Gateway** for controlled internet access
- **TLS encryption** for all external communications

### **Identity & Access**
- **OIDC federation** with GitHub Actions
- **IAM least privilege** access policies
- **Secrets management** via AWS Secrets Manager
- **Container security** with non-root users

### **Data Protection**
- **Encryption at rest** for databases and storage
- **Backup and recovery** procedures
- **Network segmentation** and firewall rules
- **Audit logging** for all operations

## 💰 **Cost Optimization**

### **Implemented Strategies**
- **Spot instances** for GitHub runners (90% cost savings)
- **Auto-scaling** based on actual demand
- **Right-sizing** instances per environment
- **Lifecycle policies** for storage retention
- **Resource monitoring** and alerting

### **Cost Monitoring**
- **Resource tagging** for cost tracking
- **Billing alerts** for unexpected usage
- **Usage reports** via Grafana dashboards
- **Automatic cleanup** of unused resources

## 🚀 **CI/CD Integration**

### **GitHub Actions Workflow**
The existing CI/CD pipeline is enhanced with:
- **Self-hosted runners** for Terraform and kubectl operations
- **Multi-environment deployment** with proper approvals
- **Container building** and registry management
- **Infrastructure validation** and testing

### **Deployment Flow**
1. **Push to branch** → Validation on self-hosted runners
2. **Pull request** → Infrastructure planning and review
3. **Merge to main** → Automatic deployment to development
4. **Release tag** → Production deployment with approvals

## 🛠️ **Troubleshooting**

### **Common Issues**

**EKS cluster connection issues:**
```bash
aws eks update-kubeconfig --region us-east-1 --name cluster-name
kubectl config current-context
```

**Application not accessible:**
```bash
kubectl get ingress
kubectl describe ingress task-manager
kubectl logs -f deployment/task-manager
```

**Database connection errors:**
```bash
kubectl get secret task-manager-db-credentials -o yaml
kubectl exec -it deployment/task-manager -- env | grep DATABASE
```

**GitHub runners not registering:**
```bash
kubectl get pods -n github-runners
kubectl logs -f -n github-runners deployment/github-runner
```

### **Health Checks**
```bash
# Check all pods
kubectl get pods --all-namespaces

# Check services
kubectl get services --all-namespaces

# Check ingresses and load balancers
kubectl get ingress --all-namespaces

# Verify monitoring
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```

## 📚 **Documentation**

- **[C4_IMPLEMENTATION.md](./C4_IMPLEMENTATION.md)** - Complete implementation details
- **[API Documentation](./applications/task-manager/README.md)** - FastAPI endpoint documentation
- **[Helm Charts](./helm-charts/)** - Chart configuration and customization
- **[Infrastructure Modules](./terraform/modules/)** - Terraform module documentation

## 🎯 **Learning Outcomes Achieved**

### **✅ Technical Skills**
- **Kubernetes orchestration** with EKS and Helm
- **Cloud-native application** development with FastAPI
- **Infrastructure as Code** with Terraform
- **Monitoring and observability** with Prometheus/Grafana
- **CI/CD automation** with self-hosted runners
- **Security implementation** and best practices

### **✅ DevOps Practices**
- **GitOps workflows** and collaboration
- **Multi-environment management** and promotion
- **Cost optimization** and resource management
- **Incident response** and troubleshooting
- **Documentation** and knowledge sharing

## 🏆 **Production Readiness**

This implementation is production-ready with:
- **High availability** and fault tolerance
- **Security hardening** and compliance
- **Monitoring and alerting** capabilities
- **Backup and disaster recovery** procedures
- **Performance optimization** and scalability
- **Cost management** and optimization

**Ready for project defense and real-world deployment! 🚀**