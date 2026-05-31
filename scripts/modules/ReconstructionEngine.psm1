# ============================================================
# Módulo ReconstructionEngine - Estruturação de Projeto Android
# Compilador APK v9.1 (Auto-Engineer)
# ============================================================

# Importar AnalysisEngine para detecção de tecnologias
Import-Module (Join-Path $PSScriptRoot "AnalysisEngine.psm1") -Force -ErrorAction SilentlyContinue

# Dicionário de regras de dependências (tecnologia → dependências)
$script:DependencyRules = @{
    'Coil' = @(
        'io.coil-kt.coil3:coil-compose:3.1.0',
        'io.coil-kt.coil3:coil-network-okhttp:3.1.0'
    )
    'DataStore' = @(
        'androidx.datastore:datastore-preferences:1.1.4'
    )
    'Serialization' = @(
        'org.jetbrains.kotlinx:kotlinx-serialization-json:1.8.1'
    )
    'MediaSession' = @(
        'androidx.media:media:1.7.0'
    )
    'Retrofit' = @(
        'com.squareup.retrofit2:retrofit:2.11.0',
        'com.squareup.retrofit2:converter-gson:2.11.0',
        'com.squareup.okhttp3:okhttp:4.12.0'
    )
    'Coroutines' = @(
        'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2'
    )
    'Navigation' = @(
        'androidx.navigation:navigation-compose:2.8.5'
    )
    'Room' = @(
        'androidx.room:room-runtime:2.7.0',
        'androidx.room:room-compiler:2.7.0',
        'androidx.room:room-ktx:2.7.0'
    )
    'Hilt' = @(
        'com.google.dagger:hilt-android:2.53.1',
        'com.google.dagger:hilt-compiler:2.53.1'
    )
    'CameraX' = @(
        'androidx.camera:camera-core:1.4.1',
        'androidx.camera:camera-camera2:1.4.1',
        'androidx.camera:camera-lifecycle:1.4.1',
        'androidx.camera:camera-view:1.4.1'
    )
    'WorkManager' = @(
        'androidx.work:work-runtime-ktx:2.10.0'
    )
}

<#
.SYNOPSIS
    Adiciona dependência ao build.gradle.kts
.DESCRIPTION
    Adiciona uma dependência ao arquivo build.gradle.kts se não existir
.PARAMETER BuildGradlePath
    Caminho do arquivo build.gradle.kts
.PARAMETER Dependency
    String da dependência no formato "group:artifact:version"
