# ============================================================
# Módulo de Armazenamento Seguro - Windows Credential Manager
# Compilador APK v9.0
# ============================================================

$CredentialTarget = "CompiladorAPK_GitHubToken"

<#
.SYNOPSIS
    Salva token GitHub no Windows Credential Manager
.DESCRIPTION
    Armazena token de forma segura usando Windows Credential Manager
.PARAMETER Token
    Token GitHub a ser salvo
.EXAMPLE
    Save-SecureToken -Token "ghp_xxxxxxxxxxxx"
#>
function Save-SecureToken {
    param([string]$Token)
    
    try {
        # Usar cmdkey para armazenar credencial
        $process = Start-Process -FilePath "cmdkey.exe" -ArgumentList "/generic:$CredentialTarget /user:GitHubToken /pass:$Token" -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Token salvo com segurança no Windows Credential Manager"
            return $true
        }
        else {
            throw "cmdkey retornou código de saída $($process.ExitCode)"
        }
    }
    catch {
        Write-Error "Falha ao salvar token: $($_.Exception.Message)"
        
        # Fallback para arquivo criptografado se Credential Manager falhar
        Write-Warning "Usando fallback para arquivo criptografado"
        return Save-TokenFallback -Token $Token
    }
}

<#
.SYNOPSIS
    Carrega token GitHub do Windows Credential Manager
.DESCRIPTION
    Recupera token armazenado no Windows Credential Manager
.OUTPUTS
    Token string ou $null se não encontrado
.EXAMPLE
    $token = Load-SecureToken
#>
function Load-SecureToken {
    try {
        # Usar cmdkey para ler credencial
        $process = Start-Process -FilePath "cmdkey.exe" -ArgumentList "/list:$CredentialTarget" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\cmdkey_output.txt" -RedirectStandardError "$env:TEMP\cmdkey_error.txt"
        
        if ($process.ExitCode -eq 0) {
            $output = Get-Content "$env:TEMP\cmdkey_output.txt" -Raw
            
            # Parse output para extrair token
            if ($output -match "Target: $CredentialTarget") {
                # Tentar extrair token do output
                if ($output -match "User: GitHubToken") {
                    # O token está na linha seguinte
                    $lines = $output -split "`n"
                    for ($i = 0; $i -lt $lines.Count; $i++) {
                        if ($lines[$i] -match "User: GitHubToken") {
                            if ($i + 1 -lt $lines.Count) {
                                $tokenLine = $lines[$i + 1]
                                if ($tokenLine -match "Password: (.+)") {
                                    Remove-Item "$env:TEMP\cmdkey_output.txt" -ErrorAction SilentlyContinue
                                    Remove-Item "$env:TEMP\cmdkey_error.txt" -ErrorAction SilentlyContinue
                                    return $matches[1].Trim()
                                }
                            }
                        }
                    }
                }
            }
            
            Remove-Item "$env:TEMP\cmdkey_output.txt" -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\cmdkey_error.txt" -ErrorAction SilentlyContinue
        }
        
        # Fallback para arquivo se Credential Manager não tiver token
        return Load-TokenFallback
    }
    catch {
        Write-Warning "Falha ao carregar do Credential Manager: $($_.Exception.Message)"
        return Load-TokenFallback
    }
}

<#
.SYNOPSIS
    Remove token do Windows Credential Manager
.DESCRIPTION
    Deleta credencial armazenada
.EXAMPLE
    Remove-SecureToken
#>
function Remove-SecureToken {
    try {
        $process = Start-Process -FilePath "cmdkey.exe" -ArgumentList "/delete:$CredentialTarget" -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Token removido do Windows Credential Manager"
            return $true
        }
        else {
            throw "cmdkey retornou código de saída $($process.ExitCode)"
        }
    }
    catch {
        Write-Error "Falha ao remover token: $($_.Exception.Message)"
        
        # Remover fallback também
        Remove-TokenFallback
        return $false
    }
}

<#
.SYNOPSIS
    Fallback para salvar token em arquivo criptografado
.DESCRIPTION
    Usa DPAPI para criptografar token em arquivo
.PARAMETER Token
    Token a ser salvo
#>
function Save-TokenFallback {
    param([string]$Token)
    
    try {
        $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $TokenFile = "$ScriptDir\token.dat"
        
        # Criptografar usando DPAPI (CurrentUser)
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Token)
        $encryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect(
            $bytes,
            $null,
            [System.Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        $encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)
        
        Set-Content -Path $TokenFile -Value $encryptedBase64 -Encoding ASCII -Force
        Write-Host "Token salvo em arquivo criptografado (fallback)"
        return $true
    }
    catch {
        Write-Error "Falha no fallback: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Fallback para carregar token de arquivo criptografado
.DESCRIPTION
    Descriptografa token usando DPAPI
.OUTPUTS
    Token string ou $null
#>
function Load-TokenFallback {
    try {
        $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $TokenFile = "$ScriptDir\token.dat"
        
        if (-not (Test-Path $TokenFile)) {
            return $null
        }
        
        $encryptedBase64 = Get-Content $TokenFile -Raw -Encoding ASCII
        $encryptedBytes = [System.Convert]::FromBase64String($encryptedBase64.Trim())
        
        $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
            $encryptedBytes,
            $null,
            [System.Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        
        $token = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
        return $token
    }
    catch {
        Write-Error "Falha ao carregar fallback: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Remove arquivo de fallback
.DESCRIPTION
    Deleta arquivo de token criptografado
#>
function Remove-TokenFallback {
    try {
        $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $TokenFile = "$ScriptDir\token.dat"
        
        if (Test-Path $TokenFile) {
            Remove-Item $TokenFile -Force
            Write-Host "Arquivo de fallback removido"
        }
    }
    catch {
        Write-Error "Falha ao remover fallback: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Verifica se token existe
.DESCRIPTION
    Checa se há token armazenado (Credential Manager ou fallback)
.OUTPUTS
    Boolean indicando se token existe
#>
function Test-SecureToken {
    $token = Load-SecureToken
    return $null -ne $token -and $token -ne ""
}

# Exportar funções
Export-ModuleMember -Function Save-SecureToken, Load-SecureToken, Remove-SecureToken, Test-SecureToken
