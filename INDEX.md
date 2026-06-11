# 📖 GitOps Lab - Documentation Index

Hướng dẫn đầy đủ cho GitOps Lab với Argo Rollouts + Prometheus + Flask API

---

## 🚀 Getting Started

### ⚡ [QUICKSTART.md](QUICKSTART.md)
**15 phút - Verify & test nhanh toàn bộ lab**
- Kiểm tra status
- Test canary success
- Test auto-rollback
- Verify git rollback < 5 phút

👉 **Bắt đầu từ đây nếu bạn muốn test nhanh!**

---

## 📚 Documentation

### 📝 [README.md](README.md)
**Tổng quan dự án & kiến trúc**
- Giới thiệu GitOps pattern
- Kiến trúc hệ thống
- Cấu trúc dự án
- Hướng dẫn từng LAB
- Monitoring & alerting setup
- Prometheus queries
- Troubleshooting

👉 **Đọc để hiểu tổng quan dự án**

---

### 🛠️ [DEPLOYMENT.md](DEPLOYMENT.md)
**Hướng dẫn deployment từng bước chi tiết**
- Pre-requisites
- 12 bước deployment
- Build Docker images
- Deploy với ArgoCD
- Setup monitoring
- Generate traffic
- Verification commands

👉 **Follow nếu deploy từ đầu**

---

### 🧪 [TESTING.md](TESTING.md)
**Hướng dẫn test chi tiết từng scenario**
- Test 1: Xem metrics trong Prometheus (5 phút)
- Test 2: Canary success (10 phút)
- Test 3: Canary auto-rollback (10 phút)
- Test 4: Git rollback < 5 phút (5 phút)
- Test 5: Grafana dashboard (5 phút)
- Troubleshooting guide

👉 **Follow để test từng tính năng**

---

### 📊 [STATUS.md](STATUS.md)
**Trạng thái hiện tại của hệ thống**
- Status từng LAB
- Pods running
- Commands hữu ích
- Quick access
- Bước tiếp theo

👉 **Check để xem trạng thái hiện tại**

---

### 🏆 [SUMMARY.md](SUMMARY.md)
**Tổng kết toàn bộ lab**
- Mục tiêu đã đạt
- Files đã tạo
- Kiến trúc chi tiết
- Tiêu chí đạt yêu cầu
- Kiến thức áp dụng
- Next steps

👉 **Đọc để xem toàn bộ kết quả**

---

### 📦 [FILES_CREATED.md](FILES_CREATED.md)
**Danh sách tất cả files đã tạo**
- LAB 1: Prometheus + Argo Rollouts (2 files)
- LAB 2: Flask API + Dockerfile (2 files)
- LAB 3: Rollout + Monitoring (4 files)
- Documentation (6 files)
- Scripts (4 files)

👉 **Reference để tìm file cụ thể**

---

## 🔧 Helper Scripts

### ✔️ [check-status.ps1](check-status.ps1)
**Kiểm tra trạng thái toàn bộ hệ thống**
```powershell
.\check-status.ps1
```
Shows:
- ArgoCD applications
- Pods trong tất cả namespaces
- Rollout status
- Monitoring resources
- Quick access commands

---

### ✅ [test-canary-success.ps1](test-canary-success.ps1)
**Test canary deployment thành công (v1 → v2)**
```powershell
.\test-canary-success.ps1
```
Actions:
- Build w9-api:2
- Load to minikube
- Update manifest
- Git commit & push
- Monitor deployment

Expected: Auto-promote 25% → 50% → 100%

---

### ⚠️ [test-canary-fail.ps1](test-canary-fail.ps1)
**Test canary auto-rollback (v2 → v3 with errors)**
```powershell
.\test-canary-fail.ps1
```
Actions:
- Build w9-api:3 with ERROR_RATE=0.1
- Update manifest
- Git commit & push
- Monitor analysis

Expected: Analysis fail → Auto ABORT

---

### ↩️ [test-git-rollback.ps1](test-git-rollback.ps1)
**Test git rollback < 5 phút**
```powershell
.\test-git-rollback.ps1
```
Actions:
- git revert HEAD
- git push
- Measure time

Expected: Rollback complete in < 5 minutes

---

## 📂 Project Structure

