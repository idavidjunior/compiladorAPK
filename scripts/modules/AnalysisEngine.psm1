# ============================================================
# Módulo AnalysisEngine - Diagnóstico de Código Android
# Compilador APK v9.1 (Auto-Engineer)
# ============================================================

# Importar módulo GitHub API para validação de token
Import-Module (Join-Path $PSScriptRoot "GitHubAPI.psm1") -Force -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Valida token GitHub
.DESCRIPTION
    Verifica se token é válido chamando endpoint /user
.PARAMETER Token
    Token GitHub pessoal
.OUTPUTS
    Hashtable com Valid (bool), User (string) e Error (string)
#>
function Test-GitHubToken {
    param([string]$Token)
    
    if ([string]::IsNullOrEmpty($Token)) {
        return @{ Valid = $false; Error = "Token não fornecido" }
    }
    
    # Tentar usar módulo GitHubAPI se disponível
    if (Get-Command Test-GitHubToken -Module GitHubAPI -ErrorAction SilentlyContinue) {
        return GitHubAPI\Test-GitHubToken -Token $Token
    }
    
    # Fallback para implementação local
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

<#
.SYNOPSIS
    Processa entrada de código (colado, ZIP, pasta)
.DESCRIPTION
    Gateway para diferentes fontes de entrada
.PARAMETER Source
    Caminho da fonte (arquivo, pasta, URL)
.PARAMETER SourceType
    Tipo da fonte (COLADO, ZIP, PASTA, TXT, GITHUB, APK)
.OUTPUTS
    Hashtable com Tipo, TempDir, Caminho, MimeType
#>
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
            "PROMPT" { 
                $result.Caminho = "MEMORIA"
                $result.MimeType = "text/plain"
                Write-Log "Prompt de IA recebido" "OK" 
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

<#
.SYNOPSIS
    Extrai conteúdo de arquivo
.DESCRIPTION
    Extrai conteúdo baseado no MIME type
.PARAMETER Source
    Caminho do arquivo
.PARAMETER MimeType
    MIME type do arquivo
.OUTPUTS
    String com conteúdo extraído
#>
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

<#
.SYNOPSIS
    Detecta tecnologias usadas no projeto
.DESCRIPTION
    Identifica linguagens, frameworks, build tools e plataformas
.PARAMETER RootPath
    Caminho raiz do projeto
.PARAMETER Conteudo
    Conteúdo do código fonte
.OUTPUTS
    Hashtable com Linguagens, Frameworks, BuildTools, Plataformas
#>
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

<#
.SYNOPSIS
    Escaneia estrutura do projeto
.DESCRIPTION
    Verifica existência de arquivos e diretórios essenciais
.PARAMETER RootPath
    Caminho raiz do projeto
.OUTPUTS
    Hashtable com status de cada componente estrutural
#>
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

<#
.SYNOPSIS
    Escaneia dependências do Gradle
.DESCRIPTION
    Identifica dependências e problemas de versão
.PARAMETER GradlePath
    Caminho do arquivo build.gradle
.OUTPUTS
    Hashtable com Dependencies, VersionIssues, Missing
#>
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

<#
.SYNOPSIS
    Escaneia erros no código
.DESCRIPTION
    Identifica problemas comuns em código Android
.PARAMETER Conteudo
    Conteúdo do código fonte
.PARAMETER RootPath
    Caminho raiz do projeto
.OUTPUTS
    Array de hashtables com Severidade e Msg
#>
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

<#
.SYNOPSIS
    Analisa integridade do projeto
.DESCRIPTION
    Calcula percentual de integridade baseado em erros
.PARAMETER Erros
    Array de erros
.OUTPUTS
    Hashtable com Percentual e Compilavel
#>
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

<#
.SYNOPSIS
    Gera relatório de diagnóstico
.DESCRIPTION
    Cria relatório estruturado com diagnóstico
.PARAMETER Techs
    Tecnologias detectadas
.PARAMETER Estrutura
    Estrutura do projeto
.PARAMETER Deps
    Dependências
.PARAMETER Erros
    Erros encontrados
.PARAMETER Integridade
    Integridade calculada
.OUTPUTS
    Hashtable com diagnóstico completo
#>
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

<#
.SYNOPSIS
    Executa análise completa do projeto
.DESCRIPTION
    Orquestra todo o processo de análise
.PARAMETER Conteudo
    Conteúdo do código fonte
.PARAMETER CaminhoFonte
    Caminho da fonte
.PARAMETER TipoFonte
    Tipo da fonte
.PARAMETER GitHubToken
    Token GitHub para validação
.OUTPUTS
    JSON com relatório completo ou $null em caso de erro
#>
function Invoke-AnalysisEngine {
    param(
        [string]$Conteudo,
        [string]$CaminhoFonte,
        [string]$TipoFonte,
        [string]$GitHubToken
    )
    
    Write-Log "════════ ANALYSISENGINE ════════" "OK"
    
    # Validar token do GitHub
    Write-Log "Validando token do GitHub..." "INFO"
    $tokenValidation = Test-GitHubToken -Token $GitHubToken
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
        
        Write-Log "Análise concluída: Integridade $($integridade.Percentual)%" "OK"
        return $relatorio | ConvertTo-Json -Depth 10
        
    } catch {
        Write-Log "AnalysisEngine ERRO: $_" "ERRO"
        return $null
    }
}

<#
.SYNOPSIS
    Detecta tecnologias avançadas no código Kotlin
.DESCRIPTION
    Analisa o código para identificar bibliotecas usadas (Coil, DataStore, Serialization, etc.)
.PARAMETER CodeContent
    Conteúdo do código Kotlin
.OUTPUTS
    Array de strings com tecnologias detectadas
#>
function Detect-AdvancedTechnologies {
    param([string]$CodeContent)
    
    $tech = @()
    
    if ([string]::IsNullOrEmpty($CodeContent)) { return $tech }
    
    # Coil3 (imagens)
    if ($CodeContent -match 'AsyncImage|coil|rememberAsyncImagePainter|SubcomposeAsyncImage') { $tech += 'Coil' }
    
    # Jetpack DataStore Preferences
    if ($CodeContent -match 'DataStore|dataStore|preferencesDataStore') { $tech += 'DataStore' }
    
    # Kotlinx Serialization
    if ($CodeContent -match '@Serializable|kotlinx\.serialization|Json\.encodeToString|Json\.decodeFromString') { $tech += 'Serialization' }
    
    # MediaSession (controles de mídia)
    if ($CodeContent -match 'MediaSessionCompat|MediaSession|MediaControllerCompat|PlaybackStateCompat') { $tech += 'MediaSession' }
    
    # Retrofit + OkHttp
    if ($CodeContent -match 'retrofit|Retrofit|@GET|@POST|@PUT|@DELETE|OkHttpClient') { $tech += 'Retrofit' }
    
    # Coroutines
    if ($CodeContent -match 'suspend\s+fun|CoroutineScope|launch\s*\{|async\s*\{|withContext|Dispatchers\.') { $tech += 'Coroutines' }
    
    # Navigation Compose
    if ($CodeContent -match 'NavController|NavHost|rememberNavController|navGraph') { $tech += 'Navigation' }
    
    # Room Database
    if ($CodeContent -match '@Entity|@Dao|@Database|RoomDatabase') { $tech += 'Room' }
    
    # Hilt (Dependency Injection)
    if ($CodeContent -match '@HiltViewModel|@Inject|@Module|@InstallIn') { $tech += 'Hilt' }
    
    # CameraX
    if ($CodeContent -match 'CameraX|CameraProvider|PreviewView|ImageAnalysis') { $tech += 'CameraX' }
    
    # WorkManager
    if ($CodeContent -match 'WorkManager|OneTimeWorkRequest|PeriodicWorkRequest') { $tech += 'WorkManager' }
    
    return $tech
}

# Exportar funções
Export-ModuleMember -Function Test-GitHubToken, Invoke-InputGateway, Invoke-ExtractionEngine, Invoke-TechnologyDetector, Invoke-StructureScanner, Invoke-DependencyScanner, Invoke-ErrorScanner, Invoke-IntegrityAnalyzer, Invoke-DiagnosticReportGenerator, Invoke-AnalysisEngine, Detect-AdvancedTechnologies
