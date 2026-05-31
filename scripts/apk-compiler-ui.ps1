﻿﻿﻿﻿# ============================================================
# Compilador APK v10.0 - AI-Powered com DeepSeek
# BUILD: 250a8e3-AI
# ============================================================
# BOTÃO 1: ANALISAR (AnalysisEngine)
# BOTÃO 2: RECONSTRUIR (ReconstructionEngine)
# BOTÃO 3: GERAR APK (BuildOrchestrator)
# NOVO: INTEGRAÇÃO COM IA DEEPSEEK
# ============================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TokenFile = "$ScriptDir\token.dat"
$host.UI.RawUI.WindowTitle = "Compilador APK v10.0 (AI-Powered)"

$global:GitHubToken = $null
$global:LogTextBox = $null
$global:LblStatus = $null
$global:AnalysisReport = $null
$global:ReconstructionReport = $null
$global:DeepSeekApiKey = $null
$global:AIProvider = "DeepSeek"
$global:AIApiKey = $null

# Importar módulos
Import-Module (Join-Path $ScriptDir "modules\Resiliency.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $ScriptDir "modules\SecureStorage.psm1") -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $ScriptDir "modules\AIApiProvider.psm1") -Force -ErrorAction SilentlyContinue

# ══════════════════════════════════════════════════════════════
# SELF-HEALING ENGINE v9.0 - Variáveis Globais
# ══════════════════════════════════════════════════════════════
$global:SelfHealingEnabled = $true
$global:RecoveryHistory = @()
$global:CurrentBuildAttempt = 0
$global:MaxBuildAttempts = 3

# ══════════════════════════════════════════════════════════════
# UTILIDADES
# ══════════════════════════════════════════════════════════════

function Write-Log {
    param([string]$msg, [string]$nivel = "INFO", [switch]$Healed)
    $ts = Get-Date -Format "HH:mm:ss"
    if ($Healed) {
        $line = "[$ts][HEALED] $msg"
    } else {
        $line = "[$ts][$nivel] $msg"
    }
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
    if (Test-Path $TokenFile) {
        try {
            $enc = Get-Content $TokenFile -Raw -ErrorAction Stop
            $bytes = [System.Convert]::FromBase64String($enc.Trim())
            $global:GitHubToken = [System.Text.Encoding]::UTF8.GetString($bytes)
            Write-Log "Token carregado" "OK"
            return $true
        } catch { Write-Log "Falha ao carregar token" "AVISO" }
    }
    return $false
}

function Save-Token([string]$token) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($token)
    $enc = [System.Convert]::ToBase64String($bytes)
    Set-Content -Path $TokenFile -Value $enc -Encoding ASCII -Force
    Write-Log "Token salvo" "OK"
}

# ══════════════════════════════════════════════════════════════
# SELF-HEALING ENGINE v9.0 - Funções de Resiliência
# ══════════════════════════════════════════════════════════════

function Add-RecoveryHistory {
    param([string]$Strategy, [string]$Details)
    $entry = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Strategy = $Strategy
        Details = $Details
    }
    $global:RecoveryHistory += $entry
    # Atualizar UI se disponível
    if ($null -ne $panelRecoveryHistory) {
        $panelRecoveryHistory.Dispatcher.Invoke([System.Action]{
            Update-RecoveryHistoryUI
        }.GetNewClosure())
    }
}

function Invoke-DSLFallback {
    param([string]$RootPath)
    
    if (-not $global:SelfHealingEnabled) {
        Write-Log "Auto-Cura desativada. Pulando fallback DSL." "AVISO"
        return $false
    }
    
    Write-Log "Iniciando Fallback: Kotlin DSL → Groovy DSL" "INFO"
    
    try {
        # Converter build.gradle.kts para build.gradle
        $ktsFile = "$RootPath\build.gradle.kts"
        $gradleFile = "$RootPath\build.gradle"
        
        if (Test-Path $ktsFile) {
            $ktsContent = Get-Content $ktsFile -Raw -Encoding UTF8
            
            # Conversão básica de Kotlin DSL para Groovy DSL
            $groovyContent = $ktsContent -replace 'plugins \{', 'plugins {'
            $groovyContent = $groovyContent -replace 'id\("([^"]+)"\)', "'$1'"
            $groovyContent = $groovyContent -replace 'version\s*=\s*"([^"]+)"', "version '$1'"
            $groovyContent = $groovyContent -replace 'apply\s+plugin:\s*"([^"]+)"', "apply plugin: '$1'"
            
            Set-Content -Path $gradleFile -Value $groovyContent -Encoding UTF8
            Remove-Item $ktsFile -Force
            
            # Converter app/build.gradle.kts para app/build.gradle
            $appKtsFile = "$RootPath\app\build.gradle.kts"
            $appGradleFile = "$RootPath\app\build.gradle"
            
            if (Test-Path $appKtsFile) {
                $appKtsContent = Get-Content $appKtsFile -Raw -Encoding UTF8
                $appGroovyContent = $appKtsContent -replace 'id\("([^"]+)"\)', "'$1'"
                $appGroovyContent = $appGroovyContent -replace 'version\s*=\s*"([^"]+)"', "version '$1'"
                $appGroovyContent = $appGroovyContent -replace 'namespace\s*=\s*"([^"]+)"', "namespace '$1'"
                
                Set-Content -Path $appGradleFile -Value $appGroovyContent -Encoding UTF8
                Remove-Item $appKtsFile -Force
            }
            
            # Converter settings.gradle.kts para settings.gradle
            $settingsKtsFile = "$RootPath\settings.gradle.kts"
            $settingsGradleFile = "$RootPath\settings.gradle"
            
            if (Test-Path $settingsKtsFile) {
                $settingsKtsContent = Get-Content $settingsKtsFile -Raw -Encoding UTF8
                $settingsGroovyContent = $settingsKtsContent -replace 'include\("([^"]+)"\)', "include '$1'"
                
                Set-Content -Path $settingsGradleFile -Value $settingsGroovyContent -Encoding UTF8
                Remove-Item $settingsKtsFile -Force
            }
            
            Write-Log "Fallback DSL concluído com sucesso" "OK" -Healed
            Add-RecoveryHistory -Strategy "DSL Fallback" -Details "Kotlin DSL convertido para Groovy DSL"
            return $true
        }
        
        return $false
    } catch {
        Write-Log "Erro no fallback DSL: $($_.Exception.Message)" "ERRO"
        return $false
    }
}

