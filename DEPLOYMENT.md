# Hướng dẫn Deployment - GitOps Lab

## Yêu cầu ban đầu
- Minikube đã cài đặt và chạy
- kubectl đã cấu hình
- ArgoCD đã cài đặt trong cluster
- Docker để build image
- kubectl argo rollouts plugin: `kubectl krew install argo-rollouts`

## Bước 1: Push code lên Git repository

```bash
# Add tất cả files mới
git add .
git commit -m "complete gitops lab: prometheus + argo-rollouts + flask api"
git push origin main
```

## Bước 2: Deploy Prometheus Stack (LAB 1 - phần 1)

```bash
# Kiểm tra root app đã deploy chưa
kubectl -n argocd get application root

# Nếu chưa có, apply root app
kubectl apply -f argocd/root.yaml

# Đợi kube-prometheus-stack sync (có thể mất 3-5 phút)
kubectl -n argocd get application kube-prometheus-stack

# Verify Prometheus đã chạy
kubectl -n monitoring get pods
```

**Kết quả mong đợi:**
- App `kube-prometheus-stack` status: Synced, Healthy
- Pods trong namespace `monitoring` đều Running

## Bước 3: Deploy Argo Rollouts (LAB 1 - phần 2)

```bash
# Kiểm tra argo-rollouts app
kubectl -n argocd get application argo-rollouts

# Verify pods
kubectl -n argo-rollouts get pods
```

**Kết quả mong đợi:**
- App `argo-rollouts` status: Synced, Healthy
- Pod `argo-rollouts-*` trong namespace `argo-rollouts` Running

## Bước 4: Build và Load Flask API Image (LAB 2)

```bash
# Build image version 1
docker build -t w9-api:1 app/

# Load vào minikube (thay w9 bằng tên profile của bạn)
minikube image load w9-api:1 -p w9

# Verify image đã load
minikube image ls -p w9 | grep w9-api
```

**Test local (optional):**
```bash
docker run -p 8080:8080 -e ERROR_RATE=0 -e VERSION=v1 w9-api:1

# Trong terminal khác:
curl http://localhost:8080/           # {"ok": true, "version": "v1"}
curl http://localhost:8080/metrics    # Prometheus metrics
curl http://localhost:8080/healthz    # ok
```

## Bước 5: Deploy API với Rollout (LAB 3)

```bash
# App api sẽ tự sync từ ArgoCD (nếu đã push code)
kubectl -n argocd get application api

# Verify Rollout
kubectl argo rollouts get rollout api -n demo

# Verify Service & ServiceMonitor
kubectl -n demo get svc api
kubectl -n demo get servicemonitor api-monitor

# Verify PrometheusRule
kubectl -n demo get prometheusrule api-alerts
```

**Kết quả mong đợi:**
- App `api` status: Synced, Healthy
- Rollout `api` status: Healthy, 4/4 pods ready
- ServiceMonitor được tạo
- PrometheusRule được tạo

## Bước 6: Test Metrics trong Prometheus

```bash
# Port-forward Prometheus
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

Mở browser: http://localhost:9090

**Query test:**
```promql
# Xem tất cả metrics từ api
flask_http_request_total{namespace="demo"}

# Xem request rate
rate(flask_http_request_total{namespace="demo"}[1m])

# Xem error rate
sum(rate(flask_http_request_total{namespace="demo",status=~"5.."}[1m])) /
sum(rate(flask_http_request_total{namespace="demo"}[1m]))
```

## Bước 7: Generate traffic để có metrics

```bash
# Tạo pod test để gọi API liên tục
kubectl -n demo run load --image=busybox --restart=Never -- \
  sh -c "while true; do wget -qO- api:8080/; done"

# Xem logs (optional)
kubectl -n demo logs load -f
```

Sau 1-2 phút, quay lại Prometheus và query lại, bạn sẽ thấy metrics tăng.

## Bước 8: Test Canary Deployment thành công (LAB 4 - Scenario 1)

```bash
# Build version 2 (vẫn ERROR_RATE=0, chỉ đổi version)
# Không cần sửa code, chỉ build lại
docker build -t w9-api:2 app/
minikube image load w9-api:2 -p w9
```

Sửa file `k8s-api/api.yaml`:
```yaml
# Thay đổi:
image: w9-api:1  →  w9-api:2
value: "v1"      →  "v2"
```

```bash
git add k8s-api/api.yaml
git commit -m "api v2 - good version"
git push

