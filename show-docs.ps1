# Script hiển thị tất cả documentation
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  📚 GitOps Lab - Documentation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "📖 Available Documentation Files:`n" -ForegroundColor Yellow

$docs = @(
    @{Name="INDEX.md"; Desc="📋 Tổng hợp tất cả tài liệu"},
    @{Name="NEXT_STEPS.md"; Desc="🚀 Bước tiếp theo - Test ngay!"},
    @{Name="QUICKSTART.md"; Desc="⚡ Test nhanh 15 phút"},
    @{Name="FINAL_CHECKLIST.md"; Desc="✅ Checklist đầy đủ yêu cầu"},
    @{Name="README.md"; Desc="📝 Overview & architecture"},
    @{Name="DEPLOYMENT.md"; Desc="🛠️ Step-by-step deployment"},
    @{Name="TESTING.md"; Desc="🧪 Chi tiết test procedures"},
    @{Name="STATUS.md"; Desc="📊 Trạng thái hiện tại"},
    @{Name="SUMMARY.md"; Desc="🏆 Tổng kết & results"},
    @{Name="FILES_CREATED.md"; Desc="📦 Danh sách files"}
)

foreach ($doc in $docs) {
    if (Test-Path $doc.Name) {
        Write-Host "  ✅ " -NoNewline -ForegroundColor Green
        Write-Host "$($doc.Name)" -NoNewline -ForegroundColor White
        Write-Host " - $($doc.Desc)" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ " -NoNewline -ForegroundColor Red
        Write-Host "$($doc.Name)" -NoNewline -ForegroundColor White
        Write-Host " - Not found" -ForegroundColor Red
    }
}

Write-Host "`n🔧 Helper Scripts:`n" -ForegroundColor Yellow

$scripts = @(
    @{Name="check-status.ps1"; Desc="Kiểm tra status hệ thống"},
    @{Name="test-canary-success.ps1"; Desc="Test canary promote"},
    @{Name="test-canary-fail.ps1"; Desc="Test auto-rollback"},
    @{Name="test-git-rollback.ps1"; Desc="Test git revert"}
)

foreach ($script in $scripts) {
    if (Test-Path $script.Name) {
        Write-Host "  ✅ " -NoNewline -ForegroundColor Green
        Write-Host "$($script.Name)" -NoNewline -ForegroundColor White
        Write-Host " - $($script.Desc)" -ForegroundColor Gray
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  🎯 Recommended Reading Order" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "For Quick Test (15 min):" -ForegroundColor Yellow
Write-Host "  1. NEXT_STEPS.md" -ForegroundColor White
Write-Host "  2. Run: .\check-status.ps1" -ForegroundColor Green
Write-Host "  3. Follow test steps in NEXT_STEPS.md`n" -ForegroundColor White

Write-Host "For Full Understanding (30 min):" -ForegroundColor Yellow
Write-Host "  1. INDEX.md - Overview" -ForegroundColor White
Write-Host "  2. README.md - Architecture" -ForegroundColor White
Write-Host "  3. FINAL_CHECKLIST.md - Requirements" -ForegroundColor White
Write-Host "  4. NEXT_STEPS.md - Start testing`n" -ForegroundColor White

Write-Host "For Reference:" -ForegroundColor Yellow
Write-Host "  - STATUS.md - Current state" -ForegroundColor White
Write-Host "  - TESTING.md - Detailed procedures" -ForegroundColor White
Write-Host "  - SUMMARY.md - Full results`n" -ForegroundColor White

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🚀 Ready to Start!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Quick commands:" -ForegroundColor Yellow
Write-Host "  .\check-status.ps1              # Check system" -ForegroundColor Cyan
Write-Host "  code NEXT_STEPS.md              # Read next steps" -ForegroundColor Cyan
Write-Host "  .\test-canary-success.ps1       # Test canary`n" -ForegroundColor Cyan
