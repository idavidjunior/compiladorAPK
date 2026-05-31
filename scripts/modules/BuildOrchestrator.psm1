# ============================================================
# Módulo BuildOrchestrator - Orquestrador de Compilação com Resiliência
# Compilador APK v9.1 (Auto-Engineer)
# ============================================================

# Importar módulos de resiliência e GitHub API
Import-Module (Join-Path $PSScriptRoot "Resiliency.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "GitHubAPI.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "ReconstructionEngine.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "AIApiProvider.psm1") -Force -ErrorAction SilentlyContinue

# Timeout absoluto para builds (30 minutos)
$script:BuildTimeoutMinutes = 30

<#
.SYNOPSIS
    Intérprete Cognitivo de Erros
.DESCRIPTION
    Classifica erros do Gradle e aciona as correções correspondentes
.PARAMETER GradleOutput
    Saída do Gradle com erros
.PARAMETER RootPath
    Caminho raiz do projeto
.OUTPUTS
    Array de hashtables com ações de correção
#>
function Invoke-ErrorInterpreter {
    param([string]$GradleOutput, [string]$RootPath)
    
    $actions = @()
    
    # 1. Erro de Unresolved Reference → Import ausente
    if ($GradleOutput -match "Unresolved reference[:\s]+'(\w+)'") {
        $missingImport = $Matches[1]
        Write-Log "[ERRO] Import ausente detectado: '$missingImport'" "ERRO"
        Write-Log "[AÇÃO] Acionando Invoke-ImportRepairEngine..." "INFO"
        
        $fixed = Invoke-ImportRepairEngine -RootPath $RootPath
        if ($fixed -gt 0) {
            $actions += @{
                type = "CompileImportFixed"
                message = "Import '$missingImport' adicionado automaticamente"
                action = "Recompilar"
            }
        } else {
            $actions += @{
                type = "CompileImportNaoResolvido"
                message = "Import '$missingImport' não encontrado no dicionário de regras"
                action = "Adicionar manualmente"
            }
        }
    }
    
    # 2. Erro de classe/material não encontrado → Dependência faltando
    if ($GradleOutput -match "Cannot access class|NoClassDefFoundError|ClassNotFoundException[:\s]+'?([\w.]+)'?") {
        $missingClass = $Matches[1]
        Write-Log "[ERRO] Classe não encontrada: '$missingClass'" "ERRO"
        
        # Mapeamento de classes → dependências
        $classToDep = @{
            'AsyncImage' = 'Coil'
            'DataStore' = 'DataStore'
            'Serializable' = 'Serialization'
            'MediaSessionCompat' = 'MediaSession'
            'NavController' = 'Navigation'
        }
        
        foreach ($class in $classToDep.Keys) {
            if ($missingClass -match $class) {
                $tech = $classToDep[$class]
                Write-Log "[AÇÃO] Injetando dependência: $tech" "INFO"
                # Reexecutar injeção de dependências
                $injected = Invoke-IntelligentDependencyInjection -RootPath $RootPath -CodeContent (Get-Content "$RootPath/app/src/main/java" -Raw -ErrorAction SilentlyContinue)
                if ($injected.Count -gt 0) {
                    $actions += @{
                        type = "DependencyInjected"
                        message = "Dependência para '$tech' injetada"
                        action = "Recompilar"
                    }
                }
                break
            }
        }
    }
    
    # 3. Erro de android:exported ausente → Manifest incompleto
    if ($GradleOutput -match "android:exported.*required|Missing 'exported' attribute") {
        Write-Log "[ERRO] Manifest sem android:exported" "ERRO"
        Write-Log "[AÇÃO] Corrigindo AndroidManifest.xml..." "INFO"
        # Corrigir manifest
        $manifestPath = "$RootPath/app/src/main/AndroidManifest.xml"
        if (Test-Path $manifestPath) {
            $manifest = Get-Content $manifestPath -Raw
            if ($manifest -notmatch 'android:exported') {
                $manifest = $manifest -replace '<activity\s+', '<activity android:exported="true" '
                Set-Content -Path $manifestPath -Value $manifest -Encoding UTF8
                $actions += @{
                    type = "ManifestFixed"
                    message = "android:exported adicionado ao manifest"
                    action = "Recompilar"
                }
            }
        }
    }
    
    # 4. Erro de dependência não resolvida
    if ($GradleOutput -match "Could not find|Could not resolve|Failed to resolve") {
        Write-Log "[ERRO] Dependência não encontrada. Verificando versões..." "ERRO"
        $actions += @{
            type = "DependencyError"
            message = "Erro de dependência no Gradle"
            action = "Verificar build.gradle.kts"
        }
    }
    
    # 5. Erro de sintaxe Kotlin (genérico)
    if ($GradleOutput -match "Expecting|Unexpected token|Missing") {
        Write-Log "[ERRO] Erro de sintaxe Kotlin detectado" "ERRO"
        $actions += @{
            type = "SyntaxError"
            message = "Erro de sintaxe no código-fonte"
            action = "Revisar arquivo .kt"
        }
    }
    
    return $actions
}

<#
.SYNOPSIS
    Valida projeto antes do build
.DESCRIPTION
    Verifica arquivos essenciais para compilação
.PARAMETER RootPath
    Caminho raiz do projeto
.OUTPUTS
    Hashtable com Valido, ErrosCriticos, Avisos
#>
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

<#
.SYNOPSIS
    Gera workflow do GitHub Actions
.DESCRIPTION
    Cria arquivo android.yml com configuração de build e integração IA
.PARAMETER RootPath
    Caminho raiz do projeto
.PARAMETER AIProvider
    Provedor de IA selecionado
.PARAMETER AIApiKey
    API Key da IA
.PARAMETER UseFallback
    Se true, gera workflow sem script Python (apenas Gradle direto)
#>
function Invoke-WorkflowGenerator {
    param(
        [string]$RootPath,
        [string]$AIProvider = "DeepSeek",
        [string]$AIApiKey = $null,
        [bool]$UseFallback = $false
    )
    
    $workflowDir = "$RootPath/.github/workflows"
    New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
    
    if ($UseFallback) {
        # Workflow de fallback - apenas Gradle direto
        $workflow = @"
name: Compilar APK Debug (Direto)

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          
      - name: Grant execute permission for gradlew
        run: chmod +x gradlew
        
      - name: Compilar APK (Gradle Direto)
        run: ./gradlew assembleDebug --stacktrace
        
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-debug
          path: app/build/outputs/apk/debug/app-debug.apk
"@
        Set-Content -Path "$workflowDir/android.yml" -Value $workflow -Encoding UTF8
        Write-Log "Workflow GitHub Actions gerado (MODO FALLBACK - Sem IA)" "OK"
    } else {
        # Workflow com IA (usando build direto do Gradle)
        $workflow = @"
name: Android APK Build

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          
      - name: Grant execute permission for gradlew
        run: chmod +x gradlew
        
      - name: Build Debug APK
        run: ./gradlew assembleDebug
        
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-debug
          path: app/build/outputs/apk/debug/app-debug.apk
"@
        Set-Content -Path "$workflowDir/android.yml" -Value $workflow -Encoding UTF8
        Write-Log "Workflow GitHub Actions gerado com provedor IA: $AIProvider" "OK"
    }
}

<#
.SYNOPSIS
    Inicializa repositório Git
.DESCRIPTION
    Inicializa git e faz commit inicial
.PARAMETER RootPath
    Caminho raiz do projeto
.PARAMETER GitHubToken
    Token GitHub
.PARAMETER Owner
    Dono do repositório
.PARAMETER RepoName
    Nome do repositório
.OUTPUTS
    URL do repositório criado
#>
function Initialize-GitRepository {
    param(
        [string]$RootPath,
        [string]$GitHubToken,
        [string]$Owner,
        [string]$RepoName
    )
    
    Push-Location $RootPath
    
    try {
        # Inicializar git
        git init | Out-Null
        Write-Log "Git inicializado" "OK"
        
        # Adicionar todos os arquivos
        git add . | Out-Null
        Write-Log "Arquivos adicionados ao git" "OK"
        
        # Commit inicial
        git commit -m "Initial commit - APK Build" | Out-Null
        Write-Log "Commit inicial criado" "OK"
        
        # Criar repositório no GitHub
        $repoUrl = New-GitHubRepository -RepoName $RepoName -Token $GitHubToken -Description "Temporary APK build repository"
        Write-Log "Repositório criado: $repoUrl" "OK"
        
        # Adicionar remote
        git remote add origin $repoUrl | Out-Null
        
        # Push
        git push -u origin main --force | Out-Null
        Write-Log "Código enviado para GitHub" "OK"
        
        return $repoUrl
    }
    catch {
        Write-Log "Erro ao inicializar repositório: $_" "ERRO"
        throw
    }
    finally {
        Pop-Location
    }
}

<#
.SYNOPSIS
    Monitora build do GitHub Actions
.DESCRIPTION
    Polling para verificar status do workflow com timeout absoluto
.PARAMETER Owner
    Dono do repositório
.PARAMETER Repo
    Nome do repositório
.PARAMETER Token
    Token GitHub
.PARAMETER LogCallback
    Callback para log
.OUTPUTS
    Hashtable com Status, RunId, ArtifactUrl
#>
function Invoke-BuildMonitor {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$Token,
        [scriptblock]$LogCallback
    )
    
    $timeout = [TimeSpan]::FromMinutes($script:BuildTimeoutMinutes)
    $startTime = Get-Date
    $lastKnownRunId = $null
    $workflowRegistered = $false
    
    Write-Log "Monitorando build (timeout: $($script:BuildTimeoutMinutes) minutos)..." "INFO"
    
    while (((Get-Date) - $startTime) -lt $timeout) {
        try {
            # Buscar runs
            $runs = Get-GitHubWorkflowRuns -Owner $Owner -Repo $Repo -Token $Token -PerPage 5
            
            if ($runs.workflow_runs.Count -gt 0) {
                $run = $null
                
                # Encontrar run mais nova
                if ($lastKnownRunId) {
                    $run = $runs.workflow_runs | Where-Object { $_.id -gt $lastKnownRunId } | Select-Object -First 1
                }
                
                if (-not $run) {
                    $run = $runs.workflow_runs[0]
                }
                
                if ($run.id -ne $lastKnownRunId) {
                    $lastKnownRunId = $run.id
                    $workflowRegistered = $true
                    Write-Log "Workflow registrado: Run #$($run.id)" "OK"
                }
                
                # Obter status detalhado
                $runDetails = Get-GitHubWorkflowRun -Owner $Owner -Repo $Repo -RunId $run.id -Token $Token
                
                $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
                $status = $runDetails.status
                $conclusion = $runDetails.conclusion
                
                if ($LogCallback) {
                    & $LogCallback "[MONITOR] Run #$($run.id) | Status: $status | Conclusão: $conclusion | Tempo: ${elapsed}s/$($timeout.TotalSeconds)s"
                }
                
                # Verificar se concluiu
                if ($status -eq "completed") {
                    if ($conclusion -eq "success") {
                        # Buscar artifacts
                        $artifacts = Get-GitHubRunArtifacts -Owner $Owner -Repo $Repo -RunId $run.id -Token $Token
                        
                        if ($artifacts.artifacts.Count -gt 0) {
                            $apkArtifact = $artifacts.artifacts[0]
                            return @{
                                Status = "SUCCESS"
                                RunId = $run.id
                                ArtifactId = $apkArtifact.id
                                ArtifactName = $apkArtifact.name
                            }
                        }
                        else {
                            return @{ Status = "SUCCESS"; RunId = $run.id; ArtifactId = $null }
                        }
                    }
                    else {
                        # Buscar logs para diagnóstico
                        $jobs = Get-GitHubWorkflowJobs -Owner $Owner -Repo $Repo -RunId $run.id -Token $Token
                        $failedJob = $jobs.jobs | Where-Object { $_.conclusion -eq "failure" } | Select-Object -First 1
                        
                        if ($failedJob) {
                            $logContent = Get-GitHubJobLogs -Owner $Owner -Repo $Repo -JobId $failedJob.id -Token $Token
                            return @{
                                Status = "FAILED"
                                RunId = $run.id
                                Error = $failedJob.name
                                Log = $logContent.Substring([Math]::Max(0, $logContent.Length - 1000))
                            }
                        }
                        
                        return @{ Status = "FAILED"; RunId = $run.id; Error = "Build failed" }
                    }
                }
            }
            elseif ($workflowRegistered) {
                Write-Log "Workflow registrado mas não encontrado em runs" "AVISO"
            }
            else {
                # Workflow ainda não registrado
                $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds)
                if ($elapsed -gt 180) {
                    # 3 minutos sem registrar workflow
                    return @{ Status = "TIMEOUT"; Error = "Workflow não registrado após 3 minutos" }
                }
            }
        }
        catch {
            Write-Log "Erro ao monitorar build: $_" "AVISO"
        }
        
        # Aguardar antes do próximo polling
        Start-Sleep -Seconds 10
    }
    
    # Timeout absoluto
    return @{ Status = "TIMEOUT"; Error = "Build excedeu timeout de $($script:BuildTimeoutMinutes) minutos" }
}

