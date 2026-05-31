# ============================================================
# Módulo AIApiProvider - Provedor Genérico de APIs de IA
# Compilador APK v10.0 (Multi-AI Support)
# ============================================================

# Importar módulo de resiliência
Import-Module (Join-Path $PSScriptRoot "Resiliency.psm1") -Force -ErrorAction SilentlyContinue
# Importar módulo de armazenamento seguro
Import-Module (Join-Path $PSScriptRoot "SecureStorage.psm1") -Force -ErrorAction SilentlyContinue

# Configurações das IAs suportadas
$script:SupportedProviders = @{
    "OpenAI" = @{
        Name = "OpenAI"
        ApiUrl = "https://api.openai.com/v1/chat/completions"
        Model = "gpt-4"
        Models = @("gpt-4", "gpt-4-turbo", "gpt-3.5-turbo")
        Headers = @{
            "Content-Type" = "application/json"
        }
    }
    "Anthropic" = @{
        Name = "Anthropic (Claude)"
        ApiUrl = "https://api.anthropic.com/v1/messages"
        Model = "claude-3-sonnet-20240229"
        Models = @("claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307")
        Headers = @{
            "Content-Type" = "application/json"
            "anthropic-version" = "2023-06-01"
        }
    }
    "DeepSeek" = @{
        Name = "DeepSeek"
        ApiUrl = "https://api.deepseek.com/v1/chat/completions"
        Model = "deepseek-chat"
        Models = @("deepseek-chat", "deepseek-coder")
        Headers = @{
            "Content-Type" = "application/json"
        }
    }
    "Google" = @{
        Name = "Google Gemini"
        ApiUrl = "https://generativelanguage.googleapis.com/v1beta/models"
        Model = "gemini-pro"
        Models = @("gemini-pro", "gemini-pro-vision")
        Headers = @{
            "Content-Type" = "application/json"
        }
    }
}

# Provider e API Key atuais
$script:CurrentProvider = "DeepSeek"
$script:CurrentApiKey = $null

<#
.SYNOPSIS
    Lista todos os provedores de IA suportados
.OUTPUTS
    Array de strings com nomes dos provedores
#>
function Get-AIProviders {
    return $script:SupportedProviders.Keys | Sort-Object
}

<#
.SYNOPSIS
    Obtém configurações de um provedor específico
.PARAMETER Provider
    Nome do provedor
.OUTPUTS
    Hashtable com configurações do provedor
#>
function Get-AIProviderConfig {
    param([string]$Provider)
    
    if ($script:SupportedProviders.ContainsKey($Provider)) {
        return $script:SupportedProviders[$Provider]
    }
    
    return $null
}

<#
.SYNOPSIS
    Define o provedor de IA atual
.PARAMETER Provider
    Nome do provedor
.OUTPUTS
    Boolean indicando sucesso
#>
function Set-AIProvider {
    param([string]$Provider)
    
    if ($script:SupportedProviders.ContainsKey($Provider)) {
        $script:CurrentProvider = $Provider
        Write-Log "Provedor de IA definido: $Provider" "OK"
        return $true
    }
    
    Write-Log "Provedor não suportado: $Provider" "ERRO"
    return $false
}

<#
.SYNOPSIS
    Obtém o provedor atual
.OUTPUTS
    String com nome do provedor atual
#>
function Get-AIProvider {
    return $script:CurrentProvider
}

<#
.SYNOPSIS
    Define a API Key do provedor atual
.PARAMETER ApiKey
    API Key
.PARAMETER SaveSecurely
    Se true, salva no Credential Manager
.OUTPUTS
    Boolean indicando sucesso
#>
function Set-AIApiKey {
    param(
        [string]$ApiKey,
        [bool]$SaveSecurely = $true
    )
    
    if ([string]::IsNullOrEmpty($ApiKey)) {
        Write-Log "API Key não fornecida" "ERRO"
        return $false
    }
    
    $script:CurrentApiKey = $ApiKey
    
    if ($SaveSecurely) {
        $target = "AI_$($script:CurrentProvider)_API"
        Save-SecureToken -Token $ApiKey -Target $target
        Write-Log "API Key salva no Credential Manager para $script:CurrentProvider" "OK"
    } else {
        Write-Log "API Key configurada (temporária) para $script:CurrentProvider" "OK"
    }
    
    return $true
}

<#
.SYNOPSIS
    Obtém a API Key configurada
.OUTPUTS
    String com a API Key ou null
#>
function Get-AIApiKey {
    # Se já estiver em memória, retorna
    if ($script:CurrentApiKey) {
        return $script:CurrentApiKey
    }
    
    # Tenta carregar do Credential Manager
    try {
        $target = "AI_$($script:CurrentProvider)_API"
        $loadedKey = Load-SecureToken -Target $target
        if ($loadedKey) {
            $script:CurrentApiKey = $loadedKey
            return $loadedKey
        }
    } catch {
        # Falha silenciosa ao carregar do Credential Manager
    }
    
    return $null
}

<#
.SYNOPSIS
    Valida API Key do provedor atual
.DESCRIPTION
    Verifica se a API Key é válida fazendo uma chamada de teste
