# 🚀 Bước tiếp theo - Sẵn sàng Test!

## ✅ Trạng thái hiện tại

Tất cả components đã **Synced** và **Healthy**:
- ✅ ArgoCD: 7 applications Synced
- ✅ Argo Rollouts: Controller running
- ✅ Prometheus Stack: All pods running
- ✅ API Rollout: 4/4 pods ready
- ✅ Load pod: Generating traffic

**🎉 Hệ thống hoàn toàn sẵn sàng để test!**

---

## 📊 Bước 1: Xem Metrics trong Prometheus (2 phút)

### Terminal 1: Port-forward Prometheus
```powershell
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

### Mở browser
**URL:** http://localhost:9090

### Test queries

**Query 1: Kiểm tra metrics từ API**
```promql
flask_http_request_total{namespace="demo"}
```
✅ Kết quả mong đợi: Thấy metrics từ 4 pods (api-b848c847f-*)

**Query 2: Request rate**
```promql
rate(flask_http_request_total{namespace="demo"}[1m])
```
✅ Kết quả mong đợi: Giá trị > 0 (do load pod generate traffic)

**Query 3: Error rate (quan trọng cho canary!)**
```promql
sum(rate(flask_http_request_total{namespace="demo",status=~"5.."}[1m])) /
sum(rate(flask_http_request_total{namespace="demo"}[1m]))
```
✅ Kết quả mong đợi: Không có kết quả hoặc = 0 (vì ERROR_RATE=0)

**Query 4: Requests by version**
```promql
sum by (version) (flask_http_request_total{namespace="demo"})
```
✅ Kết quả mong đợi: `version="v1"`

### Kiểm tra Alert
1. Vào tab **Alerts** trong Prometheus UI
2. Tìm alert: **HighErrorRate**
3. ✅ Status: **Inactive** (màu xanh) - vì error rate = 0%

---

## 🚀 Bước 2: Test Canary Deployment Thành công (5 phút)

### Chạy script
```powershell
.\test-canary-success.ps1
```

Script sẽ tự động:
1. Build image `w9-api:2`
2. Load vào minikube
3. Update manifest (VERSION: v1 → v2)
4. Git commit & push

### Monitor deployment

**Terminal 2: Watch Rollout**
```powershell
kubectl -n demo get rollout api -w
```

**Terminal 3: Watch Pods**
```powershell
kubectl -n demo get pods -l app=api -w
```

### Quan sát

**Phase 1: Canary 25%**
- 1 pod mới (v2) xuất hiện
- 3 pods cũ (v1) vẫn chạy
- Status: Paused (đợi analysis hoặc manual promote)

**Phase 2: Analysis Pass**
- AnalysisRun check error rate < 5%
- Analysis PASS

**Phase 3: Canary 50% → 100%**
- 2 pods v2, 2 pods v1 (50%)
- Pause 30s
- Tất cả 4 pods chuyển sang v2 (100%)
- Pods v1 bị terminate

### Verify
```powershell
# Check rollout status
kubectl -n demo describe rollout api | Select-String "Status|Image|Revision"

# Check all pods are v2
kubectl -n demo get pods -l app=api -o jsonpath='{.items[*].spec.containers[0].image}'
# Kết quả: w9-api:2 w9-api:2 w9-api:2 w9-api:2

# Query Prometheus - xem version v2
# sum by (version) (flask_http_request_total{namespace="demo"})
```

✅ **Kết quả mong đợi:** Canary tự động promote, tất cả pods v2

---

## ⚠️ Bước 3: Test Canary Auto-Rollback (5 phút)

### Chạy script
```powershell
.\test-canary-fail.ps1
```

Script sẽ:
1. Build image `w9-api:3` với ERROR_RATE=0.1 (10% error!)
2. Update manifest (VERSION: v2 → v3, ERROR_RATE: 0 → 0.1)
3. Git commit & push

### Monitor

**Terminal 2: Watch AnalysisRun**
```powershell
kubectl -n demo get analysisrun -w
```

**Terminal 3: Watch Rollout**
```powershell
kubectl -n demo get rollout api -w
```

### Quan sát

**Phase 1: Canary 25%**
- 1 pod v3 (bad version) xuất hiện
- 3 pods v2 (stable) vẫn chạy

**Phase 2: Analysis Detecting**
- AnalysisRun bắt đầu
- Query Prometheus mỗi 30s
- Detect error rate = 10% (> 5% threshold!)

**Phase 3: Analysis Fail**
- Fail count: 1/3 → 2/3 → 3/3
- AnalysisRun Phase: **Failed**

**Phase 4: Auto-Abort!**
- Rollout tự động ABORT
- Pod v3 bị terminate
- 100% traffic về v2 (stable)

### Verify Alert Fire

**Prometheus Alerts:** http://localhost:9090/alerts
- Tìm: **HighErrorRate**
- ✅ Status: **FIRING** (màu đỏ) 🔥
- Message: "Error rate is 10% (threshold: 5%)"

### Check AnalysisRun
```powershell
# List all analysis runs
kubectl -n demo get analysisrun

# Describe latest (thay <name>)
kubectl -n demo describe analysisrun <name>