#>
function Add-Dependency {
    param([string]$BuildGradlePath, [string]$Dependency)
    
    if (-not (Test-Path $BuildGradlePath)) { return $false }
    
    $content = Get-Content $BuildGradlePath -Raw -Encoding UTF8
    $shortId = ($Dependency -split ':')[1]
    
    # Verificar se já existe
    if ($content -match [regex]::Escape($shortId)) { return $false }
    
    # Adicionar dependência
    if ($content -match '(\s*testImplementation)') {
        $content = $content -replace '(\s*testImplementation)', "    implementation(`"$Dependency`")`r`n`$1"
    } elseif ($content -match '(\s*androidTestImplementation)') {
        $content = $content -replace '(\s*androidTestImplementation)', "    implementation(`"$Dependency`")`r`n`$1"
    } elseif ($content -match '(\s*debugImplementation)') {
        $content = $content -replace '(\s*debugImplementation)', "    implementation(`"$Dependency`")`r`n`$1"
    } else {
        $content = $content -replace '(dependencies\s*\{)', "`$1`r`n    implementation(`"$Dependency`")"
    }
    
    Set-Content -Path $BuildGradlePath -Value $content -Encoding UTF8
    return $true
}

<#
.SYNOPSIS
    Injeta dependências inteligentes baseadas no código
.DESCRIPTION
    Detecta tecnologias no código e adiciona dependências automaticamente
.PARAMETER RootPath
    Caminho raiz do projeto
.PARAMETER CodeContent
    Conteúdo do código Kotlin
.OUTPUTS
    Array de strings com dependências injetadas
#>
function Invoke-IntelligentDependencyInjection {
    param([string]$RootPath, [string]$CodeContent)
    
    $buildGradlePath = "$RootPath/app/build.gradle.kts"
    if (-not (Test-Path $buildGradlePath)) { return @() }
    
    # Detectar tecnologias avançadas
    $advancedTech = Detect-AdvancedTechnologies -CodeContent $CodeContent
    $injectedDeps = @()
    
    foreach ($tech in $advancedTech) {
        if ($script:DependencyRules.ContainsKey($tech)) {
            foreach ($dep in $script:DependencyRules[$tech]) {
                if (Add-Dependency -BuildGradlePath $buildGradlePath -Dependency $dep) {
                    $injectedDeps += $dep
                    Write-Log "[DEP] $tech detectado → $dep injetada" "OK" -Healed
                }
            }
        }
    }
    
    return $injectedDeps
}

# Dicionário de regras de imports (palavra-chave → import)
$script:ImportRules = @{
    # Compose Foundation
    'clickable' = 'import androidx.compose.foundation.clickable'
    'combinedClickable' = 'import androidx.compose.foundation.combinedClickable'
    'background' = 'import androidx.compose.foundation.background'
    'border' = 'import androidx.compose.foundation.border'
    'padding' = 'import androidx.compose.foundation.layout.padding'
    'size' = 'import androidx.compose.foundation.layout.size'
    'fillMaxSize' = 'import androidx.compose.foundation.layout.fillMaxSize'
    'fillMaxWidth' = 'import androidx.compose.foundation.layout.fillMaxWidth'
    'fillMaxHeight' = 'import androidx.compose.foundation.layout.fillMaxHeight'
    'width' = 'import androidx.compose.foundation.layout.width'
    'height' = 'import androidx.compose.foundation.layout.height'
    'Arrangement' = 'import androidx.compose.foundation.layout.Arrangement'
    'Alignment' = 'import androidx.compose.ui.Alignment'
    'Modifier' = 'import androidx.compose.ui.Modifier'
    
    # Compose UI
    'dp' = 'import androidx.compose.ui.unit.dp'
    'sp' = 'import androidx.compose.ui.unit.sp'
    'Text' = 'import androidx.compose.material3.Text'
    'Button' = 'import androidx.compose.material3.Button'
    'Card' = 'import androidx.compose.material3.Card'
    'Scaffold' = 'import androidx.compose.material3.Scaffold'
    'TopAppBar' = 'import androidx.compose.material3.TopAppBar'
    'BottomNavigation' = 'import androidx.compose.material3.BottomNavigation'
    'NavigationBar' = 'import androidx.compose.material3.NavigationBar'
    'NavigationBarItem' = 'import androidx.compose.material3.NavigationBarItem'
    'Icon' = 'import androidx.compose.material3.Icon'
    'IconButton' = 'import androidx.compose.material3.IconButton'
    'FloatingActionButton' = 'import androidx.compose.material3.FloatingActionButton'
    'TextField' = 'import androidx.compose.material3.TextField'
    'OutlinedTextField' = 'import androidx.compose.material3.OutlinedTextField'
    'Checkbox' = 'import androidx.compose.material3.Checkbox'
    'Switch' = 'import androidx.compose.material3.Switch'
    'Slider' = 'import androidx.compose.material3.Slider'
    'Tab' = 'import androidx.compose.material3.Tab'
    'TabRow' = 'import androidx.compose.material3.TabRow'
    'tabIndicatorOffset' = 'import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset'
    'HorizontalPager' = 'import androidx.compose.foundation.pager.HorizontalPager'
    'PagerState' = 'import androidx.compose.foundation.pager.PagerState'
    'rememberPagerState' = 'import androidx.compose.foundation.pager.rememberPagerState'
    
    # Compose Runtime
    'remember' = 'import androidx.compose.runtime.remember'
    'mutableStateOf' = 'import androidx.compose.runtime.mutableStateOf'
    'getValue' = 'import androidx.compose.runtime.getValue'
    'setValue' = 'import androidx.compose.runtime.setValue'
    'rememberCoroutineScope' = 'import androidx.compose.runtime.rememberCoroutineScope'
    'LaunchedEffect' = 'import androidx.compose.runtime.LaunchedEffect'
    'DisposableEffect' = 'import androidx.compose.runtime.DisposableEffect'
    'collectAsState' = 'import androidx.compose.runtime.collectAsState'
    'State' = 'import androidx.compose.runtime.State'
    'MutableState' = 'import androidx.compose.runtime.MutableState'
    'produceState' = 'import androidx.compose.runtime.produceState'
    
    # Compose Material Icons
    'Icons.Default' = 'import androidx.compose.material.icons.Icons'
    'Icons.Filled' = 'import androidx.compose.material.icons.filled.*'
    'Icons.Outlined' = 'import androidx.compose.material.icons.outlined.*'
    
    # Layout
    'Box' = 'import androidx.compose.foundation.layout.Box'
    'Column' = 'import androidx.compose.foundation.layout.Column'
    'Row' = 'import androidx.compose.foundation.layout.Row'
    'Spacer' = 'import androidx.compose.foundation.layout.Spacer'
    'LazyColumn' = 'import androidx.compose.foundation.lazy.LazyColumn'
    'LazyRow' = 'import androidx.compose.foundation.lazy.LazyRow'
    'LazyVerticalGrid' = 'import androidx.compose.foundation.lazy.grid.LazyVerticalGrid'
    
    # Coil3
    'AsyncImage' = 'import coil3.compose.AsyncImage'
    'rememberAsyncImagePainter' = 'import coil3.compose.rememberAsyncImagePainter'
    'SubcomposeAsyncImage' = 'import coil3.compose.SubcomposeAsyncImage'
    
    # Serialization
    '@Serializable' = 'import kotlinx.serialization.Serializable'
    'Serializable' = 'import kotlinx.serialization.Serializable'
    'Json' = 'import kotlinx.serialization.json.Json'
    'encodeToString' = 'import kotlinx.serialization.encodeToString'
    'decodeFromString' = 'import kotlinx.serialization.json.Json.decodeFromString'
    
    # Activity Compose
    'setContent' = 'import androidx.activity.compose.setContent'
}

<#
.SYNOPSIS
    Auto-cura de imports em arquivos Kotlin
.DESCRIPTION
    Analisa arquivos .kt e adiciona imports faltantes automaticamente
.PARAMETER RootPath
    Caminho raiz do projeto
.OUTPUTS
    Número de imports adicionados
#>
function Invoke-ImportRepairEngine {
    param([string]$RootPath)
    
    $ktFiles = Get-ChildItem (Join-Path $RootPath 'app/src/main/java') -Recurse -Filter '*.kt' -ErrorAction SilentlyContinue
    $totalFixed = 0
    
    foreach ($file in $ktFiles) {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        if ([string]::IsNullOrEmpty($content)) { continue }
        
        # Extrair imports existentes
        $existingImports = [regex]::Matches($content, '^import\s+([\w.]+)', 'Multiline') | ForEach-Object { $_.Groups[1].Value }
        
        $newImports = @()
        foreach ($keyword in $script:ImportRules.Keys) {
            # Verifica se o código usa a palavra-chave
            $pattern = "(?<![a-zA-Z])$keyword(?![a-zA-Z])"
            if ($content -match $pattern) {
                $importLine = $script:ImportRules[$keyword]
                # Extrai apenas o caminho do import (após 'import ')
                $importPath = $importLine -replace '^import\s+', ''
                # Se o import não existe no arquivo, adiciona
                if ($importPath -notin $existingImports) {
                    $newImports += $importLine
                }
            }
        }
        
        if ($newImports.Count -gt 0) {
            # Adicionar imports no topo (após package)
            $packageEnd = $content.IndexOf("`n", $content.IndexOf("package"))
            if ($packageEnd -eq -1) {
                # Sem package, adicionar no início
                $before = ""
                $after = $content
            }
            else {
                $before = $content.Substring(0, $packageEnd + 1)
                $after = $content.Substring($packageEnd + 1)
            }
            
            $importsToAdd = ($newImports | Sort-Object -Unique | ForEach-Object { "$_`r`n" }) -join ""
            $newContent = $before + "`r`n" + $importsToAdd + $after
            
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBom)
            $totalFixed += $newImports.Count
            Write-Log "[IMPORT] $($file.Name): +$($newImports.Count) imports adicionados" "OK" -Healed
        }
    }
    
    if ($totalFixed -gt 0) {
        Write-Log "[IMPORT] Total de imports corrigidos: $totalFixed" "OK"
    }
    return $totalFixed
}