function Invoke-PackageAutoRepair {
    param([string]$RootPath, [string]$Package)
    
    if (-not $global:SelfHealingEnabled) {
        Write-Log "Auto-Cura desativada. Pulando reparo de pacotes." "AVISO"
        return $false
    }
    
    Write-Log "Iniciando Auto-Reparo de Pacotes" "INFO"
    
    try {
        $pkgPath = $Package -replace '\.', '\'
        $javaDir = "$RootPath\app\src\main\java\$pkgPath"
        
        # Criar diretórios do pacote se não existirem
        if (-not (Test-Path $javaDir)) {
            New-Item -ItemType Directory -Force -Path $javaDir | Out-Null
            Write-Log "Diretório de pacote criado: $javaDir" "OK" -Healed
        }
        
        # Verificar e corrigir arquivos Kotlin - packages ausentes, corrompidos ou duplicados
        $ktFiles = Get-ChildItem -Path "$RootPath\app\src\main\java" -Filter "*.kt" -Recurse

        foreach ($ktFile in $ktFiles) {
            $content = Get-Content $ktFile.FullName -Raw -Encoding UTF8
            $modified = $false

            # ── 1. Remover package duplicado (dois "package " no arquivo) ──────────
            $packageMatches = [regex]::Matches($content, '(?m)^package\s+\S+')
            if ($packageMatches.Count -gt 1) {
                # Manter apenas a última declaração (a do código original)
                $lastPackage = $packageMatches[$packageMatches.Count - 1].Value
                # Remover todas as ocorrências e re-inserir a correta no topo
                $content = [regex]::Replace($content, '(?m)^package\s+\S+\r?\n?', '')
                $content = "$lastPackage`r`n`r`n" + $content.TrimStart()
                $modified = $true
                Write-Log "Package duplicado removido em $($ktFile.Name)" "OK" -Healed
            }

            # ── 2. Corrigir package com backslashes (ex: com\.seuplayer\.app) ─────
            if ($content -match '(?m)^package\s+([\w\\\.]+)') {
                $rawPkg = $matches[1]
                if ($rawPkg -match '\\') {
                    # Remover backslashes ilegais
                    $fixedPkg = $rawPkg -replace '\\', ''
                    # Remover pontos consecutivos gerados pela remoção
                    $fixedPkg = $fixedPkg -replace '\.{2,}', '.'
                    $content = $content -replace [regex]::Escape("package $rawPkg"), "package $fixedPkg"
                    $modified = $true
                    Write-Log "Package corrompido corrigido em $($ktFile.Name): $rawPkg -> $fixedPkg" "OK" -Healed
                }
            }

            # ── 3. Injetar package se completamente ausente ───────────────────────
            if ($content -notmatch '(?m)^package\s+') {
                $relativePath = $ktFile.FullName.Replace("$RootPath\app\src\main\java\", "").Replace(".kt", "")
                # CORREÇÃO: usar ponto literal, não '\\.' (que é regex)
                $filePackage = ($relativePath -split '\\') -join '.'
                # Remover o nome da classe do final (ultimo segmento é o arquivo, não o pacote)
                $pkgParts = $filePackage -split '\.'
                if ($pkgParts.Count -gt 1) {
                    $filePackage = ($pkgParts[0..($pkgParts.Count - 2)]) -join '.'
                }
                $content = "package $filePackage`r`n`r`n$content"
                $modified = $true
                Write-Log "Package injetado em $($ktFile.Name): $filePackage" "OK" -Healed
            }

            # ── 4. Remover linhas de comentário que ficaram antes do package ──────
            # (bloco de comentário # ... antes do package real)
            if ($content -match '(?s)^(#[^\n]*\n)+package\s+') {
                $content = [regex]::Replace($content, '(?s)^(#[^\n]*\n)+', '')
                $modified = $true
                Write-Log "Comentários inválidos removidos antes do package em $($ktFile.Name)" "OK" -Healed
            }

            if ($modified) {
                Set-Content -Path $ktFile.FullName -Value $content -Encoding UTF8
            }
        }
        
        # Sincronizar com AndroidManifest.xml
        $manifestPath = "$RootPath\app\src\main\AndroidManifest.xml"
        if (Test-Path $manifestPath) {
            $manifestContent = Get-Content $manifestPath -Raw -Encoding UTF8
            
            # Verificar se o package está correto no manifesto
            if ($manifestContent -match 'package="([^"]+)"') {
                $manifestPackage = $matches[1]
                if ($manifestPackage -ne $Package) {
                    $manifestContent = $manifestContent -replace "package=`"$manifestPackage`"", "package=`"$Package`""
                    Set-Content -Path $manifestPath -Value $manifestContent -Encoding UTF8
                    Write-Log "Manifesto sincronizado com pacote: $Package" "OK" -Healed
                }
            }
        }
        
        Add-RecoveryHistory -Strategy "Package Auto-Repair" -Details "Pacotes sincronizados e corrigidos"
        return $true
    } catch {
        Write-Log "Erro no reparo de pacotes: $($_.Exception.Message)" "ERRO"
        return $false
    }
}

function Invoke-JDKDowngrade {
    param([string]$RootPath)
    
    if (-not $global:SelfHealingEnabled) {
        Write-Log "Auto-Cura desativada. Pulando downgrade de JDK." "AVISO"
        return $false
    }
    
    Write-Log "Iniciando Downgrade Dinâmico: JDK 17 → JDK 11" "INFO"
    
    try {
        # Modificar workflow para usar JDK 11
        $workflowPath = "$RootPath\.github\workflows\android.yml"
        
        if (Test-Path $workflowPath) {
            $workflowContent = Get-Content $workflowPath -Raw -Encoding UTF8
            
            # Alterar Java 17 para Java 11
            $workflowContent = $workflowContent -replace 'java-version:\s*17', 'java-version: 11'
            $workflowContent = $workflowContent -replace 'Java 17', 'Java 11'
            
            Set-Content -Path $workflowPath -Value $workflowContent -Encoding UTF8
            
            Write-Log "JDK Downgrade aplicado no workflow" "OK" -Healed
            Add-RecoveryHistory -Strategy "JDK Downgrade" -Details "JDK 17 → JDK 11"
            return $true
        }
        
        return $false
    } catch {
        Write-Log "Erro no downgrade de JDK: $($_.Exception.Message)" "ERRO"
        return $false
    }
}

function Invoke-ManifestValidator {
    param([string]$RootPath)
    
    if (-not $global:SelfHealingEnabled) {
        Write-Log "Auto-Cura desativada. Pulando validação de manifesto." "AVISO"
        return $false
    }
    
    Write-Log "Iniciando Validação de Manifesto Android 12+" "INFO"
    
    try {
        $manifestPath = "$RootPath\app\src\main\AndroidManifest.xml"
        
        if (Test-Path $manifestPath) {
            $manifestContent = Get-Content $manifestPath -Raw -Encoding UTF8
            $modified = $false

            # ── 1. Detectar classes que são Services mas declaradas como <activity> ──
            # Escanear todos os .kt em busca de classes que estendem Service DO ANDROID
            # (não data class, não interface, não qualquer classe com "Service" no nome)
            $serviceClasses = @()
            $ktFiles = Get-ChildItem -Path "$RootPath\app\src\main\java" -Filter "*.kt" -Recurse -ErrorAction SilentlyContinue
            foreach ($kt in $ktFiles) {
                $ktContent = Get-Content $kt.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                # Padrão estrito: "class NomeQualquer : ... Service()" ou ": Service"
                # Excluir: data class, interface, abstract sealed que não instanciam Service
                $svcMatches = [regex]::Matches($ktContent,
                    '(?m)^(?!.*\bdata\b)(?!.*\binterface\b)class\s+(\w+)\s*[^{]*:\s*[^{,\n]*\b(?:android\.app\.)?Service\b')
                foreach ($m in $svcMatches) {
                    $serviceClasses += $m.Groups[1].Value
                    Write-Log "Service detectado no código: $($m.Groups[1].Value)" "INFO"
                }
            }

            # Para cada Service encontrado: se estiver em <activity>, mover para <service>
            foreach ($svcName in $serviceClasses) {
                # Padrão: <activity ... android:name="...SvcName..." ...> ... </activity>
                $actPattern = "(?s)<activity([^>]*android:name=""[^""]*$svcName[^""]*""[^>]*)>(.*?)</activity>"
                if ($manifestContent -match $actPattern) {
                    $attrs    = $matches[1] -replace 'android:exported=""true""', 'android:exported="false"'
                    # Remover intent-filter de launcher de dentro do service
                    $innerXml = $matches[2] -replace '(?s)<intent-filter>.*?</intent-filter>', ''
                    $serviceTag = "<service$attrs>$innerXml</service>"
                    $manifestContent = [regex]::Replace($manifestContent, $actPattern, $serviceTag)
                    $modified = $true
                    Write-Log "Service '$svcName' movido de <activity> para <service> no Manifest" "OK" -Healed
                }
                # Garantir que o <service> existe (se não estava no manifest ainda)
                if ($manifestContent -notmatch "android:name=""[^""]*$svcName[^""]*""") {
                    # Descobrir package completo do service lendo o arquivo
                    $svcFile = $ktFiles | Where-Object { $_.BaseName -eq $svcName } | Select-Object -First 1
                    $svcPackage = if ($svcFile) {
                        $pkgMatch = Select-String -Path $svcFile.FullName -Pattern '(?m)^package\s+(\S+)' | Select-Object -First 1
                        if ($pkgMatch) { "$($pkgMatch.Matches[0].Groups[1].Value).$svcName" } else { $svcName }
                    } else { $svcName }
                    $serviceEntry = "`n        <service android:name=""$svcPackage"" android:exported=""false"" />"
                    $manifestContent = $manifestContent -replace '</application>', "$serviceEntry`n    </application>"
                    $modified = $true
                    Write-Log "Declaração <service> adicionada para '$svcName'" "OK" -Healed
                }
            }

            # ── 2. Garantir que o launcher aponta para a MainActivity (Activity real) ──
            # Se o launcher estiver apontando para um Service, corrigir
            if ($manifestContent -match '<intent-filter>') {
                foreach ($svcName in $serviceClasses) {
                    $launcherOnService = "(?s)<activity[^>]*android:name=""[^""]*$svcName[^""]*""[^>]*>.*?<intent-filter>.*?LAUNCHER.*?</intent-filter>.*?</activity>"
                    if ($manifestContent -match $launcherOnService) {
                        # Remover intent-filter do service
                        $manifestContent = [regex]::Replace($manifestContent, $launcherOnService, "")
                        $modified = $true
                        Write-Log "Intent-filter LAUNCHER removido de Service '$svcName'" "OK" -Healed
                    }
                }
                # Garantir que a MainActivity tem o launcher
                if ($manifestContent -notmatch 'LAUNCHER') {
                    # Descobrir a Activity principal
                    $mainActivityFile = $ktFiles | Where-Object {
                        $c = Get-Content $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                        $c -match 'ComponentActivity|AppCompatActivity' -and $_.BaseName -notmatch 'Service'
                    } | Select-Object -First 1
                    $mainActivityName = if ($mainActivityFile) { $mainActivityFile.BaseName } else { "MainActivity" }
                    $mainPkg = if ($mainActivityFile) {
                        $p = Select-String -Path $mainActivityFile.FullName -Pattern '(?m)^package\s+(\S+)' | Select-Object -First 1
                        if ($p) { "$($p.Matches[0].Groups[1].Value).$mainActivityName" } else { $mainActivityName }
                    } else { $mainActivityName }
                    $launcherActivity = @"

        <activity
            android:name="$mainPkg"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
"@
                    $manifestContent = $manifestContent -replace '</application>', "$launcherActivity`n    </application>"
                    $modified = $true
                    Write-Log "Activity launcher '$mainActivityName' adicionada ao Manifest" "OK" -Healed
                }
            }

            # ── 3. android:exported obrigatório no Android 12+ ───────────────────
            if ($manifestContent -match '<activity[^>]*android:name="([^"]+)"[^>]*>.*?<intent-filter' ) {
                if ($manifestContent -notmatch '<activity[^>]*android:exported') {
                    $manifestContent = $manifestContent -replace '(<activity[^>]*)', '$1 android:exported="true"'
                    $modified = $true
                    Write-Log "android:exported injetado em activities com intent-filter" "OK" -Healed
                }
            }
            
            # ── 4. Package ausente no manifest: detectar do código .kt ────────────
            if ($manifestContent -notmatch 'package=') {
                # Tentar detectar o package real lendo os arquivos .kt
                $detectedPackage = "com.example.app"
                $ktFiles2 = Get-ChildItem -Path "$RootPath\app\src\main\java" -Filter "*.kt" -Recurse -ErrorAction SilentlyContinue
                foreach ($kt2 in $ktFiles2) {
                    $kt2Content = Get-Content $kt2.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                    if ($kt2Content -match '(?m)^package\s+([\w.]+)') {
                        $detectedPackage = $matches[1]
                        break
                    }
                }
                $manifestContent = $manifestContent -replace '<manifest', "<manifest package=`"$detectedPackage`""
                $modified = $true
                Write-Log "Package injetado no manifesto: $detectedPackage" "OK" -Healed
            }
            
            if ($modified) {
                Set-Content -Path $manifestPath -Value $manifestContent -Encoding UTF8
                Add-RecoveryHistory -Strategy "Manifest Validator" -Details "Services, launcher, android:exported e package validados"
            }
            
            return $true
        }
        
        return $false
    } catch {
        Write-Log "Erro na validação de manifesto: $($_.Exception.Message)" "ERRO"
        return $false
    }
}

function Invoke-PermissionInjector {
    param([string]$RootPath)
    
    if (-not $global:SelfHealingEnabled) {
        Write-Log "Auto-Cura desativada. Pulando injeção de permissões." "AVISO"
        return $false
    }
    
    Write-Log "Iniciando Auto-Injeção de Permissões Críticas" "INFO"
    
    try {
        $manifestPath = "$RootPath\app\src\main\AndroidManifest.xml"
        
        if (-not (Test-Path $manifestPath)) {
            return $false
        }
        
        $manifestContent = Get-Content $manifestPath -Raw -Encoding UTF8
        $modified = $false
        
        # Escanear arquivos Kotlin por imports de rede
        $ktFiles = Get-ChildItem -Path "$RootPath\app\src\main\java" -Filter "*.kt" -Recurse -ErrorAction SilentlyContinue
        
        $hasNetworkImports = $false
        foreach ($ktFile in $ktFiles) {
            $content = Get-Content $ktFile.FullName -Raw -Encoding UTF8
            if ($content -match 'import\s+(retrofit|okhttp|ktor|java\.net)') {
                $hasNetworkImports = $true
                break
            }
        }
        
        # Injetar permissão INTERNET se necessário
        if ($hasNetworkImports -and $manifestContent -notmatch 'INTERNET') {
            $permissionTag = '    <uses-permission android:name="android.permission.INTERNET" />'
            
            # Inserir após <manifest
            if ($manifestContent -match '(<manifest[^>]*>)') {
                $insertPosition = $manifestContent.IndexOf($matches[1]) + $matches[1].Length
                $manifestContent = $manifestContent.Insert($insertPosition, "`r`n$permissionTag")
                $modified = $true
                Write-Log "Permissão INTERNET injetada" "OK" -Healed
            }
        }
        
        # Verificar permissões comuns
        $commonPermissions = @(
            'READ_EXTERNAL_STORAGE',
            'WRITE_EXTERNAL_STORAGE',
            'CAMERA',
            'ACCESS_FINE_LOCATION',
            'ACCESS_COARSE_LOCATION'
        )
        
        foreach ($perm in $commonPermissions) {
            if ($manifestContent -match $perm) {
                # Verificar se a permissão está declarada
                if ($manifestContent -notmatch "android:name=`"android\.permission\.$perm`"") {
                    $permissionTag = "    <uses-permission android:name=`"android.permission.$perm`" />"
                    $manifestContent = $manifestContent -replace '(<manifest[^>]*>)', "$1`r`n$permissionTag"
                    $modified = $true
                    Write-Log "Permissão $perm injetada" "OK" -Healed
                }
            }
        }
        
        if ($modified) {
            Set-Content -Path $manifestPath -Value $manifestContent -Encoding UTF8
            Add-RecoveryHistory -Strategy "Permission Injector" -Details "Permissões críticas injetadas"
        }
        
        return $true
    } catch {
        Write-Log "Erro na injeção de permissões: $($_.Exception.Message)" "ERRO"
        return $false
    }
}

function Invoke-SelfHealingEngine {
    param([string]$RootPath, [string]$Package)
    
    if (-not $global:SelfHealingEnabled) {
        Write-Log "Self-Healing Engine desativado" "AVISO"
        return
    }
    
    Write-Log "=== Self-Healing Engine v9.0 Ativado ===" "INFO"
    
    # ManifestValidator já rodou no passo 10 do ReconstructionEngine com o
    # código do usuário no disco — não rodar de novo para evitar duplicidade
    Invoke-PermissionInjector -RootPath $RootPath
    Invoke-PackageAutoRepair -RootPath $RootPath -Package $Package
    
    Write-Log "=== Self-Healing Engine v9.0 Concluído ===" "INFO"
}

# ══════════════════════════════════════════════════════════════
# COGNITIVE AI SELF-HEALING ENGINE (OpenAI API Connection)
# ══════════════════════════════════════════════════════════════
function Invoke-AICognitiveHealer {
    param(
        [string]$ErrorLog,
        [string]$RootPath
    )
    
    Write-Log "AI-HEALER: Iniciando Diagnostico Cognitivo via IA..." "INFO"
    
    # 1. Obter chave da API do OpenAI
    $apiKey = $env:OPENAI_API_KEY
    $keyFile = "$PSScriptRoot\openai_key.dat"
    if ([string]::IsNullOrEmpty($apiKey) -and (Test-Path $keyFile)) {
        try {
            $enc = Get-Content $keyFile -Raw
            $bytes = [System.Convert]::FromBase64String($enc.Trim())
            $apiKey = [System.Text.Encoding]::UTF8.GetString($bytes)
        } catch {
            Write-Log "AI-HEALER: Falha ao descriptografar chave openai_key.dat" "AVISO"
        }
    }
    
    if ([string]::IsNullOrEmpty($apiKey)) {
        Write-Log "AI-HEALER: Chave de API da OpenAI nao configurada. Defina OPENAI_API_KEY ou crie openai_key.dat." "AVISO"
        return $false
    }
    
    # 2. Identificar o arquivo Kotlin que causou a falha no log do Gradle
    # Exemplo de log: e: file:///C:/workspace/app/src/main/java/com/agon/app/MainActivity.kt: (25, 10): Unresolved reference
    $failingFile = $null
    $errorLineNum = $null
    $errorMsg = ""
    
    if ($ErrorLog -match 'e: file:///(.*\.kt): \(([^,]+), [^\)]+\): (.*)') {
        $failingFile = $matches[1]
        $errorLineNum = $matches[2]
        $errorMsg = $matches[3]
    } elseif ($ErrorLog -match 'e: (.*\.kt): \(([^,]+), [^\)]+\): (.*)') {
        $failingFile = $matches[1]
        $errorLineNum = $matches[2]
        $errorMsg = $matches[3]
    }
    
    if ([string]::IsNullOrEmpty($failingFile) -or -not (Test-Path $failingFile)) {
        # Fallback: tentar encontrar qualquer arquivo .kt mencionado no log
        if ($ErrorLog -match '([\w\-\/\\\.]+\.kt)') {
            $potentialFile = $matches[1]
            if (Test-Path $potentialFile) {
                $failingFile = $potentialFile
            } else {
                # Tentar resolver caminho relativo
                $resolved = Get-ChildItem "$RootPath\app\src" -Filter (Split-Path $potentialFile -Leaf) -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($resolved) { $failingFile = $resolved.FullName }
            }
        }
    }
    
    if ([string]::IsNullOrEmpty($failingFile) -or -not (Test-Path $failingFile)) {
        Write-Log "AI-HEALER: Nao foi possivel mapear o arquivo Kotlin com erro no log do Gradle." "AVISO"
        return $false
    }
    
    Write-Log "AI-HEALER: Arquivo com erro identificado: $(Split-Path $failingFile -Leaf) (Linha $errorLineNum)" "INFO"
    Write-Log "AI-HEALER: Mensagem de Erro: $errorMsg" "INFO"
    
    # 3. Ler o código atual do arquivo com erro
    $originalCode = Get-Content $failingFile -Raw -Encoding UTF8
    
    # 4. Montar o prompt de cura cognitiva
    $systemPrompt = "Você é o Engenheiro de Autocura Cognitiva do Compilador Sintonize APK. Seu objetivo é analisar o erro de compilação do Gradle e corrigir o arquivo Kotlin fornecido. Você deve retornar APENAS o código Kotlin completo e corrigido do arquivo, pronto para ser gravado no disco. NÃO inclua nenhuma explicação, introdução, conclusão ou blocos de código em markdown (como ```kotlin). Apenas o código puro."
    
    $userPrompt = @"
ERRO DO COMPILADOR GRADLE:
$ErrorLog

ARQUIVO COM FALHA:
Caminho: $failingFile
Linha do Erro: $errorLineNum

CÓDIGO FONTE ATUAL:
$originalCode
"@

    $body = @{
        model = "gpt-4o-mini"
        messages = @(
            @{ role = "system"; content = $systemPrompt },
            @{ role = "user"; content = $userPrompt }
        )
        temperature = 0.1
    } | ConvertTo-Json -Depth 10
    
    # 5. Fazer a chamada à API da OpenAI
    try {
        Write-Log "AI-HEALER: Enviando contexto para a IA para cura cirurgica..." "INFO"
        
        $headers = @{
            "Authorization" = "Bearer $apiKey"
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body $body -TimeoutSec 45
        
        $correctedCode = $response.choices[0].message.content.Trim()
        
        # Limpar possíveis tags de markdown se a IA ignorar a instrução estrita
        if ($correctedCode.StartsWith('```')) {
            $correctedCode = $correctedCode -replace '^```kotlin\r?\n?', ''
            $correctedCode = $correctedCode -replace '^```\r?\n?', ''
            $correctedCode = $correctedCode -replace '\r?\n?```$', ''
        }
        
        if ([string]::IsNullOrEmpty($correctedCode) -or $correctedCode.Length -lt 20) {
            Write-Log "AI-HEALER: Resposta da IA invalida ou vazia." "ERRO"
            return $false
        }
        
        # 6. Gravar o arquivo corrigido no disco
        Set-Content -Path $failingFile -Value $correctedCode -Encoding UTF8
        
        Write-Log "AI-HEALER: Arquivo $(Split-Path $failingFile -Leaf) corrigido com sucesso pela IA!" "OK" -Healed
        Add-RecoveryHistory -Strategy "AICognitiveHealer" -Details "Corrigido erro '$errorMsg' no arquivo '$(Split-Path $failingFile -Leaf)' via OpenAI GPT-4o-mini."
        
        return $true
    } catch {
        Write-Log "AI-HEALER: Erro na comunicacao com a API da OpenAI: $($_.Exception.Message)" "ERRO"
        return $false
    }
}

# ══════════════════════════════════════════════════════════════
# BLOCO 1: ANALYSISENGINE
# ══════════════════════════════════════════════════════════════

function Test-GitHubToken {
    param([string]$Token)
    
    if ([string]::IsNullOrEmpty($Token)) {
        return @{ Valid = $false; Error = "Token não fornecido" }
    }
    
    $headers = @{ "Authorization" = "Bearer $Token"; "Accept" = "application/vnd.github.v3+json" }
    
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -Method Get -ErrorAction Stop
        return @{ Valid = $true; User = $response.login }
    } catch {
        if ($_.Exception.Response.StatusCode -eq 401) {
            return @{ Valid = $false; Error = "Token inválido ou expirado" }
        } elseif ($_.Exception.Response.StatusCode -eq 403) {
            return @{ Valid = $false; Error = "Token sem permissões suficientes" }
        } else {
            return @{ Valid = $false; Error = "Erro na validação: $($_.Exception.Message)" }
        }
    }
}

function Invoke-InputGateway {
    param([string]$Source, [string]$SourceType)
    
    $result = @{ Tipo = $SourceType; TempDir = $null; Caminho = $null; MimeType = $null }
    
    try {
        switch ($SourceType) {
            "COLADO" { 
                $result.Caminho = "MEMORIA"
                $result.MimeType = "text/plain"
                Write-Log "Código colado" "OK" 
            }
            "ZIP" {
                if (-not (Test-Path $Source)) { throw "ZIP não encontrado" }
                $size = (Get-Item $Source).Length
                if ($size -gt 500MB) { throw "Arquivo muito grande (>500MB)" }
                $tempDir = Join-Path $env:TEMP "apk-$(Get-Date -Format 'yyyyMMddHHmmss')"
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                Expand-Archive -Path $Source -DestinationPath $tempDir -Force
                $result.TempDir = $tempDir
                $result.MimeType = "application/zip"
                Write-Log "ZIP extraido: $([math]::Round($size / 1MB, 2)) MB" "OK"
            }
            "PASTA" {
                if (-not (Test-Path $Source)) { throw "Pasta não encontrada" }
                $result.TempDir = $Source
                $result.MimeType = "directory"
                Write-Log "Pasta lida" "OK"
            }
            "TXT" {
                if (-not (Test-Path $Source)) { throw "TXT não encontrado" }
                $result.Caminho = $Source
                $result.MimeType = "text/plain"
                Write-Log "TXT carregado" "OK"
            }
            "GITHUB" {
                $result.Caminho = $Source
                $result.MimeType = "url"
                Write-Log "URL GitHub detectada" "OK"
            }
            "APK" {
                if (-not (Test-Path $Source)) { throw "APK não encontrado" }
                $tempDir = Join-Path $env:TEMP "apk-$(Get-Date -Format 'yyyyMMddHHmmss')"
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                $result.TempDir = $tempDir
                $result.MimeType = "application/vnd.android.package-archive"
                Write-Log "APK carregado (requer descompilação)" "AVISO"
            }
        }
        return $result
    } catch {
        Write-Log "InputGateway ERRO: $_" "ERRO"
        return $null
    }
}

function Invoke-ExtractionEngine {
    param([string]$Source, [string]$MimeType)
    
    $content = ""
    
    try {
        switch ($MimeType) {
            "text/plain" {
                if (Test-Path $Source) {
                    $content = Get-Content $Source -Raw -Encoding UTF8
                }
            }
            "application/vnd.android.package-archive" {
                Write-Log "APK descompilação não implementada" "AVISO"
            }
            "url" {
                Write-Log "Clone GitHub não implementado" "AVISO"
            }
        }
        return $content
    } catch {
        Write-Log "ExtractionEngine ERRO: $_" "ERRO"
        return ""
    }
}

function Invoke-TechnologyDetector {
    param([string]$RootPath, [string]$Conteudo)
    
    $techs = @{ Linguagens = @(); Frameworks = @(); BuildTools = @(); Plataformas = @() }
    
    # Linguagens
    if (($Conteudo -match 'fun\s|val\s|var\s') -or (Get-ChildItem "$RootPath/*.kt" -ErrorAction SilentlyContinue)) {
        $techs.Linguagens += "Kotlin"
    }
    if (($Conteudo -match 'public class|import java\.') -or (Get-ChildItem "$RootPath/*.java" -ErrorAction SilentlyContinue)) {
        $techs.Linguagens += "Java"
    }
    if ($Conteudo -match 'import io\.flutter\.|Widget build') {
        $techs.Linguagens += "Dart"
        $techs.Frameworks += "Flutter"
    }
    if ($Conteudo -match 'import React|from ''react''|export default') {
        $techs.Linguagens += "JavaScript/TypeScript"
        $techs.Frameworks += "React Native"
    }
    if ($Conteudo -match '@Capacitor\.|import \@capacitor') {
        $techs.Frameworks += "Capacitor"
    }
    if ($Conteudo -match 'cordova\.plugin|deviceready') {
        $techs.Frameworks += "Cordova"
    }
    if ($Conteudo -match 'from kivy|import kivy') {
        $techs.Linguagens += "Python"
        $techs.Frameworks += "Kivy"
    }
    if ($Conteudo -match 'UnityEngine|using UnityEngine') {
        $techs.Linguagens += "C#"
        $techs.Frameworks += "Unity"
    }
    
    # Build Tools
    if (Test-Path "$RootPath/build.gradle*" -ErrorAction SilentlyContinue) {
        $techs.BuildTools += "Gradle"
    }
    if (Test-Path "$RootPath/pubspec.yaml" -ErrorAction SilentlyContinue) {
        $techs.BuildTools += "Flutter"
    }
    if (Test-Path "$RootPath/package.json" -ErrorAction SilentlyContinue) {
        $techs.BuildTools += "npm"
    }
    
    # Frameworks Android
    if ($Conteudo -match 'Composable|@Composable|setContent') {
        $techs.Frameworks += "Jetpack Compose"
    }
    if ($Conteudo -match 'androidx\.') {
        $techs.Frameworks += "AndroidX"
    }
    if ($Conteudo -match '<manifest|<activity') {
        $techs.Frameworks += "XML Android"
    }
    
    # Plataformas
    if (($techs.Frameworks -contains "Flutter") -or ($techs.Frameworks -contains "React Native") -or ($techs.Frameworks -contains "Capacitor") -or ($techs.Frameworks -contains "Cordova")) {
        $techs.Plataformas += "Híbrido"
    } else {
        $techs.Plataformas += "Android Native"
    }
    
    Write-Log "Tecnologias: Linguagens=$(($techs.Linguagens | Select-Object -Unique) -join ', '); Frameworks=$(($techs.Frameworks | Select-Object -Unique) -join ', ')" "OK"
    return $techs
}

function Invoke-StructureScanner {
    param([string]$RootPath)
    
    $estrutura = @{
        AndroidManifest = $false
        BuildGradle = $false
        SettingsGradle = $false
        Gradlew = $false
        GradlewBat = $false
        AppDir = $false
        SrcMain = $false
        ResDir = $false
        MainActivity = $false
        PackageName = $null
        Assets = $false
        Dependencies = $false
    }
    
    $estrutura.AndroidManifest = (Test-Path "$RootPath/app/src/main/AndroidManifest.xml") -or (Test-Path "$RootPath/AndroidManifest.xml")
    $estrutura.BuildGradle = (Test-Path "$RootPath/app/build.gradle*") -or (Test-Path "$RootPath/build.gradle*")
    $estrutura.SettingsGradle = Test-Path "$RootPath/settings.gradle*"
    $estrutura.Gradlew = Test-Path "$RootPath/gradlew"
    $estrutura.GradlewBat = Test-Path "$RootPath/gradlew.bat"
    $estrutura.AppDir = Test-Path "$RootPath/app"
    $estrutura.SrcMain = Test-Path "$RootPath/app/src/main"
    $estrutura.ResDir = Test-Path "$RootPath/app/src/main/res"
    $estrutura.Assets = Test-Path "$RootPath/app/src/main/assets"
    
    # Detectar MainActivity
    $mainActivity = Get-ChildItem "$RootPath" -Recurse -Filter "MainActivity.*" -ErrorAction SilentlyContinue | Select-Object -First 1
    $estrutura.MainActivity = $null -ne $mainActivity
    
    # Detectar package name
    $manifest = if (Test-Path "$RootPath/app/src/main/AndroidManifest.xml") { "$RootPath/app/src/main/AndroidManifest.xml" } elseif (Test-Path "$RootPath/AndroidManifest.xml") { "$RootPath/AndroidManifest.xml" } else { $null }
    if ($manifest) {
        $manifestContent = Get-Content $manifest -Raw
        if ($manifestContent -match 'package="([^"]+)"') {
            $estrutura.PackageName = $Matches[1]
        }
    }
    
    Write-Log "Estrutura: Manifest=$($estrutura.AndroidManifest); Gradle=$($estrutura.BuildGradle); App=$($estrutura.AppDir)" "OK"
    return $estrutura
}

function Invoke-DependencyScanner {
    param([string]$GradlePath)
    
    $deps = @()
    $versionIssues = @()
    $missingDeps = @()
    
    if (-not (Test-Path $GradlePath)) { 
        $missingDeps += "build.gradle"
        return @{ Dependencies = $deps; VersionIssues = $versionIssues; Missing = $missingDeps }
    }
    
    $content = Get-Content $GradlePath -Raw
    $patterns = @{ 
        "AndroidX" = "androidx"
        "Firebase" = "firebase"
        "Retrofit" = "retrofit"
        "OkHttp" = "okhttp"
        "Compose" = "compose"
        "Kotlin Coroutines" = "kotlinx-coroutines"
        "Lifecycle" = "lifecycle"
        "Material Design" = "material"
    }
    
    foreach ($name in $patterns.Keys) {
        if ($content -match $patterns[$name]) { $deps += $name }
    }
    
    # Detect version incompatibilities
    if ($content -match 'compileSdk\s+(\d+)') {
        $sdk = [int]$Matches[1]
        if ($sdk -lt 33) { $versionIssues += "compileSdk $sdk obsoleto (mínimo: 33)" }
    }
    if ($content -match 'targetSdk\s+(\d+)') {
        $sdk = [int]$Matches[1]
        if ($sdk -lt 33) { $versionIssues += "targetSdk $sdk obsoleto (mínimo: 33)" }
    }
    
    Write-Log "Dependências: $($deps -join ', '); Problemas: $($versionIssues.Count)" "OK"
    return @{ Dependencies = $deps; VersionIssues = $versionIssues; Missing = $missingDeps }
}

function Invoke-ErrorScanner {
    param([string]$Conteudo, [string]$RootPath)
    
    $erros = @()
    
    # Imports inválidos
    if ($Conteudo -match 'import\s+[^;]+$') {
        $erros += @{ Severidade = "ALTA"; Msg = "Import sem ponto e vírgula" }
    }
    if ($Conteudo -match 'android\.support\.') {
        $erros += @{ Severidade = "ALTA"; Msg = "android.support detectado (deve ser androidx)" }
    }
    
    # Package inválido
    if ($Conteudo -notmatch 'package\s+[\w.]+') {
        $erros += @{ Severidade = "CRITICA"; Msg = "Package não declarado" }
    }
    
    # Activity ausente
    if ($Conteudo -notmatch 'class.*Activity') {
        $erros += @{ Severidade = "CRITICA"; Msg = "Activity não encontrada" }
    }
    
    # SDK incompatível
    if ($Conteudo -match 'minSdkVersion\s+(\d+)') {
        $sdk = [int]$Matches[1]
        if ($sdk -lt 21) { $erros += @{ Severidade = "MEDIA"; Msg = "minSdk $sdk muito baixo" } }
    }
    
    # Gradle ausente
    if ((-not (Test-Path "$RootPath/build.gradle*" -ErrorAction SilentlyContinue)) -and (-not (Test-Path "$RootPath/app/build.gradle*" -ErrorAction SilentlyContinue))) {
        $erros += @{ Severidade = "CRITICA"; Msg = "Gradle ausente" }
    }
    
    # Manifest ausente
    if ((-not (Test-Path "$RootPath/app/src/main/AndroidManifest.xml" -ErrorAction SilentlyContinue)) -and (-not (Test-Path "$RootPath/AndroidManifest.xml" -ErrorAction SilentlyContinue))) {
        $erros += @{ Severidade = "CRITICA"; Msg = "AndroidManifest.xml ausente" }
    }
    
    # Recursos órfãos
    $resDir = "$RootPath/app/src/main/res"
    if (Test-Path $resDir) {
        $layoutFiles = Get-ChildItem "$resDir/layout" -Filter "*.xml" -ErrorAction SilentlyContinue
        foreach ($layout in $layoutFiles) {
            $content = Get-Content $layout.FullName -Raw
            if ($content -match '@\+id/(\w+)') {
                $erros += @{ Severidade = "BAIXA"; Msg = "Possível referência órfã: $($Matches[1])" }
            }
        }
    }
    
    # Encoding inválido
    try {
        [System.IO.File]::ReadAllText($RootPath + "\dummy.txt") | Out-Null
    } catch {
        $erros += @{ Severidade = "MEDIA"; Msg = "Possível problema de encoding" }
    }
    
    # Conflitos de namespace
    if ($Conteudo -match 'import\s+android\..*;\s*import\s+androidx\.') {
        $erros += @{ Severidade = "ALTA"; Msg = "Conflito de namespace (android e androidx)" }
    }
    
    Write-Log "Erros: $($erros.Count) (CRÍTICAS: $(($erros | Where-Object { $_.Severidade -eq 'CRITICA' }).Count))" "OK"
    return $erros
}

function Invoke-IntegrityAnalyzer {
    param($Erros)
    
    $integridade = 100
    foreach ($e in $Erros) {
        if ($e.Severidade -eq "CRITICA") { $integridade -= 25 }
        elseif ($e.Severidade -eq "ALTA") { $integridade -= 15 }
    }
    if ($integridade -lt 0) { $integridade = 0 }
    
    Write-Log "Integridade: $integridade%" "OK"
    return @{ Percentual = $integridade; Compilavel = ($integridade -ge 75) }
}

function Invoke-DiagnosticReportGenerator {
    param($Techs, $Estrutura, $Deps, $Erros, $Integridade)
    
    $tipoProjeto = if ($Techs.Plataformas -contains "Híbrido") { "Híbrido" } else { "Android Native" }
    $framework = if ($Techs.Frameworks.Count -gt 0) { $Techs.Frameworks[0] } else { "Desconhecido" }
    $linguagem = if ($Techs.Linguagens.Count -gt 0) { $Techs.Linguagens[0] } else { "Desconhecido" }
    
    $arquivosAusentes = @()
    if (-not $Estrutura.AndroidManifest) { $arquivosAusentes += "AndroidManifest.xml" }
    if (-not $Estrutura.BuildGradle) { $arquivosAusentes += "build.gradle" }
    if (-not $Estrutura.MainActivity) { $arquivosAusentes += "MainActivity" }
    if (-not $Estrutura.Gradlew) { $arquivosAusentes += "gradlew" }
    
    $acoesNecessarias = @()
    foreach ($erro in $Erros) {
        if ($erro.Severidade -eq "CRITICA") {
            $acoesNecessarias += "Corrigir: $($erro.Msg)"
        }
    }
    if ($Deps.VersionIssues.Count -gt 0) {
        $acoesNecessarias += "Atualizar versões SDK"
    }
    
    $relatorio = @{
        tipoProjeto = $tipoProjeto
        framework = $framework
        linguagem = $linguagem
        integridade = $Integridade.Percentual
        compilavel = $Integridade.Compilavel
        problemas = @($Erros | ForEach-Object { $_.Msg })
        dependencias = @($Deps.Dependencies)
        arquivosAusentes = @($arquivosAusentes)
        acoesNecessarias = @($acoesNecessarias)
    }
    
    return $relatorio
}

function Invoke-AnalysisEngine {
    param([string]$Conteudo, [string]$CaminhoFonte, [string]$TipoFonte)
    
    Write-Log "════════ ANALYSISENGINE ════════" "OK"
    
    # Validar token do GitHub
    Write-Log "Validando token do GitHub..." "INFO"
    $tokenValidation = Test-GitHubToken -Token $global:GitHubToken
    if (-not $tokenValidation.Valid) {
        Write-Log "[ERRO] Token do GitHub inválido: $($tokenValidation.Error)" "ERRO"
        Write-Log "[KEY] Gere uma nova chave em: https://github.com/settings/tokens/new" "INFO"
        Write-Log "   Selecione permissões: repo (full control)" "INFO"
        return $null
    }
    Write-Log "[OK] Token do GitHub válido (usuário: $($tokenValidation.User))" "OK"
    
    try {
        $gateway = Invoke-InputGateway -Source $CaminhoFonte -SourceType $TipoFonte
        if ($null -eq $gateway) { return $null }
        
        $raiz = if ($null -ne $gateway.TempDir) { $gateway.TempDir } else { $CaminhoFonte }
        
        # Extrair conteúdo se necessário
        if (([string]::IsNullOrEmpty($Conteudo)) -and ($gateway.Caminho -ne "MEMORIA")) {
            $Conteudo = Invoke-ExtractionEngine -Source $gateway.Caminho -MimeType $gateway.MimeType
        }
        
        $techs = Invoke-TechnologyDetector -RootPath $raiz -Conteudo $Conteudo
        $estrutura = Invoke-StructureScanner -RootPath $raiz
        
        $gradlePath = "$raiz/app/build.gradle.kts"
        if (-not (Test-Path $gradlePath)) { $gradlePath = "$raiz/build.gradle.kts" }
        $deps = Invoke-DependencyScanner -GradlePath $gradlePath
        
        $erros = Invoke-ErrorScanner -Conteudo $Conteudo -RootPath $raiz
        $integridade = Invoke-IntegrityAnalyzer -Erros $erros
        
        $diagnostico = Invoke-DiagnosticReportGenerator -Techs $techs -Estrutura $estrutura -Deps $deps -Erros $erros -Integridade $integridade
        
        $relatorio = @{
            Timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
            Linguagens = @($techs.Linguagens | Select-Object -Unique)
            Frameworks = @($techs.Frameworks | Select-Object -Unique)
            Plataformas = @($techs.Plataformas | Select-Object -Unique)
            Dependencias = @($deps.Dependencies | Select-Object -Unique)
            VersionIssues = @($deps.VersionIssues)
            IntegridadePercentual = $integridade.Percentual
            Compilavel = $integridade.Compilavel
            Erros = @($erros)
            Diagnostico = $diagnostico
        }
        
        $global:AnalysisReport = $relatorio
        Write-Log "Análise concluída: Integridade $($integridade.Percentual)%" "OK"
        return $relatorio | ConvertTo-Json -Depth 10
        
    } catch {
        Write-Log "AnalysisEngine ERRO: $_" "ERRO"
        return $null
    }
}

# ══════════════════════════════════════════════════════════════
# BLOCO 2: RECONSTRUCTIONENGINE
# ══════════════════════════════════════════════════════════════

function Invoke-ProjectNormalizer {
    param([string]$RootPath)
    
    # Criar estrutura completa de diretórios
    $dirs = @(
        "$RootPath/app",
        "$RootPath/app/src",
        "$RootPath/app/src/main",
        "$RootPath/app/src/main/java",
        "$RootPath/app/src/main/kotlin",
        "$RootPath/app/src/main/res",
        "$RootPath/app/src/main/res/values",
        "$RootPath/app/src/main/res/layout",
        "$RootPath/app/src/main/res/drawable",
        "$RootPath/app/src/main/assets",
        "$RootPath/gradle",
        "$RootPath/gradle/wrapper"
    )
    
    foreach ($dir in $dirs) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    
    # Normalizar encoding UTF-8 em arquivos existentes
    Get-ChildItem $RootPath -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $content = Get-Content $_.FullName -Raw
            if ($content) {
                Set-Content -Path $_.FullName -Value $content -Encoding UTF8
            }
        } catch {}
    }
    
    Write-Log "Estrutura normalizada e encoding UTF-8 aplicado" "OK"
}

function Invoke-AndroidStructureBuilder {
    param([string]$RootPath)
    
    # A estrutura já é criada pelo ProjectNormalizer
    Write-Log "Estrutura Android criada" "OK"
}

function Invoke-ManifestRebuilder {
    param([string]$RootPath, $Package, $ActivityName)
    
    $manifest = @"
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="App"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.AppCompat.Light.DarkActionBar">
        
        <activity
            android:name="$Package.$ActivityName"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
"@
    
    Set-Content -Path "$RootPath/app/src/main/AndroidManifest.xml" -Value $manifest -Encoding UTF8
    Write-Log "Manifest reconstruído com permissões" "OK"
}

function Invoke-RootGradleRebuilder {
    param([string]$RootPath)
    
    $rootBuildGradle = @"
plugins {
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}
"@
    
    Set-Content -Path "$RootPath/build.gradle.kts" -Value $rootBuildGradle -Encoding UTF8
    Write-Log "build.gradle.kts na raiz criado" "OK"
}

function Invoke-GradleRebuilder {
    param([string]$RootPath, $Package)
    
    $buildGradle = @"
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "$Package"
    compileSdk = 35
    
    defaultConfig {
        applicationId = "$Package"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
    
    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = "17"
    }
    
    buildFeatures {
        compose = true
    }
    
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.8"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation(platform("androidx.compose:compose-bom:2024.02.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("com.google.android.material:material:1.11.0")
    
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation(platform("androidx.compose:compose-bom:2024.02.01"))
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
"@
    
    Set-Content -Path "$RootPath/app/build.gradle.kts" -Value $buildGradle -Encoding UTF8
    Write-Log "Gradle reconstruído (SDK 35, Java 17)" "OK"
}

function Invoke-DependencyResolver {
    param([string]$RootPath, $AnalysisReport)
    
    $depsResolvidas = @()
    $buildGradlePath = "$RootPath\app\build.gradle.kts"

    if (-not (Test-Path $buildGradlePath)) { return $depsResolvidas }

    $buildContent  = Get-Content $buildGradlePath -Raw -Encoding UTF8
    $allKtContent  = ""
    Get-ChildItem "$RootPath\app\src" -Filter "*.kt" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $allKtContent += (Get-Content $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue)
    }

    # Mapa: padrão no código → dependência a adicionar no build.gradle.kts
    $depMap = @(
        @{ Pattern = 'LocalBroadcastManager';            Dep = 'androidx.localbroadcastmanager:localbroadcastmanager:1.1.0';  Label = "LocalBroadcastManager" }
        @{ Pattern = 'Icons\.(Default|Filled|Outlined)'; Dep = 'androidx.compose.material:material-icons-extended';           Label = "Material Icons Extended" }
        @{ Pattern = 'Retrofit|retrofit2';               Dep = 'com.squareup.retrofit2:retrofit:2.9.0';                      Label = "Retrofit" }
        @{ Pattern = 'OkHttpClient|okhttp3';             Dep = 'com.squareup.okhttp3:okhttp:4.12.0';                         Label = "OkHttp" }
        @{ Pattern = 'Glide|GlideApp';                   Dep = 'com.github.bumptech.glide:glide:4.16.0';                     Label = "Glide" }
        @{ Pattern = 'Coil|rememberAsyncImagePainter';   Dep = 'io.coil-kt:coil-compose:2.6.0';                              Label = "Coil" }
        @{ Pattern = 'AsyncImage';                       Dep = 'io.coil-kt.coil3:coil-compose:3.3.0';                        Label = "Coil3 Compose" }
        @{ Pattern = 'coil3';                            Dep = 'io.coil-kt.coil3:coil-network-okhttp:3.3.0';                 Label = "Coil3 Network OkHttp" }
        @{ Pattern = 'preferencesDataStore|dataStore';   Dep = 'androidx.datastore:datastore-preferences:1.2.0';               Label = "DataStore Preferences" }
        @{ Pattern = 'Serializable|Json\.encodeToString'; Dep = 'org.jetbrains.kotlinx:kotlinx-serialization-json:1.9.0';     Label = "Kotlinx Serialization" }
        @{ Pattern = 'MediaSessionCompat|PlaybackStateCompat'; Dep = 'androidx.media:media:1.7.0';                            Label = "AndroidX Media" }
        @{ Pattern = 'Room|@Entity|@Dao|@Database';      Dep = 'androidx.room:room-runtime:2.6.1';                           Label = "Room" }
        @{ Pattern = 'NavController|NavHost|rememberNavController'; Dep = 'androidx.navigation:navigation-compose:2.7.6'; Label = "Navigation Compose" }
        @{ Pattern = 'ViewModel\(\)|viewModel\(\)';      Dep = 'androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0';        Label = "ViewModel Compose" }
        @{ Pattern = 'Hilt|@HiltViewModel|@Inject';      Dep = 'com.google.dagger:hilt-android:2.50';                        Label = "Hilt" }
        @{ Pattern = 'MediaPlayer|MediaStore|AudioManager'; Dep = '';                                                         Label = "" }  # já no SDK
    )

    foreach ($entry in $depMap) {
        if (-not $entry.Dep) { continue }
        if ($allKtContent -match $entry.Pattern) {
            # Verificar se já está no build.gradle.kts
            $shortId = ($entry.Dep -split ':')[1]
            if ($buildContent -notmatch [regex]::Escape($shortId)) {
                # Inserir de forma robusta
                if ($buildContent -match '(\s*testImplementation)') {
                    $buildContent = $buildContent -replace '(\s*testImplementation)', "    implementation(`"$($entry.Dep)`")`n`$1"
                } else {
                    $buildContent = $buildContent -replace '(dependencies\s*\{)', "`$1`r`n    implementation(`"$($entry.Dep)`")"
                }
                $depsResolvidas += $entry.Label
                Write-Log "Dependência adicionada: $($entry.Label)" "OK" -Healed
            }
        }
    }

    # Garantir Serializable em data classes passadas via Intent (getSerializableExtra)
    if ($allKtContent -match 'getSerializableExtra|putExtra.*ArrayList') {
        # Encontrar data classes que não implementam Serializable
        $dataClassPattern = 'data\s+class\s+(\w+)\s*\([^)]*\)(?!\s*:\s*[^{]*Serializable)'
        $dataMatches = [regex]::Matches($allKtContent, $dataClassPattern)
        foreach ($dm in $dataMatches) {
            $className = $dm.Groups[1].Value
            # Corrigir nos arquivos .kt
            Get-ChildItem "$RootPath\app\src" -Filter "*.kt" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                $ktC = Get-Content $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                if ($ktC -match "data\s+class\s+$className\s*\(") {
                    if ($ktC -notmatch "$className[^{]*:\s*[^{]*Serializable") {
                        # Adicionar import Serializable se necessário
                        if ($ktC -notmatch 'import java.io.Serializable') {
                            $ktC = $ktC -replace '(^package\s+\S+)', "`$1`r`nimport java.io.Serializable"
                        }
                        # Adicionar : Serializable à data class
                        $ktC = $ktC -replace "(data\s+class\s+$className\s*\([^)]*\))", "`$1 : Serializable"
                        Set-Content -Path $_.FullName -Value $ktC -Encoding UTF8
                        Write-Log "Serializable adicionado à data class '$className'" "OK" -Healed
                        $depsResolvidas += "Serializable em $className"
                    }
                }
            }
        }
    }

    # Deps da análise (compatibilidade com sistema antigo)
    if ($AnalysisReport.Diagnostico.dependencias -contains "Firebase") { $depsResolvidas += "Firebase BOM" }
    if ($AnalysisReport.Diagnostico.dependencias -contains "Retrofit") { }  # já tratado acima
    if ($AnalysisReport.Diagnostico.dependencias -contains "OkHttp")  { }  # já tratado acima

    # Salvar build.gradle.kts atualizado
    Set-Content -Path $buildGradlePath -Value $buildContent -Encoding UTF8

    Write-Log "Dependências resolvidas: $($depsResolvidas -join ', ')" "OK"
    return $depsResolvidas
}

