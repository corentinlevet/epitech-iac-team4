# 🚨 Troubleshooting Guide

This guide provides comprehensive solutions for common issues you may encounter when deploying and operating the cloud-native task manager application.

## 📋 Table of Contents

- [🎯 Quick Diagnostic Commands](#-quick-diagnostic-commands)
- [🏗️ Infrastructure Issues](#️-infrastructure-issues)
- [⚓ Kubernetes Issues](#-kubernetes-issues)
- [🐳 Application Issues](#-application-issues)
- [📊 Monitoring Issues](#-monitoring-issues)
- [🔐 Security Issues](#-security-issues)
- [🌐 Network Issues](#-network-issues)
- [📞 Getting Help](#-getting-help)

## 🎯 Quick Diagnostic Commands

### **Emergency Diagnostic Script**

```bash
#!/bin/bash
# emergency-diagnostics.sh
echo "🚨 Emergency Diagnostics Starting..."

echo "=== CLUSTER STATUS ==="
kubectl cluster-info
kubectl get nodes
echo ""

echo "=== POD STATUS ==="
kubectl get pods --all-namespaces | grep -v Running
echo ""

echo "=== RECENT EVENTS ==="
kubectl get events --sort-by='.lastTimestamp' | tail -10
echo ""

echo "=== RESOURCE USAGE ==="
kubectl top nodes 2>/dev/null || echo "Metrics server not available"
kubectl top pods --all-namespaces 2>/dev/null | head -10
echo ""

echo "=== SERVICE STATUS ==="
kubectl get svc --all-namespaces | grep LoadBalancer
echo ""

echo "=== STORAGE STATUS ==="
kubectl get pv
kubectl get pvc --all-namespaces
echo ""

echo "🔍 Emergency diagnostics completed!"
```

### **Application Health Check**

```bash
#!/bin/bash
# health-check.sh

# Get service URLs
FRONTEND_URL=$(kubectl get svc task-manager-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
BACKEND_URL=$(kubectl get svc task-manager -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
GRAFANA_URL=$(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

echo "🔍 Testing Application Health..."

# Test frontend
if [ ! -z "$FRONTEND_URL" ]; then
    if curl -f -s "http://${FRONTEND_URL}" > /dev/null; then
        echo "✅ Frontend: http://${FRONTEND_URL} - HEALTHY"
    else
        echo "❌ Frontend: http://${FRONTEND_URL} - DOWN"
    fi
else
    echo "⚠️ Frontend: No LoadBalancer IP found"
fi

# Test backend
if [ ! -z "$BACKEND_URL" ]; then
    if curl -f -s "http://${BACKEND_URL}/health" > /dev/null; then
        echo "✅ Backend: http://${BACKEND_URL} - HEALTHY"
    else
        echo "❌ Backend: http://${BACKEND_URL} - DOWN"
    fi
else
    echo "⚠️ Backend: No LoadBalancer IP found"
fi

# Test monitoring
if [ ! -z "$GRAFANA_URL" ]; then
    if curl -f -s "http://${GRAFANA_URL}" > /dev/null; then
        echo "✅ Grafana: http://${GRAFANA_URL} - HEALTHY"
    else
        echo "❌ Grafana: http://${GRAFANA_URL} - DOWN"
    fi
else
    echo "⚠️ Grafana: No LoadBalancer IP found"
fi
```

## 🏗️ Infrastructure Issues

### **Terraform Deployment Failures**

#### **Problem**: `Error: creating EKS Cluster: AccessDenied`

**Cause**: Insufficient AWS permissions

**Solution**:
```bash
# 1. Verify AWS credentials
aws sts get-caller-identity

# 2. Check required permissions
aws iam list-attached-user-policies --user-name $(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)

# 3. Ensure you have these policies:
# - AmazonEKSClusterPolicy
# - AmazonEKSWorkerNodePolicy
# - AmazonEC2FullAccess
# - AmazonVPCFullAccess
# - IAMFullAccess

# 4. Re-run terraform
cd terraform/environments
terraform apply -var-file="dev.tfvars"
```

#### **Problem**: `Error: timeout while waiting for state to become 'ACTIVE'`

**Cause**: EKS cluster creation taking longer than expected

**Solution**:
```bash
# 1. Check cluster status in AWS Console
aws eks describe-cluster --name student-team4-iac-dev-cluster

# 2. Increase timeout in Terraform
# Edit terraform/modules/eks/main.tf:
# resource "aws_eks_cluster" "main" {
#   ...
#   timeouts {
#     create = "30m"  # Increase from 20m
#     delete = "15m"
#   }
# }

# 3. Re-apply
terraform apply -var-file="dev.tfvars"
```

#### **Problem**: `Error: creating RDS DB Instance: InvalidVpcPeeringConnectionId.NotFound`

**Cause**: VPC not properly created before RDS

**Solution**:
```bash
# 1. Check VPC status
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=student-team4-iac-dev-vpc"

# 2. Force dependency in Terraform
# Edit terraform/environments/main.tf to ensure proper depends_on

# 3. Destroy and recreate if needed
terraform destroy -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

### **AWS Resource Limits**

#### **Problem**: `Error: creating EC2 Instance: InstanceLimitExceeded`

**Cause**: AWS account limits reached

**Solution**:
```bash
# 1. Check current usage
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table

# 2. Check service quotas
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A

# 3. Request quota increase or clean up unused resources
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0

# 4. Use smaller instance types
# Edit terraform/modules/eks/variables.tf:
# default = "t3.micro"  # Instead of t3.small
```

## ⚓ Kubernetes Issues

### **Pod Issues**

#### **Problem**: Pods stuck in `Pending` state

**Diagnosis**:
```bash
# Check pod details
kubectl describe pod <pod-name>

# Check node resources
kubectl top nodes
kubectl describe nodes
```

**Solutions**:

**Insufficient Resources**:
```bash
# Scale cluster nodes
aws eks update-nodegroup-config \
  --cluster-name student-team4-iac-dev-cluster \
  --nodegroup-name student-team4-iac-dev-nodes \
  --scaling-config desiredSize=4

# Reduce resource requests
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container>","resources":{"requests":{"memory":"128Mi","cpu":"100m"}}}]}}}}'
```

**Image Pull Errors**:
```bash
# Check image exists in ECR
aws ecr describe-images --repository-name task-manager

# Update image pull secrets
kubectl create secret docker-registry ecr-secret \
  --docker-server=<account-id>.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password)

# Patch deployment to use secret
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ecr-secret"}]}}}}'
```

#### **Problem**: Pods crash looping (CrashLoopBackOff)

**Diagnosis**:
```bash
# Check pod logs
kubectl logs <pod-name> --previous

# Check recent events
kubectl get events --field-selector involvedObject.name=<pod-name>
```

**Solutions**:

**Application Error**:
```bash
# Fix application code and rebuild
docker build -t <account-id>.dkr.ecr.us-east-1.amazonaws.com/task-manager:v4 .
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/task-manager:v4

# Update deployment
kubectl set image deployment/task-manager task-manager=<account-id>.dkr.ecr.us-east-1.amazonaws.com/task-manager:v4
```

**Configuration Error**:
```bash
# Check ConfigMap
kubectl get configmap <configmap-name> -o yaml

# Update configuration
kubectl create configmap <configmap-name> --from-file=config.yaml --dry-run=client -o yaml | kubectl apply -f -

# Restart deployment
kubectl rollout restart deployment/<deployment-name>
```

### **Service Issues**

#### **Problem**: LoadBalancer not getting external IP

**Diagnosis**:
```bash
# Check service status
kubectl get svc <service-name> -o wide

# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer
kubectl logs deployment/aws-load-balancer-controller -n kube-system
```

**Solutions**:

**Load Balancer Controller Missing**:
```bash
# Install AWS Load Balancer Controller
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json

aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json

# Apply YAML manifest
kubectl apply -f https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.7.0/v2_7_0_full.yaml
```

**IAM Permission Issues**:
```bash
# Check service account annotations
kubectl get serviceaccount aws-load-balancer-controller -n kube-system -o yaml

# Annotate service account with correct role
kubectl annotate serviceaccount aws-load-balancer-controller -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::<account-id>:role/AmazonEKSLoadBalancerControllerRole
```

#### **Problem**: Service endpoints not ready

**Diagnosis**:
```bash
# Check endpoints
kubectl get endpoints <service-name>

# Check pod labels and selectors
kubectl get pods --show-labels
kubectl describe svc <service-name>
```

**Solution**:
```bash
# Fix label selectors
kubectl patch service <service-name> -p '{"spec":{"selector":{"app":"<correct-label>"}}}'

# Or recreate service with correct selector
kubectl delete svc <service-name>
kubectl expose deployment <deployment-name> --port=80 --target-port=8000 --type=LoadBalancer
```

## 🐳 Application Issues

### **Database Connection Issues**

#### **Problem**: Application can't connect to database

**Diagnosis**:
```bash
# Check database pod
kubectl get pod postgres-pod -o wide

# Test connection from application pod
kubectl exec -it <app-pod> -- nc -zv postgres-service 5432

# Check database logs
kubectl logs postgres-pod
```

**Solutions**:

**Database Not Ready**:
```bash
# Wait for database to be ready
kubectl wait --for=condition=ready pod/postgres-pod --timeout=300s

# Check database health
kubectl exec -it postgres-pod -- pg_isready -U postgres
```

**Connection String Issues**:
```bash
# Check environment variables
kubectl exec -it <app-pod> -- env | grep DATABASE

# Update ConfigMap
kubectl create configmap app-config \
  --from-literal=DATABASE_URL="postgresql://postgres:password@postgres-service:5432/taskmanager" \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart application
kubectl rollout restart deployment/<app-deployment>
```

### **Frontend Issues**

#### **Problem**: Frontend shows "API connection failed"

**Diagnosis**:
```bash
# Check backend service URL
kubectl get svc task-manager -o wide

# Test API from frontend pod
kubectl exec -it <frontend-pod> -- curl http://task-manager.default.svc.cluster.local:8000/health
```

**Solutions**:

**Wrong API URL**:
```bash
# Update frontend configuration
# Edit applications/task-manager-frontend/src/App.js
# Set correct API_BASE_URL

# Rebuild and redeploy
docker build -t <account-id>.dkr.ecr.us-east-1.amazonaws.com/task-manager-frontend:latest .
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/task-manager-frontend:latest

kubectl rollout restart deployment/task-manager-frontend
```

**CORS Issues**:
```bash
# Update backend CORS settings
# Edit applications/task-manager/main.py
# Add frontend URL to allowed origins

# Redeploy backend
kubectl rollout restart deployment/task-manager
```

## 📊 Monitoring Issues

### **Prometheus Issues**

#### **Problem**: Prometheus not scraping metrics

**Diagnosis**:
```bash
# Check Prometheus targets
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
# Open http://localhost:9090/targets

# Check pod annotations
kubectl get pods --show-labels | grep prometheus.io
```

**Solutions**:

**Missing Annotations**:
```bash
# Add Prometheus annotations to pods
kubectl annotate pod <pod-name> prometheus.io/scrape=true
kubectl annotate pod <pod-name> prometheus.io/port=8000
kubectl annotate pod <pod-name> prometheus.io/path=/metrics
```

**Service Discovery Issues**:
```bash
# Check Prometheus ConfigMap
kubectl get configmap prometheus-config -n monitoring -o yaml

# Update scrape configuration
kubectl create configmap prometheus-config \
  --from-file=prometheus.yml \
  --dry-run=client -o yaml | kubectl apply -f - -n monitoring

# Restart Prometheus
kubectl rollout restart deployment/prometheus -n monitoring
```

### **Grafana Issues**

#### **Problem**: Grafana dashboards show no data

**Diagnosis**:
```bash
# Check Grafana data source
kubectl port-forward svc/grafana 3000:3000 -n monitoring
# Open http://localhost:3000/datasources

# Test Prometheus connectivity
kubectl exec -it grafana-pod -n monitoring -- curl http://prometheus.monitoring.svc.cluster.local:9090/api/v1/query?query=up
```

**Solutions**:

**Data Source Configuration**:
```bash
# Update Grafana data source URL
# Should be: http://prometheus.monitoring.svc.cluster.local:9090

# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring
```

**Dashboard Import Issues**:
```bash
# Re-import dashboards
kubectl create configmap grafana-dashboards \
  --from-file=dashboards/ \
  --dry-run=client -o yaml | kubectl apply -f - -n monitoring
```

## 🔐 Security Issues

### **RBAC Issues**

#### **Problem**: `User cannot list pods: Forbidden`

**Diagnosis**:
```bash
# Check current user permissions
kubectl auth can-i --list

# Check role bindings
kubectl get clusterrolebindings | grep <username>
```

**Solution**:
```bash
# Create appropriate role binding
kubectl create clusterrolebinding <username>-binding \
  --clusterrole=view \
  --user=<username>

# Or for admin access
kubectl create clusterrolebinding <username>-admin \
  --clusterrole=cluster-admin \
  --user=<username>
```

### **Image Pull Issues**

#### **Problem**: `ErrImagePull` or `ImagePullBackOff`

**Diagnosis**:
```bash
# Check image exists
aws ecr describe-images --repository-name task-manager

# Test ECR authentication
aws ecr get-login-password | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

**Solution**:
```bash
# Update ECR authentication
kubectl create secret docker-registry ecr-secret \
  --docker-server=<account-id>.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password) \
  --dry-run=client -o yaml | kubectl apply -f -

# Add to deployment
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ecr-secret"}]}}}}'
```

## 🌐 Network Issues

### **DNS Resolution Issues**

#### **Problem**: Pods can't resolve service names

**Diagnosis**:
```bash
# Test DNS from pod
kubectl exec -it <pod-name> -- nslookup kubernetes.default

# Check CoreDNS pods
kubectl get pods -n kube-system | grep coredns
kubectl logs -n kube-system deployment/coredns
```

**Solution**:
```bash
# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system

# Check DNS configuration
kubectl get configmap coredns -n kube-system -o yaml
```

### **Load Balancer Issues**

#### **Problem**: Cannot access application externally

**Diagnosis**:
```bash
# Check security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*eks*"

# Check target groups
aws elbv2 describe-target-groups

# Check load balancer health
aws elbv2 describe-load-balancers
```

**Solution**:
```bash
# Update security group rules
aws ec2 authorize-security-group-ingress \
  --group-id sg-12345678 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Check target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## 📞 Getting Help

### **Log Collection for Support**

```bash
#!/bin/bash
# collect-logs.sh

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="logs_${TIMESTAMP}"
mkdir -p "${LOG_DIR}"

echo "🔍 Collecting logs for support..."

# Cluster info
kubectl cluster-info > "${LOG_DIR}/cluster-info.txt"
kubectl get nodes -o wide > "${LOG_DIR}/nodes.txt"

# Pod information
kubectl get pods --all-namespaces -o wide > "${LOG_DIR}/pods.txt"
kubectl get events --all-namespaces --sort-by='.lastTimestamp' > "${LOG_DIR}/events.txt"

# Application logs
kubectl logs deployment/task-manager > "${LOG_DIR}/task-manager.log"
kubectl logs deployment/task-manager-frontend > "${LOG_DIR}/frontend.log"
kubectl logs deployment/prometheus -n monitoring > "${LOG_DIR}/prometheus.log"

# Configuration
kubectl get configmaps --all-namespaces -o yaml > "${LOG_DIR}/configmaps.yaml"
kubectl get services --all-namespaces -o yaml > "${LOG_DIR}/services.yaml"

# Create archive
tar -czf "support-logs-${TIMESTAMP}.tar.gz" "${LOG_DIR}"
echo "✅ Logs collected in: support-logs-${TIMESTAMP}.tar.gz"
```

### **Common Support Resources**

- **📚 Kubernetes Documentation**: https://kubernetes.io/docs/
- **☁️ AWS EKS Documentation**: https://docs.aws.amazon.com/eks/
- **🏗️ Terraform Documentation**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **📊 Prometheus Documentation**: https://prometheus.io/docs/
- **📈 Grafana Documentation**: https://grafana.com/docs/

### **Emergency Rollback Procedure**

```bash
#!/bin/bash
# emergency-rollback.sh

echo "🚨 Starting emergency rollback..."

# Rollback applications
kubectl rollout undo deployment/task-manager
kubectl rollout undo deployment/task-manager-frontend

# Check rollback status
kubectl rollout status deployment/task-manager
kubectl rollout status deployment/task-manager-frontend

# Rollback infrastructure if needed
cd terraform/environments
terraform plan -var-file="dev.tfvars"
# terraform apply -var-file="dev.tfvars" -target=resource_to_rollback

echo "✅ Emergency rollback completed!"
```

---

<div align="center">

**🚨 When in doubt, check logs first, then reach out for help with detailed error messages.**

Return to **[README](../README.md)** for the main documentation.

</div>