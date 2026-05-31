﻿param(
    [switch]$InstallJava,
    [switch]$InstallAndroidStudio,
    [switch]$SetAndroidEnv,
    [switch]$InstallChocoIfMissing
)

$ErrorActionPreference = 'Stop'

function Add-ChocoToPathIfPresent {
    $chocoBin = 'C:\ProgramData\chocolatey\bin'
    $chocoExe = Join-Path $chocoBin 'choco.exe'
    if (Test-Path $chocoExe) {
        $env:Path = "$chocoBin;" + $env:Path
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if (-not $userPath) { $userPath = '' }
        if ($userPath -notlike "*$chocoBin*") {
            if ($userPath.Length -gt 0) { $userPath = "$userPath;$chocoBin" } else { $userPath = $chocoBin }
            [Environment]::SetEnvironmentVariable('Path', $userPath, 'User')
        }
        return $true
    }
    return $false
}

function Install-Choco {
    if (Get-Command choco -ErrorAction SilentlyContinue) { return }
    if (Add-ChocoToPathIfPresent) { return }

    Write-Host '[INFO] Instalando Chocolatey...' -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    [void](Add-ChocoToPathIfPresent)
}

function Get-PackageManager {
    if (Get-Command winget -ErrorAction SilentlyContinue) { return 'winget' }
    if (Get-Command choco -ErrorAction SilentlyContinue) { return 'choco' }
    [void](Add-ChocoToPathIfPresent)
    if (Get-Command choco -ErrorAction SilentlyContinue) { return 'choco' }

    if ($InstallChocoIfMissing) {
        Install-Choco
        if (Get-Command choco -ErrorAction SilentlyContinue) { return 'choco' }
    }

    throw 'Nenhum gerenciador suportado encontrado (winget/choco). Use -InstallChocoIfMissing para desbloquear automaticamente.'
}

function Install-Java([string]$pm) {
    Write-Host '[INFO] Instalando OpenJDK 17...' -ForegroundColor Cyan
    if ($pm -eq 'winget') { winget install -e --id Microsoft.OpenJDK.17 --accept-package-agreements --accept-source-agreements }
    else { choco install microsoft-openjdk17 -y }
}

function Install-AndroidStudio([string]$pm) {
    Write-Host '[INFO] Instalando Android Studio...' -ForegroundColor Cyan
    if ($pm -eq 'winget') { winget install -e --id Google.AndroidStudio --accept-package-agreements --accept-source-agreements }
    else { choco install androidstudio -y }
}

function Set-AndroidEnvironment {
    $defaultSdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
    if (-not (Test-Path $defaultSdk)) {
        Write-Host '[WARN] SDK não encontrado no caminho padrão. Abra Android Studio e instale o SDK primeiro.' -ForegroundColor Yellow
        return
    }
    [Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', $defaultSdk, 'User')
    [Environment]::SetEnvironmentVariable('ANDROID_HOME', $defaultSdk, 'User')
    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not $currentPath) { $currentPath = '' }
    $needed = @((Join-Path $defaultSdk 'platform-tools'),(Join-Path $defaultSdk 'cmdline-tools\latest\bin'))
    foreach ($item in $needed) {
        if ($currentPath -notlike "*$item*") {
            if ($currentPath.Length -gt 0) { $currentPath = "$currentPath;$item" } else { $currentPath = $item }
        }
    }
    [Environment]::SetEnvironmentVariable('Path', $currentPath, 'User')
    Write-Host '[OK] Variáveis ANDROID_HOME/ANDROID_SDK_ROOT configuradas.' -ForegroundColor Green
}

$pm = Get-PackageManager
Write-Host "[INFO] Gerenciador detectado: $pm" -ForegroundColor Cyan
if ($InstallJava) { Install-Java -pm $pm }
if ($InstallAndroidStudio) { Install-AndroidStudio -pm $pm }
if ($SetAndroidEnv) { Set-AndroidEnvironment }
Write-Host '[OK] Script finalizado. Reabra o terminal.' -ForegroundColor Green