function Invoke-ResourceRepairEngine {
    param([string]$RootPath)
    
    # Criar strings.xml básico
    $strings = @"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">App</string>
</resources>
"@
    Set-Content -Path "$RootPath/app/src/main/res/values/strings.xml" -Value $strings -Encoding UTF8
    
    # Criar colors.xml básico
    $colors = @"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="purple_200">#FFBB86FC</color>
    <color name="purple_500">#FF6200EE</color>
    <color name="purple_700">#FF3700B3</color>
    <color name="teal_200">#FF03DAC5</color>
    <color name="teal_700">#FF018786</color>
    <color name="black">#FF000000</color>
    <color name="white">#FFFFFFFF</color>
</resources>
"@
    Set-Content -Path "$RootPath/app/src/main/res/values/colors.xml" -Value $colors -Encoding UTF8
    
    # Criar themes.xml básico
    $themes = @"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.App" parent="android:Theme.Material.Light.NoActionBar" />
</resources>
"@
    Set-Content -Path "$RootPath/app/src/main/res/values/themes.xml" -Value $themes -Encoding UTF8
    
    # Criar layout activity_main.xml
    $layout = @"
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="APK Compilado!"
        android:textSize="24sp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

</androidx.constraintlayout.widget.ConstraintLayout>
"@
    Set-Content -Path "$RootPath/app/src/main/res/layout/activity_main.xml" -Value $layout -Encoding UTF8
    
    Write-Log "Recursos base criados" "OK"
}

function Invoke-ProguardRulesRebuilder {
    param([string]$RootPath)
    
    $proguardRules = @"
# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile
"@
    
    Set-Content -Path "$RootPath/app/proguard-rules.pro" -Value $proguardRules -Encoding UTF8
    Write-Log "proguard-rules.pro criado" "OK"
}

function Invoke-ActivityRecoveryEngine {
    param([string]$RootPath, $Package, $ActivityName, $Conteudo)
    
    $pkgPath = $Package -replace '\.', '\'
    $activityPath = "$RootPath/app/src/main/java/$pkgPath/$ActivityName.kt"
    
    # Criar diretório se não existir
    $activityDir = Split-Path $activityPath -Parent
    if (-not (Test-Path $activityDir)) {
        New-Item -ItemType Directory -Force -Path $activityDir | Out-Null
    }
    
    # Se não houver conteúdo, criar MainActivity básica
    if ([string]::IsNullOrEmpty($Conteudo)) {
        $basicActivity = @"
package $Package

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class $ActivityName : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
    }
}
"@
        Set-Content -Path $activityPath -Value $basicActivity -Encoding UTF8
        
        # Criar layout básico
        $layout = @"
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center">
    
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Hello World!"
        android:textSize="24sp" />
</LinearLayout>
"@
        Set-Content -Path "$RootPath/app/src/main/res/layout/activity_main.xml" -Value $layout -Encoding UTF8
    } else {
        # Usar conteúdo fornecido
        Set-Content -Path $activityPath -Value $Conteudo -Encoding UTF8
    }
    
    Write-Log "Activity recuperada: $ActivityName" "OK"
}

function Invoke-WrapperGenerator {
    param([string]$RootPath)
    
    # Baixar gradlew oficial do Gradle em vez de gerar manualmente
    try {
        $gradlewUrl = "https://raw.githubusercontent.com/gradle/gradle/v8.7.0/gradlew"
        $gradlewContent = Invoke-RestMethod -Uri $gradlewUrl -ErrorAction Stop
        # Converter line endings CRLF para LF para compatibilidade Linux
        $gradlewContent = $gradlewContent -replace "`r`n", "`n"
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText("$RootPath/gradlew", $gradlewContent, $utf8NoBom)
        Write-Log "gradlew baixado oficialmente" "OK"
    } catch {
        Write-Log "Falha ao baixar gradlew oficial, usando fallback" "AVISO"
        # Fallback: gerar manualmente
        # Remover gradlew existente para garantir arquivo limpo sem BOM
        if (Test-Path "$RootPath/gradlew") {
            Remove-Item "$RootPath/gradlew" -Force
        }
        
        # gradlew
        $gradlew = @"
#!/usr/bin/env sh

##############################################################################
##
##  Gradle start up script for UN*X
##
##############################################################################

# Attempt to set APP_HOME
# Resolve links: $0 may be a link
PRG="\$0"
# Need this for relative symlinks.
while [ -h "\$PRG" ] ; do
    ls=`ls -ld "\$PRG"`
    link=`expr "\$ls" : '.*-> \(.*\)$'
    if expr "\$link" : '/.*' > /dev/null; then
        PRG="\$link"
    else
        PRG=`dirname "\$PRG"`"/\$link"
    fi
done
SAVED="\`pwd\`"
cd "\`dirname \"\$PRG\"\`/" >/dev/null
APP_HOME="\`pwd -P\`"
cd "\$SAVED" >/dev/null

APP_NAME="Gradle"
APP_BASE_NAME=\`basename "\$0"\`

# Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
DEFAULT_JVM_OPTS='"'

# Use the maximum available, or set MAX_FD != -1 to use that value.
MAX_FD="maximum"

warn () {
    echo "\$*"
}

die () {
    echo
    echo "\$*"
    echo
    exit 1
}

# OS specific support (must be 'true' or 'false').
cygwin=false
msys=false
darwin=false
nonstop=false
case "\`uname\`" in
  CYGWIN* )
    cygwin=true
    ;;
  Darwin* )
    darwin=true
    ;;
  MINGW* )
    msys=true
    ;;
  NONSTOP* )
    nonstop=true
    ;;
esac

CLASSPATH=\$APP_HOME/gradle/wrapper/gradle-wrapper.jar

# Determine the Java command to use to start the JVM.
if [ -n "\$JAVA_HOME" ] ; then
    if [ -x "\$JAVA_HOME/jre/sh/java" ] ; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD="\$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="\$JAVA_HOME/bin/java"
    fi
    if [ ! -x "\$JAVACMD" ] ; then
        die "ERROR: JAVA_HOME is set to an invalid directory: \$JAVA_HOME\n\nPlease set the JAVA_HOME variable in your environment to match the location of your Java installation."
    fi
else
    JAVACMD="java"
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.\n\nPlease set the JAVA_HOME variable in your environment to match the location of your Java installation."
fi

# Increase the maximum file descriptors if we can.
if [ "\$cygwin" = "false" -a "\$darwin" = "false" -a "\$nonstop" = "false" ] ; then
    MAX_FD_LIMIT=`ulimit -H -n`
    if [ \$? -eq 0 ] ; then
        if [ "\$MAX_FD" = "maximum" -o "\$MAX_FD" = "max" ] ; then
            MAX_FD="\$MAX_FD_LIMIT"
        fi
        ulimit -n \$MAX_FD
        if [ \$? -ne 0 ] ; then
            warn "Could not set maximum file descriptor limit: \$MAX_FD"
        fi
    else
        warn "Could not query maximum file descriptor limit: ulimit -n -H"
    fi
fi

# For Darwin, add options to specify how the application appears in the dock
if \$darwin; then
    GRADLE_OPTS="\$GRADLE_OPTS \"-Xdock:name=\$APP_NAME\" \"-Xdock:icon=\$APP_HOME/media/gradle.icns\""
fi

# For Cygwin, switch paths to Windows format before running java
if \$cygwin ; then
    APP_HOME=`cygpath --path --mixed "\$APP_HOME"`
    CLASSPATH=`cygpath --path --mixed "\$CLASSPATH"`
    JAVACMD=`cygpath --unix "\$JAVACMD"`
    # We build the pattern for arguments to be converted via cygpath
    ROOTDIRSRAW=`find -L / -maxdepth 1 -mindepth 1 -type d 2>/dev/null`
    SEP=""
    for dir in \$ROOTDIRSRAW ; do
        ROOTDIRS="\$ROOTDIRSROWS\$SEP\$dir"
        SEP="|"
    done
    OURCYGPATTERN="(^((\$ROOTDIRS))
    # Add a user-defined pattern to the cygpath arguments
    if [ "\$GRADLE_CYGPATTERN" != "" ] ; then
        OURCYGPATTERN="\$OURCYGPATTERN|\$GRADLE_CYGPATTERN"
    fi
    # Now convert the arguments - kludge to limit ourselves to /bin/sh
    i=0
    for arg in "\$@" ; do
        CHECK=`echo "\$arg"|egrep -c "\$OURCYGPATTERN" -`
        CHECK2=`echo "\$arg"|egrep -c "^-"` ### Determine if an option
        if [ \$CHECK -ne 0 ] && [ \$CHECK2 -eq 0 ] ; then ### Added a condition
            eval `echo argsi=\`\`echo "\$arg" | sed -e 's/^\(.*\)=\(.*\)$/\1=\2/'\`\``
            arg=`echo "\$arg" | sed -e 's/^\(.*\)=\(.*\)$/\2/'`
        fi
        if [ \$CHECK -ne 0 ] ; then
            eval `echo argsi=\`\`echo "\$arg" | sed -e 's/@/@/'\`\``
            arg=`echo "\$arg" | sed -e 's/@/@/'`
        fi
        eval `echo args\$i=\$arg`
        i=`expr \$i + 1`
    done
    case \$i in
        0) set -- ;;
        1) set -- "\$args1" ;;
        2) set -- "\$args1" "\$args2" ;;
        3) set -- "\$args1" "\$args2" "\$args3" ;;
        4) set -- "\$args1" "\$args2" "\$args3" "\$args4" ;;
        5) set -- "\$args1" "\$args2" "\$args3" "\$args4" "\$args5" ;;
        6) set -- "\$args1" "\$args2" "\$args3" "\$args4" "\$args5" "\$args6" ;;
        7) set -- "\$args1" "\$args2" "\$args3" "\$args4" "\$args5" "\$args6" "\$args7" ;;
        8) set -- "\$args1" "\$args2" "\$args3" "\$args4" "\$args5" "\$args6" "\$args7" "\$args8" ;;
        9) set -- "\$args1" "\$args2" "\$args3" "\$args4" "\$args5" "\$args6" "\$args7" "\$args8" "\$args9" ;;
    esac
fi

# Escape application args
save () {
    for i do printf %s\\n "\$i" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/'/ \\$"" done
    echo " "
}
APP_ARGS=`save "\$@"`

# Collect all arguments for the java command, following the shell quoting and substitution rules
eval set -- \$DEFAULT_JVM_OPTS \$JAVA_OPTS \$GRADLE_OPTS "\"-Dorg.gradle.appname=\$APP_BASE_NAME\"" -classpath "\"\$CLASSPATH\"" org.gradle.wrapper.GradleWrapperMain "\$APP_ARGS"

exec "\$JAVACMD" "\$@"
"@
    # Usar UTF8 sem BOM para compatibilidade Linux (fallback)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    # Converter line endings CRLF para LF para compatibilidade Linux
    $gradlew = $gradlew -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText("$RootPath/gradlew", $gradlew, $utf8NoBom)
    }
    
    # gradlew.bat
    $gradlewBat = @"
@rem
@rem Copyright 2015 the original author or authors.
@rem
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem      https://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.
@rem

@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  Gradle startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%

@rem Resolve any "." and ".." in APP_HOME to make it shorter.
for %%i in ("%APP_HOME%") do set APP_HOME=%%~fi

@rem Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS="-Xmx64m" "-Xms64m"

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if "%ERRORLEVEL%" == "0" goto execute

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%\bin\java.exe

if exist "%JAVA_EXE%" goto execute

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar


@rem Execute Gradle
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %GRADLE_OPTS% "-Dorg.gradle.appname=%APP_BASE_NAME%" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*

:end
@rem End local scope for the variables with windows NT shell
if "%ERRORLEVEL%"=="0" goto mainEnd

:fail
rem Set variable GRADLE_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code!
if  not "" == "%GRADLE_EXIT_CONSOLE%" exit 1
exit /b 1

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
"@
    # Usar UTF8 sem BOM para compatibilidade Windows
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText("$RootPath/gradlew.bat", $gradlewBat, $utf8NoBom)
    
    # gradle-wrapper.properties
    $wrapperProps = @"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
"@
    Set-Content -Path "$RootPath/gradle/wrapper/gradle-wrapper.properties" -Value $wrapperProps -Encoding UTF8
    
    # Baixar gradle-wrapper.jar do repositório oficial do Gradle (GitHub)
    # URL validada: https://github.com/gradle/gradle/blob/master/gradle/wrapper/gradle-wrapper.jar (47.3 KB)
    $wrapperJarUrl = "https://raw.githubusercontent.com/gradle/gradle/v8.7.0/gradle/wrapper/gradle-wrapper.jar"
    $wrapperJarPath = "$RootPath/gradle/wrapper/gradle-wrapper.jar"
    
    try {
        Write-Log "Baixando gradle-wrapper.jar..." "INFO"
        $progressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $wrapperJarUrl -OutFile $wrapperJarPath -UseBasicParsing -ErrorAction Stop
        $progressPreference = 'Continue'
        
        # Verificar se o arquivo foi baixado corretamente (deve ter ~47KB)
        $fileInfo = Get-Item $wrapperJarPath
        if ($fileInfo.Length -lt 40000) {
            throw "Arquivo baixado é muito pequeno ($($fileInfo.Length) bytes), provavelmente corrompido"
        }
        
        # Verificar se é um arquivo JAR válido (começa com PK ou ZIP magic bytes)
        $bytes = [System.IO.File]::ReadAllBytes($wrapperJarPath)
        if ($bytes[0] -ne 0x50 -or $bytes[1] -ne 0x4B) {
            throw "Arquivo não é um JAR válido (magic bytes incorretos)"
        }
        
        Write-Log "gradle-wrapper.jar baixado com sucesso ($($fileInfo.Length) bytes)" "OK"
    } catch {
        Write-Log "Falha ao baixar gradle-wrapper.jar: $_" "ERRO"
        # Tentar baixar de mirror alternativo (services.gradle.org)
        try {
            $altUrl = "https://services.gradle.org/distributions/gradle-wrapper.jar"
            $progressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $altUrl -OutFile $wrapperJarPath -UseBasicParsing -ErrorAction Stop
            $progressPreference = 'Continue'
            
            $fileInfo = Get-Item $wrapperJarPath
            if ($fileInfo.Length -lt 40000) {
                throw "Arquivo do mirror também é muito pequeno"
            }
            
            # Verificar magic bytes do mirror
            $bytes = [System.IO.File]::ReadAllBytes($wrapperJarPath)
            if ($bytes[0] -ne 0x50 -or $bytes[1] -ne 0x4B) {
                throw "Arquivo do mirror não é um JAR válido"
            }
            
            Write-Log "gradle-wrapper.jar baixado do mirror alternativo ($($fileInfo.Length) bytes)" "OK"
        } catch {
            Write-Log "Falha crítica: não foi possível baixar gradle-wrapper.jar" "ERRO"
            throw
        }
    }
    
    Write-Log "Gradle Wrapper gerado" "OK"
}