<#
.SYNOPSIS
    Normaliza estrutura do projeto
.DESCRIPTION
    Cria estrutura de diretórios e normaliza encoding UTF-8
.PARAMETER RootPath
    Caminho raiz do projeto
#>
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

<#
.SYNOPSIS
    Reconstrói AndroidManifest.xml
.DESCRIPTION
    Cria manifest com permissões básicas
.PARAMETER RootPath
    Caminho raiz do projeto
.PARAMETER Package
    Nome do package
.PARAMETER ActivityName
    Nome da Activity principal
#>
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

<#
.SYNOPSIS
    Reconstrói build.gradle.kts na raiz
.DESCRIPTION
    Cria arquivo build.gradle.kts com plugins
.PARAMETER RootPath
    Caminho raiz do projeto
#>
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

<#
.SYNOPSIS
    Reconstrói app/build.gradle.kts
.DESCRIPTION
    Cria arquivo build.gradle.kts com configuração completa
.PARAMETER RootPath
    Caminho raiz do projeto
.PARAMETER Package
    Nome do package
#>
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

<#
.SYNOPSIS
    Cria recursos base do projeto
.DESCRIPTION
    Cria strings.xml, colors.xml, themes.xml, layout
.PARAMETER RootPath
    Caminho raiz do projeto
