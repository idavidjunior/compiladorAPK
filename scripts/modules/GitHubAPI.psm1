# ============================================================
# Módulo de Integração GitHub API com Resiliência
# Compilador APK v9.0
# ============================================================

# Importar módulo de resiliência
Import-Module (Join-Path $PSScriptRoot "Resiliency.psm1") -Force

<#
.SYNOPSIS
    Valida token GitHub
.DESCRIPTION
    Verifica se token é válido chamando endpoint /user
.PARAMETER Token
    Token GitHub pessoal
.OUTPUTS
    Hashtable com Valid (bool) e User (string)
#>
function Test-GitHubToken {
    param([string]$Token)
    
    $headers = @{ 
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    try {
        $response = Invoke-ResilientRestMethod -Uri "https://api.github.com/user" -Headers $headers -Method Get
        return @{ Valid = $true; User = $response.login }
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 401) {
            return @{ Valid = $false; User = $null; Error = "Token inválido" }
        }
        throw
    }
}

<#
.SYNOPSIS
    Verifica se repositório existe
.DESCRIPTION
    Checa se repositório existe via API
.PARAMETER Owner
    Dono do repositório
.PARAMETER Repo
    Nome do repositório
.PARAMETER Token
    Token GitHub
.OUTPUTS
    Boolean indicando se repositório existe
#>
function Test-GitHubRepository {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$Token
    )
    
    $headers = @{ 
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $uri = "https://api.github.com/repos/$Owner/$Repo"
    
    try {
        Invoke-ResilientRestMethod -Uri $uri -Headers $headers -Method Get -TimeoutSec 10 | Out-Null
        return $true
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            return $false
        }
        throw
    }
}

<#
.SYNOPSIS
    Cria repositório privado
.DESCRIPTION
    Cria novo repositório privado no GitHub
.PARAMETER RepoName
    Nome do repositório
.PARAMETER Token
    Token GitHub
.PARAMETER Description
    Descrição do repositório
.OUTPUTS
    URL do repositório criado
