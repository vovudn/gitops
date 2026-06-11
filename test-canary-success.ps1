# Script test Canary deployment thành công (v1 -> v2)
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Test Canary Success (v1 -> v2)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Build image v2
Write-Host "Step 1: Building image w9-api:2..." -ForegroundColor Yellow
docker build -t w9-api:2 app/
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build successful`n" -ForegroundColor Green

# Step 2: Load to minikube
Write-Host "Step 2: Loading image to minikube..." -ForegroundColor Yellow
minikube image load w9-api:2 -p w9
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Load failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Image loaded`n" -ForegroundColor Green

# Step 3: Update manifest
Write-Host "Step 3: Updating k8s-api/api.yaml..." -ForegroundColor Yellow
$apiFile = "k8s-api\api.yaml"
$content = Get-Content $apiFile -Raw
$content = $content -replace 'image: w9-api:1', 'image: w9-api:2'
$content = $content -replace 'value: "v1"', 'value: "v2"'
Set-Content $apiFile -Value $content
Write-Host "✅ Manifest updated`n" -ForegroundColor Green

# Step 4: Git commit and push
Write-Host "Step 4: Committing and pushing changes..." -ForegroundColor Yellow
git add k8s-api/api.yaml
git commit -m "api v2 - good version (ERROR_RATE=0)"
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
Write-Host "  kubectl -n demo get pods -l app=api -w" -ForegroundColor Green
Write-Host "`nKết quả mong đợi:" -ForegroundColor Yellow
Write-Host "  - Canary sẽ deploy 25% pods (1 pod)" -ForegroundColor White
Write-Host "  - Analysis check error rate < 5%" -ForegroundColor White
Write-Host "  - Canary tự động promote 50% -> 100%" -ForegroundColor White
Write-Host "  - Tất cả pods chuyển sang v2`n" -ForegroundColor White
