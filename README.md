# GitOps Lab - Argo Rollouts + Prometheus

## Tổng quan
Dự án GitOps triển khai Progressive Delivery với Argo Rollouts và monitoring với Prometheus/Grafana.

## Kiến trúc
- **ArgoCD**: GitOps deployment (App of Apps pattern)
- **Argo Rollouts**: Canary deployment với automated rollback
- **Prometheus**: Metrics collection & alerting
- **Flask API**: Demo app với /metrics endpoint

## Cấu trúc dự án
```
├── app/                    # Flask application
│   ├── app.py             # Flask app với Prometheus metrics
│   └── Dockerfile         # Container image
├── argocd/
│   ├── root.yaml          # Root application
│   └── apps/              # Child applications
│       ├── kube-prometheus-stack.yaml
│       ├── argo-rollouts.yaml
│       ├── api.yaml
│       ├── backend.yaml
│       └── frontend.yaml
├── k8s/                   # Basic K8s resources
└── k8s-api/              # API với Rollout
    ├── api.yaml          # Rollout + Service + AnalysisTemplate
    ├── servicemonitor.yaml
    └── prometheusrule.yaml
```

## LAB 1: Cài đặt Prometheus + Argo Rollouts

### Push ArgoCD apps lên Git:
```bash
git add argocd/apps/
git commit -m "add prometheus and argo-rollouts"
git push
```

### Verify deployment:
```bash
# Kiểm tra apps đã synced
kubectl -n argocd get applications

# Kiểm tra Prometheus
kubectl -n monitoring get pods

# Kiểm tra Argo Rollouts
kubectl -n argo-rollouts get pods
```

**Kết quả**: 2 apps synced và running (monitoring + argo-rollouts)

## LAB 2: Build Flask API image

### Build và load image vào minikube:
```bash
# Build image
docker build -t w9-api:1 app/

# Load vào minikube
minikube image load w9-api:1 -p w9

# Verify
minikube image ls -p w9 | grep w9-api:1
```

### Test local:
```bash
docker run -p 8080:8080 -e ERROR_RATE=0 -e VERSION=v1 w9-api:1

# Test endpoints
curl http://localhost:8080/
curl http://localhost:8080/metrics
curl http://localhost:8080/healthz
```

## LAB 3: Deploy API với Rollout + ServiceMonitor

### Push code lên Git:
```bash
git add app/ k8s-api/ argocd/apps/api.yaml
git commit -m "api"
git push
```

### Forward Prometheus để xem metrics:
```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

Mở browser: http://localhost:9090 và query: `flask_http_request_total{namespace="demo"}`

### Verify Rollout:
```bash
# Xem rollout status
kubectl argo rollouts get rollout api -n demo

# Xem pods
kubectl -n demo get pods -l app=api

# Test API
kubectl -n demo run load --image=busybox --restart=Never -- \
  sh -c "while true; do wget -qO- api:8080/; done"
```

## LAB 4: Canary Rollout với automated analysis

### Kịch bản test:

**Scenario 1: Canary thành công (ERROR_RATE=0)**
```bash
# Update image với version v2 (ERROR_RATE vẫn = 0)
# Sửa k8s-api/api.yaml: image: w9-api:1 -> w9-api:2, VERSION: v1 -> v2
docker build -t w9-api:2 app/
minikube image load w9-api:2 -p w9

# Push changes
git add k8s-api/api.yaml
git commit -am "api v2"
git push

# Watch rollout progress
kubectl argo rollouts get rollout api -n demo --watch

# Canary sẽ tự promote sau khi pass analysis
```

**Scenario 2: Canary fail và auto-rollback (ERROR_RATE=0.1)**
```bash
# Build v3 với ERROR_RATE cao
# Sửa k8s-api/api.yaml: VERSION: v2 -> v3, ERROR_RATE: "0" -> "0.1"
docker build -t w9-api:3 app/
minikube image load w9-api:3 -p w9

git add k8s-api/api.yaml
git commit -am "api v3 - bad version"
git push

# Watch rollout - sẽ tự động abort do error rate > 5%
kubectl argo rollouts get rollout api -n demo --watch
```

**Scenario 3: Manual promote/abort**
```bash
# Promote canary lên 100%
kubectl argo rollouts promote api -n demo

# Hoặc abort về bản cũ
kubectl argo rollouts abort api -n demo
```

### Rollback qua Git:
```bash
# Rollback về version trước đó
git revert HEAD
git push

# ArgoCD sẽ tự sync và rollout quay lại version cũ
```

## Tiêu chí đạt yêu cầu

✅ **Git rollback < 5 phút**: `git revert` + ArgoCD auto-sync

✅ **1 SLO + 1 alert**: PrometheusRule `HighErrorRate` (threshold 5% error rate)

✅ **Canary tự abort**: AnalysisTemplate kiểm tra error rate, tự abort khi > 5%

✅ **Rollout + Service**: api.yaml chứa Rollout với canary strategy

✅ **ServiceMonitor**: Scrape /metrics từ API pods

✅ **Prometheus metrics**: Query `flask_http_request_total` thấy traffic

## Monitoring & Alerting

### Access Grafana:
```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80

# Default credentials:
# Username: admin
# Password: prom-operator
```

### Useful Prometheus queries:
```promql
# Request rate
rate(flask_http_request_total{namespace="demo"}[1m])

# Error rate
sum(rate(flask_http_request_total{namespace="demo",status=~"5.."}[1m])) /
sum(rate(flask_http_request_total{namespace="demo"}[1m]))

# Request count by version
sum by (version) (flask_http_request_total{namespace="demo"})
```

## Troubleshooting

### Rollout stuck:
```bash
# Xem chi tiết rollout
kubectl argo rollouts get rollout api -n demo

# Xem events
kubectl -n demo describe rollout api

# Force abort nếu cần
kubectl argo rollouts abort api -n demo
```

### Metrics không hiển thị:
```bash
# Kiểm tra ServiceMonitor
kubectl -n demo get servicemonitor

# Kiểm tra Prometheus targets
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
# Vào http://localhost:9090/targets tìm "demo/api-monitor"
```

### Alert không fire:
```bash
# Kiểm tra PrometheusRule
kubectl -n demo get prometheusrule

# Xem alerts trong Prometheus UI
# http://localhost:9090/alerts
```

## Cleanup
```bash
# Xóa tất cả resources
kubectl delete namespace demo
kubectl delete namespace monitoring
kubectl delete namespace argo-rollouts
kubectl delete namespace argocd
```