# Output sẽ thấy:
# Phase: Failed
# Message: metric "error-rate" assessed Failed due to failureLimit
```

### Verify Rollback
```powershell
# All pods should be v2 (not v3)
kubectl -n demo get pods -l app=api -o jsonpath='{.items[*].spec.containers[0].image}'
# Kết quả: w9-api:2 w9-api:2 w9-api:2 w9-api:2

# Rollout status
kubectl -n demo get rollout api
# STATUS: Healthy (sau khi abort)
```

✅ **Kết quả mong đợi:** 
- Auto-abort thành công
- Alert fire
- Không có v3 pods

---

## ↩️ Bước 4: Test Git Rollback < 5 phút (3 phút)

### Chạy script
```powershell
.\test-git-rollback.ps1
```

Script sẽ:
1. `git revert HEAD` (revert commit bad version v3)
2. `git push`
3. Đo thời gian

### Monitor

**Terminal 2: Watch ArgoCD**
```powershell
kubectl -n argocd get application api -w
```

**Terminal 3: Watch Rollout**
```powershell
kubectl -n demo get rollout api -w
```

### Quan sát

**Phase 1: Git revert (< 5s)**
- Script thực hiện git revert + push

**Phase 2: ArgoCD detect (~30s)**
- ArgoCD polling Git
- Detect new commit
- Status: OutOfSync → Syncing

**Phase 3: Rollout deploy (~2 phút)**
- Apply manifest (version v2)
- Rollout trigger deployment
- Canary process lại

**Phase 4: Hoàn tất**
- Tất cả pods v2
- Alert inactive (error rate = 0)

### Verify
```powershell
# Check time từ script output
# Time elapsed: < 5 phút ✅

# Check image version
kubectl -n demo get pods -l app=api -o jsonpath='{.items[*].spec.containers[0].image}'
# Kết quả: w9-api:2 (stable)

# Alert inactive
# Prometheus UI → Alerts → HighErrorRate: Inactive
```

✅ **Kết quả mong đợi:** Rollback hoàn tất trong < 5 phút

---

## 📊 Bước 5: Access Grafana (Optional, 2 phút)

### Port-forward
```powershell
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

### Login
- **URL:** http://localhost:3000
- **Username:** `admin`
- **Password:** `prom-operator`

### Explore Dashboards
- **Kubernetes / Compute Resources / Namespace (Pods)** - chọn namespace: demo
- **Prometheus / Overview** - xem Prometheus stats

### Create Custom Dashboard (Optional)
1. Click **+** → **Dashboard** → **Add visualization**
2. Query:
```promql
sum by (version) (rate(flask_http_request_total{namespace="demo"}[1m]))
```
3. Title: "Request Rate by Version"
4. Save dashboard

---

## 📝 Summary Commands

```powershell
# Check status toàn bộ
.\check-status.ps1

# Test canary success
.\test-canary-success.ps1

# Test canary rollback
.\test-canary-fail.ps1

# Test git rollback
.\test-git-rollback.ps1

# Port-forward Prometheus
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090

# Port-forward Grafana
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80

# Watch rollout
kubectl -n demo get rollout api -w

# Watch analysisruns
kubectl -n demo get analysisrun -w

# Check pods
kubectl -n demo get pods -l app=api
```

---

## 🎯 Expected Results Summary

| Test | Thời gian | Kết quả |
|------|-----------|---------|
| 1. Metrics visible | 2 phút | ✅ Thấy metrics trong Prometheus |
| 2. Canary success | 5 phút | ✅ Auto-promote v1→v2 |
| 3. Canary rollback | 5 phút | ✅ Auto-abort v2→v3, alert fire |
| 4. Git rollback | 3 phút | ✅ Rollback < 5 phút |
| **Total** | **15 phút** | **✅ All PASS** |

---

## 🏆 Checklist Cuối cùng

- [ ] Prometheus metrics visible (Query: flask_http_request_total)
- [ ] Canary success test passed (v1 → v2)
- [ ] Canary rollback test passed (v2 → v3 auto-abort)
- [ ] Alert HighErrorRate fired khi error > 5%
- [ ] Git rollback completed < 5 phút
- [ ] All ArgoCD apps: Synced & Healthy

---

## 💡 Troubleshooting

### Nếu không thấy metrics:
```powershell
# Restart load pod
kubectl -n demo delete pod load
kubectl -n demo run load --image=busybox --restart=Never -- sh -c "while true; do wget -qO- api:8080/; done"

# Đợi 1-2 phút và query lại
```

### Nếu analysis không chạy:
```powershell
# Check AnalysisTemplate
kubectl -n demo get analysistemplate error-rate-analysis -o yaml

# Check Prometheus có accessible không
kubectl -n demo run curl --image=curlimages/curl --rm -it -- \
  curl http://kube-prometheus-stack-prometheus.monitoring.svc:9090/-/healthy
```

### Nếu rollout stuck:
```powershell
# Describe để xem events
kubectl -n demo describe rollout api

# Manual abort nếu cần
kubectl -n demo patch rollout api --type merge -p '{"spec":{"paused":false}}'
```

---

## 📚 Documentation

- **QUICKSTART.md** - Test nhanh 15 phút
- **TESTING.md** - Chi tiết từng test case
- **SUMMARY.md** - Tổng kết toàn bộ
- **FINAL_CHECKLIST.md** - Checklist đầy đủ

---

**🎉 Sẵn sàng! Bắt đầu test từ Bước 1!** 🚀
