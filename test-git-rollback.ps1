# Script test Git rollback
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Test Git Rollback < 5 phút" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$startTime = Get-Date

# Step 1: Git revert
Write-Host "Step 1: Reverting last commit..." -ForegroundColor Yellow
git revert --no-edit HEAD
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Git revert failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Commit reverted`n" -ForegroundColor Green

# Step 2: Git push
Write-Host "Step 2: Pushing revert to Git..." -ForegroundColor Yellow
git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Git push failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Revert pushed to Git`n" -ForegroundColor Green

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "⏱️  Time elapsed: $([math]::Round($duration, 1)) seconds" -ForegroundColor Magenta
Write-Host "`nArgoCD sẽ tự động sync và rollback deployment..." -ForegroundColor Yellow
Write-Host "`nMonitor với:" -ForegroundColor Yellow
Write-Host "  kubectl -n demo get rollout api -w" -ForegroundColor Green
Write-Host "  kubectl -n argocd get application api -w" -ForegroundColor Green
Write-Host "`nKết quả mong đợi:" -ForegroundColor Yellow
Write-Host "  - ArgoCD detect changes trong ~30s" -ForegroundColor White
Write-Host "  - Sync và deploy lại stable version" -ForegroundColor White
Write-Host "  - ✅ Hoàn tất rollback trong < 5 phút`n" -ForegroundColor Green
