# ⚡ Quick Start - GitOps Lab

Hướng dẫn nhanh để verify và test toàn bộ lab trong 15 phút.

## ✅ Step 1: Verify Setup (2 phút)

```powershell
# Check status
.\check-status.ps1
```

Đảm bảo:
- ✅ 7 ArgoCD applications: Synced
- ✅ Monitoring pods: Running
- ✅ API rollout: 4/4 pods
- ✅ Load pod: Running

## 📊 Step 2: Check Metrics (3 phút)

```powershell
# Port-forward Prometheus
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

Mở http://localhost:9090

**Query:**
```promql
flask_http_request_total{namespace="demo"}
```

✅ Thấy metrics từ 4 pods → **LAB 3 PASS**

## 🚀 Step 3: Test Canary Success (5 phút)

```powershell
.\test-canary-success.ps1
```

**Monitor:**
```powershell
kubectl -n demo get rollout api -w
```

Kết quả: 25% → 50% → 100% ✅

## ⚠️ Step 4: Test Auto-Rollback (5 phút)

```powershell
.\test-canary-fail.ps1
```

**Monitor:**
```powershell
kubectl -n demo get analysisrun -w
```

Kết quả: Analysis fail → Auto ABORT ✅

Vào Prometheus alerts: http://localhost:9090/alerts  
→ HighErrorRate: **FIRING** 🔥

## ↩️ Step 5: Test Git Rollback (3 phút)

```powershell
.\test-git-rollback.ps1
```

Kết quả: Rollback trong < 5 phút ✅

---

## 🎯 Checklist Hoàn thành

- [ ] LAB 1: Prometheus + Argo Rollouts running
- [ ] LAB 2: Flask image w9-api:1 loaded
- [ ] LAB 3: Metrics visible trong Prometheus
- [ ] LAB 4: Canary success test passed
- [ ] LAB 4: Canary rollback test passed
- [ ] Git rollback < 5 phút verified
- [ ] Alert fire khi error rate > 5%

**Total time: ~18 phút**

---

## 🔗 Access URLs

```powershell
# Prometheus
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090

# Grafana
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# admin / prom-operator

# API
kubectl -n demo port-forward svc/api 8080:8080
```

---

## 📚 Full Documentation

- **README.md** - Overview
- **DEPLOYMENT.md** - Full guide
- **TESTING.md** - Detailed tests
- **SUMMARY.md** - Architecture & results

**🎉 Ready to demo!**