#>
function New-GitHubRepository {
    param(
        [string]$RepoName,
        [string]$Token,
        [string]$Description = "Temporary build repository"
    )
    
    $headers = @{ 
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $uri = "https://api.github.com/user/repos"
    $body = @{
        name = $RepoName
        description = $Description
        private = $true
        auto_init = $false
    } | ConvertTo-Json
    
    try {
        $response = Invoke-ResilientRestMethod -Uri $uri -Headers $headers -Method Post -Body $body -ContentType "application/json"
        return $response.html_url
    }
    catch {
        throw "Falha ao criar repositório: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Deleta repositório
.DESCRIPTION
    Deleta repositório do GitHub
.PARAMETER Owner
    Dono do repositório
.PARAMETER Repo
    Nome do repositório
.PARAMETER Token
    Token GitHub
#>
function Remove-GitHubRepository {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$Token
    )
    
    $headers = @{ 
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $uri = "https://api.github.com/repos/$Owner/$Repo"
    
    try {
        Invoke-ResilientRestMethod -Uri $uri -Headers $headers -Method Delete -TimeoutSec 10
    }
    catch {
        Write-Warning "Falha ao deletar repositório: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Obtém runs do workflow
.DESCRIPTION
    Lista runs de workflow do GitHub Actions
.PARAMETER Owner
    Dono do repositório
.PARAMETER Repo
    Nome do repositório
.PARAMETER Token
    Token GitHub
.PARAMETER PerPage
    Número de resultados por página (padrão: 5)
.OUTPUTS
    Objeto com workflow_runs
#>
function Get-GitHubWorkflowRuns {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$Token,
        [int]$PerPage = 5
    )
    
    $headers = @{ 
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $uri = "https://api.github.com/repos/$Owner/$Repo/actions/runs?per_page=$PerPage"
    
    return Invoke-ResilientRestMethod -Uri $uri -Headers $headers -Method Get
}

<#
.SYNOPSIS
    Obtém status de uma run específica
.DESCRIPTION
    Retorna detalhes de uma workflow run
.PARAMETER Owner
    Dono do repositório
.PARAMETER Repo
    Nome do repositório
.PARAMETER RunId
    ID da run
.PARAMETER Token
    Token GitHub
.OUTPUTS
    Objeto com detalhes da run
#>
function Get-GitHubWorkflowRun {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$RunId,
        [string]$Token
    )
    
    $headers = @{ 
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $uri = "https://api.github.com/repos/$Owner/$Repo/actions/runs/$RunId"
    
    return Invoke-ResilientRestMethod -Uri $uri -Headers $headers -Method Get
}

<#
.SYNOPSIS
    Obtém jobs de uma run
.DESCRIPTION
    Lista jobs de uma workflow run
.PARAMETER Owner
    Dono do repositório
.PARAMETER Repo
    Nome do repositório
.PARAMETER RunId
    ID da run
.PARAMETER Token
    Token GitHub
.OUTPUTS
    Objeto com jobs
#>
function Get-GitHubWorkflowJobs {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$RunId,
        [string]$Token
    )
    
    $headers = @{ 
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $uri = "https://api.github.com/repos/$Owner/$Repo/actions/runs/$RunId/jobs"
    
    return Invoke-ResilientRestMethod -Uri $uri -Headers $headers -Method Get
}

<#
.SYNOPSIS
    Obtém logs de um job
.DESCRIPTION
    Retorna logs de um job específico
.PARAMETER Owner
    Dono do repositório
.PARAMETER Repo
    Nome do repositório
.PARAMETER JobId
    ID do job
.PARAMETER Token
    Token GitHub
.OUTPUTS
    String com logs
#>
function Get-GitHubJobLogs {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$JobId,
        [string]$Token
    )
    
    $headers = @{ 
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $uri = "https://api.github.com/repos/$Owner/$Repo/actions/jobs/$JobId/logs"
    
    return Invoke-ResilientRestMethod -Uri $uri -Headers $headers -Method Get
}

<#
.SYNOPSIS
    Obtém artifacts de uma run
.DESCRIPTION
    Lista artifacts disponíveis de uma workflow run
.PARAMETER Owner
    Dono do repositório
.PARAMETER Repo
    Nome do repositório
.PARAMETER RunId
    ID da run
.PARAMETER Token
    Token GitHub
.OUTPUTS
    Objeto com artifacts
#>
function Get-GitHubRunArtifacts {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$RunId,
        [string]$Token
    )
    
    $headers = @{ 
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $uri = "https://api.github.com/repos/$Owner/$Repo/actions/runs/$RunId/artifacts"
    
    return Invoke-ResilientRestMethod -Uri $uri -Headers $headers -Method Get
}

<#
.SYNOPSIS
    Baixa artifact
.DESCRIPTION
    Download de artifact específico
.PARAMETER Owner
    Dono do repositório
.PARAMETER Repo
    Nome do repositório
.PARAMETER ArtifactId
    ID do artifact
.PARAMETER Token
    Token GitHub
.PARAMETER DestPath
    Caminho de destino
#>
function Download-GitHubArtifact {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$ArtifactId,
        [string]$Token,
        [string]$DestPath
    )
    
    $headers = @{ 
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    $uri = "https://api.github.com/repos/$Owner/$Repo/actions/artifacts/$ArtifactId/zip"
    
    # Obter URL de download
    $artifactInfo = Invoke-ResilientRestMethod -Uri $uri -Headers $headers -Method Get
    $downloadUrl = $artifactInfo.archive_download_url
    
    # Download com retry
    $scriptBlock = {
        param($Url, $Headers, $Path)
        Invoke-WebRequest -Uri $Url -Headers $Headers -OutFile $Path -UseBasicParsing
    }
    
    $retryCondition = {
        $statusCode = $_.Exception.Response.StatusCode.value__
        return ($statusCode -ge 500 -and $statusCode -lt 600) -or ($statusCode -eq 429)
    }
    
    Invoke-RetryWithBackoff -ScriptBlock $scriptBlock -MaxRetries 3 -RetryCondition $retryCondition -ArgumentList $downloadUrl, $headers, $DestPath
}

# Exportar funções
Export-ModuleMember -Function Test-GitHubToken, Test-GitHubRepository, New-GitHubRepository, Remove-GitHubRepository, Get-GitHubWorkflowRuns, Get-GitHubWorkflowRun, Get-GitHubWorkflowJobs, Get-GitHubJobLogs, Get-GitHubRunArtifacts, Download-GitHubArtifact