<#
.SYNOPSIS
    Baixa APK do artifact
.DESCRIPTION
    Download do APK gerado pelo build
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
function Receive-BuildArtifact {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$ArtifactId,
        [string]$Token,
        [string]$DestPath
    )
    
    try {
        Download-GitHubArtifact -Owner $Owner -Repo $Repo -ArtifactId $ArtifactId -Token $Token -DestPath $DestPath
        Write-Log "APK baixado: $DestPath" "OK"
        return $true
    }
    catch {
        Write-Log "Erro ao baixar APK: $_" "ERRO"
        return $false
    }
}

<#
.SYNOPSIS
    Limpa repositório temporário
.DESCRIPTION
    Deleta repositório GitHub e diretório local
.PARAMETER Owner
    Dono do repositório
.PARAMETER Repo
    Nome do repositório
.PARAMETER Token
    Token GitHub
.PARAMETER TempDir
    Diretório temporário local
#>
function Remove-TemporaryRepository {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$Token,
        [string]$TempDir
    )
    
    try {
        # Deletar repositório GitHub
        Remove-GitHubRepository -Owner $Owner -Repo $Repo -Token $Token
        Write-Log "Repositório temporário deletado" "OK"
    }
    catch {
        Write-Log "Erro ao deletar repositório: $_" "AVISO"
    }
    
    try {
        # Deletar diretório temporário
        if (Test-Path $TempDir) {
            Remove-Item $TempDir -Recurse -Force
            Write-Log "Diretório temporário deletado" "OK"
        }
    }
    catch {
        Write-Log "Erro ao deletar diretório temporário: $_" "AVISO"
    }
}

