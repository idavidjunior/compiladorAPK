@echo off
title Compilador APK - Reparo e Atualizacao
echo.
echo  Compilador APK - Reparo Automatico
echo  Baixando versao mais recente do GitHub...
echo.

:: Criar pasta scripts se nao existir
if not exist "%~dp0scripts" mkdir "%~dp0scripts"

:: Baixar o script principal diretamente (sem verificacao de versao)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $url = 'https://raw.githubusercontent.com/idavidjunior/compiladorAPK/main/scripts/apk-compiler-ui.ps1'; $dest = '%~dp0scripts\apk-compiler-ui.ps1'; (New-Object System.Net.WebClient).DownloadFile($url, $dest); Write-Host ' Script baixado com sucesso.'"

if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERRO: Nao foi possivel baixar. Verifique sua conexao com a internet.
    pause
    exit /b 1
)

:: Baixar o launcher atualizado
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $url = 'https://raw.githubusercontent.com/idavidjunior/compiladorAPK/main/abrir-interface.bat'; $dest = '%~dp0abrir-interface.bat'; (New-Object System.Net.WebClient).DownloadFile($url, $dest); Write-Host ' Launcher baixado com sucesso.'"

echo.
echo  Atualizacao concluida! Iniciando o Compilador APK...
echo.

:: Executar a interface
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\apk-compiler-ui.ps1"

if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERRO ao iniciar. Verifique o .NET Framework e o PowerShell.
    pause
)
