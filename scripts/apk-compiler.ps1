param(
    [ValidateSet('doctor','build','sign','create-keystore','find-apk')]
    [string]$Command,
    [string]$ProjectPath = '.',
    [ValidateSet('Debug','Release')]
    [string]$Variant = 'Debug',
    [string]$ApkPath,
    [string]$KeystorePath,
    [string]$KeystoreAlias,
    [string]$OutputPath,
    [string]$StorePassword,
    [string]$KeyPassword
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/android-resource-doctor.ps1"

function Write-Info($message) { Write-Host "[INFO] $message" -ForegroundColor Cyan }
function Write-Ok($message) { Write-Host "[OK]   $message" -ForegroundColor Green }
function Write-Warn($message) { Write-Host "[WARN] $message" -ForegroundColor Yellow }
function Write-Fail($message) { Write-Host "[FAIL] $message" -ForegroundColor Red }

function Test-CommandExists([string]$cmd) {
    return $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Get-AndroidBuildToolsPath {
    if (-not $env:ANDROID_HOME -and -not $env:ANDROID_SDK_ROOT) { return $null }
    $sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { $env:ANDROID_HOME }
    $buildToolsRoot = Join-Path $sdkRoot 'build-tools'
    if (-not (Test-Path $buildToolsRoot)) { return $null }
    $latest = Get-ChildItem $buildToolsRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $latest) { return $null }
    return $latest.FullName
}

function Invoke-Doctor {
    Write-Info 'Verificando pré-requisitos...'
    $checks = @(
        @{ Name='java'; Required=$true },
        @{ Name='keytool'; Required=$true },
        @{ Name='adb'; Required=$false },
        @{ Name='sdkmanager'; Required=$false }
    )
    $allRequiredOk = $true
    foreach ($check in $checks) {
        if (Test-CommandExists $check.Name) {
            Write-Ok "$($check.Name) encontrado"
        } else {
            if ($check.Required) {
                Write-Fail "$($check.Name) não encontrado"
                $allRequiredOk = $false
            } else {
                Write-Warn "$($check.Name) não encontrado (opcional)"
            }
        }
    }

    $buildTools = Get-AndroidBuildToolsPath
    if ($buildTools) {
        $zipalign = Join-Path $buildTools 'zipalign.exe'
        $apksigner = Join-Path $buildTools 'apksigner.bat'
        if (Test-Path $zipalign) { Write-Ok "zipalign encontrado em $zipalign" } else { Write-Warn 'zipalign não encontrado no build-tools' }
        if (Test-Path $apksigner) { Write-Ok "apksigner encontrado em $apksigner" } else { Write-Warn 'apksigner não encontrado no build-tools' }
    } else {
        Write-Warn 'ANDROID_HOME/ANDROID_SDK_ROOT não configurado ou build-tools ausente'
    }

    try {
        Invoke-AndroidResourceDoctor -ProjectPath $ProjectPath
    } catch {
        Write-Fail "Diagnóstico crítico: $_"
        exit 1
    }

    if ($allRequiredOk) { Write-Ok 'Pré-requisitos mínimos atendidos.' } else { throw 'Pré-requisitos obrigatórios ausentes. Corrija e execute novamente.' }
}

function Get-GradleCommand([string]$projectPath) {
    $wrapperBat = Join-Path $projectPath 'gradlew.bat'
    $wrapperSh = Join-Path $projectPath 'gradlew'
    if ($IsWindows -or $env:OS -eq 'Windows_NT') {
        if (Test-Path $wrapperBat) { return $wrapperBat }
    } else {
        if (Test-Path $wrapperSh) { return $wrapperSh }
    }
    if (Test-CommandExists 'gradle') { return 'gradle' }
    throw 'Gradle wrapper (gradlew) ou gradle global não encontrado.'
}

function Invoke-Build {
    $fullProjectPath = Resolve-Path $ProjectPath
    $gradle = Get-GradleCommand $fullProjectPath
    $task = "assemble$Variant"
    Write-Info "Executando build: $task"
    Push-Location $fullProjectPath
    try { & $gradle $task } finally { Pop-Location }
    if ($LASTEXITCODE -ne 0) { throw 'Falha na compilação do APK.' }
    Write-Ok 'Compilação concluída.'
}

function Invoke-CreateKeystore {
    if (-not $KeystorePath) { throw 'Informe -KeystorePath' }
    if (-not $KeystoreAlias) { throw 'Informe -KeystoreAlias' }
    if (-not $StorePassword) { throw 'Informe -StorePassword' }
    if (-not $KeyPassword) { throw 'Informe -KeyPassword' }

    Write-Info 'Criando keystore...'
    & keytool -genkeypair -v -keystore $KeystorePath -alias $KeystoreAlias -keyalg RSA -keysize 2048 -validity 10000 -storepass $StorePassword -keypass $KeyPassword -dname "CN=APK,O=APK,C=BR"
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar keystore.' }
    Write-Ok "Keystore criada em $KeystorePath"
}

function Find-OutputApk([string]$projectPath,[string]$variant) {
    $variantLower = $variant.ToLowerInvariant()
    $base = Join-Path $projectPath "app/build/outputs/apk/$variantLower"
    if (-not (Test-Path $base)) { return $null }
    $apk = Get-ChildItem -Path $base -Filter '*.apk' -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    return $apk
}

function Invoke-FindApk {
    $fullProjectPath = Resolve-Path $ProjectPath
    $apk = Find-OutputApk -projectPath $fullProjectPath -variant $Variant
    if (-not $apk) { throw 'APK não encontrado para o variant informado.' }
    Write-Ok $apk.FullName
}

function Invoke-Sign {
    if (-not $ApkPath) { throw 'Informe -ApkPath' }
    if (-not $KeystorePath) { throw 'Informe -KeystorePath' }
    if (-not $KeystoreAlias) { throw 'Informe -KeystoreAlias' }
    if (-not $StorePassword) { throw 'Informe -StorePassword' }
    if (-not $KeyPassword) { throw 'Informe -KeyPassword' }

    $apkFull = Resolve-Path $ApkPath
    $buildTools = Get-AndroidBuildToolsPath
    
    $baseDir = Split-Path $apkFull -Parent
    $name = [System.IO.Path]::GetFileNameWithoutExtension($apkFull)
    $signed = Join-Path $baseDir "$name-signed.apk"

    # Verificar se temos as ferramentas do Android SDK localmente
    if ($buildTools) {
        $zipalign = Join-Path $buildTools 'zipalign.exe'
        $apksigner = Join-Path $buildTools 'apksigner.bat'
        
        if (Test-Path $zipalign -and Test-Path $apksigner) {
            Write-Info 'Alinhando APK (zipalign)...'
            $aligned = if ($OutputPath) { $OutputPath } else { Join-Path $baseDir "$name-aligned.apk" }
            & $zipalign -p -f 4 $apkFull $aligned
            if ($LASTEXITCODE -ne 0) { throw 'Falha no zipalign.' }
            
            Write-Info 'Assinando APK com apksigner oficial...'
            & $apksigner sign --ks $KeystorePath --ks-key-alias $KeystoreAlias --ks-pass "pass:$StorePassword" --key-pass "pass:$KeyPassword" --out $signed $aligned
            if ($LASTEXITCODE -ne 0) { throw 'Falha na assinatura do APK.' }
            
            Write-Info 'Validando assinatura...'
            & $apksigner verify $signed
            if ($LASTEXITCODE -ne 0) { throw 'Assinatura inválida.' }
            Write-Ok "APK assinado com sucesso: $signed"
            return
        }
    }

    # FALLBACK: Se o Android SDK local não for encontrado, usa o Jarsigner do Java nativo!
    Write-Warn 'Android build-tools nao encontrado localmente. Utilizando fallback resiliente: jarsigner (Java)...'
    
    if (-not (Test-CommandExists 'jarsigner')) {
        throw 'Nem o apksigner do Android SDK nem o jarsigner do Java foram localizados no sistema!'
    }

    # Copia o APK bruto para o destino final para assinar in-place
    Copy-Item $apkFull $signed -Force
    
    Write-Info 'Assinando APK de forma resiliente com jarsigner...'
    & jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA256 -keystore $KeystorePath -storepass $StorePassword -keypass $KeyPassword $signed $KeystoreAlias
    
    if ($LASTEXITCODE -ne 0) {
        throw 'Falha ao assinar o APK com jarsigner.'
    }
    
    Write-Ok "APK assinado com sucesso de forma resiliente (Java Fallback): $signed"
}

switch ($Command) {
    'doctor' { Invoke-Doctor }
    'build' { Invoke-Build }
    'sign' { Invoke-Sign }
    'create-keystore' { Invoke-CreateKeystore }
    'find-apk' { Invoke-FindApk }
    default { throw "Comando inválido: $Command" }
}