# Watch rollout progress (có thể mất 1-2 phút để ArgoCD sync)
kubectl argo rollouts get rollout api -n demo --watch
```

**Kết quả mong đợi:**
- Canary sẽ tiến từ 25% → 50% → 100%
- Analysis pass (error rate < 5%)
- Rollout tự động promote lên stable

## Bước 9: Test Canary Auto-Rollback (LAB 4 - Scenario 2)

```bash
# Build version 3 với ERROR_RATE cao
docker build -t w9-api:3 app/
minikube image load w9-api:3 -p w9
```

Sửa file `k8s-api/api.yaml`:
```yaml
# Thay đổi:
image: w9-api:2      →  w9-api:3
value: "v2"          →  "v3"
value: "0"           →  "0.1"    # ERROR_RATE
```

```bash
git add k8s-api/api.yaml
git commit -m "api v3 - bad version with high error rate"
git push

# Watch rollout - sẽ thấy auto abort
kubectl argo rollouts get rollout api -n demo --watch
```

**Kết quả mong đợi:**
- Canary deploy 25%
- Analysis FAIL (error rate > 5%)
- Rollout tự động ABORT
- Traffic quay về stable version (v2)

## Bước 10: Test Git Rollback < 5 phút

```bash
# Rollback commit vừa rồi
git revert HEAD
git push

# ArgoCD sẽ tự sync và deploy lại version v2
kubectl argo rollouts get rollout api -n demo --watch
```

**Kết quả**: Trong vòng < 5 phút, version v2 (stable) sẽ được deploy lại.

## Bước 11: Test Alert (1 SLO + 1 Alert)

```bash
# Port-forward Prometheus
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

Vào http://localhost:9090/alerts

Tìm alert **HighErrorRate**:
- Nếu error rate < 5%: trạng thái **Inactive** (màu xanh)
- Nếu error rate > 5% trong 1 phút: trạng thái **Firing** (màu đỏ)

**Test fire alert:**
Deploy lại version v3 (ERROR_RATE=0.1) và đợi 1-2 phút, alert sẽ fire.

## Bước 12: Manual Promote/Abort (Optional)

```bash
# Promote canary lên stable
kubectl argo rollouts promote api -n demo

# Abort canary về stable
kubectl argo rollouts abort api -n demo

# Xem history
kubectl argo rollouts history api -n demo

# Rollback về revision cũ
kubectl argo rollouts undo api -n demo
```

## Kiểm tra tổng thể

### ✅ LAB 1: Prometheus + Argo Rollouts
```bash
kubectl -n monitoring get pods    # Prometheus stack running
kubectl -n argo-rollouts get pods # Argo Rollouts running
```

### ✅ LAB 2: Flask API + Docker Image
```bash
minikube image ls -p w9 | grep w9-api   # Images: w9-api:1, w9-api:2, w9-api:3
docker run -p 8080:8080 w9-api:1        # Test /metrics endpoint
```

### ✅ LAB 3: Rollout + ServiceMonitor + Prometheus
```bash
kubectl argo rollouts get rollout api -n demo    # Rollout healthy
kubectl -n demo get servicemonitor               # api-monitor exists
# Prometheus → query: flask_http_request_total   # Metrics visible
```

### ✅ LAB 4: Canary với Auto-Rollback
```bash
# Deploy bad version → auto abort
# git revert → rollback < 5 phút
# Alert fire khi error rate > 5%
```

## Troubleshooting

### 1. Rollout không tiến triển
```bash
# Xem events
kubectl -n demo describe rollout api

# Xem analysis status
kubectl -n demo get analysisrun
kubectl -n demo describe analysisrun <name>
```

### 2. ServiceMonitor không scrape metrics
```bash
# Kiểm tra Service labels
kubectl -n demo get svc api -o yaml | grep -A5 labels

# Kiểm tra Prometheus targets
# http://localhost:9090/targets → tìm "demo/api-monitor"
```

### 3. Analysis luôn fail
```bash
# Kiểm tra Prometheus query
kubectl -n demo get analysistemplate error-rate-analysis -o yaml

# Test query trực tiếp trong Prometheus UI
```

### 4. Image pull error
```bash
# Đảm bảo image đã load vào minikube
minikube image load w9-api:1 -p w9

# Hoặc push lên Docker Hub và đổi imagePullPolicy
```

## Summary Checklist

- [ ] LAB 1: Prometheus + Argo Rollouts deployed qua GitOps
- [ ] LAB 2: Flask app built với /metrics endpoint
- [ ] LAB 3: Rollout + ServiceMonitor + PrometheusRule deployed
- [ ] LAB 4: Canary rollout tested (success + auto-rollback)
- [ ] Git rollback < 5 phút
- [ ] 1 SLO + 1 Alert configured (HighErrorRate)
- [ ] Canary tự abort khi error rate > 5%

**🎉 Hoàn thành tất cả yêu cầu!**