#>
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

<#
.SYNOPSIS
    Cria proguard-rules.pro
.DESCRIPTION
    Cria arquivo de regras ProGuard
.PARAMETER RootPath
    Caminho raiz do projeto
#>
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

<#
.SYNOPSIS
    Gera Gradle Wrapper
.DESCRIPTION
    Baixa gradlew oficial e gradle-wrapper.jar
.PARAMETER RootPath
    Caminho raiz do projeto
#>
function Invoke-WrapperGenerator {
    param([string]$RootPath)
    
    # Baixar gradlew oficial do Gradle
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
        # Fallback simplificado
        $gradlew = @"
#!/usr/bin/env sh
exec java -jar gradle/wrapper/gradle-wrapper.jar "$@"
"@
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $gradlew = $gradlew -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText("$RootPath/gradlew", $gradlew, $utf8NoBom)
    }
    
    # gradlew.bat
    $gradlewBat = @"
@echo off
"%JAVA_HOME%\bin\java.exe" -jar gradle\wrapper\gradle-wrapper.jar %*
"@
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
    
    # Baixar gradle-wrapper.jar
    $wrapperJarUrl = "https://raw.githubusercontent.com/gradle/gradle/v8.7.0/gradle/wrapper/gradle-wrapper.jar"
    $wrapperJarPath = "$RootPath/gradle/wrapper/gradle-wrapper.jar"
    
    try {
        Write-Log "Baixando gradle-wrapper.jar..." "INFO"
        $progressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $wrapperJarUrl -OutFile $wrapperJarPath -UseBasicParsing -ErrorAction Stop
        $progressPreference = 'Continue'
        
        $fileInfo = Get-Item $wrapperJarPath
        if ($fileInfo.Length -lt 40000) {
            throw "Arquivo baixado é muito pequeno"
        }
        
        Write-Log "gradle-wrapper.jar baixado com sucesso ($($fileInfo.Length) bytes)" "OK"
    } catch {
        Write-Log "Falha ao baixar gradle-wrapper.jar: $_" "ERRO"
        try {
            $altUrl = "https://services.gradle.org/distributions/gradle-wrapper.jar"
            $progressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $altUrl -OutFile $wrapperJarPath -UseBasicParsing -ErrorAction Stop
            $progressPreference = 'Continue'
            Write-Log "gradle-wrapper.jar baixado do mirror alternativo" "OK"
        } catch {
            Write-Log "Falha crítica: não foi possível baixar gradle-wrapper.jar" "ERRO"
            throw
        }
    }
    
    Write-Log "Gradle Wrapper gerado" "OK"
}

