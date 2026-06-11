# 🧪 Hướng dẫn Testing - GitOps Lab

## 📋 Checklist trước khi test

Chạy script kiểm tra trạng thái:
```powershell
.\check-status.ps1
```

Đảm bảo tất cả đều **Healthy/Running**:
- ✅ ArgoCD apps: Synced
- ✅ Prometheus stack: Running
- ✅ Argo Rollouts: Running  
- ✅ API Rollout: 4/4 pods
- ✅ Load pod: Running (generate traffic)

## 🔍 Test 1: Xem Metrics trong Prometheus (5 phút)

### Mục tiêu
Verify Prometheus đang scrape metrics từ API pods

### Steps

1. **Port-forward Prometheus**
```powershell
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

2. **Mở browser**: http://localhost:9090

3. **Test các queries:**

**Query 1: Request total**
```promql
flask_http_request_total{namespace="demo"}
```
✅ Kết quả mong đợi: Thấy metrics từ 4 pods api

**Query 2: Request rate**
```promql
rate(flask_http_request_total{namespace="demo"}[1m])
```
✅ Kết quả mong đợi: Giá trị > 0 (do load pod đang generate traffic)

**Query 3: Error rate**
```promql
sum(rate(flask_http_request_total{namespace="demo",status=~"5.."}[1m])) /
sum(rate(flask_http_request_total{namespace="demo"}[1m]))
```
✅ Kết quả mong đợi: Giá trị = 0 hoặc không có kết quả (vì ERROR_RATE=0)

**Query 4: Requests by version**
```promql
sum by (version) (flask_http_request_total{namespace="demo"})
```
✅ Kết quả mong đợi: version="v1"

4. **Check Alert**
   - Vào tab **Alerts**
   - Tìm alert **HighErrorRate**
   - ✅ Status: **Inactive** (màu xanh) vì error rate = 0

### Troubleshooting
Nếu không thấy metrics:
```powershell
# Kiểm tra ServiceMonitor
kubectl -n demo get servicemonitor api-monitor -o yaml

# Kiểm tra Prometheus targets
# Vào Prometheus UI → Status → Targets → tìm "demo/api-monitor"
# Status phải là UP
```

---

## 🚀 Test 2: Canary Deployment Thành công (10 phút)

### Mục tiêu
Deploy version v2 với ERROR_RATE=0 → Canary auto-promote

### Steps

1. **Chạy script test**
```powershell
.\test-canary-success.ps1
```

Script sẽ tự động:
- Build image w9-api:2
- Load vào minikube
- Update manifest (v1 → v2)
- Git commit & push

2. **Monitor deployment**

**Terminal 1: Watch Rollout**
```powershell
kubectl -n demo get rollout api -w
```

**Terminal 2: Watch Pods**
```powershell
kubectl -n demo get pods -l app=api -w
```

**Terminal 3: Watch AnalysisRun**
```powershell
kubectl -n demo get analysisrun -w
```

3. **Quan sát quá trình**

**Phase 1: Canary 25% (~2 phút)**
- 1 pod mới v2 được tạo
- 3 pods cũ v1 vẫn chạy
- AnalysisRun bắt đầu check error rate

**Phase 2: Canary 50% (~1 phút)**
- 2 pods v2, 2 pods v1
- AnalysisRun continue check

**Phase 3: Promote 100%**
- Tất cả 4 pods chuyển sang v2
- Pods v1 bị terminate

4. **Verify kết quả**

```powershell
# Check rollout status
kubectl -n demo describe rollout api | Select-String "Status|Image"

# Check pods (tất cả đều là v2)
kubectl -n demo get pods -l app=api -o jsonpath='{.items[*].spec.containers[0].image}'

# Query Prometheus - xem version v2
# sum by (version) (flask_http_request_total{namespace="demo"})
```

✅ **Kết quả mong đợi:**
- Rollout status: Healthy
- Image: w9-api:2
- Prometheus: version="v2"
- Alert HighErrorRate: Inactive (error rate vẫn = 0)

---

## ⚠️ Test 3: Canary Auto-Rollback (10 phút)

### Mục tiêu
Deploy version v3 với ERROR_RATE=0.1 → Analysis fail → Auto-abort

### Steps

1. **Chạy script test**
```powershell
.\test-canary-fail.ps1
```

Script sẽ:
- Build image w9-api:3
- Update manifest (v2 → v3, ERROR_RATE=0.1)
- Git commit & push

2. **Monitor deployment**

```powershell
# Terminal 1
kubectl -n demo get rollout api -w

# Terminal 2
kubectl -n demo get analysisrun -w

# Terminal 3
kubectl -n demo get pods -l app=api -w
```

3. **Quan sát quá trình**

**Phase 1: Canary 25%**
- 1 pod v3 được tạo với ERROR_RATE=0.1
- 3 pods v2 vẫn chạy
- AnalysisRun bắt đầu

**Phase 2: Analysis Detecting Errors**
- AnalysisRun query Prometheus mỗi 30s
- Detect error rate > 5% (threshold)
- Fail count tăng dần (1, 2, 3)

**Phase 3: Auto-Abort**
- Sau 3 lần fail (failureLimit=3)
- Rollout tự động ABORT
- Pod v3 bị terminate
- Traffic quay về 100% v2

4. **Verify Alert Fire**

Port-forward Prometheus:
```powershell
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

Vào http://localhost:9090/alerts
- Tìm alert **HighErrorRate**
- ✅ Status: **Pending** hoặc **Firing** (màu đỏ)

