# 🏗️ Architecture Guide

This document provides a comprehensive overview of the technical architecture, design decisions, and implementation details for the cloud-native task manager application.

## 📋 Table of Contents

- [🎯 Architecture Overview](#-architecture-overview)
- [☁️ Cloud Infrastructure](#️-cloud-infrastructure)
- [🐳 Application Architecture](#-application-architecture)
- [📊 Monitoring Architecture](#-monitoring-architecture)
- [🔐 Security Architecture](#-security-architecture)
- [🔄 Data Flow](#-data-flow)
- [🚀 Deployment Architecture](#-deployment-architecture)
- [📈 Scalability Design](#-scalability-design)

## 🎯 Architecture Overview

### **Design Principles**

Our architecture follows cloud-native principles and industry best practices:

- **🔄 Microservices**: Loosely coupled, independently deployable services
- **📦 Containerization**: All applications packaged as immutable containers
- **☁️ Cloud-Native**: Built for cloud environments with auto-scaling and resilience
- **📊 Observability**: Comprehensive monitoring, logging, and tracing
- **🔐 Security**: Zero-trust model with least-privilege access
- **🚀 DevOps**: Infrastructure as Code and GitOps workflows

### **Technology Stack**

```
┌─────────────────────────────────────────────────────┐
│                  Technology Stack                   │
├─────────────────────────────────────────────────────┤
│  🎨 Frontend    │ React, TypeScript, Nginx          │
│  🔧 Backend     │ FastAPI, Python, PostgreSQL       │
│  📊 Monitoring  │ Prometheus, Grafana, Alertmanager │
│  ⚓ Platform    │ Kubernetes (EKS), Docker, Helm    │
│  🏗️ IaC        │ Terraform, AWS Provider            │
│  ☁️ Cloud      │ AWS (EKS, VPC, RDS, ALB, ECR)     │
│  🔄 CI/CD      │ GitHub Actions, GitOps             │
└─────────────────────────────────────────────────────┘
```

## ☁️ Cloud Infrastructure

### **AWS Architecture Diagram**

```
                              ┌─────────────────────────────────────────┐
                              │                AWS Cloud                │
                              │                                         │
                              │  ┌─────────────────────────────────┐   │
                              │  │         VPC (10.0.0.0/16)      │   │
                              │  │                                 │   │
┌─────────────┐              │  │  ┌─────────────┐  ┌─────────────┐ │   │
│             │              │  │  │   Public    │  │   Private   │ │   │
│  Internet   │◄─────────────┼─►│  │  Subnets    │  │   Subnets   │ │   │
│   Gateway   │              │  │  │             │  │             │ │   │
│             │              │  │  │  ┌───────┐  │  │ ┌─────────┐ │ │   │
└─────────────┘              │  │  │  │  ALB  │  │  │ │   EKS   │ │ │   │
                              │  │  │  └───────┘  │  │ │ Cluster │ │ │   │
                              │  │  │             │  │ └─────────┘ │ │   │
                              │  │  │  ┌───────┐  │  │             │ │   │
                              │  │  │  │  NAT  │  │  │ ┌─────────┐ │ │   │
                              │  │  │  │Gateway│  │  │ │Database │ │ │   │
                              │  │  │  └───────┘  │  │ │ Subnets │ │ │   │
                              │  │  └─────────────┘  │ └─────────┘ │ │   │
                              │  └─────────────────────────────────┘   │
                              │                                         │
                              │  ┌─────────────┐  ┌─────────────┐     │
                              │  │     ECR     │  │     RDS     │     │
                              │  │(Containers) │  │(PostgreSQL) │     │
                              │  └─────────────┘  │  Multi-AZ   │     │
                              │                   └─────────────┘     │
                              └─────────────────────────────────────────┘
```

### **Infrastructure Components**

#### **🌐 Networking (VPC)**
```hcl
# Primary VPC Configuration
VPC CIDR: 10.0.0.0/16

Public Subnets:
├── 10.0.1.0/24 (us-east-1a) - Load Balancers, NAT Gateway
├── 10.0.2.0/24 (us-east-1b) - Load Balancers, NAT Gateway
└── 10.0.3.0/24 (us-east-1c) - Load Balancers, NAT Gateway

Private Subnets:
├── 10.0.4.0/24 (us-east-1a) - EKS Nodes, Applications
├── 10.0.5.0/24 (us-east-1b) - EKS Nodes, Applications
└── 10.0.6.0/24 (us-east-1c) - EKS Nodes, Applications

Database Subnets:
├── 10.0.7.0/24 (us-east-1a) - RDS Primary
├── 10.0.8.0/24 (us-east-1b) - RDS Standby
└── 10.0.9.0/24 (us-east-1c) - RDS Backup
```

#### **⚓ Kubernetes Cluster (EKS)**
```yaml
EKS Cluster Configuration:
  Name: student-team4-iac-dev-cluster
  Version: 1.28
  Endpoint: Private + Public
  
  Node Groups:
    - Name: student-team4-iac-dev-nodes
    - Instance Type: t3.micro
    - Min Size: 1
    - Max Size: 3
    - Desired Size: 3
    - Disk Size: 20GB
    - AMI Type: AL2_x86_64
    
  Add-ons:
    - vpc-cni (CNI networking)
    - coredns (DNS resolution)
    - kube-proxy (network proxying)
    - aws-load-balancer-controller (ALB/NLB integration)
```

#### **🗄️ Database (RDS)**
```yaml
RDS PostgreSQL Configuration:
  Engine: PostgreSQL 15.4
  Instance Class: db.t3.micro
  Storage: 20GB (gp2)
  Multi-AZ: true (High Availability)
  Backup Retention: 7 days
  Monitoring: Enhanced monitoring enabled
  
  Security:
    - Encrypted at rest
    - SSL/TLS in transit
    - VPC security groups
    - Private subnet deployment
```

## 🐳 Application Architecture

### **Microservices Overview**

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Application Layer                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐ │
│  │                 │    │                 │    │                 │ │
│  │   📱 Frontend    │    │   🔧 Backend     │    │   🗄️ Database   │ │
│  │                 │    │                 │    │                 │ │
│  │  React SPA      │◄──►│  FastAPI        │◄──►│  PostgreSQL     │ │
│  │  TypeScript     │    │  Python 3.11    │    │  Version 15.4   │ │
│  │  Nginx          │    │  Pydantic       │    │  Persistent     │ │
│  │  Port 80        │    │  Port 8000      │    │  Port 5432      │ │
│  │                 │    │                 │    │                 │ │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Monitoring Layer                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐              ┌─────────────────┐               │
│  │                 │              │                 │               │
│  │  📊 Prometheus   │◄────────────►│  📈 Grafana     │               │
│  │                 │              │                 │               │
│  │  Metrics Store  │              │  Dashboards     │               │
│  │  Port 9090      │              │  Port 3000      │               │
│  │                 │              │                 │               │
│  └─────────────────┘              └─────────────────┘               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### **Frontend Architecture (React)**

```typescript
// Application Structure
src/
├── components/          # Reusable UI components
│   ├── TaskList.tsx    # Task display component
│   ├── TaskForm.tsx    # Task creation/editing
│   └── Header.tsx      # Navigation header
├── services/           # API communication
│   └── api.ts         # HTTP client configuration
├── types/             # TypeScript type definitions
│   └── Task.ts        # Task interface
├── App.tsx            # Main application component
└── index.tsx          # Application entry point

// Key Features:
- Material-UI components for consistent design
- React hooks for state management
- Axios for HTTP requests
- TypeScript for type safety
- Responsive design for mobile/desktop
```

### **Backend Architecture (FastAPI)**

```python
# Application Structure
app/
├── main.py              # FastAPI application entry point
├── models/             # Database models
│   └── task.py        # Task model definition
├── routers/           # API route handlers
│   ├── tasks.py       # Task CRUD operations
│   └── health.py      # Health check endpoints
├── database/          # Database configuration
│   └── connection.py  # PostgreSQL connection
└── metrics/           # Prometheus metrics
    └── collectors.py  # Custom metric collectors

# Key Features:
- FastAPI framework for high performance
- SQLAlchemy ORM for database operations
- Pydantic for request/response validation
- Prometheus metrics integration
- Automatic API documentation (Swagger/OpenAPI)
- CORS enabled for frontend integration
```

### **Database Schema**

```sql
-- Task Management Schema
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    priority VARCHAR(20) DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    due_date TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);

-- Sample data
INSERT INTO tasks (title, description, status, priority) VALUES
('Setup CI/CD Pipeline', 'Configure GitHub Actions for automated deployment', 'in_progress', 'high'),
('Write Documentation', 'Create comprehensive user and technical documentation', 'pending', 'medium'),
('Performance Testing', 'Load test the application under various conditions', 'pending', 'low');
```

## 📊 Monitoring Architecture

### **Observability Stack**

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Monitoring Architecture                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Data Collection                          │   │
│  │                                                             │   │
│  │  📱 Frontend   🔧 Backend   ⚓ Kubernetes   ☁️ AWS         │   │
│  │      │           │            │             │             │   │
│  │      └───────────┼────────────┼─────────────┘             │   │
│  │                  │            │                           │   │
│  │                  ▼            ▼                           │   │
│  │            ┌─────────────────────────────────────┐       │   │
│  │            │         📊 Prometheus               │       │   │
│  │            │                                     │       │   │
│  │            │  • Custom application metrics       │       │   │
│  │            │  • Kubernetes cluster metrics      │       │   │
│  │            │  • Node and pod metrics            │       │   │
│  │            │  • Database performance metrics    │       │   │
│  │            └─────────────────────────────────────┘       │   │
│  │                            │                             │   │
│  │                            ▼                             │   │
│  │            ┌─────────────────────────────────────┐       │   │
│  │            │         📈 Grafana                  │       │   │
│  │            │                                     │       │   │
│  │            │  • Application dashboards           │       │   │
│  │            │  • Infrastructure monitoring        │       │   │
│  │            │  • Custom alerting rules           │       │   │
│  │            │  • Performance analytics           │       │   │
│  │            └─────────────────────────────────────┘       │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### **Custom Metrics**

```python
# Application Metrics (main.py)
from prometheus_client import Counter, Histogram, Gauge

# HTTP Request metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

# Response time metrics
http_request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint']
)

# Business metrics
tasks_total = Gauge(
    'tasks_total',
    'Total number of tasks',
    ['status']
)

# Database metrics
database_connections_active = Gauge(
    'database_connections_active',
    'Active database connections'
)

# Infrastructure metrics collected automatically:
# - CPU usage per pod
# - Memory usage per pod
# - Network I/O
# - Disk I/O
# - Kubernetes events
```

### **Grafana Dashboards**

```yaml
Available Dashboards:
  1. Application Overview:
     - Request rate and latency
     - Error rate and success rate
     - Task creation/completion trends
     - User activity patterns
     
  2. Infrastructure Monitoring:
     - Node CPU/Memory utilization
     - Pod resource consumption
     - Network traffic patterns
     - Storage usage trends
     
  3. Database Performance:
     - Connection pool status
     - Query performance metrics
     - Database size and growth
     - Slow query analysis
     
  4. Kubernetes Cluster:
     - Cluster resource utilization
     - Pod scheduling patterns
     - Service mesh metrics
     - Event monitoring
```

## 🔐 Security Architecture

### **Security Layers**

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Security Model                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  🌐 Network Security                                               │
│  ├── VPC with private subnets                                      │
│  ├── Security groups (firewall rules)                              │
│  ├── NACLs (network access control lists)                          │
│  └── TLS/SSL encryption in transit                                 │
│                                                                     │
│  🔑 Identity & Access Management                                   │
│  ├── IAM roles and policies                                        │
│  ├── Service accounts for Kubernetes                               │
│  ├── RBAC (Role-Based Access Control)                             │
│  └── Least privilege principle                                     │
│                                                                     │
│  📦 Container Security                                             │
│  ├── Minimal base images (Alpine Linux)                           │
│  ├── Non-root user execution                                       │
│  ├── Security contexts and pod security standards                  │
│  └── Image vulnerability scanning                                  │
│                                                                     │
│  🗄️ Data Security                                                  │
│  ├── Encryption at rest (RDS, EBS)                                │
│  ├── Encryption in transit (TLS 1.3)                              │
│  ├── Database access controls                                      │
│  └── Secrets management (Kubernetes secrets)                       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### **IAM Role Architecture**

```json
{
  "EKS_Cluster_Role": {
    "purpose": "EKS cluster management",
    "policies": [
      "AmazonEKSClusterPolicy"
    ]
  },
  "EKS_NodeGroup_Role": {
    "purpose": "EC2 instances in node groups",
    "policies": [
      "AmazonEKSWorkerNodePolicy",
      "AmazonEKS_CNI_Policy",
      "AmazonEC2ContainerRegistryReadOnly"
    ]
  },
  "LoadBalancer_Controller_Role": {
    "purpose": "AWS Load Balancer Controller",
    "policies": [
      "Custom ALB management policy"
    ]
  }
}
```

## 🔄 Data Flow

### **Request Flow Diagram**

```
User Request Journey:

1. 👤 User Browser
   │
   ▼
2. 🌐 Internet Gateway
   │
   ▼
3. ⚖️ Application Load Balancer
   │
   ▼
4. ⚓ Kubernetes Service (ClusterIP)
   │
   ▼
5. 📱 Frontend Pod (React/Nginx)
   │
   ▼ (API calls)
6. ⚖️ Backend Load Balancer
   │
   ▼
7. 🔧 Backend Pod (FastAPI)
   │
   ▼ (Database queries)
8. 🗄️ PostgreSQL RDS
   │
   ▼ (Response)
9. 🔧 Backend Pod
   │
   ▼
10. 📱 Frontend Pod
    │
    ▼
11. 👤 User Browser

Monitoring Data Flow:

📊 Application Metrics
   │
   ▼
📈 Prometheus (scraping)
   │
   ▼
📊 Grafana (visualization)
   │
   ▼
👨‍💻 Operations Team
```

## 🚀 Deployment Architecture

### **GitOps Workflow**

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Deployment Pipeline                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. 👨‍💻 Developer                                                    │
│     │                                                               │
│     ▼ (git push)                                                    │
│  2. 📚 GitHub Repository                                             │
│     │                                                               │
│     ▼ (webhook trigger)                                             │
│  3. 🤖 GitHub Actions                                                │
│     ├── Build Docker images                                         │
│     ├── Push to ECR                                                 │
│     ├── Update Helm values                                          │
│     └── Deploy to EKS                                               │
│     │                                                               │
│     ▼                                                               │
│  4. ⚓ Kubernetes Cluster                                            │
│     ├── Pull images from ECR                                        │
│     ├── Deploy using Helm                                           │
│     ├── Health checks                                               │
│     └── Service discovery                                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### **Helm Chart Structure**

```yaml
helm-charts/
├── task-manager/                 # Backend API chart
│   ├── Chart.yaml               # Chart metadata
│   ├── values.yaml              # Default values
│   └── templates/
│       ├── deployment.yaml      # Pod deployment
│       ├── service.yaml         # Service definition
│       ├── configmap.yaml       # Configuration
│       └── ingress.yaml         # Load balancer rules
│
├── task-manager-frontend/       # Frontend chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── configmap.yaml
│
└── monitoring/                  # Monitoring stack
    ├── prometheus/
    └── grafana/
```

## 📈 Scalability Design

### **Horizontal Scaling Strategy**

```yaml
Auto-scaling Configuration:

EKS Cluster Auto-scaling:
  - Cluster Autoscaler for nodes
  - Min nodes: 1
  - Max nodes: 10
  - Target CPU: 70%
  - Target Memory: 80%

Application Auto-scaling:
  Frontend Pods:
    - Min replicas: 2
    - Max replicas: 10
    - CPU threshold: 70%
    - Memory threshold: 80%
    
  Backend Pods:
    - Min replicas: 2
    - Max replicas: 20
    - CPU threshold: 70%
    - Memory threshold: 80%
    - Custom metrics: requests/second

Database Scaling:
  - RDS Multi-AZ for high availability
  - Read replicas for read-heavy workloads
  - Connection pooling
  - Query optimization
```

### **Performance Characteristics**

```
Expected Performance:
├── Frontend Response Time: < 200ms
├── API Response Time: < 100ms
├── Database Query Time: < 50ms
├── End-to-End Latency: < 500ms
├── Throughput: 1000+ requests/second
└── Availability: 99.9% uptime

Load Testing Results:
├── Concurrent Users: 500+
├── Peak RPS: 2000+
├── Memory Usage: < 512MB per pod
├── CPU Usage: < 50% under normal load
└── Database Connections: < 100 concurrent
```

---

<div align="center">

**🏗️ This architecture provides a robust, scalable, and secure foundation for cloud-native applications.**

Continue to **[Monitoring Guide](MONITORING.md)** to learn about observability and metrics.

</div>