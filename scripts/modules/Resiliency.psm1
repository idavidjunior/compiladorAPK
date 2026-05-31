# ============================================================
# Módulo de Resiliência - Retry com Exponential Backoff e Circuit Breaker
# Compilador APK v9.0
# ============================================================

# Estado global do Circuit Breaker
$script:CircuitBreakerState = @{
    IsOpen = $false
    FailureCount = 0
    LastFailureTime = $null
    SuccessCount = 0
    Threshold = 5  # Número de falhas consecutivas para abrir circuito
    Timeout = 60   # Segundos para tentar fechar circuito novamente
    HalfOpenMaxSuccess = 3  # Sucessos necessários em half-open para fechar
}

<#
.SYNOPSIS
    Invoca uma função com retry com exponential backoff
.DESCRIPTION
    Executa uma função com retry automático usando exponential backoff com jitter
.PARAMETER ScriptBlock
    Bloco de script a ser executado
.PARAMETER MaxRetries
    Número máximo de tentativas (padrão: 3)
.PARAMETER InitialDelaySeconds
    Delay inicial em segundos (padrão: 1)
.PARAMETER MaxDelaySeconds
    Delay máximo em segundos (padrão: 30)
.PARAMETER RetryCondition
    Condição para retry (scriptblock que retorna $true se deve retry)
.EXAMPLE
    Invoke-RetryWithBackoff -ScriptBlock { Invoke-RestMethod -Uri "https://api.github.com/user" }
#>
function Invoke-RetryWithBackoff {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [int]$MaxRetries = 3,
        [int]$InitialDelaySeconds = 1,
        [int]$MaxDelaySeconds = 30,
        [scriptblock]$RetryCondition = { $true }
    )
    
    $attempt = 0
    $delay = $InitialDelaySeconds
    
    while ($attempt -le $MaxRetries) {
        try {
            $result = & $ScriptBlock
            return $result
        }
        catch {
            $attempt++
            
            # Verificar se deve retry
            $shouldRetry = & $RetryCondition
            
            if ($attempt -le $MaxRetries -and $shouldRetry) {
                # Exponential backoff com jitter (±25%)
                $jitter = Get-Random -Minimum 0.75 -Maximum 1.25
                $actualDelay = [Math]::Min($delay * $jitter, $MaxDelaySeconds)
                
                Write-Warning "Tentativa $attempt/$MaxRetries falhou. Retry em $([Math]::Round($actualDelay, 2))s. Erro: $($_.Exception.Message)"
                Start-Sleep -Seconds $actualDelay
                
                # Exponential backoff
                $delay = [Math]::Min($delay * 2, $MaxDelaySeconds)
            }
            else {
                throw $_
            }
        }
    }
}

<#
.SYNOPSIS
    Verifica se o circuit breaker está aberto
.DESCRIPTION
    Retorna $true se o circuit breaker estiver aberto (bloqueando chamadas)
#>
function Test-CircuitBreakerOpen {
    if (-not $script:CircuitBreakerState.IsOpen) {
        return $false
    }
    
    # Verificar se timeout expirou para tentar half-open
    $timeSinceFailure = (Get-Date) - $script:CircuitBreakerState.LastFailureTime
    if ($timeSinceFailure.TotalSeconds -gt $script:CircuitBreakerState.Timeout) {
        # Transição para half-open
        $script:CircuitBreakerState.IsOpen = $false
        $script:CircuitBreakerState.SuccessCount = 0
        Write-Warning "Circuit breaker transicionando para HALF-OPEN"
        return $false
    }
    
    return $true
}

<#
.SYNOPSIS
    Registra falha no circuit breaker
.DESCRIPTION
    Incrementa contador de falhas e abre circuito se threshold atingido
#>
function Register-CircuitBreakerFailure {
    $script:CircuitBreakerState.FailureCount++
    $script:CircuitBreakerState.LastFailureTime = Get-Date
    $script:CircuitBreakerState.SuccessCount = 0
    
    if ($script:CircuitBreakerState.FailureCount -ge $script:CircuitBreakerState.Threshold) {
        $script:CircuitBreakerState.IsOpen = $true
        Write-Error "Circuit breaker ABERTO após $($script:CircuitBreakerState.FailureCount) falhas consecutivas"
    }
}

<#
.SYNOPSIS
    Registra sucesso no circuit breaker
