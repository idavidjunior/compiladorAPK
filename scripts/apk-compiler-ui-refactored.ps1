# ============================================================
# Compilador APK v9.0 - UI Refatorada com Módulos
# BUILD: 250a8e3-REFACTORED
# ============================================================
# Esta versão usa os módulos separados para:
# - Resiliência (retry + circuit breaker)
# - GitHub API (integração resiliente)
# - SecureStorage (Credential Manager)
# - AnalysisEngine (diagnóstico)
# - ReconstructionEngine (estruturação)
# - BuildOrchestrator (compilação com timeout 30min)
# ============================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir "modules"

# Importar módulos
Import-Module (Join-Path $ModulesDir "SecureStorage.psm1") -Force
Import-Module (Join-Path $ModulesDir "AnalysisEngine.psm1") -Force
Import-Module (Join-Path $ModulesDir "ReconstructionEngine.psm1") -Force
Import-Module (Join-Path $ModulesDir "BuildOrchestrator.psm1") -Force

$host.UI.RawUI.WindowTitle = "Compilador APK v9.0 (Refatorado)"

$global:GitHubToken = $null
$global:LogTextBox = $null
$global:LblStatus = $null
$global:AnalysisReport = $null
$global:ReconstructionReport = $null

# ══════════════════════════════════════════════════════════════
# UTILIDADES
# ══════════════════════════════════════════════════════════════

function Write-Log {
    param([string]$msg, [string]$nivel = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $line = "[$ts][$nivel] $msg"
    Write-Host $line
    if ($null -ne $global:LogTextBox) {
        $c = $line
        $global:LogTextBox.Dispatcher.Invoke([System.Action]{
            $global:LogTextBox.AppendText($c + "`r`n")
            $global:LogTextBox.ScrollToEnd()
        }.GetNewClosure())
    }
}

function Set-StatusUI {
    param([string]$msg, [string]$cor = "#0078D7")
    if ($null -ne $global:LblStatus) {
        $m = $msg; $c = $cor
        $global:LblStatus.Dispatcher.Invoke([System.Action]{
            $global:LblStatus.Text = $m
            $global:LblStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($c)
        }.GetNewClosure())
    }
}

function Import-Token {
    if (Test-SecureToken) {
        $global:GitHubToken = Load-SecureToken
        Write-Log "Token carregado do Credential Manager" "OK"
        return $true
    }
    return $false
}

function Save-TokenUI([string]$token) {
    Save-SecureToken -Token $token
    $global:GitHubToken = $token
    Write-Log "Token salvo no Credential Manager" "OK"
}

# ══════════════════════════════════════════════════════════════
# WRAPPER PARA COMPATIBILIDADE COM UI EXISTENTE
# ══════════════════════════════════════════════════════════════

function Invoke-AnalysisEngineWrapper {
    param([string]$Conteudo, [string]$CaminhoFonte, [string]$TipoFonte)
    
    $result = Invoke-AnalysisEngine -Conteudo $Conteudo -CaminhoFonte $CaminhoFonte -TipoFonte $TipoFonte -GitHubToken $global:GitHubToken
    
    if ($null -ne $result) {
        $global:AnalysisReport = $result | ConvertFrom-Json
        return $result
    }
    return $null
}

function Invoke-ReconstructionEngineWrapper {
    param([string]$RootPath, [string]$Conteudo)
    
    $result = Invoke-ReconstructionEngine -RootPath $RootPath -Conteudo $Conteudo -AnalysisReport $global:AnalysisReport
    
    if ($null -ne $result) {
        $global:ReconstructionReport = $result | ConvertFrom-Json
        return $result
    }
    return $null
}

function Invoke-BuildOrchestratorWrapper {
    param([string]$RootPath)
    
    $logCallback = {
        param($msg)
        Write-Log $msg "INFO"
    }
    
    $result = Invoke-BuildOrchestrator -RootPath $RootPath -GitHubToken $global:GitHubToken -LogCallback $logCallback
    
    return $result
}

# ══════════════════════════════════════════════════════════════
# UI WPF (Simplificada para demonstração)
# ══════════════════════════════════════════════════════════════

# Nota: A UI completa WPF está no arquivo original apk-compiler-ui.ps1
# Esta versão refatorada demonstra como usar os módulos
# Para uso completo, integre estas funções na UI existente

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Compilador APK v9.0 - UI Refatorada" -ForegroundColor Cyan
Write-Host "  Módulos carregados com sucesso!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Módulos disponíveis:"
Write-Host "  - Resiliency (retry + circuit breaker)"
Write-Host "  - GitHub API (integração resiliente)"
Write-Host "  - SecureStorage (Credential Manager)"
Write-Host "  - AnalysisEngine (diagnóstico)"
Write-Host "  - ReconstructionEngine (estruturação)"
Write-Host "  - BuildOrchestrator (compilação com timeout 30min)"
Write-Host ""
Write-Host "Para usar a UI completa, execute:"
Write-Host "  .\abrir-interface.bat"
Write-Host ""
