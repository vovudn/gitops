# Monitor alert and cleanup unnecessary files
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  EMAIL ALERT TEST - READY!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Current status:" -ForegroundColor Yellow
Write-Host "  OK Email config applied (AlertmanagerConfig)" -ForegroundColor Green
Write-Host "  OK v3-email-test deployed (ERROR_RATE=0.20 = 20%)" -ForegroundColor Green
Write-Host "  OK Load pod generating traffic" -ForegroundColor Green
Write-Host "  OK Alert will fire in 1-2 minutes`n" -ForegroundColor Green

Write-Host "Timeline:" -ForegroundColor Cyan
Write-Host "  [Now] v3 with 20% error rate running" -ForegroundColor White
Write-Host "  [+15s] Prometheus scrapes metrics" -ForegroundColor White
Write-Host "  [+60s] Alert evaluates (for: 1m)" -ForegroundColor White
Write-Host "  [+90s] Alert FIRES -> Alertmanager sends email" -ForegroundColor White
Write-Host "  [+120s] Email arrives (check Spam folder!)`n" -ForegroundColor White

Write-Host "Monitor progress:" -ForegroundColor Yellow
Write-Host "  1. Check Prometheus alerts:" -ForegroundColor White
Write-Host "     kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090" -ForegroundColor Cyan
Write-Host "     Open: http://localhost:9090/alerts" -ForegroundColor Gray
Write-Host "     Find: HighErrorRate -> Status: FIRING (red)`n" -ForegroundColor Gray

Write-Host "  2. Check Alertmanager logs:" -ForegroundColor White
Write-Host "     kubectl -n monitoring logs -l app.kubernetes.io/name=alertmanager --tail=50 -f" -ForegroundColor Cyan
Write-Host "     Look for: Successfully sent email`n" -ForegroundColor Gray

Write-Host "  3. Check email inbox:" -ForegroundColor White
Write-Host "     To: vovudn95@gmail.com" -ForegroundColor Gray
Write-Host "     Subject: [FIRING] HighErrorRate" -ForegroundColor Gray
Write-Host "     Check Spam folder!`n" -ForegroundColor Gray

$wait = Read-Host "Wait for alert and check email? (y to continue with cleanup)"

if ($wait -ne "y") {
    Write-Host "`nExiting. Run this script again when ready to cleanup.`n" -ForegroundColor Yellow
    exit 0
}

# Cleanup
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  CLEANUP UNNECESSARY FILES" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Scanning for unnecessary files...`n" -ForegroundColor Yellow

$filesToDelete = @(
    "apply-email-simple.ps1",
    "full-diagnostic.ps1",
    "LAB4_FINAL_CHECK.ps1",
    "DIAGNOSIS.md",
    "WHY_NO_EMAIL.md",
    "TEST_EMAIL_ALERT.md",
    "FINAL_STATUS.md",
    "setup-email-gitops.ps1"
)

Write-Host "Files to delete:" -ForegroundColor Yellow
foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        Write-Host "  - $file" -ForegroundColor Gray
    }
}

Write-Host ""
$confirm = Read-Host "Delete these files? (y/n)"

if ($confirm -eq "y") {
    Write-Host "`nDeleting..." -ForegroundColor Cyan
    foreach ($file in $filesToDelete) {
        if (Test-Path $file) {
            Remove-Item $file -Force
            Write-Host "  Deleted: $file" -ForegroundColor Green
        }
    }
    
    Write-Host "`nCleanup complete!`n" -ForegroundColor Green
    
    Write-Host "Files remaining:" -ForegroundColor Yellow
    Get-ChildItem -Path . -File | Where-Object { $_.Extension -in '.md','.ps1' } | Select-Object Name | Format-Table -AutoSize
} else {
    Write-Host "`nCleanup cancelled.`n" -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FINAL PROJECT FILES" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Documentation:" -ForegroundColor White
Write-Host "  - README.md (project overview)" -ForegroundColor Gray
Write-Host "  - QUICKSTART.md (quick start)" -ForegroundColor Gray
Write-Host "  - SETUP_EMAIL_GITOPS.md (email setup guide)" -ForegroundColor Gray
Write-Host "  - EMAIL_METHODS_COMPARISON.md (comparison)`n" -ForegroundColor Gray

Write-Host "Scripts:" -ForegroundColor White
Write-Host "  - monitor-alert-and-cleanup.ps1 (this script)`n" -ForegroundColor Gray

Write-Host "Application:" -ForegroundColor White
Write-Host "  - app/ (Flask API)" -ForegroundColor Gray
Write-Host "  - k8s-api/ (Rollout + ServiceMonitor + PrometheusRule)" -ForegroundColor Gray
Write-Host "  - k8s-monitoring/ (AlertmanagerConfig)" -ForegroundColor Gray
Write-Host "  - argocd/ (GitOps applications)`n" -ForegroundColor Gray

Write-Host "========================================`n" -ForegroundColor Cyan