<#
.SYNOPSIS
    Valida projeto após reconstrução
.DESCRIPTION
    Verifica existência de arquivos essenciais
.PARAMETER RootPath
    Caminho raiz do projeto
.OUTPUTS
    Hashtable com Validacoes e Percentual
#>
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

<#
.SYNOPSIS
    Executa reconstrução completa do projeto
.DESCRIPTION
    Orquestra todo o processo de estruturação
.PARAMETER RootPath
    Caminho raiz do projeto
.PARAMETER Conteudo
    Conteúdo do código fonte
.PARAMETER AnalysisReport
    Relatório de análise
.OUTPUTS
    JSON com relatório de reconstrução ou $null em caso de erro
#>
function Invoke-ReconstructionEngine {
    param([string]$RootPath, [string]$Conteudo, $AnalysisReport)
    
    Write-Log "════════ RECONSTRUCTIONENGINE ════════" "OK"
    
    try {
        $arquivosCriados = @()
        $arquivosCorrigidos = @()

        # Check if the content is a prompt (meaning it is a prompt source type or doesn't have package lines)
        $isPrompt = ($null -ne $AnalysisReport -and $AnalysisReport.Diagnostico.Tipo -eq "PROMPT") -or ($Conteudo.Trim() -notmatch '(?m)^package\s+')
        
        if ($isPrompt) {
            $package = "com.agon.app"
            $activity = "MainActivity"
            
            # Write prompt.txt to the root of the destination
            $promptFile = Join-Path $RootPath "prompt.txt"
            Set-Content -Path $promptFile -Value $Conteudo -Encoding UTF8
            $arquivosCriados += "prompt.txt"
            Write-Log "Prompt de IA gravado com sucesso em prompt.txt" "OK"
            
            # Generate a basic MainActivity template so it is a valid project initially
            $Conteudo = @"
package com.agon.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(text = "Gerando aplicativo de IA...")
            }
        }
    }
}
"@
        } else {
            $package = if ($Conteudo -match 'package\s+([\w.]+)') { $Matches[1] } else { "com.example.app" }
            $activity = if ($Conteudo -match 'class\s+(\w+)\s') { $Matches[1] } else { "MainActivity" }
        }
        
        # 1. ProjectNormalizer
        Invoke-ProjectNormalizer -RootPath $RootPath
        $arquivosCriados += "Estrutura de diretórios"
        
        # 2. RootGradleRebuilder
        Invoke-RootGradleRebuilder -RootPath $RootPath
        $arquivosCriados += "build.gradle.kts (raiz)"
        
        # 3. GradleRebuilder
        Invoke-GradleRebuilder -RootPath $RootPath -Package $package
        $arquivosCriados += "app/build.gradle.kts"
        
        # 4. ManifestRebuilder
        Invoke-ManifestRebuilder -RootPath $RootPath -Package $package -ActivityName $activity
        $arquivosCriados += "AndroidManifest.xml"
        
        # 5. ResourceRepairEngine
        Invoke-ResourceRepairEngine -RootPath $RootPath
        $arquivosCriados += "strings.xml", "colors.xml", "themes.xml", "activity_main.xml"
        
        # 6. ProguardRulesRebuilder
        Invoke-ProguardRulesRebuilder -RootPath $RootPath
        $arquivosCriados += "proguard-rules.pro"
        
        # 7. Gravar código do usuário
        $javaDir = "$RootPath\app\src\main\java"
        $packageLines = [regex]::Matches($Conteudo, '(?m)^package\s+(\S+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
        
        if ($packageLines.Count -eq 0) {
            $packageLines = @($package)
        }
        
        foreach ($pkg in $packageLines) {
            $pkgEsc = [regex]::Escape($pkg)
            $pkgPathDir = ($pkg -replace '\.', '\')
            $targetDir = "$javaDir\$pkgPathDir"
            
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
            }
            
            $pkgBlock = if ($packageLines.Count -gt 1) {
                $pattern = "(?s)(package\s+$pkgEsc\b.*?)(?=\npackage\s+(?!$pkgEsc\b)|\z)"
                $m = [regex]::Match($Conteudo, $pattern)
                if ($m.Success) { $m.Value } else { $Conteudo }
            } else {
                $Conteudo
            }
            
            $firstClass = if ($pkgBlock -match '(?m)^(?:class|object|interface|data class|sealed class|abstract class|enum class)\s+(\w+)') {
                $matches[1]
            } else {
                $activity
            }
            
            $targetFile = "$targetDir\$firstClass.kt"
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($targetFile, $pkgBlock.Trim(), $utf8NoBom)
            $arquivosCriados += "$firstClass.kt"
            Write-Log "Código do usuário gravado: $firstClass.kt (package: $pkg)" "OK"
        }
        
        # 8. Injeção Inteligente de Dependências
        $injectedDeps = Invoke-IntelligentDependencyInjection -RootPath $RootPath -CodeContent $Conteudo
        if ($injectedDeps.Count -gt 0) {
            $arquivosCorrigidos += "Dependências injetadas: $($injectedDeps.Count)"
        }
        
        # 9. WrapperGenerator
        Invoke-WrapperGenerator -RootPath $RootPath
        $arquivosCriados += "gradlew", "gradlew.bat", "gradle-wrapper.properties", "gradle-wrapper.jar"
        
        # 10. Auto-Cura de Imports
        $importFixed = Invoke-ImportRepairEngine -RootPath $RootPath
        if ($importFixed -gt 0) {
            $arquivosCorrigidos += "Imports corrigidos: $importFixed"
        }
        
        # 11. settings.gradle.kts
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
        
        # 10. ProjectValidator
        $validacao = Invoke-ProjectValidator -RootPath $RootPath
        
        $relatorio = @{
            Timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
            arquivosCriados = @($arquivosCriados)
            arquivosCorrigidos = @($arquivosCorrigidos)
            manifestReconstruido = $true
            gradleReconstruido = $true
            validacaoEstrutura = $validacao.Percentual
            statusFinal = "READY_FOR_BUILD"
        }
        
        Write-Log "Reconstrução concluída: $($arquivosCriados.Count) arquivos criados" "OK"
        return $relatorio | ConvertTo-Json -Depth 10
        
    } catch {
        Write-Log "ReconstructionEngine ERRO: $_" "ERRO"
        return $null
    }
}

# Exportar funções
Export-ModuleMember -Function Invoke-ProjectNormalizer, Invoke-ManifestRebuilder, Invoke-RootGradleRebuilder, Invoke-GradleRebuilder, Invoke-ResourceRepairEngine, Invoke-ProguardRulesRebuilder, Invoke-WrapperGenerator, Invoke-ProjectValidator, Invoke-ReconstructionEngine, Add-Dependency, Invoke-IntelligentDependencyInjection, Invoke-ImportRepairEngine
