# 🔧 Operations Guide

This guide provides comprehensive information for day-to-day operations, maintenance, and management of the cloud-native task manager infrastructure.

## 📋 Table of Contents

- [🎯 Operations Overview](#-operations-overview)
- [🚀 Daily Operations](#-daily-operations)
- [📊 Health Monitoring](#-health-monitoring)
- [🔄 Updates and Maintenance](#-updates-and-maintenance)
- [📈 Scaling Operations](#-scaling-operations)
- [🛡️ Security Operations](#️-security-operations)
- [💾 Backup and Recovery](#-backup-and-recovery)
- [🚨 Incident Response](#-incident-response)

## 🎯 Operations Overview

### **Operational Responsibilities**

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Operations Framework                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  🔍 Monitoring & Alerting                                          │
│  ├── System health monitoring                                      │
│  ├── Application performance tracking                              │
│  ├── Resource utilization analysis                                 │
│  └── Proactive issue detection                                     │
│                                                                     │
│  🔄 Maintenance & Updates                                           │
│  ├── Security patch management                                     │
│  ├── Application version updates                                   │
│  ├── Infrastructure maintenance                                    │
│  └── Configuration management                                      │
│                                                                     │
│  📈 Capacity Management                                             │
│  ├── Resource planning and allocation                              │
│  ├── Auto-scaling configuration                                    │
│  ├── Performance optimization                                      │
│  └── Cost optimization                                             │
│                                                                     │
│  🛡️ Security & Compliance                                          │
│  ├── Access control management                                     │
│  ├── Security monitoring                                           │
│  ├── Vulnerability management                                      │
│  └── Compliance reporting                                          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### **Operational Tools**

- **🔧 kubectl**: Kubernetes cluster management
- **📊 Grafana**: Performance monitoring and dashboards
- **⚓ Helm**: Application deployment and management
- **☁️ AWS CLI**: Cloud infrastructure management
- **🏗️ Terraform**: Infrastructure as Code operations
- **📈 Prometheus**: Metrics collection and alerting

## 🚀 Daily Operations

### **Morning Health Check**

Perform these checks every morning to ensure system health:

```bash
#!/bin/bash
# daily-health-check.sh

echo "🌅 Starting Daily Health Check..."

# 1. Check cluster status
echo "📋 Checking EKS cluster status..."
kubectl get nodes
echo ""

# 2. Check pod health
echo "🔍 Checking pod status..."
kubectl get pods --all-namespaces | grep -v Running
echo ""

# 3. Check service endpoints
echo "🌐 Checking service endpoints..."
kubectl get svc --all-namespaces | grep LoadBalancer
echo ""

# 4. Check resource usage
echo "📊 Checking resource usage..."
kubectl top nodes
kubectl top pods --all-namespaces --sort-by=memory
echo ""

# 5. Check recent events
echo "📰 Checking recent events..."
kubectl get events --sort-by='.lastTimestamp' | tail -10
echo ""

# 6. Application health checks
echo "🔍 Testing application endpoints..."
FRONTEND_URL=$(kubectl get svc task-manager-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
BACKEND_URL=$(kubectl get svc task-manager -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl -f "http://${FRONTEND_URL}" > /dev/null && echo "✅ Frontend is healthy" || echo "❌ Frontend is down"
curl -f "http://${BACKEND_URL}/health" > /dev/null && echo "✅ Backend is healthy" || echo "❌ Backend is down"

echo "✅ Daily health check completed!"
```

### **Application Status Commands**

```bash
# Quick status overview
kubectl get all --all-namespaces

# Detailed pod information
kubectl describe pod <pod-name>

# Pod logs (last 100 lines)
kubectl logs <pod-name> --tail=100

# Follow logs in real-time
kubectl logs -f <pod-name>

# Check resource usage
kubectl top pods
kubectl top nodes

# Network connectivity test
kubectl exec -it <pod-name> -- wget -O- http://service-name:port/health
```

## 📊 Health Monitoring

### **Key Performance Indicators (KPIs)**

Monitor these metrics daily:

```yaml
Application KPIs:
  ├── Response Time: < 200ms (95th percentile)
  ├── Error Rate: < 1%
  ├── Throughput: Current requests/second
  ├── Availability: > 99.9%
  └── User Satisfaction: Response times and error rates

Infrastructure KPIs:
  ├── CPU Usage: < 70% average
  ├── Memory Usage: < 80% average
  ├── Disk Usage: < 85%
  ├── Network Latency: < 10ms
  └── Pod Restart Rate: < 1 per day

Business KPIs:
  ├── Tasks Created: Daily count
  ├── Active Users: Concurrent users
  ├── API Usage: Requests by endpoint
  └── Database Performance: Query times
```

### **Health Check Endpoints**

```bash
# Application health endpoints
curl http://<backend-url>/health
curl http://<backend-url>/metrics
curl http://<backend-url>/docs

# Infrastructure health
kubectl get componentstatuses
kubectl cluster-info

# Database health
kubectl exec -it postgres-pod -- pg_isready
```

### **Grafana Dashboard Monitoring**

Access Grafana dashboards daily to review:

1. **Application Overview Dashboard**:
   - Request rate trends
   - Response time distribution
   - Error rate analysis
   - Task creation patterns

2. **Infrastructure Dashboard**:
   - Node resource utilization
   - Pod memory and CPU usage
   - Network traffic patterns
   - Storage usage trends

3. **Database Dashboard**:
   - Connection pool status
   - Query performance metrics
   - Database size growth
   - Slow query analysis

## 🔄 Updates and Maintenance

### **Application Updates**

#### **Rolling Updates**

```bash
# Update application image
kubectl set image deployment/task-manager task-manager=<ecr-url>/task-manager:v4

# Monitor rollout status
kubectl rollout status deployment/task-manager

# Check rollout history
kubectl rollout history deployment/task-manager

# Rollback if needed
kubectl rollout undo deployment/task-manager
```

#### **Helm Chart Updates**

```bash
# Update Helm chart values
helm upgrade task-manager helm-charts/task-manager/ \
  --set image.tag=v4 \
  --set resources.requests.memory=256Mi

# Verify deployment
helm status task-manager
helm get values task-manager
```

### **Infrastructure Updates**

#### **EKS Cluster Updates**

```bash
# Check current cluster version
aws eks describe-cluster --name student-team4-iac-dev-cluster --query 'cluster.version'

# Update cluster (requires planning)
aws eks update-cluster-version \
  --name student-team4-iac-dev-cluster \
  --kubernetes-version 1.29

# Update node groups
aws eks update-nodegroup-version \
  --cluster-name student-team4-iac-dev-cluster \
  --nodegroup-name student-team4-iac-dev-nodes
```

#### **Terraform Updates**

```bash
# Navigate to terraform directory
cd terraform/environments

# Check for configuration drift
terraform plan -var-file="dev.tfvars"

# Apply infrastructure updates
terraform apply -var-file="dev.tfvars"

# Validate changes
terraform show
```

### **Security Updates**

```bash
# Update container images
docker pull alpine:latest
docker pull nginx:latest
docker pull postgres:15

# Scan for vulnerabilities
docker scan <image-name>

# Update Kubernetes
kubectl apply -f https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.7.0/v2_7_0_full.yaml
```

## 📈 Scaling Operations

### **Horizontal Pod Autoscaling (HPA)**

```yaml
# hpa-config.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: task-manager-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: task-manager
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

```bash
# Apply HPA configuration
kubectl apply -f hpa-config.yaml

# Monitor autoscaling
kubectl get hpa
kubectl describe hpa task-manager-hpa

# Test scaling
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
# In the pod: while true; do wget -q -O- http://task-manager.default.svc.cluster.local:8000/health; done
```

### **Cluster Autoscaling**

```bash
# Check cluster autoscaler status
kubectl get pods -n kube-system | grep cluster-autoscaler

# Monitor scaling events
kubectl get events --field-selector reason=TriggeredScaleUp
kubectl get events --field-selector reason=ScaleDown

# View autoscaler logs
kubectl logs deployment/cluster-autoscaler -n kube-system
```

### **Manual Scaling**

```bash
# Scale deployment replicas
kubectl scale deployment task-manager --replicas=5

# Scale node group (AWS)
aws eks update-nodegroup-config \
  --cluster-name student-team4-iac-dev-cluster \
  --nodegroup-name student-team4-iac-dev-nodes \
  --scaling-config minSize=2,maxSize=5,desiredSize=4
```

## 🛡️ Security Operations

### **Access Management**

```bash
# Review RBAC permissions
kubectl get clusterrolebindings
kubectl get rolebindings --all-namespaces

# Check service accounts
kubectl get serviceaccounts --all-namespaces

# Audit user access
kubectl auth can-i --list --as=user@example.com
```

### **Security Monitoring**

```bash
# Check for security events
kubectl get events --field-selector type=Warning

# Review pod security contexts
kubectl get pods -o json | jq '.items[].spec.securityContext'

# Check network policies
kubectl get networkpolicies --all-namespaces

# Scan for vulnerabilities
kubectl exec -it <pod-name> -- trivy image <image-name>
```

### **Secret Management**

```bash
# List all secrets
kubectl get secrets --all-namespaces

# Rotate database password
kubectl create secret generic postgres-secret \
  --from-literal=password=$(openssl rand -base64 32) \
  --dry-run=client -o yaml | kubectl apply -f -

# Update application to use new secret
kubectl rollout restart deployment/task-manager
```

## 💾 Backup and Recovery

### **Database Backups**

```bash
# Create database backup
kubectl exec -it postgres-pod -- pg_dump -U postgres taskmanager > backup-$(date +%Y%m%d).sql

# Automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="taskmanager_backup_${DATE}.sql"

kubectl exec postgres-pod -- pg_dump -U postgres taskmanager > "/backups/${BACKUP_FILE}"
aws s3 cp "/backups/${BACKUP_FILE}" "s3://your-backup-bucket/database/"

# Retention cleanup (keep last 30 days)
find /backups -name "taskmanager_backup_*.sql" -mtime +30 -delete
```

### **Configuration Backups**

```bash
# Backup Kubernetes configurations
kubectl get all --all-namespaces -o yaml > k8s-backup-$(date +%Y%m%d).yaml

# Backup Helm releases
helm list --all-namespaces -o yaml > helm-releases-$(date +%Y%m%d).yaml

# Backup ConfigMaps and Secrets
kubectl get configmaps --all-namespaces -o yaml > configmaps-backup-$(date +%Y%m%d).yaml
kubectl get secrets --all-namespaces -o yaml > secrets-backup-$(date +%Y%m%d).yaml
```

### **Disaster Recovery**

```bash
# Infrastructure recovery
cd terraform/environments
terraform apply -var-file="dev.tfvars" -auto-approve

# Application recovery
helm install task-manager helm-charts/task-manager/
helm install task-manager-frontend helm-charts/task-manager-frontend/

# Database recovery
kubectl exec -it postgres-pod -- psql -U postgres -d taskmanager < backup-20240115.sql

# Verify recovery
kubectl get pods
curl http://<frontend-url>/health
```

## 🚨 Incident Response

### **Incident Response Procedure**

1. **🚨 Detection**:
   - Monitor alerts from Grafana/Prometheus
   - User reports or monitoring systems
   - Automated health checks

2. **🔍 Assessment**:
   ```bash
   # Quick assessment commands
   kubectl get pods --all-namespaces | grep -v Running
   kubectl get events --sort-by='.lastTimestamp' | tail -20
   kubectl top nodes
   ```

3. **🛠️ Mitigation**:
   ```bash
   # Common mitigation steps
   kubectl rollout restart deployment/<deployment-name>
   kubectl scale deployment/<deployment-name> --replicas=3
   kubectl delete pod <problematic-pod>
   ```

4. **📊 Investigation**:
   ```bash
   # Detailed investigation
   kubectl describe pod <pod-name>
   kubectl logs <pod-name> --previous
   kubectl exec -it <pod-name> -- /bin/sh
   ```

5. **🔧 Resolution**:
   - Apply fixes through Helm or kubectl
   - Deploy updated applications
   - Update infrastructure if needed

6. **📝 Post-Incident**:
   - Document lessons learned
   - Update monitoring and alerting
   - Improve automation and procedures

### **Common Incident Scenarios**

#### **High CPU Usage**

```bash
# Identify high CPU pods
kubectl top pods --sort-by=cpu

# Check resource limits
kubectl describe pod <pod-name> | grep -A 5 "Limits"

# Scale horizontally
kubectl scale deployment <deployment-name> --replicas=5

# Update resource limits
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"limits":{"cpu":"500m"}}}]}}}}'
```

#### **Database Connection Issues**

```bash
# Check database pod status
kubectl get pod postgres-pod -o wide

# Check connection pool
kubectl exec -it postgres-pod -- psql -U postgres -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';"

# Restart database connections
kubectl rollout restart deployment/task-manager

# Scale database resources
kubectl patch statefulset postgres -p '{"spec":{"template":{"spec":{"containers":[{"name":"postgres","resources":{"limits":{"memory":"1Gi"}}}]}}}}'
```

#### **Load Balancer Issues**

```bash
# Check load balancer status
kubectl get svc | grep LoadBalancer

# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer

# Restart load balancer controller
kubectl rollout restart deployment/aws-load-balancer-controller -n kube-system

# Check target groups in AWS Console
aws elbv2 describe-target-groups
```

### **Emergency Contacts**

```yaml
Escalation Matrix:
  Level 1 - On-Call Engineer:
    - Initial response (0-15 minutes)
    - Basic troubleshooting
    - Status page updates
    
  Level 2 - Senior Engineer:
    - Complex issues (15-60 minutes)
    - Architecture decisions
    - Vendor escalation
    
  Level 3 - Engineering Manager:
    - Critical incidents (60+ minutes)
    - Customer communication
    - Business decisions
```

---

<div align="center">

**🔧 Effective operations ensure reliable, secure, and performant applications.**

Continue to **[Security Guide](SECURITY.md)** to learn about security best practices.

</div>