<#
.SYNOPSIS
    Executa orquestração completa de build
.DESCRIPTION
    Valida, gera workflow, cria repo, monitora build e baixa APK
.PARAMETER RootPath
    Caminho raiz do projeto
.PARAMETER GitHubToken
    Token GitHub
.PARAMETER AIProvider
    Provedor de IA selecionado
.PARAMETER AIApiKey
    API Key da IA
.PARAMETER LogCallback
    Callback para log
.PARAMETER SkipToolsCopy
    Se true, não copia a pasta tools/ (para fallback)
.OUTPUTS
    Hashtable com resultado do build
#>
function Invoke-BuildOrchestrator {
    param(
        [string]$RootPath,
        [string]$GitHubToken,
        [string]$AIProvider = "DeepSeek",
        [string]$AIApiKey = $null,
        [scriptblock]$LogCallback,
        [bool]$SkipToolsCopy = $false
    )
    
    Write-Log "════════ BUILDORCHESTRATOR ════════" "OK"
    
    $tempDir = Join-Path $env:TEMP "apk-build-$(Get-Date -Format 'yyyyMMddHHmmss')"
    $repoName = "apk-build-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    try {
        # 1. Pre-build validation
        $validation = Invoke-PreBuildValidator -RootPath $RootPath
        if (-not $validation.Valido) {
            return @{
                Status = "VALIDATION_FAILED"
                Errors = $validation.ErrosCriticos
            }
        }
        
        # 2. Copiar projeto para diretório temporário
        Write-Log "Copiando projeto para diretório temporário..." "INFO"
        Copy-Item -Path $RootPath -Destination $tempDir -Recurse -Force
        Write-Log "Projeto copiado para: $tempDir" "OK"

        # Copy Self-Healing compiler tool (only if not skipping)
        if (-not $SkipToolsCopy) {
            $toolsDir = "$tempDir/tools"
            if (-not (Test-Path $toolsDir)) {
                New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
            }
            $sourceCompiler = Join-Path $PSScriptRoot "..\tools\self_healing_compiler.py"
            if (Test-Path $sourceCompiler) {
                Copy-Item -Path $sourceCompiler -Destination "$toolsDir\self_healing_compiler.py" -Force
                Write-Log "Ferramenta de Auto-Cura IA copiada para o projeto temporário" "OK"
            }
        } else {
            Write-Log "Pulando cópia de tools/ (modo fallback)" "INFO"
        }
        
        # 3. Gerar workflow com configuração de IA
        Invoke-WorkflowGenerator -RootPath $tempDir -AIProvider $AIProvider -AIApiKey $AIApiKey -UseFallback:$SkipToolsCopy
        
        # 4. Obter usuário do GitHub
        $tokenValidation = Test-GitHubToken -Token $GitHubToken
        $owner = $tokenValidation.User
        
        # 5. Inicializar repositório Git e criar no GitHub
        $repoUrl = Initialize-GitRepository -RootPath $tempDir -GitHubToken $GitHubToken -Owner $owner -RepoName $repoName
        Write-Log "Repositório criado: $repoUrl" "OK"
        
        # 6. Monitorar build
        $buildResult = Invoke-BuildMonitor -Owner $owner -Repo $repoName -Token $GitHubToken -LogCallback $LogCallback
        
        # 7. Baixar APK se sucesso
        if ($buildResult.Status -eq "SUCCESS" -and $buildResult.ArtifactId) {
            $apkDestPath = Join-Path $RootPath "app-debug.apk"
            $downloadSuccess = Receive-BuildArtifact -Owner $owner -Repo $repoName -ArtifactId $buildResult.ArtifactId -Token $GitHubToken -DestPath $apkDestPath
            
            if ($downloadSuccess) {
                $buildResult.ApkPath = $apkDestPath
            }
        }
        # 8. Se falhou, tentar auto-cura
        elseif ($buildResult.Status -eq "FAILED" -and $buildResult.Log) {
            Write-Log "[AUTO-CURA] Build falhou. Iniciando interpretação de erros..." "INFO"
            $actions = Invoke-ErrorInterpreter -GradleOutput $buildResult.Log -RootPath $RootPath
            
            $autoFixable = $actions | Where-Object { $_.type -in @('CompileImportFixed', 'ManifestFixed', 'DependencyInjected') }
            if ($autoFixable.Count -gt 0) {
                Write-Log "[AUTO-CURA] Aplicando correções automáticas..." "INFO"
                Write-Log "[AUTO-CURA] Correções aplicadas: $($autoFixable.Count)" "OK"
                $buildResult.AutoFixApplied = $true
                $buildResult.AutoFixActions = $actions
            }
        }
        
        # 8. Limpar recursos temporários
        Remove-TemporaryRepository -Owner $owner -Repo $repoName -Token $GitHubToken -TempDir $tempDir
        
        return $buildResult
        
    }
    catch {
        Write-Log "BuildOrchestrator ERRO: $_" "ERRO"
        
        # Tentar limpar recursos mesmo em caso de erro
        try {
            $tokenValidation = Test-GitHubToken -Token $GitHubToken
            if ($tokenValidation.Valid) {
                Remove-TemporaryRepository -Owner $tokenValidation.User -Repo $repoName -Token $GitHubToken -TempDir $tempDir
            }
        }
        catch {}
        
        return @{
            Status = "ERROR"
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Executa build resiliente com fallback automático
.DESCRIPTION
    Tenta build com IA primeiro, se falhar usa build direto com Gradle
.PARAMETER RootPath
    Caminho raiz do projeto
.PARAMETER GitHubToken
    Token GitHub
.PARAMETER AIProvider
    Provedor de IA selecionado
.PARAMETER AIApiKey
    API Key da IA
.PARAMETER LogCallback
    Callback para log
.OUTPUTS
    Hashtable com resultado do build e qual caminho foi usado
#>
function Invoke-ResilientBuild {
    param(
        [string]$RootPath,
        [string]$GitHubToken,
        [string]$AIProvider = "DeepSeek",
        [string]$AIApiKey = $null,
        [scriptblock]$LogCallback
    )
    
    Write-Log "════════ RESILIENT BUILD SYSTEM ════════" "OK"
    Write-Log "🧠 Sistema de Build Resiliente com Fallback Automático" "OK"
    
    # --- CAMADA 1: Tentar Auto-Cura com IA ---
    Write-Log "[BUILD] 🤖 Camada 1: Tentando build com Auto-Cura IA..." "INFO"
    
    $layer1Result = Invoke-BuildOrchestrator -RootPath $RootPath -GitHubToken $GitHubToken -AIProvider $AIProvider -AIApiKey $AIApiKey -LogCallback $LogCallback -SkipToolsCopy:$false
    
    if ($layer1Result.Status -eq "SUCCESS") {
        Write-Log "[BUILD] ✅ Sucesso com Auto-Cura IA!" "OK"
        $layer1Result.BuildMethod = "AI_Powered"
        $layer1Result.FallbackUsed = $false
        return $layer1Result
    }
    
    Write-Log "[BUILD] ⚠️ Auto-Cura IA falhou. Iniciando Camada 2..." "INFO"
    Write-Log "[BUILD] Motivo da falha: $($layer1Result.Status)" "AVISO"
    if ($layer1Result.Error) {
        Write-Log "[BUILD] Detalhes: $($layer1Result.Error)" "AVISO"
    }
    
    # --- CAMADA 2: Fallback para Build Gradle Direto ---
    Write-Log "[BUILD] 🔧 Camada 2: Iniciando Build Gradle Direto (Fallback)..." "INFO"
    
    # Limpar recursos temporários do primeiro build se existirem
    try {
        $tokenValidation = Test-GitHubToken -Token $GitHubToken
        if ($tokenValidation.Valid) {
            $tempDirs = Get-ChildItem "$env:TEMP" -Filter "apk-build-*" -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -Skip 1
            foreach ($dir in $tempDirs) {
                try {
                    Remove-Item $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
                } catch {}
            }
        }
    } catch {}
    
    # Executar build com fallback (sem IA, sem tools/)
    $layer2Result = Invoke-BuildOrchestrator -RootPath $RootPath -GitHubToken $GitHubToken -AIProvider $AIProvider -AIApiKey $null -LogCallback $LogCallback -SkipToolsCopy:$true
    
    if ($layer2Result.Status -eq "SUCCESS") {
        Write-Log "[BUILD] ✅ Sucesso com Build Direto (Fallback)!" "OK"
        $layer2Result.BuildMethod = "Gradle_Direct"
        $layer2Result.FallbackUsed = $true
        $layer2Result.Layer1Error = $layer1Result.Error
        return $layer2Result
    }
    
    # Ambas as camadas falharam
    Write-Log "[BUILD] ❌ Ambas as camadas falharam. Build não foi possível." "ERRO"
    return @{
        Status = "FAILED"
        Error = "Ambas as camadas (IA e Gradle Direto) falharam"
        Layer1Error = $layer1Result.Error
        Layer2Error = $layer2Result.Error
        BuildMethod = "None"
        FallbackUsed = $true
    }
}

# Exportar funções
Export-ModuleMember -Function Invoke-PreBuildValidator, Invoke-WorkflowGenerator, Initialize-GitRepository, Invoke-BuildMonitor, Receive-BuildArtifact, Remove-TemporaryRepository, Invoke-BuildOrchestrator, Invoke-ErrorInterpreter, Invoke-ResilientBuild