function Invoke-ImportRepairEngine {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) { return }
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    
    # Standard replacements
    $content = $content -replace 'android\.support\.', 'androidx.'
    $content = $content -replace 'import android\.app\.', 'import androidx.appcompat.app.'
    
    # Common Compose/Kotlin patterns and their required imports
    $rules = @(
        @{ Pattern = '\bclickable\b'; Import = 'import androidx.compose.foundation.clickable' }
        @{ Pattern = '\bfillMaxSize\b'; Import = 'import androidx.compose.foundation.layout.fillMaxSize' }
        @{ Pattern = '\bfillMaxWidth\b'; Import = 'import androidx.compose.foundation.layout.fillMaxWidth' }
        @{ Pattern = '\bfillMaxHeight\b'; Import = 'import androidx.compose.foundation.layout.fillMaxHeight' }
        @{ Pattern = '\bpadding\b'; Import = 'import androidx.compose.foundation.layout.padding' }
        @{ Pattern = '\bSpacer\b'; Import = 'import androidx.compose.foundation.layout.Spacer' }
        @{ Pattern = '\bColumn\b'; Import = 'import androidx.compose.foundation.layout.Column' }
        @{ Pattern = '\bRow\b'; Import = 'import androidx.compose.foundation.layout.Row' }
        @{ Pattern = '\bBox\b'; Import = 'import androidx.compose.foundation.layout.Box' }
        @{ Pattern = '\bArrangement\b'; Import = 'import androidx.compose.foundation.layout.Arrangement' }
        @{ Pattern = '\bAlignment\b'; Import = 'import androidx.compose.ui.Alignment' }
        @{ Pattern = '\bModifier\b'; Import = 'import androidx.compose.ui.Modifier' }
        @{ Pattern = '\bclip\b'; Import = 'import androidx.compose.ui.draw.clip' }
        @{ Pattern = '\bshadow\b'; Import = 'import androidx.compose.ui.draw.shadow' }
        @{ Pattern = '\bgraphicsLayer\b'; Import = 'import androidx.compose.ui.graphics.graphicsLayer' }
        @{ Pattern = '\bBrush\b'; Import = 'import androidx.compose.ui.graphics.Brush' }
        @{ Pattern = '\bColor\b'; Import = 'import androidx.compose.ui.graphics.Color' }
        @{ Pattern = '\bContentScale\b'; Import = 'import androidx.compose.ui.layout.ContentScale' }
        @{ Pattern = '\b(\d+)\.dp\b'; Import = 'import androidx.compose.ui.unit.dp' }
        @{ Pattern = '\b(\d+)\.sp\b'; Import = 'import androidx.compose.ui.unit.sp' }
        @{ Pattern = '\bDp\b'; Import = 'import androidx.compose.ui.unit.Dp' }
        @{ Pattern = '\bFontWeight\b'; Import = 'import androidx.compose.ui.text.font.FontWeight' }
        @{ Pattern = '\bTextAlign\b'; Import = 'import androidx.compose.ui.text.style.TextAlign' }
        @{ Pattern = '\bTextOverflow\b'; Import = 'import androidx.compose.ui.text.style.TextOverflow' }
        
        @{ Pattern = '\bremember\s*\{'; Import = 'import androidx.compose.runtime.remember' }
        @{ Pattern = '\bmutableStateOf\b'; Import = 'import androidx.compose.runtime.mutableStateOf' }
        @{ Pattern = '\bgetValue\b'; Import = 'import androidx.compose.runtime.getValue' }
        @{ Pattern = '\bsetValue\b'; Import = 'import androidx.compose.runtime.setValue' }
        @{ Pattern = '\bLaunchedEffect\b'; Import = 'import androidx.compose.runtime.LaunchedEffect' }
        @{ Pattern = '\brememberCoroutineScope\b'; Import = 'import androidx.compose.runtime.rememberCoroutineScope' }
        @{ Pattern = '\bviewModel\b'; Import = 'import androidx.lifecycle.viewmodel.compose.viewModel' }
        @{ Pattern = '\bLocalContext\b'; Import = 'import androidx.compose.ui.platform.LocalContext' }
        
        @{ Pattern = '\bIcons\b'; Import = 'import androidx.compose.material.icons.Icons' }
        @{ Pattern = '\bIcon\b'; Import = 'import androidx.compose.material3.Icon' }
        @{ Pattern = '\bText\b'; Import = 'import androidx.compose.material3.Text' }
        @{ Pattern = '\bButton\b'; Import = 'import androidx.compose.material3.Button' }
        @{ Pattern = '\bIconButton\b'; Import = 'import androidx.compose.material3.IconButton' }
        @{ Pattern = '\bCard\b'; Import = 'import androidx.compose.material3.Card' }
        @{ Pattern = '\bScaffold\b'; Import = 'import androidx.compose.material3.Scaffold' }
        @{ Pattern = '\bCircularProgressIndicator\b'; Import = 'import androidx.compose.material3.CircularProgressIndicator' }
        @{ Pattern = '\bLinearProgressIndicator\b'; Import = 'import androidx.compose.material3.LinearProgressIndicator' }
        @{ Pattern = '\bSlider\b'; Import = 'import androidx.compose.material3.Slider' }
        @{ Pattern = '\bSwitch\b'; Import = 'import androidx.compose.material3.Switch' }
        @{ Pattern = '\bTab\b'; Import = 'import androidx.compose.material3.Tab' }
        @{ Pattern = '\bTabRow\b'; Import = 'import androidx.compose.material3.TabRow' }
        @{ Pattern = '\btabIndicatorOffset\b'; Import = 'import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset' }
        @{ Pattern = '\bModalBottomSheet\b'; Import = 'import androidx.compose.material3.ModalBottomSheet' }
        @{ Pattern = '\brememberModalBottomSheetState\b'; Import = 'import androidx.compose.material3.rememberModalBottomSheetState' }
        @{ Pattern = '\bAlertDialog\b'; Import = 'import androidx.compose.material3.AlertDialog' }
        @{ Pattern = '\bDropdownMenu\b'; Import = 'import androidx.compose.material3.DropdownMenu' }
        @{ Pattern = '\bDropdownMenuItem\b'; Import = 'import androidx.compose.material3.DropdownMenuItem' }
        
        @{ Pattern = '\bAsyncImage\b'; Import = 'import coil3.compose.AsyncImage' }
        @{ Pattern = '@Serializable\b'; Import = 'import kotlinx.serialization.Serializable' }
    )
    
    $importsAdded = 0
    foreach ($rule in $rules) {
        if ($content -match $rule.Pattern) {
            $escapedImport = [regex]::Escape($rule.Import)
            if ($content -notmatch $escapedImport) {
                # Find package line or first import line
                if ($content -match '(?m)^(package\s+\S+)') {
                    $pkgLine = $matches[1]
                    $content = $content -replace [regex]::Escape($pkgLine), "$pkgLine`r`n$($rule.Import)"
                    $importsAdded++
                } elseif ($content -match '(?m)^(import\s+\S+)') {
                    $firstImport = $matches[1]
                    $content = $content -replace [regex]::Escape($firstImport), "$($rule.Import)`r`n$firstImport"
                    $importsAdded++
                }
            }
        }
    }
    
    Set-Content -Path $FilePath -Value $content -Encoding UTF8
    if ($importsAdded -gt 0) {
        Write-Log "Imports reparados ($importsAdded adicionados) em $($FilePath | Split-Path -Leaf)" "OK" -Healed
    } else {
        Write-Log "Imports verificados em $($FilePath | Split-Path -Leaf)" "OK"
    }
}

