# 📊 Monitoring Guide

This guide provides comprehensive information about the monitoring and observability stack implemented in our cloud-native task manager application.

## 📋 Table of Contents

- [🎯 Monitoring Overview](#-monitoring-overview)
- [📊 Prometheus Configuration](#-prometheus-configuration)
- [📈 Grafana Dashboards](#-grafana-dashboards)
- [🚨 Alerting](#-alerting)
- [📏 Custom Metrics](#-custom-metrics)
- [🔍 Troubleshooting](#-troubleshooting)
- [📚 Best Practices](#-best-practices)

## 🎯 Monitoring Overview

### **Observability Stack Components**

Our monitoring solution provides comprehensive observability across all layers of the application:

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Observability Architecture                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  📊 Metrics Collection                                              │
│  ├── Prometheus Server (scraping and storage)                      │
│  ├── Custom application metrics                                    │
│  ├── Kubernetes cluster metrics                                    │
│  └── Infrastructure metrics                                        │
│                                                                     │
│  📈 Visualization                                                   │
│  ├── Grafana dashboards                                           │
│  ├── Real-time monitoring                                         │
│  ├── Historical analysis                                          │
│  └── Custom alerting                                              │
│                                                                     │
│  🚨 Alerting                                                       │
│  ├── Prometheus Alertmanager                                      │
│  ├── Multi-channel notifications                                  │
│  ├── Alert routing and grouping                                   │
│  └── Escalation policies                                          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### **Key Features**

- ✅ **Real-time Metrics**: Live monitoring of application and infrastructure
- ✅ **Custom Dashboards**: Purpose-built visualizations for different teams
- ✅ **Intelligent Alerting**: Smart alerts with context and actionable information
- ✅ **Historical Data**: Long-term trend analysis and capacity planning
- ✅ **Multi-dimensional Metrics**: Rich labeling for detailed analysis
- ✅ **High Availability**: Resilient monitoring infrastructure

## 📊 Prometheus Configuration

### **Prometheus Server Setup**

```yaml
# kubernetes-manifests/monitoring/final-prometheus.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    scrape_configs:
      # Application metrics
      - job_name: 'task-manager-api'
        static_configs:
          - targets: ['task-manager.default.svc.cluster.local:8000']
        metrics_path: /metrics
        scrape_interval: 10s
        
      # Kubernetes metrics
      - job_name: 'kubernetes-nodes'
        kubernetes_sd_configs:
          - role: node
        relabel_configs:
          - source_labels: [__address__]
            target_label: __address__
            regex: (.+):(.+)
            replacement: ${1}:9100
            
      # Pod metrics
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
```

### **Service Discovery**

Prometheus automatically discovers monitoring targets using Kubernetes service discovery:

```yaml
Service Discovery Configuration:
  ├── Kubernetes Nodes: Node-level metrics (CPU, memory, disk)
  ├── Kubernetes Pods: Pod-level metrics (containers, resources)
  ├── Services: Service-level metrics (endpoints, health)
  └── Custom Applications: Application-specific metrics
```

### **Data Retention**

```yaml
Storage Configuration:
  ├── Retention Period: 15 days
  ├── Storage Size: 10GB persistent volume
  ├── Data Compression: Enabled
  └── Backup Strategy: Persistent volume snapshots
```

## 📈 Grafana Dashboards

### **Access Grafana**

1. **Get Grafana URL**:
   ```bash
   kubectl get svc grafana -n monitoring
   # Note the EXTERNAL-IP
   ```

2. **Login**:
   - **URL**: `http://<grafana-external-ip>`
   - **Username**: `admin`
   - **Password**: `admin` (change on first login)

### **Available Dashboards**

#### **🎯 Application Overview Dashboard**

```json
{
  "dashboard": "Application Overview",
  "panels": [
    {
      "title": "HTTP Request Rate",
      "type": "graph",
      "query": "rate(http_requests_total[5m])",
      "description": "Requests per second by endpoint"
    },
    {
      "title": "Response Time",
      "type": "graph", 
      "query": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
      "description": "95th percentile response time"
    },
    {
      "title": "Error Rate",
      "type": "stat",
      "query": "rate(http_requests_total{status=~\"5..\"}[5m]) / rate(http_requests_total[5m]) * 100",
      "description": "Percentage of 5xx errors"
    },
    {
      "title": "Active Tasks",
      "type": "stat",
      "query": "tasks_total",
      "description": "Total tasks by status"
    }
  ]
}
```

#### **🏗️ Infrastructure Dashboard**

```json
{
  "dashboard": "Infrastructure Monitoring", 
  "panels": [
    {
      "title": "Node CPU Usage",
      "type": "graph",
      "query": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
      "description": "CPU utilization per node"
    },
    {
      "title": "Node Memory Usage", 
      "type": "graph",
      "query": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
      "description": "Memory utilization per node"
    },
    {
      "title": "Pod Resource Usage",
      "type": "table",
      "query": "container_memory_usage_bytes{container!=\"POD\"}",
      "description": "Memory usage by pod"
    },
    {
      "title": "Network I/O",
      "type": "graph", 
      "query": "rate(container_network_receive_bytes_total[5m])",
      "description": "Network traffic by pod"
    }
  ]
}
```

#### **🗄️ Database Dashboard**

```json
{
  "dashboard": "Database Monitoring",
  "panels": [
    {
      "title": "Database Connections",
      "type": "graph",
      "query": "database_connections_active",
      "description": "Active PostgreSQL connections"
    },
    {
      "title": "Query Performance",
      "type": "graph", 
      "query": "rate(database_queries_total[5m])",
      "description": "Database queries per second"
    },
    {
      "title": "Connection Pool",
      "type": "stat",
      "query": "database_connection_pool_size",
      "description": "Connection pool utilization"
    }
  ]
}
```

### **Creating Custom Dashboards**

1. **Access Grafana**: Navigate to your Grafana instance
2. **Create Dashboard**: Click "+" → "Dashboard"
3. **Add Panel**: Click "Add panel"
4. **Configure Query**: 
   ```promql
   # Example: API response time
   histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
   
   # Example: Error rate
   rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100
   
   # Example: Task creation rate
   rate(tasks_created_total[5m])
   ```
5. **Customize Visualization**: Choose graph type, colors, thresholds
6. **Save Dashboard**: Give it a meaningful name and tags

## 🚨 Alerting

### **Alert Rules Configuration**

```yaml
# prometheus-alerts.yml
groups:
  - name: application.rules
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100 > 5
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }}% for the last 5 minutes"
          
      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High response time detected"
          description: "95th percentile response time is {{ $value }}s"
          
      - alert: DatabaseConnectionHigh
        expr: database_connections_active > 80
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High database connection usage"
          description: "Database has {{ $value }} active connections"
          
  - name: infrastructure.rules
    rules:
      - alert: NodeCPUHigh
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on node {{ $labels.instance }}"
          description: "CPU usage is {{ $value }}%"
          
      - alert: NodeMemoryHigh
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on node {{ $labels.instance }}"
          description: "Memory usage is {{ $value }}%"
          
      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[5m]) > 0
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: "Pod {{ $labels.pod }} is crash looping"
          description: "Pod has restarted {{ $value }} times in the last 5 minutes"
```

### **Alertmanager Configuration**

```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@yourcompany.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
    - match:
        severity: warning
      receiver: 'warning-alerts'

receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://127.0.0.1:5001/'
        
  - name: 'critical-alerts'
    email_configs:
      - to: 'oncall@yourcompany.com'
        subject: 'CRITICAL: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
          
  - name: 'warning-alerts'
    email_configs:
      - to: 'team@yourcompany.com'
        subject: 'WARNING: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
```

## 📏 Custom Metrics

### **Application Metrics Implementation**

Our FastAPI application exposes custom business metrics:

```python
# applications/task-manager/main.py
from prometheus_client import Counter, Histogram, Gauge, generate_latest

# Initialize metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint']
)

tasks_total = Gauge(
    'tasks_total',
    'Total number of tasks',
    ['status']
)

database_connections_active = Gauge(
    'database_connections_active',
    'Active database connections'
)

# Middleware to collect metrics
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    # Record metrics
    process_time = time.time() - start_time
    http_request_duration.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(process_time)
    
    http_requests_total.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    return response

# Metrics endpoint
@app.get("/metrics")
async def metrics():
    # Update business metrics
    async with get_db() as db:
        # Count tasks by status
        for status in ['pending', 'in_progress', 'completed']:
            count = await db.scalar(
                select(func.count(Task.id)).where(Task.status == status)
            )
            tasks_total.labels(status=status).set(count)
        
        # Update database connections
        active_connections = await db.scalar(
            text("SELECT count(*) FROM pg_stat_activity WHERE state = 'active'")
        )
        database_connections_active.set(active_connections)
    
    return Response(generate_latest(), media_type="text/plain")
```

### **Kubernetes Metrics**

Prometheus automatically collects Kubernetes metrics:

```yaml
Available Kubernetes Metrics:
  Pod Metrics:
    - container_cpu_usage_seconds_total
    - container_memory_usage_bytes
    - container_network_receive_bytes_total
    - container_network_transmit_bytes_total
    - container_fs_usage_bytes
    
  Node Metrics:
    - node_cpu_seconds_total
    - node_memory_MemTotal_bytes
    - node_memory_MemAvailable_bytes
    - node_filesystem_size_bytes
    - node_network_receive_bytes_total
    
  Cluster Metrics:
    - kube_pod_status_phase
    - kube_deployment_status_replicas
    - kube_service_info
    - kube_node_status_condition
```

## 🔍 Troubleshooting

### **Common Monitoring Issues**

#### **Issue: Prometheus not scraping metrics**

**Symptoms**:
- Missing data in Grafana
- Targets showing as "DOWN" in Prometheus

**Diagnosis**:
```bash
# Check Prometheus targets
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
# Open http://localhost:9090/targets

# Check pod labels and annotations
kubectl get pods --show-labels

# Verify service endpoints
kubectl get endpoints
```

**Solution**:
```bash
# Ensure pods have correct annotations
kubectl annotate pod <pod-name> prometheus.io/scrape=true
kubectl annotate pod <pod-name> prometheus.io/port=8000
kubectl annotate pod <pod-name> prometheus.io/path=/metrics

# Restart Prometheus
kubectl rollout restart deployment prometheus -n monitoring
```

#### **Issue: Grafana dashboards showing no data**

**Diagnosis**:
```bash
# Check Grafana logs
kubectl logs deployment/grafana -n monitoring

# Verify Prometheus data source
kubectl port-forward svc/grafana 3000:3000 -n monitoring
# Open http://localhost:3000/datasources
```

**Solution**:
1. Verify Prometheus URL in Grafana data source
2. Check network connectivity between Grafana and Prometheus
3. Validate PromQL queries in Prometheus directly

#### **Issue: High memory usage in Prometheus**

**Diagnosis**:
```bash
# Check Prometheus resource usage
kubectl top pod prometheus-xxx -n monitoring

# Check metrics cardinality
curl http://<prometheus-url>:9090/api/v1/label/__name__/values | jq '.data | length'
```

**Solution**:
```yaml
# Adjust retention and storage
spec:
  retention: 7d  # Reduce from 15d
  resources:
    requests:
      memory: 2Gi
    limits:
      memory: 4Gi
```

### **Alert Debugging**

```bash
# Check alert rules
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
# Visit http://localhost:9090/alerts

# Check Alertmanager
kubectl port-forward svc/alertmanager 9093:9093 -n monitoring
# Visit http://localhost:9093

# Test alert routing
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "TestAlert",
      "severity": "warning"
    },
    "annotations": {
      "summary": "Test alert"
    }
  }]'
```

## 📚 Best Practices

### **Metric Naming Conventions**

```yaml
Naming Standards:
  ├── Use descriptive names: http_requests_total (not requests)
  ├── Include units in name: http_request_duration_seconds
  ├── Use consistent labeling: {method="GET", endpoint="/api/tasks"}
  ├── Avoid high cardinality: Don't use user IDs as labels
  └── Follow Prometheus conventions: _total for counters, _seconds for durations
```

### **Dashboard Design**

```yaml
Dashboard Guidelines:
  ├── Start with overview dashboards
  ├── Drill down to specific components
  ├── Use consistent time ranges
  ├── Include context and annotations
  ├── Set appropriate refresh intervals
  └── Use meaningful color schemes
```

### **Alerting Best Practices**

```yaml
Alert Guidelines:
  ├── Alert on symptoms, not causes
  ├── Make alerts actionable
  ├── Include relevant context in descriptions
  ├── Use appropriate severity levels
  ├── Avoid alert fatigue with proper grouping
  └── Test alert notifications regularly
```

### **Performance Optimization**

```yaml
Optimization Strategies:
  ├── Tune scrape intervals based on need
  ├── Use recording rules for expensive queries
  ├── Implement metric retention policies
  ├── Monitor monitoring system resource usage
  └── Use federation for large-scale deployments
```

---

<div align="center">

**📊 Comprehensive monitoring enables proactive operations and faster issue resolution.**

Continue to **[Operations Guide](OPERATIONS.md)** to learn about day-to-day management.

</div>