function Invoke-AndroidResourceDoctor {
    param(
        [string]$ProjectPath = "."
    )
    $buildGradle = Join-Path $ProjectPath "app/build.gradle"
    $buildGradleKts = Join-Path $ProjectPath "app/build.gradle.kts"
    $stylesXml = Join-Path $ProjectPath "app/src/main/res/values/styles.xml"
    $themeFound = $false
    $depFound = $false

    if (Test-Path $buildGradle) {
        $content = Get-Content $buildGradle -Raw
        if ($content -match "com\.google\.android\.material:material") {
            Write-Host "[OK] dependência Material3 encontrada no build.gradle" -ForegroundColor Green
            $depFound = $true
        }
    }
    elseif (Test-Path $buildGradleKts) {
        $content = Get-Content $buildGradleKts -Raw
        if ($content -match "androidx\.compose\.material3:material3") {
            Write-Host "[OK] dependência Material3 encontrada no build.gradle.kts" -ForegroundColor Green
            $depFound = $true
        }
    }
    else {
        Write-Host "[WARN] build.gradle não encontrado!" -ForegroundColor Yellow
    }

    if (Test-Path $stylesXml) {
        $styles = Get-Content $stylesXml -Raw
        if ($styles -match "Theme.Material3.DayNight") {
            Write-Host "[OK] Tema Theme.Material3.DayNight encontrado." -ForegroundColor Green
            $themeFound = $true
        }
        else {
            Write-Host "[ERRO] Tema Theme.Material3.DayNight não encontrado em styles.xml" -ForegroundColor Red
        }
    }
    else {
        Write-Host "[WARN] styles.xml não encontrado, não foi possível concluir validação de tema." -ForegroundColor Yellow
    }

    if (-not ($depFound -and $themeFound)) {
        throw "Falha de validação: recursos Android Material3 obrigatórios não encontrados."
    }
    Write-Host "[OK] Validação de recursos Android concluída com sucesso." -ForegroundColor Green
}