function Invoke-ProjectValidator {
    param([string]$RootPath)
    
    $validacoes = @(
        @{ Arquivo = "build.gradle.kts (raiz)"; Existe = Test-Path "$RootPath/build.gradle.kts" }
        @{ Arquivo = "AndroidManifest.xml"; Existe = Test-Path "$RootPath/app/src/main/AndroidManifest.xml" }
        @{ Arquivo = "app/build.gradle.kts"; Existe = Test-Path "$RootPath/app/build.gradle.kts" }
        @{ Arquivo = "settings.gradle.kts"; Existe = Test-Path "$RootPath/settings.gradle.kts" }
        @{ Arquivo = "gradlew"; Existe = Test-Path "$RootPath/gradlew" }
        @{ Arquivo = "gradlew.bat"; Existe = Test-Path "$RootPath/gradlew.bat" }
        @{ Arquivo = "MainActivity"; Existe = (Get-ChildItem "$RootPath" -Recurse -Filter "MainActivity.*" -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0 }
        @{ Arquivo = "strings.xml"; Existe = Test-Path "$RootPath/app/src/main/res/values/strings.xml" }
        @{ Arquivo = "themes.xml"; Existe = Test-Path "$RootPath/app/src/main/res/values/themes.xml" }
        @{ Arquivo = "activity_main.xml"; Existe = Test-Path "$RootPath/app/src/main/res/layout/activity_main.xml" }
        @{ Arquivo = "proguard-rules.pro"; Existe = Test-Path "$RootPath/app/proguard-rules.pro" }
    )
    
    $todosValidos = ($validacoes | Where-Object { $_.Existe }).Count
    $total = $validacoes.Count
    
    Write-Log "Validação: $todosValidos/$total arquivos válidos" "OK"
    return @{ Validacoes = $validacoes; Percentual = [math]::Round(($todosValidos / $total) * 100) }
}

function Invoke-ReconstructionReportGenerator {
    param($ArquivosCriados, $ArquivosCorrigidos, $DepsResolvidas, $ManifestReconstruido, $GradleReconstruido, $Validacao)
    
    $relatorio = @{
        Timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
        arquivosCriados = @($ArquivosCriados)
        arquivosCorrigidos = @($ArquivosCorrigidos)
        dependenciasResolvidas = @($DepsResolvidas)
        manifestReconstruido = $ManifestReconstruido
        gradleReconstruido = $GradleReconstruido
        validacaoEstrutura = $Validacao.Percentual
        statusFinal = "READY_FOR_BUILD"
    }
    
    return $relatorio
}

function Invoke-ReconstructionEngine {
    param([string]$RootPath, [string]$Conteudo, $AnalysisReport)
    
    Write-Log "════════ RECONSTRUCTIONENGINE ════════" "OK"
    
    try {
        $package = if ($Conteudo -match 'package\s+([\w.]+)') { $Matches[1] } else { "com.example.app" }
        $activity = if ($Conteudo -match 'class\s+(\w+)\s') { $Matches[1] } else { "MainActivity" }
        
        $arquivosCriados = @()
        $arquivosCorrigidos = @()
        
        # 1. ProjectNormalizer
        Invoke-ProjectNormalizer -RootPath $RootPath
        $arquivosCriados += "Estrutura de diretórios"
        
        # 2. AndroidStructureBuilder
        Invoke-AndroidStructureBuilder -RootPath $RootPath
        
        # 3. RootGradleRebuilder (build.gradle.kts na raiz)
        Invoke-RootGradleRebuilder -RootPath $RootPath
        $arquivosCriados += "build.gradle.kts (raiz)"
        
        # 4. GradleRebuilder (app/build.gradle.kts)
        Invoke-GradleRebuilder -RootPath $RootPath -Package $package
        $arquivosCriados += "app/build.gradle.kts"
        
        # 5. ManifestRebuilder
        Invoke-ManifestRebuilder -RootPath $RootPath -Package $package -ActivityName $activity
        $arquivosCriados += "AndroidManifest.xml"
        
        # 6. ResourceRepairEngine
        Invoke-ResourceRepairEngine -RootPath $RootPath
        $arquivosCriados += "strings.xml", "colors.xml", "themes.xml", "activity_main.xml"
        
        # 7. ProguardRulesRebuilder
        Invoke-ProguardRulesRebuilder -RootPath $RootPath
        $arquivosCriados += "proguard-rules.pro"

        # ── FIX: Gravar código do usuário ANTES de resolver dependências ──────
        # Estratégia simples e confiável: detectar cada classe pelo nome,
        # mas gravar o Conteudo num único arquivo por package.
        # Kotlin aceita múltiplas classes no mesmo arquivo — não há necessidade
        # de separar em arquivos individuais para compilar.

        $javaDir = "$RootPath\app\src\main\java"

        # Detectar todos os packages únicos no Conteudo
        $packageLines = [regex]::Matches($Conteudo, '(?m)^package\s+(\S+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

        if ($packageLines.Count -eq 0) {
            # Sem declaração de package: usar o package detectado na análise
            $packageLines = @($package)
        }

        # Para cada package, extrair o trecho do código que pertence a ele
        # e gravar num arquivo nomeado pela primeira classe encontrada
        foreach ($pkg in $packageLines) {
            $pkgEsc     = [regex]::Escape($pkg)
            $pkgPathDir = ($pkg -replace '\.', '\')
            $targetDir  = "$javaDir\$pkgPathDir"

            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
            }

            # Extrair bloco do Conteudo que pertence a este package
            # (do "package X" até o próximo "package Y" diferente, ou fim)
            $pkgBlock = if ($packageLines.Count -gt 1) {
                # Múltiplos packages: extrair só o trecho deste
                $pattern = "(?s)(package\s+$pkgEsc\b.*?)(?=\npackage\s+(?!$pkgEsc\b)|\z)"
                $m = [regex]::Match($Conteudo, $pattern)
                if ($m.Success) { $m.Value } else { $Conteudo }
            } else {
                # Único package: gravar tudo
                $Conteudo
            }

            # Descobrir nome da primeira classe/object/interface para nomear o arquivo
            $firstClass = if ($pkgBlock -match '(?m)^(?:class|object|interface|data class|sealed class|abstract class|enum class)\s+(\w+)') {
                $matches[1]
            } else {
                $activity  # fallback: nome da activity principal
            }

            $targetFile = "$targetDir\$firstClass.kt"
            $utf8NoBom  = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($targetFile, $pkgBlock.Trim(), $utf8NoBom)
            $arquivosCriados += "$firstClass.kt"
            Write-Log "Código do usuário gravado: $firstClass.kt (package: $pkg)" "OK"
        }
        # ──────────────────────────────────────────────────────────────────────

        # 9. DependencyResolver - AGORA roda com código do usuário já no disco
        $depsResolvidas = Invoke-DependencyResolver -RootPath $RootPath -AnalysisReport $AnalysisReport

        # 10. ManifestValidator - AGORA detecta Services reais do código do usuário
        Invoke-ManifestValidator -RootPath $RootPath | Out-Null

        # 11. WrapperGenerator
        Invoke-WrapperGenerator -RootPath $RootPath
        $arquivosCriados += "gradlew", "gradlew.bat", "gradle-wrapper.properties", "gradle-wrapper.jar"

        # Copy Self-Healing compiler tool
        $toolsDir = "$RootPath/tools"
        if (-not (Test-Path $toolsDir)) {
            New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
        }
        $sourceCompiler = Join-Path $ScriptDir "..\tools\self_healing_compiler.py"
        if (Test-Path $sourceCompiler) {
            Copy-Item -Path $sourceCompiler -Destination "$toolsDir\self_healing_compiler.py" -Force
            $arquivosCriados += "tools/self_healing_compiler.py"
            Write-Log "Ferramenta de Auto-Cura IA copiada para o projeto" "OK"
        }

        # 12. Self-Healing Engine v9.0 - Aplica resiliência ao projeto
        Invoke-SelfHealingEngine -RootPath $RootPath -Package $package
        
        # 9. Settings.gradle.kts
        $settings = @"
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement { 
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "App"
include(":app")
"@
        Set-Content -Path "$RootPath/settings.gradle.kts" -Value $settings -Encoding UTF8
        $arquivosCriados += "settings.gradle.kts"
        
        # 13. ImportRepairEngine - roda em todos os .kt do projeto
        Get-ChildItem "$RootPath\app\src\main\java" -Filter "*.kt" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            Invoke-ImportRepairEngine -FilePath $_.FullName
            $arquivosCorrigidos += "Imports em $($_.Name)"
        }
        
        # 11. ProjectValidator
        $validacao = Invoke-ProjectValidator -RootPath $RootPath
        
        # 12. ReconstructionReportGenerator
        $relatorio = Invoke-ReconstructionReportGenerator `
            -ArquivosCriados $arquivosCriados `
            -ArquivosCorrigidos $arquivosCorrigidos `
            -DepsResolvidas $depsResolvidas `
            -ManifestReconstruido $true `
            -GradleReconstruido $true `
            -Validacao $validacao
        
        $global:ReconstructionReport = $relatorio
        Write-Log "Reconstrução concluída: $($arquivosCriados.Count) arquivos criados" "OK"
        return $relatorio | ConvertTo-Json -Depth 10
        
    } catch {
        Write-Log "ReconstructionEngine ERRO: $_" "ERRO"
        return $null
    }
}

# ══════════════════════════════════════════════════════════════
# BLOCO 3: BUILDORCHESTRATOR
# ══════════════════════════════════════════════════════════════

function Invoke-PreBuildValidator {
    param([string]$RootPath)
    
    $validacoes = @(
        @{ Arquivo = "AndroidManifest.xml"; Caminho = "$RootPath/app/src/main/AndroidManifest.xml"; Critico = $true }
        @{ Arquivo = "build.gradle.kts"; Caminho = "$RootPath/app/build.gradle.kts"; Critico = $true }
        @{ Arquivo = "settings.gradle.kts"; Caminho = "$RootPath/settings.gradle.kts"; Critico = $true }
        @{ Arquivo = "gradlew"; Caminho = "$RootPath/gradlew"; Critico = $true }
        @{ Arquivo = "gradlew.bat"; Caminho = "$RootPath/gradlew.bat"; Critico = $false }
        @{ Arquivo = "MainActivity"; Caminho = "$RootPath/app/src/main/java"; Critico = $true }
        @{ Arquivo = "app/"; Caminho = "$RootPath/app"; Critico = $true }
    )
    
    $errosCriticos = @()
    $avisos = @()
    
    foreach ($v in $validacoes) {
        if (-not (Test-Path $v.Caminho)) {
            if ($v.Critico) {
                $errosCriticos += "CRÍTICO: $($v.Arquivo) ausente"
            } else {
                $avisos += "AVISO: $($v.Arquivo) ausente"
            }
        }
    }
    
    $valido = $errosCriticos.Count -eq 0
    
    Write-Log "Validação pré-build: $($validacoes.Count) arquivos, $($errosCriticos.Count) erros críticos" $(if ($valido) { "OK" } else { "ERRO" })
    
    return @{ Valido = $valido; ErrosCriticos = $errosCriticos; Avisos = $avisos }
}

function Invoke-WorkflowGenerator {
    param([string]$RootPath)
    
    $workflowDir = "$RootPath/.github/workflows"
    New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
    
    $workflow = @'
name: Android APK Build Resiliente

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: 'Configurar JDK 17 (Solucao Principal)'
        id: setup-java-17
        uses: actions/setup-java@v4
        continue-on-error: true
        with:
          distribution: temurin
          java-version: 17
          cache: gradle

      - name: 'Configurar JDK 11 (Fallback se JDK 17 Falhar)'
        if: steps.setup-java-17.outcome == 'failure'
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 11
          cache: gradle

      - name: 'Setup Gradle Cache inteligente'
        uses: gradle/actions/setup-gradle@v4

      - name: Grant execute permission for gradlew
        run: chmod +x gradlew

      - name: 'Compilar APK com Agente de Auto-Cura IA'
        run: |
          chmod +x tools/self_healing_compiler.py
          python3 tools/self_healing_compiler.py
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

      - name: 'Localizar ferramentas do Android SDK'
        id: find-tools
        run: |
          ZIPALIGN=$(find $ANDROID_HOME/build-tools -name zipalign | sort -V | tail -n 1)
          APKSIGNER=$(find $ANDROID_HOME/build-tools -name apksigner | sort -V | tail -n 1)
          echo "zipalign=$ZIPALIGN" >> $GITHUB_OUTPUT
          echo "apksigner=$APKSIGNER" >> $GITHUB_OUTPUT

      - name: 'Auto-Gerar Keystore de Assinatura na Nuvem'
        run: |
          keytool -genkeypair -v -keystore release.jks -alias cloudalias -keyalg RSA -keysize 2048 -validity 10000 -storepass cloudpass -keypass cloudpass -dname "CN=APK,O=APK,C=BR"

      - name: 'Alinhar APK (zipalign) na Nuvem'
        run: |
          ${{ steps.find-tools.outputs.zipalign }} -p -f 4 app/build/outputs/apk/debug/app-debug.apk app/build/outputs/apk/debug/app-aligned.apk

      - name: 'Assinar APK (apksigner) na Nuvem'
        run: |
          ${{ steps.find-tools.outputs.apksigner }} sign --ks release.jks --ks-key-alias cloudalias --ks-pass pass:cloudpass --key-pass pass:cloudpass --out app/build/outputs/apk/debug/app-signed.apk app/build/outputs/apk/debug/app-aligned.apk

      - name: 'Upload APK Assinado e Pronto para Uso'
        uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: app/build/outputs/apk/debug/app-signed.apk
          retention-days: 7

      - name: 'Upload Build Logs'
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: build-logs
          path: |
            app/build/reports/
            build.log
          retention-days: 7
'@
    
    Set-Content -Path "$workflowDir/android.yml" -Value $workflow -Encoding UTF8
    Write-Log "Workflow GitHub Actions gerado com Auto-Cura ativa" "OK"
}

function Invoke-GitHubActionsMonitor {
    param([string]$Owner, [string]$Repo, [string]$Token, [string]$LastKnownRunId = $null, [scriptblock]$LogCallback)
    
    $headers = @{ "Authorization" = "Bearer $Token"; "Accept" = "application/vnd.github.v3+json" }
    $startTime = Get-Date
    
    for ($i = 0; $i -lt 120; $i++) {
        Start-Sleep -Seconds 10
        
        try {
            $runs = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/actions/runs" -Headers $headers
            
            if ($runs.workflow_runs.Count -gt 0) {
                $run = $null
                if ($LastKnownRunId) {
                    $newRuns = $runs.workflow_runs | Where-Object { [long]$_.id -gt [long]$LastKnownRunId }
                    if ($newRuns) { $run = $newRuns[0] }
                } else {
                    $run = $runs.workflow_runs[0]
                }
                
                if (-not $run) {
                    continue
                }

                $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
                
                # Buscar etapas reais em execução para logar de forma realista
                $stepInfo = ""
                try {
                    $jobsUri = "https://api.github.com/repos/$Owner/$Repo/actions/runs/$($run.id)/jobs"
                    $jobsData = Invoke-RestMethod -Uri $jobsUri -Headers $headers -ErrorAction SilentlyContinue
                    if ($jobsData -and $jobsData.jobs -and $jobsData.jobs.Count -gt 0) {
                        $job = $jobsData.jobs[0]
                        $steps = $job.steps
                        $activeStep = $null
                        foreach ($step in $steps) {
                            if ($step.status -eq 'in_progress') {
                                $activeStep = $step
                                break
                            }
                        }
                        if ($activeStep) {
                            $stepInfo = " | Etapa: $($activeStep.name)"
                        }
                    }
                } catch {}

                & $LogCallback "Status: $($run.status)$stepInfo | Conclusão: $($run.conclusion) | Tempo: ${elapsed}s"
                
                if ($run.status -eq "completed") {
                    return @{
                        Status = $run.status
                        Conclusion = $run.conclusion
                        RunId = $run.id
                        HtmlUrl = $run.html_url
                        ElapsedTime = $elapsed
                    }
                }
            }
        } catch {
            & $LogCallback "Erro ao monitorar: $_"
        }
    }
    
    return @{ Status = "timeout"; Conclusion = "unknown" }
}

function Invoke-ArtifactDownloader {
    param([string]$Owner, [string]$Repo, [string]$Token, [string]$RunId, [string]$DestDir)

    $headers = @{ "Authorization" = "Bearer $Token"; "Accept" = "application/vnd.github.v3+json" }
    $artifactsData = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/actions/runs/$RunId/artifacts" -Headers $headers

    $apkPaths = @()

    foreach ($art in $artifactsData.artifacts) {
        try {
            # 1. Baixar o ZIP do artefato
            $zipPath = "$DestDir\$($art.name).zip"
            $downloadUrl = $art.archive_download_url

            # A API redireciona para URL temporária — usar WebClient para seguir redirect
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("Authorization", "Bearer $Token")
            $webClient.Headers.Add("User-Agent", "CompilaAPK/9.0")
            $webClient.DownloadFile($downloadUrl, $zipPath)
            $webClient.Dispose()

            Write-Log "ZIP baixado: $($art.name).zip ($([Math]::Round((Get-Item $zipPath).Length / 1KB, 1)) KB)" "OK"

            # 2. Descompactar o ZIP
            $extractDir = "$DestDir\$($art.name)"
            if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
            Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
            Write-Log "ZIP extraído em: $extractDir" "OK"

            # 3. Encontrar todos os .apk dentro do ZIP extraído
            $apkFiles = Get-ChildItem -Path $extractDir -Filter "*.apk" -Recurse -ErrorAction SilentlyContinue
            if ($apkFiles.Count -eq 0) {
                Write-Log "Nenhum .apk encontrado dentro de $($art.name).zip" "AVISO"
                continue
            }

            foreach ($apk in $apkFiles) {
                # Copiar o .apk para a raiz do DestDir com nome limpo
                $destApk = "$DestDir\$($apk.Name)"
                Copy-Item $apk.FullName $destApk -Force
                $apkPaths += $destApk
                $sizeMB = [Math]::Round($apk.Length / 1MB, 2)
                Write-Log "APK extraído: $($apk.Name) ($sizeMB MB) → $destApk" "OK"
            }

        } catch {
            Write-Log "Falha ao baixar/extrair $($art.name): $_" "ERRO"
        }
    }

    return $apkPaths
}

function Invoke-ErrorInterpreter {
    param([string]$LogContent)
    
    $erros = @()

    # ── Erros de Módulo / Projeto ────────────────────────────────────────────
    if ($LogContent -match "Project with path '([^']+)' could not be found|UnknownProjectException") {
        $modulo = if ($matches[1]) { $matches[1] } else { ":desconhecido" }
        $erros += @{
            Tipo     = "ModuloAusente"
            Mensagem = "Módulo '$modulo' não encontrado no projeto"
            Correcao = "Remover referência a '$modulo' do app/build.gradle.kts e do settings.gradle.kts"
            AutoFix  = "RemoveModuleRef"
            Modulo   = $modulo
        }
    }

    # ── Erros de Package / Classe ────────────────────────────────────────────
    if ($LogContent -match "error: package .* does not exist|Unresolved reference") {
        if ($LogContent -match "Unresolved reference\s+'(clickable|tabIndicatorOffset|remember|mutableStateOf|getValue|setValue|dp|sp|Modifier|Alignment|Box|Column|Row|Spacer|Icons)'") {
            $erros += @{
                Tipo     = "ComposeImportAusente"
                Mensagem = "Importação do Jetpack Compose ausente no código Kotlin"
                Correcao = "Executar ImportRepairEngine para injetar automaticamente as importações necessárias"
                AutoFix  = "RunImportRepairEngine"
            }
        } else {
            # Adicionar suporte ao Cognitive AI Healer como AutoFix primário para erros de compilação Kotlin complexos
            $erros += @{
                Tipo     = "ErroCompilacaoComplexo"
                Mensagem = "Falha de compilação complexa ou referência não resolvida no Kotlin"
                Correcao = "Acionar IA Cognitiva para reescrever o trecho do arquivo com falha"
                AutoFix  = "RunAICognitiveHealer"
            }
        }
    }
    if ($LogContent -match "ClassNotFoundException|Could not find or load main class") {
        $erros += @{
            Tipo     = "ClasseNaoEncontrada"
            Mensagem = "Classe não encontrada: gradle-wrapper.jar ausente ou corrompido"
            Correcao = "Substituir gradle-wrapper.jar pelo oficial do Gradle 8.7"
            AutoFix  = "FixGradleWrapper"
        }
    }

    # ── Erros de Gradle ──────────────────────────────────────────────────────
    if ($LogContent -match 'Minimum supported Gradle version is (\S+)\. Current version is (\S+)') {
        $required = $matches[1]; $current = $matches[2]
        $erros += @{
            Tipo     = "GradleVersao"
            Mensagem = "Gradle $current incompatível. Mínimo exigido: $required"
            Correcao = "Atualizar distributionUrl em gradle-wrapper.properties para gradle-$required-bin.zip"
            AutoFix  = "UpdateGradleVersion"
            Versao   = $required
        }
    }
    if ($LogContent -match 'Gradle error|Could not resolve com\.|Could not download') {
        $erros += @{
            Tipo     = "GradleConfig"
            Mensagem = "Erro de configuração ou resolução de dependências no Gradle"
            Correcao = "Verificar repositórios no settings.gradle.kts e versões no build.gradle.kts"
            AutoFix  = "None"
        }
    }
    if ($LogContent -match 'Found unknown Gradle Wrapper JAR|Wrapper JAR.*validation') {
        $erros += @{
            Tipo     = "GradleWrapperInvalido"
            Mensagem = "gradle-wrapper.jar não reconhecido pela validação de segurança"
            Correcao = "Substituir pelo JAR oficial do repositório gradle/gradle"
            AutoFix  = "FixGradleWrapper"
        }
    }

    # ── Erros de Manifest ────────────────────────────────────────────────────
    if ($LogContent -match 'android:exported|Targeting.*API.*34') {
        $erros += @{
            Tipo     = "ManifestExported"
            Mensagem = "android:exported ausente em Activity/Service com intent-filter"
            Correcao = "Adicionar android:exported='true' nas activities e 'false' nos services"
            AutoFix  = "RunManifestValidator"
        }
    }
    if ($LogContent -match 'Activity.*not found|does not extend Activity|Service.*declared.*activity') {
        $erros += @{
            Tipo     = "ManifestTipoErrado"
            Mensagem = "Service declarado como <activity> ou Activity não encontrada no Manifest"
            Correcao = "Executar ManifestValidator para detectar Services e mover para <service>"
            AutoFix  = "RunManifestValidator"
        }
    }

    # ── Erros de SDK ─────────────────────────────────────────────────────────
    if ($LogContent -match 'SDK error|compileSdkVersion|uses-sdk') {
        $erros += @{
            Tipo     = "SDK"
            Mensagem = "SDK incompatível ou ausente"
            Correcao = "Atualizar compileSdk/targetSdk para 35 no app/build.gradle.kts"
            AutoFix  = "None"
        }
    }

    # ── Erros de Java / Kotlin ───────────────────────────────────────────────
    if ($LogContent -match 'Java.*incompatible|source.*compatibility|target.*compatibility') {
        $erros += @{
            Tipo     = "JavaVersao"
            Mensagem = "Versão Java incompatível"
            Correcao = "Definir sourceCompatibility/targetCompatibility como JavaVersion.VERSION_17"
            AutoFix  = "None"
        }
    }
    if ($LogContent -match 'Serializable|NotSerializableException') {
        $erros += @{
            Tipo     = "Serializable"
            Mensagem = "Data class passada via Intent não implementa Serializable"
            Correcao = "Adicionar ': Serializable' à data class e 'import java.io.Serializable'"
            AutoFix  = "RunDependencyResolver"
        }
    }

    # ── Erros de Workflow ────────────────────────────────────────────────────
    if ($LogContent -match 'YAML error|Invalid workflow') {
        $erros += @{
            Tipo     = "Workflow"
            Mensagem = "Erro no YAML do workflow"
            Correcao = "Verificar .github/workflows/android.yml"
            AutoFix  = "None"
        }
    }

    # ── Erro genérico (fallback) ─────────────────────────────────────────────
    if ($erros.Count -eq 0) {
        $erros += @{
            Tipo     = "Build"
            Mensagem = "Build falhou (causa não identificada automaticamente)"
            Correcao = "Verificar logs completos em GitHub Actions"
            AutoFix  = "None"
        }
    }

    return $erros
}

function Invoke-BuildReportGenerator {
    param($BuildResult, $Artifacts, $Erros, $ElapsedTime)
    
    $relatorio = @{
        status = $BuildResult.Status
        conclusao = $BuildResult.Conclusion
        tempoBuild = "$ElapsedTime segundos"
        apkGerado = $Artifacts -contains "android-apk"
        downloadDisponivel = $Artifacts.Count -gt 0
        artefatos = @($Artifacts)
        erros = @($Erros | ForEach-Object { $_.Mensagem })
        correcoes = @($Erros | ForEach-Object { $_.Correcao })
        timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
    }
    
    return $relatorio
}

function Start-BuildOrchestrator {
    param([string]$Dir, [string]$Token, [string]$AIProvider = "DeepSeek", [string]$AIApiKey = $null,
        [System.Windows.Threading.Dispatcher]$Disp,
        [System.Windows.Controls.TextBox]$Log, [System.Windows.Controls.TextBlock]$Lbl,
        [System.Windows.Controls.Button]$BtnC, [System.Windows.Controls.Button]$BtnA,
        [System.Windows.Window]$Win, [System.Windows.Controls.ProgressBar]$ProgBar,
        [System.Windows.Controls.TextBlock]$LblProg, [bool]$UseAI = $false)

    $rs = [RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = 'STA'
    $rs.Open()
    $ps = [PowerShell]::Create()
    $ps.Runspace = $rs

    [void]$ps.AddScript({
        param($Dir, $Token, $AIProvider, $AIApiKey, $Disp, $Log, $Lbl, $BtnC, $BtnA, $Win, $ProgBar, $LblProg, $UseAI)

        function UILog([string]$msg, [string]$nivel = "INFO", [string]$detalhe = "") {
            $ts = Get-Date -Format "HH:mm:ss.fff"
            $line = "[$ts][$nivel] $msg"
            if (-not [string]::IsNullOrEmpty($detalhe)) {
                $line += " | $detalhe"
            }
            $Log.Dispatcher.Invoke([System.Action]{ $Log.AppendText($line + "`r`n"); $Log.ScrollToEnd() }.GetNewClosure())
        }

        function LogSuccess([string]$msg, [string]$detalhe = "") {
            UILog "[SUCESSO] $msg" "OK" $detalhe
        }

        function LogError([string]$msg, [string]$erro = "", [string]$correcao = "") {
            $detalhe = ""
            if (-not [string]::IsNullOrEmpty($erro)) {
                $detalhe += "ERRO: $erro"
            }
            if (-not [string]::IsNullOrEmpty($correcao)) {
                if (-not [string]::IsNullOrEmpty($detalhe)) { $detalhe += " | " }
                $detalhe += "CORREÇÃO: $correcao"
            }
            UILog "[ERRO] $msg" "ERRO" $detalhe
        }

        function LogEvent([string]$msg, [string]$detalhe = "") {
            UILog "[EVENTO] $msg" "INFO" $detalhe
        }

        function UpdateProgress([int]$value, [string]$message) {
            $ProgBar.Dispatcher.Invoke([System.Action]{ $ProgBar.Value = $value }.GetNewClosure())
            $LblProg.Dispatcher.Invoke([System.Action]{ $LblProg.Text = "$message ($value%)" }.GetNewClosure())
        }

        function Test-GitHubRepository {
            param([string]$Token, [string]$Owner, [string]$Repo)
            
            $headers = @{ "Authorization" = "Bearer $Token"; "Accept" = "application/vnd.github.v3+json" }
            $uri = "https://api.github.com/repos/$Owner/$Repo"
            
            try {
                Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop | Out-Null
                return $true
            } catch {
                if ($_.Exception.Response.StatusCode -eq 404) {
                    return $false
                }
                throw $_
            }
        }

        function New-GitHubRepository {
            param([string]$Token, [string]$RepoName, [string]$Description = "")
            
            $headers = @{ "Authorization" = "Bearer $Token"; "Accept" = "application/vnd.github.v3+json" }
            $uri = "https://api.github.com/user/repos"
            
            $body = @{
                name = $RepoName
                description = $Description
                private = $false
                auto_init = $false
            } | ConvertTo-Json
            
            try {
                $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body -ContentType "application/json"
                UILog "Repositório $RepoName criado com sucesso" "OK"
                return $response.html_url
            } catch {
                UILog "Erro ao criar repositório: $_" "ERRO"
                throw $_
            }
        }

        function Invoke-ArtifactDownloader {
            param([string]$Owner, [string]$Repo, [string]$Token, [string]$RunId, [string]$DestDir)

            $headers = @{ "Authorization" = "Bearer $Token"; "Accept" = "application/vnd.github.v3+json" }
            $artifactsData = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/actions/runs/$RunId/artifacts" -Headers $headers

            $apkPaths = @()

            foreach ($art in $artifactsData.artifacts) {
                try {
                    # 1. Baixar o ZIP do artefato
                    $zipPath = "$DestDir\$($art.name).zip"
                    $downloadUrl = $art.archive_download_url

                    # A API redireciona para URL temporária — usar WebClient para seguir redirect
                    $webClient = New-Object System.Net.WebClient
                    $webClient.Headers.Add("Authorization", "Bearer $Token")
                    $webClient.Headers.Add("User-Agent", "CompilaAPK/9.0")
                    $webClient.DownloadFile($downloadUrl, $zipPath)
                    $webClient.Dispose()

                    Write-Log "ZIP baixado: $($art.name).zip ($([Math]::Round((Get-Item $zipPath).Length / 1KB, 1)) KB)" "OK"

                    # 2. Descompactar o ZIP
                    $extractDir = "$DestDir\$($art.name)"
                    if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
                    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
                    Write-Log "ZIP extraído em: $extractDir" "OK"

                    # 3. Encontrar todos os .apk dentro do ZIP extraído
                    $apkFiles = Get-ChildItem -Path $extractDir -Filter "*.apk" -Recurse -ErrorAction SilentlyContinue
                    if ($apkFiles.Count -eq 0) {
                        Write-Log "Nenhum .apk encontrado dentro de $($art.name).zip" "AVISO"
                        continue
                    }

                    foreach ($apk in $apkFiles) {
                        # Copiar o .apk para a raiz do DestDir com nome limpo
                        $destApk = "$DestDir\$($apk.Name)"
                        Copy-Item $apk.FullName $destApk -Force
                        $apkPaths += $destApk
                        $sizeMB = [Math]::Round($apk.Length / 1MB, 2)
                        Write-Log "APK extraído: $($apk.Name) ($sizeMB MB) → $destApk" "OK"
                    }

                } catch {
                    Write-Log "Falha ao baixar/extrair $($art.name): $_" "ERRO"
                }
            }

            return $apkPaths
        }

        function Invoke-ErrorInterpreter {
            param([string]$LogContent)
            
            $erros = @()

            # ── Erros de Módulo / Projeto ────────────────────────────────────────────
            if ($LogContent -match "Project with path '([^']+)' could not be found|UnknownProjectException") {
                $modulo = if ($matches[1]) { $matches[1] } else { ":desconhecido" }
                $erros += @{
                    Tipo     = "ModuloAusente"
                    Mensagem = "Módulo '$modulo' não encontrado no projeto"
                    Correcao = "Remover referência a '$modulo' do app/build.gradle.kts e do settings.gradle.kts"
                    AutoFix  = "RemoveModuleRef"
                    Modulo   = $modulo
                }
            }

            # ── Erros de Package / Classe ────────────────────────────────────────────
            if ($LogContent -match "error: package .* does not exist|Unresolved reference") {
                if ($LogContent -match "Unresolved reference\s+'(clickable|tabIndicatorOffset|remember|mutableStateOf|getValue|setValue|dp|sp|Modifier|Alignment|Box|Column|Row|Spacer|Icons)'") {
                    $erros += @{
                        Tipo     = "ComposeImportAusente"
                        Mensagem = "Importação do Jetpack Compose ausente no código Kotlin"
                        Correcao = "Executar ImportRepairEngine para injetar automaticamente as importações necessárias"
                        AutoFix  = "RunImportRepairEngine"
                    }
                } else {
                    $erros += @{
                        Tipo     = "PackageAusente"
                        Mensagem = "Pacote ou referência não resolvida no código Kotlin"
                        Correcao = "Verificar imports e dependências no build.gradle.kts"
                        AutoFix  = "RunDependencyResolver"
                    }
                }
            }
            if ($LogContent -match "ClassNotFoundException|Could not find or load main class") {
                $erros += @{
                    Tipo     = "ClasseNaoEncontrada"
                    Mensagem = "Classe não encontrada: gradle-wrapper.jar ausente ou corrompido"
                    Correcao = "Substituir gradle-wrapper.jar pelo oficial do Gradle 8.7"
                    AutoFix  = "RebuildWrapper"
                }
            }

            # ── Erros de Manifesto / Recursos ─────────────────────────────────────────
            if ($LogContent -match "must be declared|exported|Android 12") {
                $erros += @{
                    Tipo     = "ExportedManifestError"
                    Mensagem = "Atributo 'android:exported' ausente na Activity principal para Android 12+"
                    Correcao = "Adicionar android:exported='true' no AndroidManifest.xml"
                    AutoFix  = "FixManifestExported"
                }
            }
            if ($LogContent -match "AAPT2 error|resource.*not found|Resource compilation failed") {
                $erros += @{
                    Tipo     = "ErroRecursos"
                    Mensagem = "Erro na compilação de recursos XML ou imagens do app"
                    Correcao = "Verificar imagens corrompidas ou XMLs inválidos na pasta res/"
                    AutoFix  = "FixResourceFiles"
                }
            }

            # ── Erros de Versão de JDK / Gradle ───────────────────────────────────────
            if ($LogContent -match "class file has wrong version|Unsupported class file major version|Unsupported Java") {
                $erros += @{
                    Tipo     = "JavaGradleMismatch"
                    Mensagem = "Incompatibilidade de versão entre Java (JDK) e Gradle"
                    Correcao = "Ajustar JDK para 17 no workflow ou atualizar Gradle para 8.2+"
                    AutoFix  = "UpgradeGradle"
                }
            }

            # ── Erros de Sintaxe Kotlin ──────────────────────────────────────────────
            if ($LogContent -match "error: expecting a member|Syntax error") {
                $erros += @{
                    Tipo     = "SyntaxError"
                    Mensagem = "Erro de sintaxe no código Kotlin principal"
                    Correcao = "Verificar chaves, parênteses e ponto-e-vírgula pendentes no arquivo .kt"
                    AutoFix  = "None"
                }
            }

            # Se nenhum erro conhecido foi mapeado mas há falha
            if ($erros.Count -eq 0) {
                $erros += @{
                    Tipo     = "ErroDesconhecido"
                    Mensagem = "Falha geral de compilação do Gradle"
                    Correcao = "Analise os logs detalhados do Gradle no painel do GitHub Actions"
                    AutoFix  = "None"
                }
            }

            return $erros
        }

        function Invoke-BuildFolderOrganizer {
            param([string]$ProjectPath, [string]$AppName, [string]$Timestamp)
            
            $sanitizedName = $AppName -replace '[^a-zA-Z0-9_-]', '_'
            $buildFolder = "${sanitizedName}_${Timestamp}"
            
            $tempDir = Join-Path $env:TEMP "apk-build-$Timestamp"
            $buildDir = Join-Path $tempDir $buildFolder
            
            # [AVISO] REMOVER diretório se já existir (limpeza de builds anteriores)
            if (Test-Path $tempDir) {
                LogEvent "Limpando diretório temporário existente" $tempDir
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            # Criar diretório FRESCO
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            
            # Criar estrutura
            New-Item -ItemType Directory -Path "$buildDir/apk" -Force | Out-Null
            
            # [SEARCH] DEBUG: Verificar se $projectPath contém arquivos
            LogEvent "[DEBUG] Verificando projeto fonte" $ProjectPath
            if (Test-Path $ProjectPath) {
                $sourceFiles = Get-ChildItem $ProjectPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object
                LogEvent "[DEBUG] Arquivos encontrados no projeto fonte" "$($sourceFiles.Count)"
                
                if ($sourceFiles.Count -eq 0) {
                    LogError "[DEBUG] Projeto fonte está vazio!" $ProjectPath "Verifique ReconstructionEngine"
                } else {
                    # Listar primeiros 10 arquivos para conferência
                    Get-ChildItem $ProjectPath -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 10 | ForEach-Object {
                        LogEvent "[DEBUG]   →" $_.FullName
                    }
                }
            } else {
                LogError "[DEBUG] Caminho do projeto não existe!" $ProjectPath
            }
            
            # Copiar arquivos do projeto reconstruído diretamente para a raiz do tempDir
            if (Test-Path $ProjectPath) {
                try {
                    $sourcePath = Join-Path $ProjectPath "*"
                    $copyResult = Copy-Item $sourcePath "$tempDir/" -Recurse -Force -PassThru -ErrorAction Stop
                    if (-not $copyResult) {
                        throw "Falha na cópia dos arquivos do projeto para o diretório temporário."
                    }
                    LogEvent "[DEBUG] Cópia concluída" "$($copyResult.Count) arquivos copiados"
                } catch {
                    LogError "[DEBUG] Erro na cópia" $_.Exception.Message
                    throw $_
                }
            }
            
            # [SEARCH] DEBUG: Verificar a cópia para $tempDir
            $destFiles = Get-ChildItem $tempDir -Recurse -File -ErrorAction SilentlyContinue | Measure-Object
            LogEvent "[DEBUG] Arquivos no diretório temporário" "$($destFiles.Count)"
            
            if ($destFiles.Count -gt 0) {
                # Listar primeiros 10 arquivos para conferência
                Get-ChildItem $tempDir -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 10 | ForEach-Object {
                    LogEvent "[DEBUG]   →" $_.FullName
                }
            } else {
                LogError "[DEBUG] Diretório temporário está vazio após cópia!" $tempDir
            }
            
            # [AVISO] NOVO: Garantir que o workflow YAML esteja na RAIZ do tempDir
            $workflowSource = Join-Path $ProjectPath ".github\workflows\android.yml"
            $workflowDestDir = Join-Path $tempDir ".github\workflows"
            New-Item -ItemType Directory -Path $workflowDestDir -Force | Out-Null
            if (Test-Path $workflowSource) {
                Copy-Item $workflowSource $workflowDestDir -Force
                LogEvent "Workflow copiado para raiz" "$workflowDestDir"
                LogEvent "[DEBUG] Workflow YAML existe" $workflowSource
            } else {
                LogError "[DEBUG] Workflow YAML não encontrado no projeto fonte!" $workflowSource
            }
            
            # [SEARCH] DEBUG: Verificar estrutura final
            LogEvent "[DEBUG] Estrutura final do tempDir" $tempDir
            Get-ChildItem $tempDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                LogEvent "[DEBUG]   [DIR]" $_.Name
            }
            
            return @{ TempDir = $tempDir; BuildDir = $buildDir; BuildFolder = $buildFolder }
        }

        function Update-BuildIndex {
            param([string]$RepoPath, [string]$BuildFolder, [string]$AppName, [string]$Timestamp)
            
            $readmePath = "$RepoPath/README.md"
            
            # Criar ou atualizar README
            if (Test-Path $readmePath) {
                $content = Get-Content $readmePath -Raw
            } else {
                $content = @"

# [PKG] APK Builds

| App | Data | Hora | APK |
|-----|------|------|-----|
"@
            }
            
            # Adicionar nova entrada
            $date = $Timestamp.Substring(0, 8)
            $time = $Timestamp.Substring(9, 6)
            $newEntry = "| $AppName | $date | $time | [Download](./app/build/outputs/apk/debug/app-debug.apk) |"
            
            # Verificar se já existe entrada para este build
            if ($content -notmatch [regex]::Escape($BuildFolder)) {
                $content = $content + "`n$newEntry"
            }
            
            Set-Content -Path $readmePath -Value $content -Encoding UTF8
            UILog "Índice de builds atualizado" "OK"
        }

        function Invoke-PreBuildValidator {
            param([string]$RootPath)
            
            $validacoes = @(
                @{ Arquivo = "AndroidManifest.xml"; Caminho = "$RootPath/app/src/main/AndroidManifest.xml"; Critico = $true }
                @{ Arquivo = "build.gradle.kts"; Caminho = "$RootPath/app/build.gradle.kts"; Critico = $true }
                @{ Arquivo = "settings.gradle.kts"; Caminho = "$RootPath/settings.gradle.kts"; Critico = $true }
                @{ Arquivo = "gradlew"; Caminho = "$RootPath/gradlew"; Critico = $true }
                @{ Arquivo = "MainActivity"; Caminho = "$RootPath/app/src/main/java"; Critico = $true }
            )
            
            $errosCriticos = @()
            foreach ($v in $validacoes) {
                if (-not (Test-Path $v.Caminho)) {
                    $errosCriticos += "CRÍTICO: $($v.Arquivo) ausente"
                }
            }
            
            return $errosCriticos.Count -eq 0
        }

        function Invoke-WorkflowGenerator {
            param([string]$RootPath)
            
            $workflowDir = "$RootPath/.github/workflows"
            New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
            
            $workflow = @'
name: Android APK Build Resiliente

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: 'Configurar JDK 17 (Solucao Principal)'
        id: setup-java-17
        uses: actions/setup-java@v4
        continue-on-error: true
        with:
          distribution: temurin
          java-version: 17
          cache: gradle

      - name: 'Configurar JDK 11 (Fallback se JDK 17 Falhar)'
        if: steps.setup-java-17.outcome == 'failure'
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 11
          cache: gradle

      - name: 'Setup Gradle Cache inteligente'
        uses: gradle/actions/setup-gradle@v4

      - name: Grant execute permission for gradlew
        run: chmod +x gradlew

      - name: 'Compilar APK com Agente de Auto-Cura IA'
        run: |
          chmod +x tools/self_healing_compiler.py
          python3 tools/self_healing_compiler.py
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

      - name: 'Localizar ferramentas do Android SDK'
        id: find-tools
        run: |
          ZIPALIGN=$(find $ANDROID_HOME/build-tools -name zipalign | sort -V | tail -n 1)
          APKSIGNER=$(find $ANDROID_HOME/build-tools -name apksigner | sort -V | tail -n 1)
          echo "zipalign=$ZIPALIGN" >> $GITHUB_OUTPUT
          echo "apksigner=$APKSIGNER" >> $GITHUB_OUTPUT

      - name: 'Auto-Gerar Keystore de Assinatura na Nuvem'
        run: |
          keytool -genkeypair -v -keystore release.jks -alias cloudalias -keyalg RSA -keysize 2048 -validity 10000 -storepass cloudpass -keypass cloudpass -dname "CN=APK,O=APK,C=BR"

      - name: 'Alinhar APK (zipalign) na Nuvem'
        run: |
          ${{ steps.find-tools.outputs.zipalign }} -p -f 4 app/build/outputs/apk/debug/app-debug.apk app/build/outputs/apk/debug/app-aligned.apk

      - name: 'Assinar APK (apksigner) na Nuvem'
        run: |
          ${{ steps.find-tools.outputs.apksigner }} sign --ks release.jks --ks-key-alias cloudalias --ks-pass pass:cloudpass --key-pass pass:cloudpass --out app/build/outputs/apk/debug/app-signed.apk app/build/outputs/apk/debug/app-aligned.apk

      - name: 'Upload APK Assinado e Pronto para Uso'
        uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: app/build/outputs/apk/debug/app-signed.apk
          retention-days: 7

      - name: 'Upload Build Logs'
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: build-logs
          path: |
            app/build/reports/
            build.log
          retention-days: 7
'@
            
            Set-Content -Path "$workflowDir/android.yml" -Value $workflow -Encoding UTF8
        }

        function Invoke-GitHubActionsMonitor {
            param([string]$Owner, [string]$Repo, [string]$Token, [string]$LastKnownRunId = $null, [scriptblock]$LogCallback, [scriptblock]$ProgressCallback, [int]$TimeoutMinutes = 20)

            $headers = @{ "Authorization" = "Bearer $Token"; "Accept" = "application/vnd.github.v3+json" }
            $startTime = Get-Date
            $timeout = $startTime.AddMinutes($TimeoutMinutes)
            $lastDotUpdate = Get-Date
            $dotCount = 0
            $estimatedBuildTime = 120  # segundos (2 minutos típico)

            & $LogCallback "[MONITOR] [SEARCH] Procurando execução do workflow..."
            & $LogCallback "[MONITOR] [TIME] Tempo máximo: ${TimeoutMinutes} minutos"

            # Aguardar a run criada pelo push aparecer (até 90 segundos)
            $run = $null
            $waitStart = Get-Date
            while (-not $run -and (Get-Date) -lt $waitStart.AddSeconds(90)) {
                Start-Sleep -Seconds 3
                try {
                    $uri = "https://api.github.com/repos/$Owner/$Repo/actions/runs?per_page=5"
                    $runs = Invoke-RestMethod -Uri $uri -Headers $headers -ErrorAction Stop
                    if ($runs.workflow_runs.Count -gt 0) {
                        if ($LastKnownRunId) {
                            # Procurar run mais nova que a última conhecida
                            $newRun = $runs.workflow_runs | Where-Object { [long]$_.id -gt [long]$LastKnownRunId } | Select-Object -First 1
                            if ($newRun) { $run = $newRun }
                        } else {
                            # Sem referência anterior: pegar a mais recente
                            $candidate = $runs.workflow_runs[0]
                            if ($candidate.status -ne "completed") {
                                $run = $candidate
                            } elseif ($candidate.created_at -gt (Get-Date).AddMinutes(-3).ToUniversalTime().ToString("o")) {
                                # Run concluída há menos de 3 minutos — pode ser a do push atual
                                $run = $candidate
                            }
                        }
                    }
                } catch {
                    # Continua tentando
                }

                if (-not $run) {
                    $dotCount++
                    $dots = "." * ($dotCount % 4)
                    & $LogCallback "[MONITOR] Aguardando nova run iniciar$dots"
                }
            }

            if (-not $run) {
                throw "Run não encontrada após 90 segundos. O push foi feito com sucesso, mas o workflow não iniciou. Verifique: https://github.com/$Owner/$Repo/actions"
            }

            $runId = $run.id
            & $LogCallback "[MONITOR] [OK] Nova run encontrada!"
            & $LogCallback "[MONITOR] [LINK] URL: https://github.com/$Owner/$Repo/actions/runs/$runId"
            & $LogCallback "[MONITOR] [INFO] Status inicial: $($run.status)"

            # Monitoramento EM TEMPO REAL
            $lastStatus = ''

            do {
                $elapsed = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 0)
                # Formatação segura do tempo (converte para int antes de usar 'D2')
                $minutes = [int][Math]::Floor($elapsed / 60)
                $seconds = [int]($elapsed % 60)
                $elapsedFormatted = "{0:D2}:{1:D2}" -f $minutes, $seconds

                try {
                    $uri = "https://api.github.com/repos/$Owner/$Repo/actions/runs/$runId"
                    $run = Invoke-RestMethod -Uri $uri -Headers $headers -ErrorAction Stop
                } catch {
                    & $LogCallback "[MONITOR] [AVISO] Erro ao verificar status. Tentando novamente em 5s..."
                    Start-Sleep -Seconds 5
                    continue
                }

                $status = $run.status
                $conclusion = $run.conclusion

                # ATUALIZAÇÃO VIVA A CADA 3 SEGUNDOS (mostra dots de atividade)
                if (((Get-Date) - $lastDotUpdate).TotalSeconds -ge 3) {
                    $dotCount++
                    $dots = "." * ($dotCount % 4)
                    $activityLine = "[MONITOR] [WAIT] Build em andamento$dots | Tempo: $elapsedFormatted | Status: $status"
                    if ($conclusion) {
                        $activityLine += " | Conclusão: $conclusion"
                    }
                    & $LogCallback $activityLine
                    $lastDotUpdate = Get-Date

                    # Buscar etapas reais em execução no GitHub Actions para progresso 100% realista
                    $realProgressUpdated = $false
                    try {
                        $jobsUri = "https://api.github.com/repos/$Owner/$Repo/actions/runs/$runId/jobs"
                        $jobsData = Invoke-RestMethod -Uri $jobsUri -Headers $headers -ErrorAction SilentlyContinue
                        if ($jobsData -and $jobsData.jobs -and $jobsData.jobs.Count -gt 0) {
                            $job = $jobsData.jobs[0]
                            $steps = $job.steps
                            
                            $activeStep = $null
                            $activeStepIndex = -1
                            for ($j = 0; $j -lt $steps.Count; $j++) {
                                if ($steps[$j].status -eq 'in_progress') {
                                    $activeStep = $steps[$j]
                                    $activeStepIndex = $j
                                    break
                                }
                            }
                            
                            if (-not $activeStep) {
                                for ($j = 0; $j -lt $steps.Count; $j++) {
                                    if ($steps[$j].status -eq 'queued') {
                                        $activeStep = $steps[$j]
                                        $activeStepIndex = $j
                                        break
                                    }
                                }
                            }
                            
                            if ($activeStep) {
                                $stepName = $activeStep.name
                                # Calcula porcentagem real baseada no índice da etapa (entre 70% e 98%)
                                $realPercent = [int](70 + [Math]::Floor(($activeStepIndex / $steps.Count) * 28))
                                
                                if ($ProgressCallback) {
                                    & $ProgressCallback $realPercent "Nuvem: $stepName ($elapsedFormatted)"
                                    $realProgressUpdated = $true
                                }
                            }
                        }
                    } catch {
                        # Silencia erros secundários da API de jobs
                    }

                    # Se falhar em obter as etapas reais, usa o fallback estimado anterior
                    if (-not $realProgressUpdated -and $ProgressCallback) {
                        $estimatedProgress = 70 + [Math]::Min(15, [Math]::Floor(($elapsed / $estimatedBuildTime) * 15))
                        & $ProgressCallback $estimatedProgress "Build em andamento ($elapsedFormatted)"
                    }
                }

                # ALERTA DE MUDANÇA DE STATUS (detalhado)
                if ($status -ne $lastStatus -or $conclusion) {
                    & $LogCallback ("=" * 50)
                    & $LogCallback "[MONITOR] [INFO] ATUALIZAÇÃO DE STATUS"
                    & $LogCallback "[MONITOR] Status: $status"
                    if ($conclusion) {
                        & $LogCallback "[MONITOR] Conclusão: $conclusion"
                    }
                    & $LogCallback "[MONITOR] Tempo decorrido: $elapsedFormatted"
                    & $LogCallback "[MONITOR] URL: https://github.com/$Owner/$Repo/actions/runs/$runId"
                    & $LogCallback ("=" * 50)
                    $lastStatus = $status
                }

                # Timeout
                if ((Get-Date) -gt $timeout) {
                    & $LogCallback "[MONITOR] [TIMEOUT] Timeout! Máximo de ${TimeoutMinutes} minutos excedido."
                    & $LogCallback "[MONITOR] Verifique manualmente: https://github.com/$Owner/$Repo/actions/runs/$runId"
                    throw "Timeout do build excedido"
                }

                # Build concluído
                if ($run.status -eq 'completed') {
                    & $LogCallback ""
                    & $LogCallback "═══════════════════════════════════════"
                    & $LogCallback "[MONITOR] [SUCESSO] BUILD CONCLUÍDO!"
                    & $LogCallback "[MONITOR] Status final: $conclusion"
                    & $LogCallback "[MONITOR] Tempo total: $elapsedFormatted"
                    & $LogCallback "[MONITOR] URL: https://github.com/$Owner/$Repo/actions/runs/$runId"
                    & $LogCallback "═══════════════════════════════════════"

                    return @{
                        RunId = $runId
                        Status = $status
                        Conclusion = $conclusion
                        RunUrl = $run.html_url
                        ElapsedTime = $elapsedFormatted
                        ElapsedSeconds = $elapsed
                    }
                }

                Start-Sleep -Seconds 3
            } while ($true)
        }

        try {
            $startTime = Get-Date
            LogEvent "BUILDORCHESTRATOR iniciado" "Diretório: $Dir"
            UILog "════════════════════════════════" "OK"
            UILog "BUILDORCHESTRATOR INICIADO" "OK"
            UILog "════════════════════════════════" "OK"
            
            # 1. PreBuildValidator
            UpdateProgress 5 "Validando estrutura pré-build"
            LogEvent "Iniciando validação pré-build" "Verificando arquivos críticos"
            $valido = Invoke-PreBuildValidator -RootPath $Dir
            if (-not $valido) {
                UpdateProgress 0 "Validação falhou"
                LogError "Validação pré-build falhou" "Arquivos críticos ausentes" "Execute RECONSTRUIR primeiro"
                return
            }
            UpdateProgress 10 "Validação pré-build aprovada"
            LogSuccess "Validação pré-build aprovada" "Todos os arquivos críticos presentes"
            
            # 2. GitIntegrationEngine
            UpdateProgress 15 "Inicializando Git"
            LogEvent "Iniciando Git" "Diretório: $Dir"
            Push-Location $Dir
            
            # Check if already a git repo
            if (-not (Test-Path ".git")) {
                LogEvent "Git não encontrado" "Executando git init"
                git init 2>&1 | Out-Null
                LogSuccess "Repositório Git inicializado"
            } else {
                LogEvent "Repositório Git já existe" "Reutilizando"
            }
            
            git config user.email "compilador@apk.local" 2>&1 | Out-Null
            git config user.name "Compilador APK" 2>&1 | Out-Null
            LogSuccess "Configuração Git definida" "User: compilador@apk.local"
            
            git add . 2>&1 | Out-Null
            LogSuccess "Arquivos adicionados ao staging"
            
            git commit -m "build: v9.0 automated build" 2>&1 | Out-Null
            LogSuccess "Commit criado" "Mensagem: build: v9.0 automated build"
            
            UpdateProgress 20 "Git inicializado"
            
            # 3. WorkflowGenerator
            UpdateProgress 25 "Gerando GitHub Actions workflow"
            LogEvent "Gerando workflow GitHub Actions" "Criando .github/workflows/android.yml"
            Invoke-WorkflowGenerator -RootPath $Dir
            LogSuccess "Workflow GitHub Actions gerado" "Java 17, Gradle, APK build"
            
            git add .github/workflows/android.yml 2>&1 | Out-Null
            git commit -m "chore: add GitHub Actions workflow" 2>&1 | Out-Null
            LogSuccess "Workflow commitado"
            
            UpdateProgress 30 "Workflow gerado"
            
            # 4. Configurar repositório de builds (apk-builds)
            UpdateProgress 35 "Configurando repositório de builds"
            $repoOwner = "idavidjunior"
            $repoName = "apk-builds"
            $buildsUrl = "https://github.com/$repoOwner/$repoName"
            LogEvent "Configurando repositório de builds" "Target: $repoOwner/$repoName"

            # Verificar/criar repositório apk-builds
            $repoExists = Test-GitHubRepository -Token $Token -Owner $repoOwner -Repo $repoName
            if (-not $repoExists) {
                LogEvent "Repositório de builds não existe" "Criando automaticamente"
                New-GitHubRepository -Token $Token -RepoName $repoName -Description "APKs compilados automaticamente pelo Compilador APK"
            } else {
                LogEvent "Repositório de builds encontrado" "Reutilizando"
            }

            # 5. Organizar build em subpasta com timestamp
            UpdateProgress 40 "Organizando build"
            $appName = if ($Dir -match '([^\\]+)$') { $Matches[1] } else { "App" }
            $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
            $buildOrg = Invoke-BuildFolderOrganizer -ProjectPath $Dir -AppName $appName -Timestamp $timestamp
            LogSuccess "Build organizado" "$($buildOrg.BuildFolder)"

            # Copiar projeto para subpasta organizada
            Push-Location $buildOrg.TempDir
            LogEvent "Preparando para push" "Subpasta: $($buildOrg.BuildFolder)"
            LogEvent "Diretório atual" $(Get-Location)

            # [AVISO] FORÇAR remoção de qualquer repositório Git anterior
            if (Test-Path ".git") {
                LogEvent "[DEBUG] Removendo repositório Git existente" ".git"
                Remove-Item ".git" -Recurse -Force -ErrorAction SilentlyContinue
                # Confirmar remoção
                if (Test-Path ".git") {
                    LogError "Falha ao remover repositório Git existente" "" "Verifique permissões"
                    Pop-Location
                    return
                }
                LogSuccess "Repositório Git anterior removido"
            }

            # Verificar e remover .gitignore que pode estar ocultando arquivos
            if (Test-Path ".gitignore") {
                LogEvent "[DEBUG] .gitignore encontrado" "Conteúdo:"
                Get-Content ".gitignore" | ForEach-Object {
                    LogEvent "[DEBUG]   →" $_
                }
                LogEvent "[DEBUG] Removendo .gitignore temporariamente"
                Remove-Item ".gitignore" -Force -ErrorAction SilentlyContinue
            }

            # Inicializar repositório Git no diretório temporário
            LogEvent "Inicializando Git no diretório temporário"
            $initResult = git init 2>&1
            if ($LASTEXITCODE -ne 0) {
                LogError "git init falhou" $initResult "Verifique permissões do diretório"
                Pop-Location
                return
            }
            LogSuccess "Repositório Git inicializado" "Branch: (default)"

            # Adicionar todos os arquivos ao staging
            LogEvent "Adicionando arquivos ao staging" "git add ."
            $addResult = git add . 2>&1
            if ($LASTEXITCODE -ne 0) {
                LogError "git add falhou" $addResult "Verifique se há arquivos no diretório"
                Pop-Location
                return
            }
            
            # Verificar se há arquivos para commit
            $status = git status --porcelain 2>&1
            if (-not $status) {
                LogError "[DEBUG] Nenhum arquivo para commitar" "" "Listando diretório:"
                Get-ChildItem . -Recurse -ErrorAction SilentlyContinue | Select-Object -First 20 | ForEach-Object {
                    LogEvent "[DEBUG]   →" $_.FullName
                }
                LogError "Nenhum arquivo foi adicionado ao Git" "" "Verifique se os arquivos do projeto estão acessíveis"
                Pop-Location
                return
            }
            
            $statusResult = git status --short 2>&1
            LogSuccess "Arquivos adicionados" "$statusResult"

            # Fazer commit inicial
            LogEvent "Criando commit inicial" "Mensagem: build: $buildFolder"
            $commitResult = git commit -m "build: $buildFolder" 2>&1
            if ($LASTEXITCODE -ne 0) {
                LogError "git commit falhou" $commitResult "Verifique se há arquivos para commitar"
                Pop-Location
                return
            }
            LogSuccess "Commit criado" "SHA: $(git rev-parse --short HEAD 2>&1)"

            # Renomear branch para main
            LogEvent "Renomeando branch para main"
            git branch -M main 2>&1 | Out-Null
            LogSuccess "Branch renomeada para main"

            # Configurar remote para repositório de builds
            git remote get-url origin 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                LogEvent "Remote origin não encontrado" "Adicionando novo remote"
                $authUrl = "https://$Token@github.com/$repoOwner/$repoName.git"
                git remote add origin $authUrl 2>&1 | Out-Null
                LogSuccess "Remote origin adicionado" $authUrl
            } else {
                LogEvent "Remote origin encontrado" "Atualizando URL"
                $authUrl = "https://$Token@github.com/$repoOwner/$repoName.git"
                git remote set-url origin $authUrl 2>&1 | Out-Null
                LogSuccess "Remote origin atualizado" $authUrl
            }
            
            UpdateProgress 45 "Repositório de builds configurado"
            LogSuccess "Repositório configurado" $buildsUrl

            # 6. Push para GitHub
            UpdateProgress 50 "Enviando código para GitHub"
            LogEvent "Iniciando push para GitHub" "Branch: main | Remote: origin"
            LogEvent "Verificando branch atual" $(git branch --show-current 2>&1)
            LogEvent "Verificando commits" "Total: $(git rev-list --count HEAD 2>&1)"

            # Buscar o ID da run mais recente ANTES do push para servir de referência de ID maior
            $lastKnownRunId = $null
            try {
                $headers = @{ "Authorization" = "Bearer $Token"; "Accept" = "application/vnd.github.v3+json" }
                $runsUri = "https://api.github.com/repos/$repoOwner/$repoName/actions/runs?per_page=1"
                $runsData = Invoke-RestMethod -Uri $runsUri -Headers $headers -ErrorAction SilentlyContinue
                if ($runsData.workflow_runs.Count -gt 0) {
                    $lastKnownRunId = $runsData.workflow_runs[0].id
                    LogEvent "ID da última run conhecida" "$lastKnownRunId"
                }
            } catch {
                LogEvent "Erro ao buscar última run conhecida" $_
            }

            $pushResult = git push -u origin main --force 2>&1
            if ($LASTEXITCODE -eq 0) {
                LogSuccess "Push realizado com sucesso" "Branch: main | Remote: origin"
                LogEvent "Push detalhes" "$pushResult"
                UILog "[INFO] Workflow deve iniciar em: https://github.com/$repoOwner/$repoName/actions" "INFO"
            } else {
                LogError "Push falhou" $pushResult "Causa provável: branch sem commits ou autenticação inválida"
                LogEvent "Verificando status do repositório" "Branch: $(git branch --show-current 2>&1)"
                LogEvent "Verificando commits" "Total: $(git rev-list --count HEAD 2>&1)"
                LogEvent "Verificando remote" "$(git remote -v 2>&1)"
                Pop-Location
                return
            }

            UpdateProgress 60 "Código enviado para GitHub"
            
            # 6. GitHubActionsMonitor (Inicia imediatamente sem o sleep de 20s)
            UpdateProgress 65 "Iniciando monitoramento do build"
            LogEvent "Iniciando monitoramento do build" "Timeout: 20 minutos"
            $buildResult = Invoke-GitHubActionsMonitor -Owner $repoOwner -Repo $repoName -Token $Token -LastKnownRunId $lastKnownRunId -LogCallback { param($msg) UILog $msg } -ProgressCallback { param($value, $message) UpdateProgress $value $message }
            
            # 7. Interpretar resultado
            if (($buildResult.Status -eq "completed") -and ($buildResult.Conclusion -eq "success")) {
                UpdateProgress 85 "BUILD SUCESSO"
                LogSuccess "Build concluído com sucesso" "Tempo: $($buildResult.ElapsedTime)s"
                UILog "Tempo: $($buildResult.ElapsedTime)s" "OK"
                
                # 8. ArtifactDownloader
                UpdateProgress 90 "Baixando artefatos"
                LogEvent "Baixando artefatos" "Run ID: $($buildResult.RunId)"
                $downloadDir = "$Dir\build-artifacts"
                New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
                LogSuccess "Diretório de artefatos criado" $downloadDir
                
                $artifacts = Invoke-ArtifactDownloader -Owner $repoOwner -Repo $repoName -Token $Token -RunId $buildResult.RunId -DestDir $downloadDir
                if ($artifacts.Count -gt 0) {
                    LogSuccess "APKs encontrados" "$($artifacts.Count) arquivo(s)"

                    # artifacts já são caminhos completos de .apk (retornados pelo novo ArtifactDownloader)
                    $apkFile = $null
                    foreach ($apkPath in $artifacts) {
                        if (Test-Path $apkPath) {
                            # Criar subpasta organizada e copiar
                            $apkDir = "$($buildOrg.BuildDir)\apk"
                            New-Item -ItemType Directory -Path $apkDir -Force | Out-Null
                            $apkDestPath = "$apkDir\$(Split-Path $apkPath -Leaf)"
                            Copy-Item $apkPath $apkDestPath -Force
                            LogSuccess "APK copiado para subpasta" "$($buildOrg.BuildFolder)\apk\$(Split-Path $apkPath -Leaf)"
                            $apkFile = $apkDestPath
                        }
                    }

                    # Abrir pasta do APK automaticamente
                    if ($apkFile -and (Test-Path $apkFile)) {
                        $apkFolder = Split-Path $apkFile -Parent
                        $apkSize = [Math]::Round((Get-Item $apkFile).Length / 1MB, 2)

                        UILog ""
                        UILog "═══════════════════════════════════════" "OK"
                        UILog "[SUCESSO] APK GERADO COM SUCESSO!" "OK"
                        UILog "Caminho: $apkFile" "OK"
                        UILog "Tamanho: ${apkSize} MB" "OK"
                        UILog "═══════════════════════════════════════" "OK"

                        LogEvent "Abrindo pasta do APK" $apkFolder
                        Start-Process explorer.exe -ArgumentList $apkFolder
                        LogSuccess "Pasta do APK aberta" $apkFolder
                    }

                    # Atualizar índice README.md
                    Update-BuildIndex -RepoPath $buildOrg.TempDir -BuildFolder $buildOrg.BuildFolder -AppName $appName -Timestamp $timestamp
                    
                    # Commitar e push do índice atualizado
                    Push-Location $buildOrg.TempDir
                    git add README.md 2>&1 | Out-Null
                    git add "$($buildOrg.BuildFolder)/" 2>&1 | Out-Null
                    git commit -m "build: add $appName build ($timestamp)" 2>&1 | Out-Null
                    git push origin main 2>&1 | Out-Null
                    Pop-Location
                    
                    LogSuccess "Índice de builds atualizado" "README.md"
                } else {
                    LogError "Nenhum artefato baixado" "Verifique se o build gerou APK"
                }
                
                UpdateProgress 95 "Artefatos baixados"
            } elseif ($buildResult.Status -eq "completed") {
                UpdateProgress 0 "BUILD FALHOU"
                LogError "Build falhou" "Conclusão: $($buildResult.Conclusion)" "Verifique os logs no GitHub Actions"
                UILog "Verifique os logs no GitHub Actions" "AVISO"
            } else {
                UpdateProgress 0 "BUILD TIMEOUT"
                LogError "Build timeout" "Status: $($buildResult.Status)" "O build excedeu o tempo limite de 20 minutos"
            }
            
            # 9. ErrorInterpreter (se houver falha) - busca logs reais da API
            if ($buildResult.Conclusion -ne "success") {
                LogEvent "Interpretando erros do build" "Buscando logs reais do GitHub Actions"
                $logContent = ""

                try {
                    $headers = @{ Authorization = "Bearer $Token"; "User-Agent" = "CompilaAPK/9.0" }

                    # Buscar job ID da run com falha
                    $jobsUri = "https://api.github.com/repos/$repoOwner/$repoName/actions/runs/$($buildResult.RunId)/jobs"
                    $jobsData = Invoke-RestMethod -Uri $jobsUri -Headers $headers -ErrorAction SilentlyContinue
                    $failedJob = $jobsData.jobs | Where-Object { $_.conclusion -eq "failure" } | Select-Object -First 1

                    if ($failedJob) {
                        # Buscar log texto do job
                        $logUri = "https://api.github.com/repos/$repoOwner/$repoName/actions/jobs/$($failedJob.id)/logs"
                        $logContent = Invoke-RestMethod -Uri $logUri -Headers $headers -ErrorAction SilentlyContinue
                        UILog "[MONITOR] [LOG] Log do job '$($failedJob.name)' obtido ($($logContent.Length) chars)" "INFO"

                        # Mostrar últimas linhas do log no painel
                        $logLines = $logContent -split "`n"
                        $lastLines = $logLines | Select-Object -Last 30
                        foreach ($line in $lastLines) {
                            if ($line -match 'error|FAILED|Exception|Caused by' -and $line.Trim()) {
                                UILog "  $($line.Trim())" "ERRO"
                            }
                        }
                    }
                } catch {
                    UILog "[AVISO] Não foi possível buscar logs via API: $($_.Exception.Message)" "AVISO"
                    $logContent = "Build failed - logs unavailable"
                }

                # Chamar ErrorInterpreter com log real
                $erros = Invoke-ErrorInterpreter -LogContent $logContent

                foreach ($erro in $erros) {
                    LogError $erro.Mensagem $erro.Tipo $erro.Correcao
                    UILog "[FIX] AutoFix disponível: $($erro.AutoFix)" "INFO"
                }

                # AutoFix automático baseado no tipo de erro detectado
                $autoFixRan = $false
                foreach ($erro in $erros) {
                    switch ($erro.AutoFix) {

                        "RemoveModuleRef" {
                            UILog "[AUTOFIX] Removendo referência ao módulo '$($erro.Modulo)'..." "INFO"
                            $settingsPath = "$RootPath\settings.gradle.kts"
                            $appBuildPath = "$RootPath\app\build.gradle.kts"
                            if (-not (Test-Path $settingsPath)) {
                                $found = Get-ChildItem -Path $RootPath -Filter "settings.gradle.kts" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
                                if ($found) { $settingsPath = $found.FullName }
                            }
                            if (-not (Test-Path $appBuildPath)) {
                                $found = Get-ChildItem -Path $RootPath -Filter "build.gradle.kts" -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -eq "app" } | Select-Object -First 1
                                if ($found) { $appBuildPath = $found.FullName }
                            }
                            if (Test-Path $settingsPath) {
                                $s = Get-Content $settingsPath -Raw -Encoding UTF8
                                $s = $s -replace "(?m)^\s*include\s*\(`"$([regex]::Escape($erro.Modulo))`"\)\s*\r?\n?", ""
                                Set-Content $settingsPath $s -Encoding UTF8
                                UILog "[AUTOFIX] [OK] Módulo '$($erro.Modulo)' removido de settings.gradle.kts em: $settingsPath" "OK"
                            }
                            if (Test-Path $appBuildPath) {
                                $b = Get-Content $appBuildPath -Raw -Encoding UTF8
                                $b = $b -replace "(?m)^\s*(implementation|api)\s*\(project\s*\(`"$([regex]::Escape($erro.Modulo))`"\)\s*\)\s*\r?\n?", ""
                                Set-Content $appBuildPath $b -Encoding UTF8
                                UILog "[AUTOFIX] [OK] Referência '$($erro.Modulo)' removida de: $appBuildPath" "OK"
                            }
                            $autoFixRan = $true
                        }

                        "UpdateGradleVersion" {
                            UILog "[AUTOFIX] Atualizando Gradle para versão $($erro.Versao)..." "INFO"
                            $wrapperPath = "$RootPath\gradle\wrapper\gradle-wrapper.properties"
                            if (-not (Test-Path $wrapperPath)) {
                                $found = Get-ChildItem -Path $RootPath -Filter "gradle-wrapper.properties" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
                                if ($found) { $wrapperPath = $found.FullName }
                            }
                            if (Test-Path $wrapperPath) {
                                $w = Get-Content $wrapperPath -Raw -Encoding UTF8
                                $w = $w -replace 'gradle-[\d\.]+-bin\.zip', "gradle-$($erro.Versao)-bin.zip"
                                Set-Content $wrapperPath $w -Encoding UTF8
                                UILog "[AUTOFIX] [OK] gradle-wrapper.properties atualizado para $($erro.Versao) em: $wrapperPath" "OK"
                            }
                            $autoFixRan = $true
                        }

                        { $_ -in "FixGradleWrapper", "RebuildWrapper" } {
                            UILog "[AUTOFIX] Substituindo gradle-wrapper.jar pelo oficial..." "INFO"
                            $jarPath = "$RootPath\gradle\wrapper\gradle-wrapper.jar"
                            if (-not (Test-Path $jarPath)) {
                                $found = Get-ChildItem -Path $RootPath -Filter "gradle-wrapper.jar" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
                                if ($found) { $jarPath = $found.FullName }
                            }
                            $jarUrl  = "https://raw.githubusercontent.com/gradle/gradle/v8.7.0/gradle/wrapper/gradle-wrapper.jar"
                            try {
                                # Garantir diretório pai
                                $parentDir = Split-Path $jarPath -Parent
                                if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Force -Path $parentDir | Out-Null }
                                $wc = New-Object System.Net.WebClient
                                $wc.DownloadFile($jarUrl, $jarPath)
                                $wc.Dispose()
                                UILog "[AUTOFIX] [OK] gradle-wrapper.jar oficial baixado (Gradle 8.7) em: $jarPath" "OK"
                                $autoFixRan = $true
                            } catch {
                                UILog "[AUTOFIX] [AVISO] Falha ao baixar wrapper: $($_.Exception.Message)" "AVISO"
                            }
                        }

                        "FixManifestExported" {
                            UILog "[AUTOFIX] Corrigindo android:exported no AndroidManifest.xml..." "INFO"
                            $manifestPath = "$RootPath\app\src\main\AndroidManifest.xml"
                            if (-not (Test-Path $manifestPath)) {
                                $found = Get-ChildItem -Path $RootPath -Filter "AndroidManifest.xml" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
                                if ($found) { $manifestPath = $found.FullName }
                            }
                            if (Test-Path $manifestPath) {
                                $m = Get-Content $manifestPath -Raw -Encoding UTF8
                                # Adicionar android:exported="true" em <activity> com intent-filter que não tenha exported
                                $m = [regex]::Replace($m, '(<activity(?![^>]*android:exported)[^>]*>)', '<activity android:exported="true"$1')
                                $m = $m -replace '<activity android:exported="true"><activity', '<activity android:exported="true"'
                                # Mais simples e robusto: sed-like direto
                                $m = $m -replace '(<activity\b)(?![^>]*android:exported)', '$1 android:exported="true"'
                                # Services exportados=false por padrão se não tiverem intent-filter público
                                $m = $m -replace '(<service\b)(?![^>]*android:exported)', '$1 android:exported="false"'
                                Set-Content $manifestPath $m -Encoding UTF8
                                UILog "[AUTOFIX] [OK] android:exported corrigido no Manifest em: $manifestPath" "OK"
                                $autoFixRan = $true
                            } else {
                                UILog "[AUTOFIX] [AVISO] AndroidManifest.xml não foi encontrado em $RootPath" "AVISO"
                            }
                        }

                        "FixResourceFiles" {
                            UILog "[AUTOFIX] Verificando e recriando recursos XML corrompidos..." "INFO"
                            $resPath = "$RootPath\app\src\main\res"
                            if (-not (Test-Path $resPath)) {
                                $found = Get-ChildItem -Path $RootPath -Directory -Filter "res" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match "src[\\/]main[\\/]res" } | Select-Object -First 1
                                if ($found) { $resPath = $found.FullName }
                            }
                            # Garantir diretório values
                            $valuesPath = Join-Path $resPath "values"
                            if (-not (Test-Path $valuesPath)) { New-Item -ItemType Directory -Force -Path $valuesPath | Out-Null }

                            # Recriar valores base se corrompidos
                            $stringsPath = Join-Path $valuesPath "strings.xml"
                            $colorsPath  = Join-Path $valuesPath "colors.xml"
                            $themesPath  = Join-Path $valuesPath "themes.xml"
                            if (-not (Test-Path $stringsPath) -or (Get-Item $stringsPath).Length -lt 30) {
                                Set-Content $stringsPath '<resources><string name="app_name">MeuApp</string></resources>' -Encoding UTF8
                                UILog "[AUTOFIX] [OK] strings.xml recriado em: $stringsPath" "OK"
                            }
                            if (-not (Test-Path $colorsPath) -or (Get-Item $colorsPath).Length -lt 30) {
                                Set-Content $colorsPath '<resources><color name="purple_200">#FFBB86FC</color><color name="purple_500">#FF6200EE</color><color name="purple_700">#FF3700B3</color><color name="teal_200">#FF03DAC5</color><color name="teal_700">#FF018786</color><color name="black">#FF000000</color><color name="white">#FFFFFFFF</color></resources>' -Encoding UTF8
                                UILog "[AUTOFIX] [OK] colors.xml recriado em: $colorsPath" "OK"
                            }
                            if (-not (Test-Path $themesPath) -or (Get-Item $themesPath).Length -lt 30) {
                                Set-Content $themesPath '<resources><style name="Theme.App" parent="Theme.MaterialComponents.DayNight.DarkActionBar"/></resources>' -Encoding UTF8
                                UILog "[AUTOFIX] [OK] themes.xml recriado em: $themesPath" "OK"
                            }
                            $autoFixRan = $true
                        }

                        { $_ -in "UpgradeGradle", "JavaGradleMismatch" } {
                            UILog "[AUTOFIX] Atualizando Gradle wrapper para 8.7 (compatível com JDK 17)..." "INFO"
                            $wrapperPath = "$RootPath\gradle\wrapper\gradle-wrapper.properties"
                            if (Test-Path $wrapperPath) {
                                $w = Get-Content $wrapperPath -Raw -Encoding UTF8
                                $w = $w -replace 'gradle-[\d\.]+-bin\.zip', "gradle-8.7-bin.zip"
                                Set-Content $wrapperPath $w -Encoding UTF8
                                UILog "[AUTOFIX] [OK] Gradle atualizado para 8.7" "OK"
                                $autoFixRan = $true
                            }
                        }

                        "RunManifestValidator" {
                            UILog "[AUTOFIX] Executando ManifestValidator..." "INFO"
                            Invoke-ManifestValidator -RootPath $RootPath | Out-Null
                            UILog "[AUTOFIX] [OK] ManifestValidator concluído" "OK"
                            $autoFixRan = $true
                        }

                        "RunDependencyResolver" {
                            UILog "[AUTOFIX] Executando DependencyResolver..." "INFO"
                            Invoke-DependencyResolver -RootPath $RootPath -AnalysisReport $AnalysisReport | Out-Null
                            UILog "[AUTOFIX] [OK] DependencyResolver concluído" "OK"
                            $autoFixRan = $true
                        }

                        "RunImportRepairEngine" {
                            UILog "[AUTOFIX] Executando ImportRepairEngine em todos os arquivos Kotlin..." "INFO"
                            Get-ChildItem "$RootPath\app\src\main\java" -Filter "*.kt" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                                Invoke-ImportRepairEngine -FilePath $_.FullName
                            }
                            UILog "[AUTOFIX] [OK] ImportRepairEngine concluído" "OK"
                            $autoFixRan = $true
                        }

                        "RunAICognitiveHealer" {
                            UILog "[AUTOFIX] Acionando o AI Cognitive Healer para reparo inteligente via IA..." "INFO"
                            $aiSuccess = Invoke-AICognitiveHealer -ErrorLog $LogContent -RootPath $RootPath
                            if ($aiSuccess) {
                                UILog "[AUTOFIX] [SUCESSO] IA Cognitiva corrigiu o código com sucesso!" "OK"
                                $autoFixRan = $true
                            } else {
                                UILog "[AUTOFIX] [AVISO] IA Cognitiva falhou ou chave de API não configurada. Executando DependencyResolver como fallback..." "AVISO"
                                Invoke-DependencyResolver -RootPath $RootPath -AnalysisReport $AnalysisReport | Out-Null
                                $autoFixRan = $true
                            }
                        }
                    }
                }

                # Se AutoFix foi aplicado, re-executar o build automaticamente
                if ($autoFixRan) {
                    UILog "" "INFO"
                    UILog "[AUTOFIX] AutoFix aplicado! Reiniciando build com as correções..." "INFO"
                    UILog "════════════════════════════════════════" "INFO"

                    # Buscar o ID da run mais recente ANTES do re-push
                    $repushLastKnownRunId = $null
                    try {
                        $runsUri = "https://api.github.com/repos/$repoOwner/$repoName/actions/runs?per_page=1"
                        $runsData = Invoke-RestMethod -Uri $runsUri -Headers $headers -ErrorAction SilentlyContinue
                        if ($runsData.workflow_runs.Count -gt 0) {
                            $repushLastKnownRunId = $runsData.workflow_runs[0].id
                        }
                    } catch { }

                    # Re-commit e re-push com as correções
                    Push-Location $tempDir
                    git add . 2>&1 | Out-Null
                    $fixTypes = ($erros | Where-Object { $_.AutoFix -ne "None" } | ForEach-Object { $_.Tipo }) -join ", "
                    git commit -m "autofix: corrige $fixTypes detectado pelo ErrorInterpreter" 2>&1 | Out-Null
                    $repushResult = git push origin main --force 2>&1
                    Pop-Location

                    if ($LASTEXITCODE -eq 0) {
                        UILog "[OK] Correções enviadas. Aguardando novo build..." "OK"
                        # Novo monitoramento do build re-executado (sem o sleep de 25s!)
                        $buildResult2 = Invoke-GitHubActionsMonitor -Owner $repoOwner -Repo $repoName -Token $Token -LastKnownRunId $repushLastKnownRunId `
                            -LogCallback { param($msg) UILog $msg } -ProgressCallback { param($v,$m) UpdateProgress $v $m }
                        if ($buildResult2.Conclusion -eq "success") {
                            UILog "[SUCESSO] BUILD CORRIGIDO COM SUCESSO PELO AUTOFIX!" "OK"
                            $buildResult = $buildResult2
                        } else {
                            UILog "[AVISO] Build ainda falhou após AutoFix. Verifique manualmente." "AVISO"
                            UILog "[LINK] https://github.com/$repoOwner/$repoName/actions" "INFO"
                        }
                    } else {
                        UILog "[AVISO] Falha ao re-enviar correções: $repushResult" "AVISO"
                    }
                }

            } else {
                $erros = @()
            }
            
            # 10. BuildReportGenerator
            $relatorio = @{
                status = $buildResult.Status
                conclusao = $buildResult.Conclusion
                tempoBuild = "$($buildResult.ElapsedTime)s"
                apkGerado = ($buildResult.Conclusion -eq "success")
                downloadDisponivel = $artifacts.Count -gt 0
                artefatos = @($artifacts)
                erros = @($erros | ForEach-Object { $_.Mensagem })
                timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
            }
            
            $totalTime = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
            UpdateProgress 100 "BUILDORCHESTRATOR CONCLUÍDO"
            
            UILog "════════════════════════════════" "OK"
            UILog "BUILDORCHESTRATOR CONCLUÍDO" "OK"
            UILog "Status: $($relatorio.status)" "OK"
            UILog "Conclusão: $($relatorio.conclusao)" "OK"
            UILog "Tempo total: ${totalTime}s" "OK"
            UILog "Repositório atualizado: https://github.com/$repoOwner/$repoName" "OK"
            UILog "════════════════════════════════" "OK"
            
            LogSuccess "BUILDORCHESTRATOR concluído" "Tempo total: ${totalTime}s | Status: $($relatorio.status)"
            
            Pop-Location
            
        } catch {
            UpdateProgress 0 "ERRO CRÍTICO"
            LogError "ERRO CRÍTICO no BUILDORCHESTRATOR" $_ "Verifique o stack trace abaixo"
            UILog "Stack: $($_.ScriptStackTrace)" "ERRO"
            UILog "Line: $($_.InvocationInfo.ScriptLineNumber)" "ERRO"
        } finally {
            $Disp.Invoke([System.Action]{ $BtnC.IsEnabled = $true; $BtnA.IsEnabled = $true; $Win.Cursor = "Arrow" }.GetNewClosure())
        }
    })

    [void]$ps.AddParameters(@{ Dir = $Dir; Token = $Token; AIProvider = $AIProvider; AIApiKey = $AIApiKey; Disp = $Disp; Log = $Log; Lbl = $Lbl; BtnC = $BtnC; BtnA = $BtnA; Win = $Win; ProgBar = $ProgBar; LblProg = $LblProg; UseAI = $UseAI })
    [void]$ps.BeginInvoke()
}

# ══════════════════════════════════════════════════════════════
# INTERFACE WPF v9.0
# ══════════════════════════════════════════════════════════════

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Compilador APK v9.0" Height="900" Width="1200" WindowStartupLocation="CenterScreen" Background="#F0F2F5">
  <ScrollViewer VerticalScrollBarVisibility="Auto">
  <StackPanel Margin="16,14,16,10">
    <Grid Margin="0,0,0,12">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="Auto"/>
      </Grid.ColumnDefinitions>
      <TextBlock Text="Compilador APK v9.5" FontSize="22" FontWeight="Bold" Foreground="#0078D7" Grid.Column="0" VerticalAlignment="Center"/>
      <Border Background="#E3F2FD" BorderBrush="#90CAF9" BorderThickness="1" CornerRadius="4" Padding="8,4" Grid.Column="1" VerticalAlignment="Center">
        <TextBlock Text="[FAST] Atualização Jetpack Compose Ativa (Coil3, DataStore, MediaSession, Auto-Cura de Imports)" FontSize="11" FontWeight="SemiBold" Foreground="#0D47A1"/>
      </Border>
    </Grid>
    
    <Border Background="White" CornerRadius="8" Padding="14" Margin="0,0,0,10">
      <StackPanel>
        <TextBlock Text="GitHub Token" FontWeight="SemiBold" Margin="0,0,0,8"/>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
          <PasswordBox x:Name="pwdToken" Grid.Column="0" FontFamily="Consolas" Padding="7,5" Margin="0,0,8,0"/>
          <Button x:Name="btnValidarToken" Grid.Column="1" Content="Validar" Width="80" Margin="0,0,6,0" Background="#28A745" Foreground="White" Padding="12,8"/>
          <Button x:Name="btnSalvarToken" Grid.Column="2" Content="Salvar Token" Width="120" Margin="0,0,6,0" Background="#0078D7" Foreground="White" Padding="12,8"/>
          <Button x:Name="btnLimparToken" Grid.Column="3" Content="Alterar" Width="80" Background="#6C757D" Foreground="White" Padding="12,8"/>
        </Grid>
        <TextBlock x:Name="lblTokenStatus" Text="" FontSize="11" Margin="0,8,0,0" Foreground="#28A745"/>
      </StackPanel>
    </Border>
    
    <Border Background="#FFF3E0" CornerRadius="8" Padding="14" Margin="0,0,0,10" BorderBrush="#FFB74D" BorderThickness="1">
      <StackPanel>
        <TextBlock Text="🤖 Provedor de IA" FontWeight="SemiBold" Margin="0,0,0,8" Foreground="#E65100"/>
        <ComboBox x:Name="cmbAIProvider" Margin="0,0,0,10" Padding="7,5" FontFamily="Segoe UI">
          <ComboBoxItem Content="DeepSeek" Tag="DeepSeek" IsSelected="True"/>
          <ComboBoxItem Content="OpenAI (GPT-4)" Tag="OpenAI"/>
          <ComboBoxItem Content="Anthropic (Claude)" Tag="Anthropic"/>
          <ComboBoxItem Content="Google Gemini" Tag="Google"/>
        </ComboBox>
        <TextBlock Text="API Key da IA" FontWeight="SemiBold" Margin="0,0,0,8" Foreground="#E65100"/>
        <TextBlock x:Name="lblAIProviderInfo" Text="Configure a API Key para usar análise inteligente automática." FontSize="11" Foreground="#E65100" Margin="0,0,0,8"/>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
          <PasswordBox x:Name="pwdAIKey" Grid.Column="0" FontFamily="Consolas" Padding="7,5" Margin="0,0,8,0"/>
          <Button x:Name="btnValidarAIKey" Grid.Column="1" Content="Validar" Width="80" Margin="0,0,6,0" Background="#28A745" Foreground="White" Padding="12,8"/>
          <Button x:Name="btnSalvarAIKey" Grid.Column="2" Content="Salvar" Width="100" Margin="0,0,6,0" Background="#FF6F00" Foreground="White" Padding="12,8"/>
          <Button x:Name="btnLimparAIKey" Grid.Column="3" Content="Limpar" Width="80" Background="#6C757D" Foreground="White" Padding="12,8"/>
        </Grid>
        <TextBlock x:Name="lblAIKeyStatus" Text="" FontSize="11" Margin="0,8,0,0" Foreground="#28A745"/>
      </StackPanel>
    </Border>
    
    <Border Background="White" CornerRadius="8" Padding="14" Margin="0,0,0,10">
      <StackPanel>
        <TextBlock Text="Fonte" FontWeight="SemiBold" Margin="0,0,0,8"/>
        <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
          <RadioButton x:Name="rbColar" Content="Colar" GroupName="fonte" IsChecked="True" Margin="0,0,18,0"/>
          <RadioButton x:Name="rbPrompt" Content="Prompt de IA" GroupName="fonte" Margin="0,0,18,0"/>
          <RadioButton x:Name="rbZip" Content="ZIP" GroupName="fonte" Margin="0,0,18,0"/>
          <RadioButton x:Name="rbPasta" Content="Pasta" GroupName="fonte"/>
        </StackPanel>
        <Grid x:Name="panelColar"><TextBox x:Name="txtCodigo" Height="300" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" TextWrapping="NoWrap" Background="#1E1E1E" Foreground="#DDD" FontFamily="Consolas" FontSize="12" Padding="8"/></Grid>
        <Grid x:Name="panelPrompt" Visibility="Collapsed"><TextBox x:Name="txtPrompt" Height="300" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" Background="#1E1E1E" Foreground="#DDD" FontFamily="Segoe UI" FontSize="12.5" Padding="8" ToolTip="Descreva detalhadamente o aplicativo que deseja gerar (ex: 'Um aplicativo de lista de tarefas moderno em Material 3 com Jetpack Compose...')"/></Grid>
        <Grid x:Name="panelZip" Visibility="Collapsed"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBox x:Name="txtZipPath" Grid.Column="0" IsReadOnly="True" Margin="0,0,8,0"/><Button x:Name="btnZip" Grid.Column="1" Content="ZIP" Width="80" Background="#0078D7" Foreground="White"/></Grid>
        <Grid x:Name="panelPasta" Visibility="Collapsed"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBox x:Name="txtPastaPath" Grid.Column="0" IsReadOnly="True" Margin="0,0,8,0"/><Button x:Name="btnPasta" Grid.Column="1" Content="Pasta" Width="80" Background="#0078D7" Foreground="White"/></Grid>
      </StackPanel>
    </Border>
    
    <Border Background="White" CornerRadius="8" Padding="14" Margin="0,0,0,10">
      <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <TextBlock Grid.Column="0" Text="Destino:" Margin="0,0,10,0" VerticalAlignment="Center"/>
        <TextBox x:Name="txtDiretorio" Grid.Column="1" IsReadOnly="True" Margin="0,0,8,0"/>
        <Button x:Name="btnDestino" Grid.Column="2" Content="Alterar" Width="80" Background="#6C757D" Foreground="White" Padding="12,8"/>
      </Grid>
    </Border>
    
    <Border Background="White" CornerRadius="8" Padding="14" Margin="0,0,0,10">
      <StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,10">
          <Button x:Name="btnAnalisar" Content="1 — ANALISAR" Width="180" Background="#28A745" Foreground="White" Margin="0,0,10,0" Padding="12,8"/>
          <Button x:Name="btnReconstruir" Content="2 — RECONSTRUIR" Width="180" Background="#FF8C00" Foreground="White" Margin="0,0,10,0" Padding="12,8"/>
          <Button x:Name="btnGerar" Content="3 — GERAR APK" Width="180" Background="#DC3545" Foreground="White" Padding="12,8"/>
        </StackPanel>
        <TextBlock x:Name="lblStatus" Text="Pronto para análise." FontSize="13" Foreground="#0078D7" FontWeight="SemiBold"/>
      </StackPanel>
    </Border>

    <Border Background="White" CornerRadius="8" Padding="14" Margin="0,0,0,10">
      <StackPanel>
        <Grid Margin="0,0,0,6"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBlock Grid.Column="0" Text="Log" FontWeight="SemiBold"/><Button x:Name="btnLimparLog" Grid.Column="1" Content="Limpar" Width="80" Background="#6C757D" Foreground="White"/></Grid>
        <TextBox x:Name="txtLog" Height="280" IsReadOnly="True" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" Background="#1A1A2E" Foreground="#E0E0E0" FontFamily="Consolas" FontSize="11" Padding="8"/>
      </StackPanel>
    </Border>

    <Border Background="White" CornerRadius="8" Padding="14" Margin="0,0,0,10">
      <StackPanel>
        <TextBlock Text="[SECURITY] Self-Healing Engine v9.0" FontWeight="Bold" FontSize="16" Foreground="#0078D7" Margin="0,0,0,10"/>
        <Grid Margin="0,0,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <CheckBox x:Name="chkSelfHealing" Grid.Column="0" Content="Ativar Auto-Cura" IsChecked="True" Margin="0,0,10,0" VerticalAlignment="Center"/>
          <TextBlock Grid.Column="1" Text="Package, Manifest, Dependências e Gradle — corrigidos automaticamente" FontSize="11" Foreground="#6C757D" VerticalAlignment="Center"/>
        </Grid>

        <TextBlock Text="Histórico de Recuperação" FontWeight="SemiBold" Margin="0,0,0,8"/>
        <Border Background="#F8F9FA" CornerRadius="4" Padding="8">
          <ScrollViewer Height="100" VerticalScrollBarVisibility="Auto">
            <StackPanel x:Name="panelRecoveryHistory">
              <TextBlock Text="Nenhuma recuperação registrada ainda." FontSize="11" Foreground="#6C757D" FontStyle="Italic"/>
            </StackPanel>
          </ScrollViewer>
        </Border>
      </StackPanel>
    </Border>

    <Border Background="White" CornerRadius="8" Padding="14" Margin="0,0,0,10">
      <StackPanel>
        <TextBlock Text="[AI] Auto-Cura Cognitiva Avançada (Opcional)" FontWeight="Bold" FontSize="16" Foreground="#6F42C1" Margin="0,0,0,10"/>
        <TextBlock Text="Se você configurar uma chave de API nos Secrets do seu repositório do GitHub (OPENAI_API_KEY, GEMINI_API_KEY ou ANTHROPIC_API_KEY), o orquestrador usará inteligência artificial para ler e corrigir erros lógicos complexos de forma autônoma!" FontSize="11.5" Foreground="#6C757D" TextWrapping="Wrap" Margin="0,0,0,10"/>
        
        <Grid Margin="0,0,0,10">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
          </Grid.ColumnDefinitions>
          <CheckBox x:Name="chkCognitiveHealing" Grid.Column="0" Content="Ativar Cura Cognitiva Inteligente" IsChecked="True" Margin="0,0,10,0" VerticalAlignment="Center"/>
          <TextBlock Grid.Column="1" Text="Envia relatórios de erro para o LLM propor correções cirúrgicas em caso de falha de build" FontSize="11" Foreground="#6C757D" VerticalAlignment="Center"/>
        </Grid>
        
        <TextBlock Text="Dica: O Google Gemini API oferece uma chave gratuita excelente para desenvolvedores (até 15 RPM grátis)!" FontSize="11" Foreground="#28A745" FontWeight="SemiBold"/>
      </StackPanel>
    </Border>
    
    <Border Background="White" CornerRadius="8" Padding="14">
      <StackPanel>
        <TextBlock Text="Progresso do Build" FontWeight="SemiBold" Margin="0,0,0,8"/>
        <ProgressBar x:Name="progressBar" Height="25" Minimum="0" Maximum="100" Value="0" Margin="0,0,0,6"/>
        <TextBlock x:Name="lblProgresso" Text="Aguardando início..." FontSize="12" Foreground="#6C757D"/>
      </StackPanel>
    </Border>
  </StackPanel>
  </ScrollViewer>
</Window>
'@

$reader = [System.Xml.XmlNodeReader]::new(([xml]$xaml))
$window = [Windows.Markup.XamlReader]::Load($reader)

$pwdToken = $window.FindName("pwdToken")
$btnValidarToken = $window.FindName("btnValidarToken")
$btnSalvarToken = $window.FindName("btnSalvarToken")
$btnLimparToken = $window.FindName("btnLimparToken")
$lblTokenStatus = $window.FindName("lblTokenStatus")
$cmbAIProvider = $window.FindName("cmbAIProvider")
$lblAIProviderInfo = $window.FindName("lblAIProviderInfo")
$pwdAIKey = $window.FindName("pwdAIKey")
$btnValidarAIKey = $window.FindName("btnValidarAIKey")
$btnSalvarAIKey = $window.FindName("btnSalvarAIKey")
$btnLimparAIKey = $window.FindName("btnLimparAIKey")
$lblAIKeyStatus = $window.FindName("lblAIKeyStatus")
$rbColar = $window.FindName("rbColar")
$rbPrompt = $window.FindName("rbPrompt")
$rbZip = $window.FindName("rbZip")
$rbPasta = $window.FindName("rbPasta")
$panelColar = $window.FindName("panelColar")
$panelPrompt = $window.FindName("panelPrompt")
$panelZip = $window.FindName("panelZip")
$panelPasta = $window.FindName("panelPasta")
$txtCodigo = $window.FindName("txtCodigo")
$txtPrompt = $window.FindName("txtPrompt")
$txtZipPath = $window.FindName("txtZipPath")
$txtPastaPath = $window.FindName("txtPastaPath")
$btnZip = $window.FindName("btnZip")
$btnPasta = $window.FindName("btnPasta")
$txtDiretorio = $window.FindName("txtDiretorio")
$btnDestino = $window.FindName("btnDestino")
$lblStatus = $window.FindName("lblStatus")
$txtLog = $window.FindName("txtLog")
$btnLimparLog = $window.FindName("btnLimparLog")
$progressBar = $window.FindName("progressBar")
$lblProgresso = $window.FindName("lblProgresso")
$btnAnalisar = $window.FindName("btnAnalisar")
$btnReconstruir = $window.FindName("btnReconstruir")
$btnGerar = $window.FindName("btnGerar")
$chkSelfHealing = $window.FindName("chkSelfHealing")
$chkCognitiveHealing = $window.FindName("chkCognitiveHealing")

$panelRecoveryHistory = $window.FindName("panelRecoveryHistory")

$global:LogTextBox = $txtLog
$global:LblStatus = $lblStatus

# Carregar tokens salvos
Import-Token

$btnReconstruir.IsEnabled = $false
$btnGerar.IsEnabled = $false
$txtDiretorio.Text = [Environment]::GetFolderPath("Desktop") + "\ProjetoAndroid"

$rbColar.Add_Checked({ $panelColar.Visibility = "Visible"; $panelPrompt.Visibility = "Collapsed"; $panelZip.Visibility = "Collapsed"; $panelPasta.Visibility = "Collapsed" })
$rbPrompt.Add_Checked({ $panelColar.Visibility = "Collapsed"; $panelPrompt.Visibility = "Visible"; $panelZip.Visibility = "Collapsed"; $panelPasta.Visibility = "Collapsed" })
$rbZip.Add_Checked({ $panelColar.Visibility = "Collapsed"; $panelPrompt.Visibility = "Collapsed"; $panelZip.Visibility = "Visible"; $panelPasta.Visibility = "Collapsed" })
$rbPasta.Add_Checked({ $panelColar.Visibility = "Collapsed"; $panelPrompt.Visibility = "Collapsed"; $panelZip.Visibility = "Collapsed"; $panelPasta.Visibility = "Visible" })

$btnZip.Add_Click({ $dlg = New-Object System.Windows.Forms.OpenFileDialog; $dlg.Filter = "ZIP|*.zip"; if ($dlg.ShowDialog() -eq "OK") { $txtZipPath.Text = $dlg.FileName } })
$btnPasta.Add_Click({ $dlg = New-Object System.Windows.Forms.FolderBrowserDialog; if ($dlg.ShowDialog() -eq "OK") { $txtPastaPath.Text = $dlg.SelectedPath } })
$btnDestino.Add_Click({ $dlg = New-Object System.Windows.Forms.FolderBrowserDialog; $dlg.ShowNewFolderButton = $true; if ($dlg.ShowDialog() -eq "OK") { $txtDiretorio.Text = $dlg.SelectedPath } })

# Event Handler: Validar GitHub Token
$btnValidarToken.Add_Click({
    $token = $pwdToken.Password
    if ([string]::IsNullOrEmpty($token)) {
        $lblTokenStatus.Text = "ERRO: Token não fornecido"
        $lblTokenStatus.Foreground = "#DC3545"
        return
    }
    
    $lblTokenStatus.Text = "Validando..."
    $lblTokenStatus.Foreground = "#FFC107"
    
    try {
        $result = Test-GitHubToken -Token $token
        if ($result.Valid) {
            $lblTokenStatus.Text = "✓ Token válido (usuário: $($result.User))"
            $lblTokenStatus.Foreground = "#28A745"
            $global:GitHubToken = $token
        } else {
            $lblTokenStatus.Text = "✗ Token inválido: $($result.Error)"
            $lblTokenStatus.Foreground = "#DC3545"
        }
    } catch {
        $lblTokenStatus.Text = "✗ Erro na validação: $($_.Exception.Message)"
        $lblTokenStatus.Foreground = "#DC3545"
    }
})

# Event Handler: Salvar GitHub Token
$btnSalvarToken.Add_Click({
    $token = $pwdToken.Password
    if ([string]::IsNullOrEmpty($token)) {
        $lblTokenStatus.Text = "ERRO: Token não fornecido"
        $lblTokenStatus.Foreground = "#DC3545"
        return
    }
    
    # Validar antes de salvar
    $result = Test-GitHubToken -Token $token
    if ($result.Valid) {
        $global:GitHubToken = $token
        Save-Token $token
        $lblTokenStatus.Text = "✓ Token salvo e validado (usuário: $($result.User))"
        $lblTokenStatus.Foreground = "#28A745"
    } else {
        $lblTokenStatus.Text = "✗ Token inválido: $($result.Error)"
        $lblTokenStatus.Foreground = "#DC3545"
    }
})

# Event Handler: Limpar GitHub Token
$btnLimparToken.Add_Click({
    $pwdToken.Password = ""
    $global:GitHubToken = $null
    $lblTokenStatus.Text = "Token limpo"
    $lblTokenStatus.Foreground = "#6C757D"
})

# Event Handler: Seleção de Provedor de IA
$cmbAIProvider.Add_SelectionChanged({
    $selectedItem = $cmbAIProvider.SelectedItem
    if ($selectedItem) {
        $provider = $selectedItem.Tag.ToString()
        $global:AIProvider = $provider
        Set-AIProvider -Provider $provider
        
        # Atualizar informações do provedor
        $infoText = switch ($provider) {
            "DeepSeek" { "Configure a API Key para usar análise inteligente automática. Obtenha em: https://platform.deepseek.com/" }
            "OpenAI" { "Configure a API Key para usar análise inteligente automática. Obtenha em: https://platform.openai.com/api-keys" }
            "Anthropic" { "Configure a API Key para usar análise inteligente automática. Obtenha em: https://console.anthropic.com/" }
            "Google" { "Configure a API Key para usar análise inteligente automática. Obtenha em: https://makersuite.google.com/app/apikey" }
            default { "Configure a API Key para usar análise inteligente automática." }
        }
        $lblAIProviderInfo.Text = $infoText
        
        # Limpar status anterior
        $lblAIKeyStatus.Text = ""
        $pwdAIKey.Password = ""
        
        Write-Log "Provedor de IA alterado para: $provider" "INFO"
    }
})

# Event Handler: Validar API Key da IA
$btnValidarAIKey.Add_Click({
    $apiKey = $pwdAIKey.Password
    if ([string]::IsNullOrEmpty($apiKey)) {
        $lblAIKeyStatus.Text = "ERRO: API Key não fornecida"
        $lblAIKeyStatus.Foreground = "#DC3545"
        return
    }
    
    $lblAIKeyStatus.Text = "Validando..."
    $lblAIKeyStatus.Foreground = "#FFC107"
    
    # Configurar a API Key temporariamente para validação
    Set-AIApiKey -ApiKey $apiKey -SaveSecurely $false
    
    try {
        $result = Test-AIApiKey
        if ($result.Valid) {
            $lblAIKeyStatus.Text = "✓ API Key válida para $($result.Provider)"
            $lblAIKeyStatus.Foreground = "#28A745"
            $global:AIApiKey = $apiKey
        } else {
            $lblAIKeyStatus.Text = "✗ API Key inválida: $($result.Error)"
            $lblAIKeyStatus.Foreground = "#DC3545"
        }
    } catch {
        $lblAIKeyStatus.Text = "✗ Erro na validação: $($_.Exception.Message)"
        $lblAIKeyStatus.Foreground = "#DC3545"
    }
})

# Event Handler: Salvar API Key da IA
$btnSalvarAIKey.Add_Click({
    $apiKey = $pwdAIKey.Password
    if ([string]::IsNullOrEmpty($apiKey)) {
        $lblAIKeyStatus.Text = "ERRO: API Key não fornecida"
        $lblAIKeyStatus.Foreground = "#DC3545"
        return
    }
    
    # Validar antes de salvar
    Set-AIApiKey -ApiKey $apiKey -SaveSecurely $false
    $result = Test-AIApiKey
    if ($result.Valid) {
        Set-AIApiKey -ApiKey $apiKey -SaveSecurely $true
        $global:AIApiKey = $apiKey
        $lblAIKeyStatus.Text = "✓ API Key salva e validada para $($result.Provider)"
        $lblAIKeyStatus.Foreground = "#28A745"
    } else {
        $lblAIKeyStatus.Text = "✗ API Key inválida: $($result.Error)"
        $lblAIKeyStatus.Foreground = "#DC3545"
    }
})

# Event Handler: Limpar API Key da IA
$btnLimparAIKey.Add_Click({
    $pwdAIKey.Password = ""
    Remove-AIApiKey
    $global:AIApiKey = $null
    $lblAIKeyStatus.Text = "API Key limpa"
    $lblAIKeyStatus.Foreground = "#6C757D"
})
$btnLimparLog.Add_Click({ $txtLog.Clear() })

# Carregar tokens salvos ao iniciar
Import-Token

# Carregar configuração de IA salva
if (Test-AIApiKeyConfigured) {
    $savedKey = Get-AIApiKey
    if ($savedKey) {
        Write-Log "API Key de IA carregada do Credential Manager" "OK"
        $lblAIKeyStatus.Text = "✓ API Key carregada para $(Get-AIProvider)"
        $lblAIKeyStatus.Foreground = "#28A745"
    }
}

# Event Handlers do Self-Healing Engine
$chkSelfHealing.Add_Checked({ $global:SelfHealingEnabled = $true; Write-Log "Auto-Cura ATIVADA" "OK" })
$chkSelfHealing.Add_Unchecked({ $global:SelfHealingEnabled = $false; Write-Log "Auto-Cura DESATIVADA" "AVISO" })

$global:CognitiveHealingEnabled = $true
$chkCognitiveHealing.Add_Checked({ $global:CognitiveHealingEnabled = $true; Write-Log "Cura Cognitiva Inteligente ATIVADA" "OK" })
$chkCognitiveHealing.Add_Unchecked({ $global:CognitiveHealingEnabled = $false; Write-Log "Cura Cognitiva Inteligente DESATIVADA" "AVISO" })

function Update-RecoveryHistoryUI {
    $panelRecoveryHistory.Children.Clear()
    if ($global:RecoveryHistory.Count -eq 0) {
        $panelRecoveryHistory.Children.Add((New-Object System.Windows.Controls.TextBlock -Property @{
            Text = "Nenhuma recuperação registrada ainda."
            FontSize = 11
            Foreground = "#6C757D"
            FontStyle = "Italic"
        }))
    } else {
        foreach ($entry in $global:RecoveryHistory) {
            $badge = New-Object System.Windows.Controls.Border -Property @{
                Background = "#D4EDDA"
                CornerRadius = 4
                Padding = "8,4"
                Margin = "0,0,0,4"
            }
            $stack = New-Object System.Windows.Controls.StackPanel
            $timestamp = New-Object System.Windows.Controls.TextBlock -Property @{
                Text = "[$($entry.Timestamp)]"
                FontSize = 10
                Foreground = "#155724"
                FontWeight = "Bold"
            }
            $strategy = New-Object System.Windows.Controls.TextBlock -Property @{
                Text = "[SECURITY] $($entry.Strategy)"
                FontSize = 11
                Foreground = "#155724"
                FontWeight = "SemiBold"
            }
            $details = New-Object System.Windows.Controls.TextBlock -Property @{
                Text = $entry.Details
                FontSize = 10
                Foreground = "#155724"
                TextWrapping = "Wrap"
            }
            $stack.Children.Add($timestamp) | Out-Null
            $stack.Children.Add($strategy) | Out-Null
            $stack.Children.Add($details) | Out-Null
            $badge.Child = $stack
            $panelRecoveryHistory.Children.Add($badge) | Out-Null
        }
    }
}



$btnAnalisar.Add_Click({
    $window.Cursor = "Wait"
    $btnReconstruir.IsEnabled = $false
    $btnGerar.IsEnabled = $false
    
    $codigo = if ($rbColar.IsChecked) { $txtCodigo.Text } elseif ($rbPrompt.IsChecked) { $txtPrompt.Text } else { "" }
    $caminho = if ($rbZip.IsChecked) { $txtZipPath.Text } elseif ($rbPasta.IsChecked) { $txtPastaPath.Text } else { "" }
    $tipo = if ($rbColar.IsChecked) { "COLADO" } elseif ($rbPrompt.IsChecked) { "PROMPT" } elseif ($rbZip.IsChecked) { "ZIP" } else { "PASTA" }
    
    $report = Invoke-AnalysisEngine -Conteudo $codigo -CaminhoFonte $caminho -TipoFonte $tipo
    if ($null -ne $report) {
        $btnReconstruir.IsEnabled = $true
        if ($global:AnalysisReport.Compilavel -or $tipo -eq "PROMPT") { $btnGerar.IsEnabled = $true }
    }
    
    $window.Cursor = "Arrow"
})

$btnReconstruir.Add_Click({
    $window.Cursor = "Wait"
    $btnGerar.IsEnabled = $false
    
    $codigo = if ($rbColar.IsChecked) { $txtCodigo.Text } elseif ($rbPrompt.IsChecked) { $txtPrompt.Text } else { "" }
    $destino = $txtDiretorio.Text
    
    $report = Invoke-ReconstructionEngine -RootPath $destino -Conteudo $codigo -AnalysisReport $global:AnalysisReport
    if ($null -ne $report) {
        $btnGerar.IsEnabled = $true
    }
    
    $window.Cursor = "Arrow"
})

$btnGerar.Add_Click({
    if ([string]::IsNullOrEmpty($global:GitHubToken)) {
        Write-Log "Token GitHub não configurado" "ERRO"
        return
    }
    
    # Verifica se deve usar IA
    $useAI = -not [string]::IsNullOrEmpty($global:DeepSeekApiKey)
    
    if ($useAI) {
        Write-Log "[IA] API Key DeepSeek configurada. Usando análise inteligente..." "OK"
    }
    
    $btnAnalisar.IsEnabled = $false
    $btnReconstruir.IsEnabled = $false
    $btnGerar.IsEnabled = $false
    $window.Cursor = "Wait"
    $progressBar.Value = 0
    $lblProgresso.Text = "Aguardando início..."

    # Se for um prompt de IA, garante que a reconstrução (geração do prompt.txt) foi executada
    if ($rbPrompt.IsChecked) {
        Write-Log "Iniciando geração automática do projeto a partir do Prompt de IA..." "INFO"
        $codigo = $txtPrompt.Text
        $destino = $txtDiretorio.Text
        $report = Invoke-ReconstructionEngine -RootPath $destino -Conteudo $codigo -AnalysisReport $global:AnalysisReport
        if ($null -eq $report) {
            Write-Log "Falha ao preparar o projeto a partir do Prompt de IA." "ERRO"
            $btnAnalisar.IsEnabled = $true
            $btnReconstruir.IsEnabled = $true
            $btnGerar.IsEnabled = $true
            $window.Cursor = "Arrow"
            return
        }
    }
    
    Start-BuildOrchestrator -Dir $txtDiretorio.Text -Token $global:GitHubToken -AIProvider $global:AIProvider -AIApiKey $global:AIApiKey `
        -Disp $window.Dispatcher -Log $txtLog -Lbl $lblStatus -BtnC $btnGerar -BtnA $btnAnalisar -Win $window `
        -ProgBar $progressBar -LblProg $lblProgresso -UseAI:$useAI
})

if (Import-Token) { $pwdToken.Password = $global:GitHubToken }

Write-Log "Compilador APK v10.0 (AI-Powered Multi-IA) iniciado"
Write-Log "Fluxo: ANALISAR → RECONSTRUIR → GERAR APK"
if ($global:AIApiKey) {
    Write-Log "[IA] API de IA configurada ($($global:AIProvider)) - Análise inteligente ativa" "OK"
} else {
    Write-Log "[IA] Configure uma API Key para usar análise inteligente" "AVISO"
}

$window.ShowDialog() | Out-Null
