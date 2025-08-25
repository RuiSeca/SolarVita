#!/usr/bin/env pwsh
# SolarVita Validation Framework Test - PowerShell Version

Write-Host "🎯 SolarVita Validation Framework Test" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Testing compilation..." -ForegroundColor Yellow
dart test_compile.dart

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Compilation successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Available validation commands:" -ForegroundColor White
    Write-Host "  dart run_validation.dart all          - Complete validation suite" -ForegroundColor Gray
    Write-Host "  dart run_validation.dart dpi          - Direct Prompt Injection tests" -ForegroundColor Gray
    Write-Host "  dart run_validation.dart mai          - Medical Authority Impersonation tests" -ForegroundColor Gray
    Write-Host "  dart run_validation.dart icm          - Indirect Context Manipulation tests" -ForegroundColor Gray
    Write-Host "  dart run_validation.dart performance  - Performance impact analysis" -ForegroundColor Gray
    Write-Host "  dart run_validation.dart latex        - Generate LaTeX tables" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🎓 Ready to generate dissertation data!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Compilation test failed" -ForegroundColor Red
    Write-Host "Check for syntax errors in the validation framework files." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")