```
d:\w9\
├── app/                    # Flask application
│   ├── app.py
│   └── Dockerfile
│
├── argocd/                 # ArgoCD applications
│   ├── root.yaml
│   └── apps/
│       ├── kube-prometheus-stack.yaml  # NEW
│       ├── argo-rollouts.yaml          # NEW
│       ├── api.yaml                    # NEW
│       ├── backend.yaml
│       └── frontend.yaml
│
├── k8s-api/               # API Rollout resources
│   ├── api.yaml           # Rollout + Service + Analysis
│   ├── servicemonitor.yaml
│   └── prometheusrule.yaml
│
├── k8s/                   # Basic K8s resources
│
├── Documentation/         # This folder
│   ├── INDEX.md          # This file
│   ├── QUICKSTART.md
│   ├── README.md
│   ├── DEPLOYMENT.md
│   ├── TESTING.md
│   ├── STATUS.md
│   ├── SUMMARY.md
│   └── FILES_CREATED.md
│
└── Scripts/
    ├── check-status.ps1
    ├── test-canary-success.ps1
    ├── test-canary-fail.ps1
    └── test-git-rollback.ps1
```

---

## 🎯 Reading Path

### Path 1: Quick Demo (15 phút)
1. **QUICKSTART.md** → Run all tests
2. **STATUS.md** → Verify results

### Path 2: Understanding (30 phút)
1. **README.md** → Understand architecture
2. **TESTING.md** → Learn how to test
3. **SUMMARY.md** → See full results

### Path 3: Full Deploy (60 phút)
1. **README.md** → Overview
2. **DEPLOYMENT.md** → Deploy step-by-step
3. **TESTING.md** → Test everything
4. **SUMMARY.md** → Review results

### Path 4: Reference
- **FILES_CREATED.md** → Find specific files
- **Scripts** → Automation helpers
- **STATUS.md** → Current state

---

## 🔗 Quick Commands

```powershell
# Check status
.\check-status.ps1

# Test canary success
.\test-canary-success.ps1

# Test canary rollback
.\test-canary-fail.ps1

# Test git rollback
.\test-git-rollback.ps1

# Access Prometheus
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090

# Access Grafana
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# admin / prom-operator

# Access API
kubectl -n demo port-forward svc/api 8080:8080
```

---

## 🎓 Learning Resources

### Argo Rollouts
- [Official Docs](https://argoproj.github.io/argo-rollouts/)
- [Canary Strategy](https://argoproj.github.io/argo-rollouts/features/canary/)
- [Analysis](https://argoproj.github.io/argo-rollouts/features/analysis/)

### ArgoCD
- [Official Docs](https://argo-cd.readthedocs.io/)
- [App of Apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)

### Prometheus
- [Operator Docs](https://prometheus-operator.dev/)
- [Query Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)

### GitOps
- [GitOps Principles](https://www.gitops.tech/)
- [Progressive Delivery](https://www.weave.works/blog/progressive-delivery/)

---

## 💡 Tips

### Debug Commands
```powershell
# Check rollout details
kubectl -n demo describe rollout api

# Check analysis runs
kubectl -n demo get analysisrun
kubectl -n demo describe analysisrun <name>

# Check pods
kubectl -n demo get pods -l app=api
kubectl -n demo logs -f <pod-name>

# Check ArgoCD sync status
kubectl -n argocd get application api -o yaml
```

### Useful Prometheus Queries
```promql
# Request rate by version
sum by (version) (rate(flask_http_request_total{namespace="demo"}[1m]))

# Error rate
sum(rate(flask_http_request_total{namespace="demo",status=~"5.."}[1m])) /
sum(rate(flask_http_request_total{namespace="demo"}[1m]))

# Total requests
sum(flask_http_request_total{namespace="demo"})
```

---

## 🏁 Checklist

- [ ] Đọc README.md để hiểu overview
- [ ] Follow DEPLOYMENT.md để deploy (nếu chưa deploy)
- [ ] Chạy check-status.ps1 để verify
- [ ] Follow TESTING.md để test từng scenario
- [ ] Test với scripts (test-*.ps1)
- [ ] Đọc SUMMARY.md để xem kết quả tổng thể
- [ ] Bookmark INDEX.md để reference

---

## 📞 Support

Nếu gặp vấn đề:
1. Check **STATUS.md** → current state
2. Check **TESTING.md** → Troubleshooting section
3. Check **README.md** → Troubleshooting section
4. Run `.\check-status.ps1` để verify components

---

**🎉 Happy GitOps-ing! 🚀**

All documentation is ready. Pick your path and start learning!
