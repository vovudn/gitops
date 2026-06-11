# Script kiểm tra trạng thái GitOps Lab
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  GitOps Lab - Status Check" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 1. ArgoCD Applications
Write-Host "1. ArgoCD Applications:" -ForegroundColor Yellow
kubectl -n argocd get applications
Write-Host ""

# 2. Monitoring Stack
Write-Host "2. Monitoring Stack (namespace: monitoring):" -ForegroundColor Yellow
kubectl -n monitoring get pods
Write-Host ""

# 3. Argo Rollouts
Write-Host "3. Argo Rollouts (namespace: argo-rollouts):" -ForegroundColor Yellow
kubectl -n argo-rollouts get pods
Write-Host ""

# 4. API Rollout
Write-Host "4. API Rollout (namespace: demo):" -ForegroundColor Yellow
kubectl -n demo get rollout api
Write-Host ""
kubectl -n demo get pods -l app=api
Write-Host ""

# 5. Monitoring Resources
Write-Host "5. Monitoring Resources:" -ForegroundColor Yellow
kubectl -n demo get servicemonitor,prometheusrule
Write-Host ""

# 6. Load pod
Write-Host "6. Traffic Generator:" -ForegroundColor Yellow
kubectl -n demo get pod load
Write-Host ""

# 7. Docker images
Write-Host "7. Docker Images in Minikube:" -ForegroundColor Yellow
minikube image ls -p w9 | Select-String "w9-api"
Write-Host ""

# 8. Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Quick Access Commands" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Prometheus: kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090" -ForegroundColor Green
Write-Host "Grafana:    kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80" -ForegroundColor Green
Write-Host "API:        kubectl -n demo port-forward svc/api 8080:8080" -ForegroundColor Green
Write-Host "`nGrafana credentials: admin / prom-operator`n" -ForegroundColor Magenta
