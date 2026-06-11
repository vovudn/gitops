# ✅ Trạng thái Deployment - GitOps Lab

**Thời gian**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 🎯 Tổng quan

Tất cả các LAB đã được setup thành công! Dưới đây là trạng thái hiện tại của hệ thống.

## ✅ LAB 1: Prometheus + Argo Rollouts - HOÀN THÀNH

### ArgoCD Applications
```
NAME                    SYNC STATUS   HEALTH STATUS
api                     Synced        Healthy
argo-rollouts           Synced        Healthy
backend                 Synced        Healthy
frontend                Synced        Healthy
kube-prometheus-stack   Synced        Healthy
root                    Synced        Healthy
web                     Synced        Healthy
```

### Monitoring Stack (namespace: monitoring)
- ✅ Prometheus: Running (2/2)
- ✅ Alertmanager: Running (2/2)
- ✅ Grafana: Running (3/3)
- ✅ Kube State Metrics: Running (1/1)
- ✅ Node Exporter: Running (1/1)

### Argo Rollouts (namespace: argo-rollouts)
- ✅ Argo Rollouts Controller: 2/2 pods Running

## ✅ LAB 2: Flask API + Docker Image - HOÀN THÀNH

### Docker Images
- ✅ w9-api:1 - Built và loaded vào minikube

### Application Structure
- ✅ app/app.py - Flask với /metrics endpoint
- ✅ app/Dockerfile - Python 3.12-slim base image
- ✅ Endpoints:
  - `/` - JSON response với version
  - `/metrics` - Prometheus metrics
  - `/healthz` - Health check

## ✅ LAB 3: Rollout + ServiceMonitor - HOÀN THÀNH

### API Rollout (namespace: demo)
```
NAME   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE
api    4         4         4            4
```
- ✅ Image: w9-api:1
- ✅ Replicas: 4/4 Running
- ✅ Status: Healthy, Completed
- ✅ Strategy: Canary (25% → 50% → 100%)

### Monitoring Resources
- ✅ ServiceMonitor: api-monitor (scrape interval: 15s)
- ✅ PrometheusRule: api-alerts (HighErrorRate alert)
- ✅ Service: api (port 8080)

### Traffic Generation
- ✅ Load pod running (wget loop to api:8080/)

## 🧪 LAB 4: Canary Deployment - SẴN SÀNG TEST

### Test Scenarios Chuẩn bị:

#### Scenario 1: Canary Thành công ✅
```bash
# Build image v2 (ERROR_RATE=0)
docker build -t w9-api:2 app/
minikube image load w9-api:2 -p w9

# Sửa k8s-api/api.yaml:
#   image: w9-api:1 → w9-api:2
#   VERSION: "v1" → "v2"

git add k8s-api/api.yaml
git commit -m "api v2 - good version"
git push

# Kết quả: Canary tự động promote lên 100%
```

#### Scenario 2: Canary Auto-Rollback ⚠️
```bash
# Build image v3 (ERROR_RATE=0.1)
docker build -t w9-api:3 app/

# Sửa k8s-api/api.yaml:
#   image: w9-api:2 → w9-api:3
#   VERSION: "v2" → "v3"
#   ERROR_RATE: "0" → "0.1"

git add k8s-api/api.yaml
git commit -m "api v3 - bad version"
git push

# Kết quả: Canary tự động ABORT do error rate > 5%
```

#### Scenario 3: Git Rollback ↩️
```bash
git revert HEAD
git push

# Kết quả: Rollback hoàn tất trong < 5 phút
```

## 📊 Kiểm tra Metrics & Alerts

### Access Prometheus
```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```
Mở: http://localhost:9090

**Query test:**
```promql
# Request total
flask_http_request_total{namespace="demo"}

# Request rate
rate(flask_http_request_total{namespace="demo"}[1m])

# Error rate
sum(rate(flask_http_request_total{namespace="demo",status=~"5.."}[1m])) /
sum(rate(flask_http_request_total{namespace="demo"}[1m]))
```

### Access Grafana
```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```
Mở: http://localhost:3000
- Username: `admin`
- Password: `prom-operator`

### Check Alerts
Vào Prometheus UI → Alerts → tìm **HighErrorRate**
- Inactive: error rate < 5% ✅
- Firing: error rate > 5% for 1m 🔥

## 🎯 Tiêu chí Đạt yêu cầu

| Tiêu chí | Trạng thái | Ghi chú |
|----------|------------|---------|
| ✅ Git rollback < 5 phút | SẴN SÀNG | `git revert` + ArgoCD auto-sync |
| ✅ 1 SLO + 1 Alert | HOÀN THÀNH | PrometheusRule: HighErrorRate (> 5%) |
| ✅ Canary tự abort | SẴN SÀNG | AnalysisTemplate kiểm tra error rate |
| ✅ Prometheus + Argo Rollouts | HOÀN THÀNH | Deployed qua GitOps |
| ✅ Flask app /metrics | HOÀN THÀNH | w9-api:1 running |
| ✅ Rollout + ServiceMonitor | HOÀN THÀNH | Metrics đang được scrape |

## 📝 Commands Hữu ích

### Xem trạng thái Rollout
```bash
kubectl -n demo get rollout api
kubectl -n demo describe rollout api
```

### Xem pods
```bash
kubectl -n demo get pods -l app=api
kubectl -n demo logs -f <pod-name>
```

### Xem AnalysisRun (khi có canary)
```bash
kubectl -n demo get analysisrun
kubectl -n demo describe analysisrun <name>
```

### Manual promote/abort
```bash
# Promote canary lên stable (cần kubectl plugin)
kubectl argo rollouts promote api -n demo

# Abort canary về stable
kubectl argo rollouts abort api -n demo
```

### Xem metrics từ pod
```bash
kubectl -n demo port-forward svc/api 8080:8080
curl http://localhost:8080/metrics
```

## 🚀 Bước tiếp theo

1. **Đợi 2-3 phút** để Prometheus bắt đầu scrape metrics từ api pods
2. **Kiểm tra metrics** trong Prometheus UI
3. **Test Scenario 1**: Deploy version v2 (canary success)
4. **Test Scenario 2**: Deploy version v3 (canary auto-rollback)
5. **Test Scenario 3**: Git revert (rollback < 5 phút)

## 📚 Documentation

Xem thêm chi tiết:
- **README.md** - Tổng quan và kiến trúc
- **DEPLOYMENT.md** - Hướng dẫn deployment từng bước
- **FILES_CREATED.md** - Danh sách files đã tạo

---

**🎉 Status: READY FOR TESTING!**

Tất cả infrastructure đã sẵn sàng. Bây giờ bạn có thể test các scenarios canary deployment!