5. **Check AnalysisRun details**

```powershell
# List all analysis runs
kubectl -n demo get analysisrun

# Describe latest one
kubectl -n demo describe analysisrun <name>
```

✅ **Kết quả mong đợi:**
- AnalysisRun Phase: Failed
- Rollout Phase: Degraded hoặc Healthy (sau abort)
- Pods: tất cả đều v2, không còn v3
- Alert: Firing (error rate > 5%)

### Cleanup alert

Sau khi test xong, pod v3 đã bị xóa → error rate về 0 → alert tự động inactive sau 1-2 phút.

---

## ↩️ Test 4: Git Rollback < 5 phút (5 phút)

### Mục tiêu
Chứng minh rollback qua Git trong < 5 phút

### Steps

1. **Chạy script rollback**
```powershell
.\test-git-rollback.ps1
```

Script sẽ:
- `git revert HEAD` (revert commit v3)
- `git push`
- Đo thời gian

2. **Monitor ArgoCD sync**

```powershell
# Watch ArgoCD application
kubectl -n argocd get application api -w

# Watch Rollout
kubectl -n demo get rollout api -w
```

3. **Quan sát quá trình**

**Phase 1: ArgoCD detect changes** (~30s)
- ArgoCD polling Git repo
- Detect new commit (revert)
- Status: OutOfSync

**Phase 2: ArgoCD sync** (~1 phút)
- ArgoCD apply manifest cũ (v2)
- Rollout trigger deployment

**Phase 3: Rollout deploy** (~2-3 phút)
- Rollout deploy lại stable version
- Canary process: 25% → 50% → 100%

4. **Verify kết quả**

```powershell
# Check image version
kubectl -n demo get pods -l app=api -o jsonpath='{.items[*].spec.containers[0].image}'

# Check rollout
kubectl -n demo describe rollout api
```

✅ **Kết quả mong đợi:**
- Image: w9-api:2
- Total time: < 5 phút
- Alert: Inactive (error rate = 0)

---

## 📊 Test 5: Grafana Dashboard (Optional, 5 phút)

### Steps

1. **Port-forward Grafana**
```powershell
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

2. **Login**
- URL: http://localhost:3000
- Username: `admin`
- Password: `prom-operator`

3. **Import Dashboard**
- Vào **Dashboards** → **New** → **Import**
- Dashboard ID: `3662` (Prometheus 2.0 Overview)
- Hoặc tạo dashboard custom với queries từ Test 1

4. **Create custom panel**
- Add panel
- Query:
```promql
sum by (version) (rate(flask_http_request_total{namespace="demo"}[1m]))
```
- Visualization: Time series hoặc Stat

---

## 🎯 Summary Checklist

| Test | Mục tiêu | Kết quả | Thời gian |
|------|----------|---------|-----------|
| ✅ Test 1 | Metrics trong Prometheus | Metrics visible | 5 phút |
| ✅ Test 2 | Canary success (v1→v2) | Auto-promote | 10 phút |
| ✅ Test 3 | Canary fail (v2→v3) | Auto-rollback | 10 phút |
| ✅ Test 4 | Git rollback | < 5 phút | 5 phút |
| ✅ Test 5 | Grafana dashboard | Dashboard hiển thị | 5 phút |

**Total time: ~35 phút**

---

## 🔧 Troubleshooting

### Rollout stuck ở Paused
```powershell
# Check analysis run
kubectl -n demo get analysisrun
kubectl -n demo describe analysisrun <name>

# Manual promote (chỉ test, không dùng trong production)
kubectl -n demo patch rollout api --type merge -p '{"spec":{"paused":false}}'
```

### Metrics không hiển thị trong Prometheus
```powershell
# Restart load pod
kubectl -n demo delete pod load
kubectl -n demo run load --image=busybox --restart=Never -- sh -c "while true; do wget -qO- api:8080/; done"

# Check ServiceMonitor
kubectl -n demo get servicemonitor api-monitor -o yaml
```

### ArgoCD không sync
```powershell
# Force refresh
kubectl -n argocd patch application api --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'

# Check sync status
kubectl -n argocd get application api -o yaml | Select-String "message|status"
```

### Alert không fire
```powershell
# Check PrometheusRule
kubectl -n demo get prometheusrule api-alerts -o yaml

# Verify Prometheus loaded rules
# Prometheus UI → Status → Rules → tìm "api-slo"
```

---

## 📚 Tài liệu tham khảo

- **README.md** - Kiến trúc tổng quan
- **DEPLOYMENT.md** - Deployment guide
- **STATUS.md** - Trạng thái hiện tại
- **FILES_CREATED.md** - Danh sách files

---

## 🎉 Kết luận

Sau khi hoàn thành tất cả tests, bạn đã chứng minh được:

1. ✅ **LAB 1**: Prometheus + Argo Rollouts deployed qua GitOps
2. ✅ **LAB 2**: Flask app với /metrics endpoint
3. ✅ **LAB 3**: Rollout + ServiceMonitor + Alert
4. ✅ **LAB 4**: Canary deployment với auto-rollback

### Tiêu chí đạt yêu cầu:
- ✅ Git rollback < 5 phút
- ✅ 1 SLO + 1 Alert (HighErrorRate > 5%)
- ✅ Canary tự động abort khi metric tệ
- ✅ Do lường và chứng minh qua Prometheus

**🏆 Hoàn thành GitOps Lab!**
