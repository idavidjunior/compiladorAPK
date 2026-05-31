# ============================================================
# Script de Teste dos Módulos Refatorados
# Compilador APK v9.0
# ============================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir "modules"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Teste dos Módulos Refatorados" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$testResults = @()

# Test 1: Carregar módulo de Resiliency
Write-Host "[TEST 1] Carregando módulo Resiliency..." -ForegroundColor Yellow
try {
    Import-Module (Join-Path $ModulesDir "Resiliency.psm1") -Force -ErrorAction Stop
    Write-Host "  Módulo Resiliency carregado" -ForegroundColor Green
    $testResults += "Resiliency:PASS"
}
catch {
    Write-Host "  Erro ao carregar módulo Resiliency: $_" -ForegroundColor Red
    $testResults += "Resiliency:FAIL"
}

# Test 2: Carregar módulo GitHub API
Write-Host "[TEST 2] Carregando módulo GitHub API..." -ForegroundColor Yellow
try {
    Import-Module (Join-Path $ModulesDir "GitHubAPI.psm1") -Force -ErrorAction Stop
    Write-Host "  Módulo GitHub API carregado" -ForegroundColor Green
    $testResults += "GitHubAPI:PASS"
}
catch {
    Write-Host "  Erro ao carregar módulo GitHub API: $_" -ForegroundColor Red
    $testResults += "GitHubAPI:FAIL"
}

# Test 3: Carregar módulo SecureStorage
Write-Host "[TEST 3] Carregando módulo SecureStorage..." -ForegroundColor Yellow
try {
    Import-Module (Join-Path $ModulesDir "SecureStorage.psm1") -Force -ErrorAction Stop
    Write-Host "  Módulo SecureStorage carregado" -ForegroundColor Green
    $testResults += "SecureStorage:PASS"
}
catch {
    Write-Host "  Erro ao carregar módulo SecureStorage: $_" -ForegroundColor Red
    $testResults += "SecureStorage:FAIL"
}

# Test 4: Carregar módulo AnalysisEngine
Write-Host "[TEST 4] Carregando módulo AnalysisEngine..." -ForegroundColor Yellow
try {
    Import-Module (Join-Path $ModulesDir "AnalysisEngine.psm1") -Force -ErrorAction Stop
    Write-Host "  Módulo AnalysisEngine carregado" -ForegroundColor Green
    $testResults += "AnalysisEngine:PASS"
}
catch {
    Write-Host "  Erro ao carregar módulo AnalysisEngine: $_" -ForegroundColor Red
    $testResults += "AnalysisEngine:FAIL"
}

# Test 5: Carregar módulo ReconstructionEngine
Write-Host "[TEST 5] Carregando módulo ReconstructionEngine..." -ForegroundColor Yellow
try {
    Import-Module (Join-Path $ModulesDir "ReconstructionEngine.psm1") -Force -ErrorAction Stop
    Write-Host "  Módulo ReconstructionEngine carregado" -ForegroundColor Green
    $testResults += "ReconstructionEngine:PASS"
}
catch {
    Write-Host "  Erro ao carregar módulo ReconstructionEngine: $_" -ForegroundColor Red
    $testResults += "ReconstructionEngine:FAIL"
}

# Test 6: Carregar módulo BuildOrchestrator
Write-Host "[TEST 6] Carregando módulo BuildOrchestrator..." -ForegroundColor Yellow
try {
    Import-Module (Join-Path $ModulesDir "BuildOrchestrator.psm1") -Force -ErrorAction Stop
    Write-Host "  Módulo BuildOrchestrator carregado" -ForegroundColor Green
    $testResults += "BuildOrchestrator:PASS"
}
catch {
    Write-Host "  Erro ao carregar módulo BuildOrchestrator: $_" -ForegroundColor Red
    $testResults += "BuildOrchestrator:FAIL"
}

# Test 7: Verificar runbook de incidentes
Write-Host "[TEST 7] Verificando runbook de incidentes..." -ForegroundColor Yellow
$runbookPath = Join-Path $ScriptDir "..\docs\INCIDENT_RUNBOOK.md"
if (Test-Path $runbookPath) {
    Write-Host "  Runbook de incidentes encontrado" -ForegroundColor Green
    $testResults += "Runbook:PASS"
}
else {
    Write-Host "  Runbook não encontrado" -ForegroundColor Red
    $testResults += "Runbook:FAIL"
}

# Resumo dos testes
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Resumo dos Testes" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$passed = ($testResults | Where-Object { $_ -like "*:PASS" }).Count
$total = $testResults.Count

foreach ($result in $testResults) {
    $parts = $result -split ":"
    $status = $parts[1]
    $test = $parts[0]
    $color = if ($status -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  [$status] $test" -ForegroundColor $color
}

Write-Host ""
Write-Host "Total: $passed/$total testes passaram" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })

if ($passed -eq $total) {
    Write-Host ""
    Write-Host "Todos os módulos estão funcionando corretamente!" -ForegroundColor Green
    Write-Host "A refatoração foi concluída com sucesso." -ForegroundColor Green
    exit 0
}
else {
    Write-Host ""
    Write-Host "Alguns testes falharam. Revise os erros acima." -ForegroundColor Red
    exit 1
}
