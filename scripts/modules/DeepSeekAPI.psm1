# ============================================================
# Módulo DeepSeekAPI - Integração com IA Inteligente
# Compilador APK v10.0 (AI-Powered)
# ============================================================

# Importar módulo de resiliência para chamadas à API
Import-Module (Join-Path $PSScriptRoot "Resiliency.psm1") -Force -ErrorAction SilentlyContinue
# Importar módulo de armazenamento seguro
Import-Module (Join-Path $PSScriptRoot "SecureStorage.psm1") -Force -ErrorAction SilentlyContinue

# Configurações padrão da API DeepSeek
$script:DeepSeekAPIUrl = "https://api.deepseek.com/v1/chat/completions"
$script:DeepSeekModel = "deepseek-chat"

<#
.SYNOPSIS
    Define a API Key da DeepSeek
.DESCRIPTION
    Configura a API Key para chamadas à API DeepSeek e salva no Credential Manager
.PARAMETER ApiKey
    API Key da DeepSeek
.PARAMETER SaveSecurely
    Se true, salva no Credential Manager
#>
function Set-DeepSeekApiKey {
    param(
        [string]$ApiKey,
        [bool]$SaveSecurely = $true
    )
    
    if ([string]::IsNullOrEmpty($ApiKey)) {
        Write-Log "API Key não fornecida" "ERRO"
        return $false
    }
    
    $script:DeepSeekApiKey = $ApiKey
    
    if ($SaveSecurely) {
        Save-SecureToken -Token $ApiKey -Target "DeepSeekAPI"
        Write-Log "API Key configurada e salva no Credential Manager" "OK"
    } else {
        Write-Log "API Key configurada (temporária)" "OK"
    }
    
    return $true
}

<#
.SYNOPSIS
    Obtém a API Key configurada
.DESCRIPTION
    Retorna a API Key configurada ou carrega do Credential Manager se não estiver em memória
.OUTPUTS
    String com a API Key ou null
#>
function Get-DeepSeekApiKey {
    # Se já estiver em memória, retorna
    if ($script:DeepSeekApiKey) {
        return $script:DeepSeekApiKey
    }
    
    # Tenta carregar do Credential Manager
    try {
        $loadedKey = Load-SecureToken -Target "DeepSeekAPI"
        if ($loadedKey) {
            $script:DeepSeekApiKey = $loadedKey
            return $loadedKey
        }
    } catch {
        # Falha silenciosa ao carregar do Credential Manager
    }
    
    return $null
}

<#
.SYNOPSIS
    Analisa código Kotlin usando IA DeepSeek
.DESCRIPTION
    Envia código para a IA DeepSeek que analisa, corrige erros e gera projeto Android completo
.PARAMETER CodeContent
    Conteúdo do código Kotlin
.PARAMETER PackageName
    Nome do package do projeto
.PARAMETER AppName
    Nome do aplicativo
.OUTPUTS
    Hashtable com projeto completo gerado pela IA
