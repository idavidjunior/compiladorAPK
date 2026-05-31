@echo off
setlocal EnableDelayedExpansion
title Compilador APK v9.0

set "SCRIPT_DIR=%~dp0"
set "SCRIPT=%SCRIPT_DIR%scripts\apk-compiler-ui.ps1"
set "SCRIPT_TEMP=%SCRIPT_DIR%scripts\apk-compiler-ui.tmp"
set "GITHUB_RAW=https://raw.githubusercontent.com/idavidjunior/compiladorAPK/main/scripts/apk-compiler-ui.ps1"
set "GITHUB_BUILD=https://raw.githubusercontent.com/idavidjunior/compiladorAPK/main/build.txt"

echo ===========================================================
echo    Compilador APK v9.0
echo    Fluxo: ANALISAR ^> RECONSTRUIR ^> GERAR APK
echo    Self-Healing Engine v9.0 ^| Auto-Correcao Ativa
echo ===========================================================
echo.

:: ── Verificar PowerShell ───────────────────────────────────────────────────
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERRO] PowerShell nao encontrado.
    pause & exit /b 1
)

:: ── Garantir pasta scripts ─────────────────────────────────────────────────
if not exist "%SCRIPT_DIR%scripts" mkdir "%SCRIPT_DIR%scripts"

:: ── Extrair BUILD local ────────────────────────────────────────────────────
set "LOCAL_BUILD="
if exist "%SCRIPT%" (
    for /f "tokens=3 delims= " %%A in ('findstr /B /C:"# BUILD:" "%SCRIPT%" 2^>nul') do (
        set "LOCAL_BUILD=%%A"
    )
)

:: ── Baixar BUILD remoto ────────────────────────────────────────────────────
echo [UPDATE] Verificando atualizacoes...
set "REMOTE_BUILD="
for /f "delims=" %%A in ('powershell -NoProfile -Command "try{(Invoke-WebRequest -Uri '%GITHUB_BUILD%' -UseBasicParsing -TimeoutSec 8).Content.Trim()}catch{''}" 2^>nul') do (
    set "REMOTE_BUILD=%%A"
)

:: ── Comparar e decidir se atualiza ────────────────────────────────────────
set "PRECISA_ATUALIZAR=0"

if "!LOCAL_BUILD!"=="" (
    echo [UPDATE] Script sem marcador de versao. Atualizando...
    set "PRECISA_ATUALIZAR=1"
) else if "!REMOTE_BUILD!"=="" (
    echo [UPDATE] Sem conexao. Usando versao local ^(!LOCAL_BUILD!^).
) else if not "!LOCAL_BUILD!"=="!REMOTE_BUILD!" (
    echo [UPDATE] Nova versao disponivel^^!
    echo [UPDATE]   Local : !LOCAL_BUILD!
    echo [UPDATE]   GitHub: !REMOTE_BUILD!
    set "PRECISA_ATUALIZAR=1"
) else (
    echo [UPDATE] Versao !LOCAL_BUILD! - ja esta atualizado.
)

:: ── Baixar script atualizado ───────────────────────────────────────────────
if "!PRECISA_ATUALIZAR!"=="1" (
    echo [UPDATE] Baixando atualizacao...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "try { $content = (Invoke-WebRequest -Uri '%GITHUB_RAW%' -UseBasicParsing -TimeoutSec 30).Content; [System.IO.File]::WriteAllText('%SCRIPT_TEMP%', $content, [System.Text.Encoding]::UTF8); Write-Host 'OK' } catch { Write-Host 'ERRO:' + $_.Exception.Message }" > "%TEMP%\upd_result.txt" 2>&1
    set /p UPD_RESULT=<"%TEMP%\upd_result.txt"
    
    if "!UPD_RESULT!"=="OK" (
        :: Substituir script antigo pelo novo
        if exist "%SCRIPT_TEMP%" (
            copy /y "%SCRIPT_TEMP%" "%SCRIPT%" >nul 2>&1
            del "%SCRIPT_TEMP%" >nul 2>&1
            echo [UPDATE] Script atualizado com sucesso^^!
        )
    ) else (
        echo [UPDATE] Falha no download: !UPD_RESULT!
        echo [UPDATE] Usando versao local.
    )
    echo.
)

:: ── Verificar se o script existe antes de executar ─────────────────────────
if not exist "%SCRIPT%" (
    echo [ERRO] Script nao encontrado mesmo apos tentativa de download.
    echo Verifique sua conexao e tente novamente.
    pause & exit /b 1
)

:: ── Executar interface ─────────────────────────────────────────────────────
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "EXIT_CODE=%ERRORLEVEL%"

if %EXIT_CODE% neq 0 (
    echo.
    echo [ERRO] A interface encerrou com codigo %EXIT_CODE%.
    echo Verifique se o .NET Framework e o Windows PowerShell estao atualizados.
    pause
)

endlocal
