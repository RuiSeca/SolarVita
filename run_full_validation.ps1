#!/usr/bin/env pwsh
# SolarVita Complete Validation Suite - PowerShell Version

Write-Host "🎯 SolarVita Complete Validation Suite" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📊 Starting comprehensive security validation..." -ForegroundColor Yellow
dart run_validation.dart all

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Validation completed successfully!" -ForegroundColor Green
    Write-Host "📄 Check these generated files:" -ForegroundColor White
    Write-Host "  - dissertation_validation_results.json" -ForegroundColor Gray
    Write-Host "  - dissertation_latex_tables.tex" -ForegroundColor Gray
    Write-Host "  - user_study_results.json (if applicable)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🎓 Your Chapter 8 data is ready!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Validation failed" -ForegroundColor Red
    Write-Host "Check the error messages above for details." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")