.OUTPUTS
    Hashtable com Valid (bool), Error (string) e Provider (string)
#>
function Test-AIApiKey {
    $apiKey = Get-AIApiKey
    if ([string]::IsNullOrEmpty($apiKey)) {
        return @{ Valid = $false; Error = "API Key não configurada"; Provider = $script:CurrentProvider }
    }
    
    $config = $script:SupportedProviders[$script:CurrentProvider]
    
    try {
        $headers = $config.Headers.Clone()
        $headers["Authorization"] = "Bearer $apiKey"
        
        # Payload de teste simples
        $body = @{
            model = $config.Model
            messages = @(
                @{
                    role = "user"
                    content = "test"
                }
            )
            max_tokens = 10
        }
        
        # Ajustar formato para Anthropic
        if ($script:CurrentProvider -eq "Anthropic") {
            $body = @{
                model = $config.Model
                max_tokens = 10
                messages = @(
                    @{
                        role = "user"
                        content = "test"
                    }
                )
            }
        }
        
        # Ajustar para Google Gemini
        if ($script:CurrentProvider -eq "Google") {
            $uri = "$($config.ApiUrl)/$($config.Model):generateContent?key=$apiKey"
            $body = @{
                contents = @(
                    @{
                        parts = @(
                            @{
                                text = "test"
                            }
                        )
                    }
                )
            }
            $jsonBody = $body | ConvertTo-Json -Depth 10
            $null = Invoke-RestMethod -Uri $uri -Method Post -Headers $config.Headers -Body $jsonBody
        } else {
            $jsonBody = $body | ConvertTo-Json -Depth 10
            $null = Invoke-RestMethod -Uri $config.ApiUrl -Method Post -Headers $headers -Body $jsonBody
        }
        
        return @{ Valid = $true; Provider = $script:CurrentProvider }
        
    } catch {
        if ($_.Exception.Response.StatusCode -eq 401) {
            return @{ Valid = $false; Error = "API Key inválida"; Provider = $script:CurrentProvider }
        } elseif ($_.Exception.Response.StatusCode -eq 429) {
            return @{ Valid = $false; Error = "Rate limit excedido"; Provider = $script:CurrentProvider }
        } else {
            return @{ Valid = $false; Error = "Erro na validação: $($_.Exception.Message)"; Provider = $script:CurrentProvider }
        }
    }
}

<#
.SYNOPSIS
    Remove API Key salva
.DESCRIPTION
    Remove a API Key do Credential Manager e da memória
#>
function Remove-AIApiKey {
    try {
        $target = "AI_$($script:CurrentProvider)_API"
        Remove-SecureToken -Target $target
        $script:CurrentApiKey = $null
        Write-Log "API Key removida para $script:CurrentProvider" "OK"
        return $true
    } catch {
        Write-Log "Erro ao remover API Key: $_" "ERRO"
        return $false
    }
}

<#
.SYNOPSIS
    Verifica se API Key está configurada
.OUTPUTS
    Boolean indicando se API Key está configurada
#>
function Test-AIApiKeyConfigured {
    $key = Get-AIApiKey
    return -not [string]::IsNullOrEmpty($key)
}

<#
.SYNOPSIS
    Analisa código usando IA
.DESCRIPTION
    Envia código para a IA que analisa, corrige erros e gera projeto Android completo
.PARAMETER CodeContent
    Conteúdo do código Kotlin
.PARAMETER PackageName
    Nome do package do projeto
.PARAMETER AppName
    Nome do aplicativo
.OUTPUTS
    Hashtable com projeto completo gerado pela IA