.DESCRIPTION
    Reseta contador de falhas ou incrementa sucessos em half-open
#>
function Register-CircuitBreakerSuccess {
    if ($script:CircuitBreakerState.FailureCount -gt 0) {
        # Reset em half-open após sucessos suficientes
        if ($script:CircuitBreakerState.SuccessCount -ge $script:CircuitBreakerState.HalfOpenMaxSuccess) {
            $script:CircuitBreakerState.FailureCount = 0
            $script:CircuitBreakerState.IsOpen = $false
            Write-Warning "Circuit breaker FECHADO após $($script:CircuitBreakerState.SuccessCount) sucessos consecutivos"
        }
        else {
            $script:CircuitBreakerState.SuccessCount++
        }
    }
}

<#
.SYNOPSIS
    Reseta o circuit breaker para estado fechado
.DESCRIPTION
    Força reset do circuit breaker (útil para testes ou recuperação manual)
#>
function Reset-CircuitBreaker {
    $script:CircuitBreakerState.IsOpen = $false
    $script:CircuitBreakerState.FailureCount = 0
    $script:CircuitBreakerState.LastFailureTime = $null
    $script:CircuitBreakerState.SuccessCount = 0
    Write-Warning "Circuit breaker resetado manualmente"
}

<#
.SYNOPSIS
    Obtém estado atual do circuit breaker
.DESCRIPTION
    Retorna objeto com estado atual para monitoramento
#>
function Get-CircuitBreakerState {
    return @{
        IsOpen = $script:CircuitBreakerState.IsOpen
        FailureCount = $script:CircuitBreakerState.FailureCount
        LastFailureTime = $script:CircuitBreakerState.LastFailureTime
        SuccessCount = $script:CircuitBreakerState.SuccessCount
        Threshold = $script:CircuitBreakerState.Threshold
        Timeout = $script:CircuitBreakerState.Timeout
    }
}

<#
.SYNOPSIS
    Wrapper para Invoke-RestMethod com retry e circuit breaker
.DESCRIPTION
    Executa chamada REST com resiliência automática
.PARAMETER Uri
    URI da requisição
.PARAMETER Method
    Método HTTP (Get, Post, etc)
.PARAMETER Headers
    Headers da requisição
.PARAMETER Body
    Body da requisição
.PARAMETER ContentType
    Content-Type
.PARAMETER TimeoutSec
    Timeout em segundos
.EXAMPLE
    Invoke-ResilientRestMethod -Uri "https://api.github.com/user" -Headers $headers -Method Get
#>
function Invoke-ResilientRestMethod {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Uri,
        
        [string]$Method = "Get",
        [hashtable]$Headers = @{},
        [string]$Body,
        [string]$ContentType,
        [int]$TimeoutSec = 30
    )
    
    # Verificar circuit breaker
    if (Test-CircuitBreakerOpen) {
        throw "Circuit breaker ABERTO - chamada bloqueada para $Uri"
    }
    
    $scriptBlock = {
        param($Uri, $Method, $Headers, $Body, $ContentType, $TimeoutSec)
        $params = @{
            Uri = $Uri
            Method = $Method
            Headers = $Headers
            TimeoutSec = $TimeoutSec
        }
        
        if ($Body) { $params.Body = $Body }
        if ($ContentType) { $params.ContentType = $ContentType }
        
        return Invoke-RestMethod @params
    }
    
    # Condição de retry: retry em erros transitórios (5xx, 429, timeout)
    $retryCondition = {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $isTransient = ($statusCode -ge 500 -and $statusCode -lt 600) -or 
                       ($statusCode -eq 429) -or
                       ($_.Exception.Message -match "timeout")
        return $isTransient
    }
    
    try {
        $result = Invoke-RetryWithBackoff -ScriptBlock $scriptBlock -MaxRetries 3 -RetryCondition $retryCondition -ArgumentList $Uri, $Method, $Headers, $Body, $ContentType, $TimeoutSec
        Register-CircuitBreakerSuccess
        return $result
    }
    catch {
        Register-CircuitBreakerFailure
        throw
    }
}

# Exportar funções
Export-ModuleMember -Function Invoke-RetryWithBackoff, Test-CircuitBreakerOpen, Register-CircuitBreakerFailure, Register-CircuitBreakerSuccess, Reset-CircuitBreaker, Get-CircuitBreakerState, Invoke-ResilientRestMethod