#>
function Invoke-DeepSeekAnalysis {
    param(
        [string]$CodeContent,
        [string]$PackageName,
        [string]$AppName
    )
    
    $apiKey = Get-DeepSeekApiKey
    if ([string]::IsNullOrEmpty($apiKey)) {
        Write-Log "API Key não configurada. Use Set-DeepSeekApiKey primeiro." "ERRO"
        return $null
    }
    
    Write-Log "[IA] Enviando código para análise inteligente..." "INFO"
    
    $headers = @{
        "Authorization" = "Bearer $apiKey"
        "Content-Type" = "application/json"
    }
    
    $prompt = @"
Você é um engenheiro Android especialista. Analise o código Kotlin abaixo e:

1. Corrija TODOS os erros de sintaxe e imports.
2. Detecte TODAS as tecnologias usadas (Compose, Coil, DataStore, Serialization, MediaSession, Retrofit, Coroutines, Navigation, Room, Hilt, CameraX, WorkManager).
3. Gere um `app/build.gradle.kts` completo com TODAS as dependências necessárias.
4. Gere um `build.gradle.kts` (raiz) com plugins e configurações.
5. Gere um `AndroidManifest.xml` correto com permissões adequadas e android:exported="true".
6. Gere o `settings.gradle.kts`.
7. Corrija o código-fonte injetando imports faltantes.
8. Gere recursos básicos (strings.xml, themes.xml, layout básico).

Responda em JSON neste formato EXATO:
{
    "packageName": "com.exemplo.app",
    "mainActivityName": "MainActivity",
    "technologies": ["Jetpack Compose", "Coil"],
    "files": {
        "app/src/main/java/com/exemplo/app/MainActivity.kt": "código corrigido aqui",
        "app/build.gradle.kts": "gradle completo aqui",
        "build.gradle.kts": "gradle raiz aqui",
        "settings.gradle.kts": "settings aqui",
        "app/src/main/AndroidManifest.xml": "manifest aqui",
        "app/src/main/res/values/strings.xml": "<resources><string name=\"app_name\">$AppName</string></resources>",
        "app/src/main/res/values/themes.xml": "<resources><style name=\"Theme.App\" parent=\"Theme.Material3.DayNight.NoActionBar\"/></resources>",
        "app/src/main/res/layout/activity_main.xml": "layout básico com ConstraintLayout"
    },
    "permissions": ["INTERNET"],
    "minSdk": 24,
    "targetSdk": 35,
    "compileSdk": 35
}

IMPORTANTE:
- Use versões estáveis das dependências (não use + ou latest)
- Garanta que o código seja compilável
- Inclua todos os imports necessários
- Configure corretamente o manifest com android:exported

Código-fonte:
```kotlin
$CodeContent
```

Nome do app: $AppName
Package: $PackageName
"@
    
    $body = @{
        model = $script:DeepSeekModel
        messages = @(
            @{
                role = "user"
                content = $prompt
            }
        )
        temperature = 0.1
        max_tokens = 16000
    } | ConvertTo-Json -Depth 10
    
    try {
        # Usar Invoke-ResilientRestMethod se disponível
        if (Get-Command Invoke-ResilientRestMethod -ErrorAction SilentlyContinue) {
            $response = Invoke-ResilientRestMethod -Uri $script:DeepSeekAPIUrl -Method Post -Headers $headers -Body $body -MaxRetries 3
        } else {
            $response = Invoke-RestMethod -Uri $script:DeepSeekAPIUrl -Method Post -Headers $headers -Body $body
        }
        
        $jsonText = $response.choices[0].message.content
        
        # Extrair JSON da resposta
        $jsonMatch = [regex]::Match($jsonText, '```json\s*(.*?)\s*```', 'Singleline')
        if ($jsonMatch.Success) {
            $jsonText = $jsonMatch.Groups[1].Value
        }
        
        $result = $jsonText | ConvertFrom-Json
        
        Write-Log "[IA] Análise concluída!" "OK"
        Write-Log "[IA] Tecnologias detectadas: $($result.technologies -join ', ')" "INFO"
        Write-Log "[IA] Arquivos gerados: $(($result.files | Get-Member -MemberType NoteProperty).Count)" "INFO"
        
        return $result
        
    } catch {
        Write-Log "[IA] Erro na análise: $($_.Exception.Message)" "ERRO"
        return $null
    }
}

<#
.SYNOPSIS
    Valida API Key da DeepSeek
.DESCRIPTION
    Verifica se a API Key é válida fazendo uma chamada de teste
.PARAMETER ApiKey
    API Key a ser validada
.OUTPUTS
    Hashtable com Valid (bool) e Error (string)
#>
function Test-DeepSeekApiKey {
    param([string]$ApiKey)
    
    if ([string]::IsNullOrEmpty($ApiKey)) {
        return @{ Valid = $false; Error = "API Key não fornecida" }
    }
    
    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        model = $script:DeepSeekModel
        messages = @(
            @{
                role = "user"
                content = "Test"
            }
        )
        max_tokens = 10
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri $script:DeepSeekAPIUrl -Method Post -Headers $headers -Body $body
        return @{ Valid = $true }
    } catch {
        if ($_.Exception.Response.StatusCode -eq 401) {
            return @{ Valid = $false; Error = "API Key inválida" }
        } else {
            return @{ Valid = $false; Error = "Erro na validação: $($_.Exception.Message)" }
        }
    }
}

<#
.SYNOPSIS
    Remove API Key salva
.DESCRIPTION
    Remove a API Key do Credential Manager e da memória
#>
function Remove-DeepSeekApiKey {
    try {
        Remove-SecureToken -Target "DeepSeekAPI"
        $script:DeepSeekApiKey = $null
        Write-Log "API Key removida" "OK"
        return $true
    } catch {
        Write-Log "Erro ao remover API Key: $_" "ERRO"
        return $false
    }
}

<#
.SYNOPSIS
    Verifica se API Key está configurada
.DESCRIPTION
    Retorna true se a API Key estiver configurada
.OUTPUTS
    Boolean indicando se API Key está configurada
#>
function Test-DeepSeekApiKeyConfigured {
    $key = Get-DeepSeekApiKey
    return -not [string]::IsNullOrEmpty($key)
}

# Exportar funções
Export-ModuleMember -Function Set-DeepSeekApiKey, Get-DeepSeekApiKey, Invoke-DeepSeekAnalysis, Test-DeepSeekApiKey, Remove-DeepSeekApiKey, Test-DeepSeekApiKeyConfigured