#>
function Invoke-AIAnalysis {
    param(
        [string]$CodeContent,
        [string]$PackageName,
        [string]$AppName
    )
    
    $apiKey = Get-AIApiKey
    if ([string]::IsNullOrEmpty($apiKey)) {
        Write-Log "API Key não configurada. Use Set-AIApiKey primeiro." "ERRO"
        return $null
    }
    
    $config = $script:SupportedProviders[$script:CurrentProvider]
    
    Write-Log "[IA] Enviando código para análise com $script:CurrentProvider..." "INFO"
    
    $headers = $config.Headers.Clone()
    $headers["Authorization"] = "Bearer $apiKey"
    
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
    
    try {
        $body = $null
        $uri = $config.ApiUrl
        
        # Formatar payload conforme o provedor
        if ($script:CurrentProvider -eq "Anthropic") {
            $body = @{
                model = $config.Model
                max_tokens = 16000
                messages = @(
                    @{
                        role = "user"
                        content = $prompt
                    }
                )
            }
        } elseif ($script:CurrentProvider -eq "Google") {
            $uri = "$($config.ApiUrl)/$($config.Model):generateContent?key=$apiKey"
            $body = @{
                contents = @(
                    @{
                        parts = @(
                            @{
                                text = $prompt
                            }
                        )
                    }
                )
                generationConfig = @{
                    temperature = 0.1
                    maxOutputTokens = 16000
                }
            }
        } else {
            # OpenAI e DeepSeek (formato compatível)
            $body = @{
                model = $config.Model
                messages = @(
                    @{
                        role = "user"
                        content = $prompt
                    }
                )
                temperature = 0.1
                max_tokens = 16000
            }
        }
        
        $jsonBody = $body | ConvertTo-Json -Depth 10
        
        # Usar Invoke-ResilientRestMethod se disponível
        if (Get-Command Invoke-ResilientRestMethod -ErrorAction SilentlyContinue) {
            $response = Invoke-ResilientRestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody -MaxRetries 3
        } else {
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody
        }
        
        # Extrair conteúdo da resposta conforme o provedor
        $jsonText = $null
        
        if ($script:CurrentProvider -eq "Anthropic") {
            $jsonText = $response.content[0].text
        } elseif ($script:CurrentProvider -eq "Google") {
            $jsonText = $response.candidates[0].content.parts[0].text
        } else {
            # OpenAI e DeepSeek
            $jsonText = $response.choices[0].message.content
        }
        
        # Extrair JSON da resposta
        $jsonMatch = [regex]::Match($jsonText, '```json\s*(.*?)\s*```', 'Singleline')
        if ($jsonMatch.Success) {
            $jsonText = $jsonMatch.Groups[1].Value
        }
        
        $result = $jsonText | ConvertFrom-Json
        
        Write-Log "[IA] Análise concluída com $script:CurrentProvider!" "OK"
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
    Corrige erros de compilação usando IA
.DESCRIPTION
    Envia logs de erro para a IA que sugere correções
.PARAMETER ErrorLog
    Logs de erro do Gradle
.PARAMETER SourceCode
    Código-fonte atual
.OUTPUTS
    Hashtable com correções sugeridas
#>
function Invoke-AIErrorCorrection {
    param(
        [string]$ErrorLog,
        [string]$SourceCode
    )
    
    $apiKey = Get-AIApiKey
    if ([string]::IsNullOrEmpty($apiKey)) {
        Write-Log "API Key não configurada para correção de erros" "ERRO"
        return $null
    }
    
    $config = $script:SupportedProviders[$script:CurrentProvider]
    
    Write-Log "[IA] Analisando erros com $script:CurrentProvider..." "INFO"
    
    $headers = $config.Headers.Clone()
    $headers["Authorization"] = "Bearer $apiKey"
    
    $prompt = @"
Analise os erros de compilação abaixo e sugira correções específicas:

ERROS:
```
$ErrorLog
```

CÓDIGO-FONTE:
```
$SourceCode
```

Forneça sua resposta em JSON neste formato:
{
    "errorType": "tipo do erro",
    "suggestedFix": "descrição da correção",
    "correctedCode": "código corrigido",
    "filesToModify": ["lista de arquivos para modificar"]
}

Seja específico e forneça código que possa ser aplicado diretamente.
"@
    
    try {
        $body = $null
        $uri = $config.ApiUrl
        
        if ($script:CurrentProvider -eq "Anthropic") {
            $body = @{
                model = $config.Model
                max_tokens = 8000
                messages = @(
                    @{
                        role = "user"
                        content = $prompt
                    }
                )
            }
        } elseif ($script:CurrentProvider -eq "Google") {
            $uri = "$($config.ApiUrl)/$($config.Model):generateContent?key=$apiKey"
            $body = @{
                contents = @(
                    @{
                        parts = @(
                            @{
                                text = $prompt
                            }
                        )
                    }
                )
                generationConfig = @{
                    temperature = 0.1
                    maxOutputTokens = 8000
                }
            }
        } else {
            $body = @{
                model = $config.Model
                messages = @(
                    @{
                        role = "user"
                        content = $prompt
                    }
                )
                temperature = 0.1
                max_tokens = 8000
            }
        }
        
        $jsonBody = $body | ConvertTo-Json -Depth 10
        
        if (Get-Command Invoke-ResilientRestMethod -ErrorAction SilentlyContinue) {
            $response = Invoke-ResilientRestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody -MaxRetries 3
        } else {
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody
        }
        
        $jsonText = $null
        
        if ($script:CurrentProvider -eq "Anthropic") {
            $jsonText = $response.content[0].text
        } elseif ($script:CurrentProvider -eq "Google") {
            $jsonText = $response.candidates[0].content.parts[0].text
        } else {
            $jsonText = $response.choices[0].message.content
        }
        
        $jsonMatch = [regex]::Match($jsonText, '```json\s*(.*?)\s*```', 'Singleline')
        if ($jsonMatch.Success) {
            $jsonText = $jsonMatch.Groups[1].Value
        }
        
        $result = $jsonText | ConvertFrom-Json
        
        Write-Log "[IA] Correção sugerida pelo $script:CurrentProvider" "OK"
        
        return $result
        
    } catch {
        Write-Log "[IA] Erro na correção: $($_.Exception.Message)" "ERRO"
        return $null
    }
}

# Exportar funções
Export-ModuleMember -Function Get-AIProviders, Get-AIProviderConfig, Set-AIProvider, Get-AIProvider, Set-AIApiKey, Get-AIApiKey, Test-AIApiKey, Remove-AIApiKey, Test-AIApiKeyConfigured, Invoke-AIAnalysis, Invoke-AIErrorCorrection
