# Danh sách Files đã tạo cho GitOps Lab

## 📦 LAB 1: Prometheus + Argo Rollouts

### ArgoCD Applications
- `argocd/apps/kube-prometheus-stack.yaml` - Helm chart application cho Prometheus + Grafana + Alertmanager
- `argocd/apps/argo-rollouts.yaml` - Helm chart application cho Argo Rollouts controller

**Chức năng**: Deploy monitoring stack và progressive delivery controller qua GitOps

## 🐍 LAB 2: Flask API Application

### Application Code
- `app/app.py` - Flask API với:
  - Endpoint `/` - trả về JSON với version
  - Endpoint `/metrics` - Prometheus metrics
  - Endpoint `/healthz` - health check
  - Environment variables: ERROR_RATE, VERSION
  - Random error injection để test canary rollback

### Docker
- `app/Dockerfile` - Multi-stage build với Python 3.12-slim
  - Install flask + prometheus-flask-exporter
  - Expose port 8080
  - CMD: flask run

**Chức năng**: Demo app có metrics để test canary deployment

## 🚀 LAB 3: Kubernetes Rollout Resources

### Rollout Configuration
- `k8s-api/api.yaml` - Bao gồm:
  - **Rollout**: 4 replicas với canary strategy
    - Steps: 25% → pause → 50% → pause 30s → 100% → pause
    - Analysis template reference
  - **Service**: ClusterIP expose port 8080
  - **AnalysisTemplate**: Query Prometheus error rate
    - Interval: 30s
    - Success condition: error rate < 5%
    - Failure limit: 3 lần fail → abort

### Monitoring
- `k8s-api/servicemonitor.yaml` - Prometheus ServiceMonitor
  - Scrape `/metrics` endpoint từ api service
  - Interval: 15s
  - Label selector: app=api

- `k8s-api/prometheusrule.yaml` - Alert rule
  - Alert: **HighErrorRate**
  - Condition: error rate > 5% for 1 minute
  - Severity: critical

### ArgoCD Application
- `argocd/apps/api.yaml` - Application manifest
  - Source: k8s-api/ folder
  - Destination: demo namespace
  - Auto-sync enabled

**Chức năng**: Deploy API với progressive delivery + monitoring + alerting

## 📚 Documentation

### README.md
- Tổng quan kiến trúc
- Cấu trúc dự án
- Hướng dẫn từng LAB
- Monitoring & alerting setup
- Prometheus queries
- Troubleshooting guide

### DEPLOYMENT.md
- Step-by-step deployment guide
- Pre-requisites
- 12 bước deployment chi tiết
- Test scenarios cho canary deployment
- Verification commands
- Troubleshooting checklist

### FILES_CREATED.md (file này)
- Danh sách tất cả files đã tạo
- Mục đích của từng file

## 📊 Tổng kết

| LAB | Files | Description |
|-----|-------|-------------|
| LAB 1 | 2 files | kube-prometheus-stack.yaml, argo-rollouts.yaml |
| LAB 2 | 2 files | app.py, Dockerfile |
| LAB 3 | 4 files | api.yaml (Rollout+Service+Analysis), servicemonitor.yaml, prometheusrule.yaml, argocd/apps/api.yaml |
| Docs | 3 files | README.md, DEPLOYMENT.md, FILES_CREATED.md |
| **Total** | **11 files** | |

## 🎯 Đáp ứng yêu cầu đề bài

### ✅ LAB 1: Prometheus + Argo Rollouts
- kube-prometheus-stack.yaml → deploy qua Helm
- argo-rollouts.yaml → deploy qua Helm
- Push vào `argocd/apps/` → root app tự deploy

### ✅ LAB 2: Flask app với /metrics
- app.py → Flask với prometheus-flask-exporter
- Dockerfile → build image w9-api:1
- docker build + minikube image load

### ✅ LAB 3: Rollout + Prometheus
- api.yaml → Rollout với canary strategy + AnalysisTemplate
- servicemonitor.yaml → scrape metrics từ /metrics
- prometheusrule.yaml → alert HighErrorRate (SLO)
- Push → Prometheus nhận metrics

### ✅ LAB 4: Canary rollout
- Strategy.canary trong api.yaml → 25% → 50% → 100%
- AnalysisTemplate → tự động kiểm tra error rate
- Auto-abort nếu error rate > 5%
- Manual promote/abort: `kubectl argo rollouts promote/abort`

### ✅ Tiêu chí đạt yêu cầu

1. **Git rollback < 5 phút**:
   - `git revert HEAD && git push`
   - ArgoCD auto-sync → rollback trong 2-3 phút

2. **1 SLO + 1 Alert**:
   - SLO: error rate < 5%
   - Alert: HighErrorRate trong prometheusrule.yaml
   - Fire khi error rate > 5% for 1m

3. **Canary tự abort**:
   - AnalysisTemplate query Prometheus mỗi 30s
   - Nếu error rate > 5% trong 3 lần → auto abort
   - Rollback về stable version

4. **Rollout không lên 100% ngay**:
   - Canary steps: 25% (pause) → 50% (pause 30s) → 100% (pause)
   - Phải promote bằng tay hoặc đợi analysis pass

5. **Chứng minh qua Git + do lường + chứng minh**:
   - Git: ArgoCD sync từ Git repo
   - Do lường: ServiceMonitor → Prometheus → alert
   - Chứng minh: kubectl argo rollouts get rollout, Prometheus UI, alerts firing

## 🔧 Commands để verify

```bash
# Verify all components
kubectl -n monitoring get pods                    # Prometheus stack
kubectl -n argo-rollouts get pods                 # Argo Rollouts
kubectl -n demo get rollout                       # API rollout
kubectl -n demo get servicemonitor                # Metrics scraping
kubectl -n demo get prometheusrule                # Alert rules
kubectl argo rollouts get rollout api -n demo     # Rollout status

# Test canary
# 1. Deploy good version → auto promote
# 2. Deploy bad version (ERROR_RATE=0.1) → auto abort
# 3. git revert → rollback < 5 phút

# Check metrics & alerts
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
# → http://localhost:9090 query: flask_http_request_total
# → http://localhost:9090/alerts check HighErrorRate
```

## 📁 File structure final

```
d:\w9\
├── app/
│   ├── app.py                                    # Flask API
│   └── Dockerfile                                # Container build
├── argocd/
│   ├── root.yaml                                 # Existing
│   └── apps/
│       ├── kube-prometheus-stack.yaml            # NEW - LAB 1
│       ├── argo-rollouts.yaml                    # NEW - LAB 1
│       ├── api.yaml                              # NEW - LAB 3
│       ├── backend.yaml                          # Existing
│       └── frontend.yaml                         # Existing
├── k8s-api/
│   ├── api.yaml                                  # NEW - Rollout+Service+AnalysisTemplate
│   ├── servicemonitor.yaml                       # NEW - LAB 3
│   └── prometheusrule.yaml                       # NEW - LAB 3
├── README.md                                     # NEW - Documentation
├── DEPLOYMENT.md                                 # NEW - Step-by-step guide
└── FILES_CREATED.md                              # NEW - This file
```
