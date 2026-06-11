# Script test Canary auto-rollback (v2 -> v3 with high error rate)
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Test Canary Auto-Rollback (v2 -> v3)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Build image v3
Write-Host "Step 1: Building image w9-api:3 (with ERROR_RATE=0.1)..." -ForegroundColor Yellow
docker build -t w9-api:3 app/
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build successful`n" -ForegroundColor Green

# Step 2: Load to minikube
Write-Host "Step 2: Loading image to minikube..." -ForegroundColor Yellow
minikube image load w9-api:3 -p w9
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Load failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Image loaded`n" -ForegroundColor Green

# Step 3: Update manifest with bad version
Write-Host "Step 3: Updating k8s-api/api.yaml with ERROR_RATE=0.1..." -ForegroundColor Yellow
$apiFile = "k8s-api\api.yaml"
$content = Get-Content $apiFile -Raw
$content = $content -replace 'image: w9-api:2', 'image: w9-api:3'
$content = $content -replace 'value: "v2"', 'value: "v3"'
# Update ERROR_RATE (tìm env block và update)
$content = $content -replace '- name: ERROR_RATE\s+value: "0"', '- name: ERROR_RATE
              value: "0.1"'
Set-Content $apiFile -Value $content
Write-Host "✅ Manifest updated with high error rate`n" -ForegroundColor Green

# Step 4: Git commit and push
Write-Host "Step 4: Committing and pushing changes..." -ForegroundColor Yellow
git add k8s-api/api.yaml
git commit -m "api v3 - bad version (ERROR_RATE=0.1)"
git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Git push failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Changes pushed to Git`n" -ForegroundColor Green

# Step 5: Monitor
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment started! Monitor với:" -ForegroundColor Yellow
Write-Host "  kubectl -n demo get rollout api -w" -ForegroundColor Green
Write-Host "  kubectl -n demo get analysisrun -w" -ForegroundColor Green
Write-Host "  kubectl -n demo get pods -l app=api -w" -ForegroundColor Green
Write-Host "`nKết quả mong đợi:" -ForegroundColor Yellow
Write-Host "  - Canary deploy 25% (1 pod v3)" -ForegroundColor White
Write-Host "  - Analysis detect error rate > 5%" -ForegroundColor White
Write-Host "  - ❌ Analysis FAIL sau 3 lần check" -ForegroundColor Red
Write-Host "  - 🔄 Rollout tự động ABORT" -ForegroundColor Yellow
Write-Host "  - ✅ Traffic quay về v2 (stable)`n" -ForegroundColor Green
