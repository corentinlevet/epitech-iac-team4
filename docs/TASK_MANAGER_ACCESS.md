# 🚀 Task Manager Testing Guide

## Deployment Status
✅ **Infrastructure**: Complete (VPC, Security Groups, IAM)  
🔄 **EKS Cluster**: Creating (10-15 minutes total)  
🔄 **RDS Database**: Creating (5-10 minutes total)

---

## 🎯 Where to Test the Task Manager

### Option 1: Local Testing (Available Now)
Run this from the project root directory:
```bash
cd /Users/clevet/Documents/Code/EPITECH/delivery2025-2026/IaC
docker-compose up -d
```

**Access URLs:**
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health
- **Task Manager API**: http://localhost:8000

### Option 2: AWS Production (After Deployment Completes)
Once Terraform completes, you'll have:
- **Cluster Name**: `student-team4-iac-dev-cluster`
- **API URL**: `https://api-dev.student-team4.local` (requires Helm deployment)
- **Grafana**: `https://grafana-dev.student-team4.local`

---

## 🛠️ Complete Setup Steps for AWS

### 1. Connect to EKS Cluster
```bash
aws eks update-kubeconfig --region us-east-1 --name student-team4-iac-dev-cluster
```

### 2. Deploy Applications with Helm
```bash
cd helm/charts
helm install task-manager ./task-manager --values ./task-manager/values.yaml
helm install monitoring ./monitoring --values ./monitoring/values.yaml
```

### 3. Verify Deployments
```bash
kubectl get pods -n default
kubectl get services -n default
```

---

## 🔍 API Testing Examples

### Create a Task
```bash
curl -X POST "http://localhost:8000/tasks/" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Task",
    "description": "This is a test task",
    "completed": false
  }'
```

### Get All Tasks
```bash
curl -X GET "http://localhost:8000/tasks/"
```

### Get Specific Task
```bash
curl -X GET "http://localhost:8000/tasks/1"
```

### Update Task
```bash
curl -X PUT "http://localhost:8000/tasks/1" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Task",
    "description": "Updated description",
    "completed": true
  }'
```

### Delete Task
```bash
curl -X DELETE "http://localhost:8000/tasks/1"
```

---

## 📊 Monitoring & Health

### Health Endpoints
- **API Health**: http://localhost:8000/health
- **Database Health**: http://localhost:8000/health/db
- **Metrics**: http://localhost:8000/metrics (Prometheus format)

### Swagger UI Features
Visit http://localhost:8000/docs for:
- Interactive API testing
- Request/response examples
- Schema documentation
- Authentication testing

---

## 🐳 Docker Compose Services

The local setup includes:
- **PostgreSQL 15.14**: Database server on port 5432
- **Task Manager API**: FastAPI application on port 8000
- **Network**: Isolated bridge network for secure communication

### Local Database Access
```bash
# Connect to PostgreSQL directly
docker exec -it taskmanager-db psql -U taskmanager_user -d taskmanager

# View logs
docker-compose logs task-manager
docker-compose logs postgres
```

---

## 🔧 Troubleshooting

### Local Environment
```bash
# Restart services
docker-compose down && docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### AWS Environment
```bash
# Check cluster status
kubectl cluster-info

# Check pod logs
kubectl logs -f deployment/task-manager

# Check services
kubectl get svc -o wide
```

---

## 📈 Expected Response Times
- Local: Immediate (< 100ms)
- AWS EKS: Low latency (< 500ms within region)
- Database queries: Very fast with proper indexing

**Start with local testing for immediate validation, then move to AWS for production-scale testing!**