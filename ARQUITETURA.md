# Arquitetura - Compilador APK v8.0

## Visão Geral

O Compilador APK é um **orquestrador Windows** (PowerShell) que:
1. **Diagnostica** código Kotlin contra exigências do GitHub Actions + Android
2. **Estrutura** o projeto aplicando a "estrutura espelho" (11 arquivos template)
3. **Compila** remotamente via GitHub Actions

**Linguagem**: PowerShell puro  
**Plataforma**: Windows (PowerShell 5.1+)  
**Tamanho**: 67 KB, 1461 linhas

---

## Componentes Principais

### 1. Interface Windows (PowerShell v8.0)
**Arquivo**: `scripts/apk-compiler-ui.ps1`

#### Funcionalidades
- **3 fontes de entrada**:
  - Colar código diretamente
  - Arquivo ZIP (auto-extrai e detecta .kt)
  - Pasta local (varre .kt files)

- **Fluxo em 3 etapas**:
  1. **DIAGNOSTICAR**: Analisa código + estrutura, habilita ESTRUTURAR
  2. **ESTRUTURAR**: Corrige todos os problemas, habilita COMPILAR
  3. **COMPILAR NA NUVEM**: Envia ao GitHub, monitora build até APK gerado

#### Estrutura Espelho Embutida
11 arquivos template (referência canônica):
```
.github/workflows/android.yml       ← GitHub Actions workflow
settings.gradle.kts                 ← Kotlin DSL, include(":app")
build.gradle.kts                    ← Plugins raiz (AGP 8.2, Kotlin)
app/build.gradle.kts                ← namespace, compileSdk, deps, Compose
gradle.properties                   ← AndroidX, cache, parallel build
gradle/wrapper/gradle-wrapper.properties ← Gradle 8.2
gradlew                             ← Wrapper Unix
gradlew.bat                         ← Wrapper Windows
app/src/main/AndroidManifest.xml    ← activity exported, MAIN intent
app/src/main/res/values/strings.xml ← app name
.gitignore                          ← Git exclusions
```

#### Funcionalidades Avançadas

**Diagnostico** (Invoke-Diagnostico):
- Valida package Kotlin (2+ segmentos, minúsculas)
- Detecta Activity (ComponentActivity, AppCompatActivity, etc)
- Valida imports: android.os.Bundle, androidx.activity.ComponentActivity
- Valida método onCreate()
- Compara arquivos contra estrutura espelho
- Valida conteúdo de cada arquivo (não só existência)
- Gera relatório: erros, avisos, arquivos OK/faltando/inválidos

**Estruturacao** (Invoke-Estruturacao):
- Recebe resultado do diagnóstico
- Extrai package e activity name do código
- Cria toda a árvore de diretórios
- Gera 11 arquivos com conteúdo correto
- Injeta dados: `namespace`, `applicationId`, `app_name`, etc
- Valida estrutura final (re-diagnostica)
- Confirma cada arquivo criado no log

**Compilacao** (Start-CompilacaoBackground):
- Executa em RunSpace separado (UI não congela)
- Copia projeto para `%TEMP%\apk-build-*`
- Git commit local
- Cria repositório GitHub **privado**
- Push do código
- Aguarda workflow ser registrado (até 3 min)
- Monitora status do build (polling a cada 10s)
- Baixa APK ao concluir
- Deleta repositório temporário no finally

#### Token GitHub
- Persistido em `token.dat` (Base64)
- Carregado automaticamente ao abrir
- Botão "Alterar" para trocar token
- Não substitui sem confirmação explícita

#### Log Detalhado
Cada operação registrada em TextBox:
```
[HH:mm:ss][OK] Package: com.example.app
[HH:mm:ss][AVISO] Import 'android.os.Bundle' nao encontrado
[HH:mm:ss][FALTA] .github/workflows/android.yml — workflow GitHub Actions
[HH:mm:ss][INFO] Estruturando projeto...
[HH:mm:ss][INFO] Repositorio criado: username/apk-build-20260526
[HH:mm:ss][INFO] Run #1 | Status: in_progress | Conclusao: pendente | Tempo: 50s/1200s
[HH:mm:ss][OK] BUILD CONCLUIDO COM SUCESSO!
```

---

### 2. Android App (Opcional)
**Diretório**: `android-app/`

Aplicação Android nativa com:
- **Framework**: Jetpack Compose
- **Telas**: BuildDashboardScreen
- **ViewModel**: BuildDashboardViewModel
- **Build**: Gradle 8.2, AGP 8.2.0, Kotlin 1.9.22

Pode ser compilado separadamente se necessário.

---

### 3. Scripts Auxiliares

#### apk-compiler.ps1
CLI para operações:
- `doctor`: Verifica ambiente (JDK, Gradle, etc)
- `build`: Compila APK localmente
- `sign`: Assina APK com keystore
- `create-keystore`: Cria keystore para assinatura
- `find-apk`: Localiza APK compilados

Uso:
```powershell
.\apk-compiler.ps1 doctor
.\apk-compiler.ps1 build -apkPath "C:\projeto"
.\apk-compiler.ps1 sign -apkPath "app-debug.apk" -keystore "keystore.jks"
```

#### install-deps.ps1
Instala dependências necessárias:
- JDK 17 (via `winget` ou `choco`)
- Git
- Gradle (opcional, wrapper é auto-extraído)

Uso:
```powershell
.\install-deps.ps1
```

#### abrir-interface.bat
Atalho para abrir a UI PowerShell:
```batch
@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\apk-compiler-ui.ps1"
pause
```

---

## Fluxo de Execução

```
User clica em abrir-interface.bat
    ↓
PowerShell v8.0 abre (WPF)
    ↓
User seleciona fonte (colar/ZIP/pasta)
    ↓
User clica DIAGNOSTICAR
    ├→ Invoke-Diagnostico
    ├→ Analisa código + estrutura
    ├→ Log detalhado
    └→ HABILITA ESTRUTURAR
    ↓
User clica ESTRUTURAR
    ├→ Invoke-Estruturacao
    ├→ Cria 11 arquivos
    ├→ Valida estrutura final
    ├→ Re-diagnostica
    └→ HABILITA COMPILAR (se sem erros)
    ↓
User clica COMPILAR NA NUVEM
    ├→ Start-CompilacaoBackground (RunSpace)
    ├→ Git commit + push ao repo privado GitHub
    ├→ Aguarda workflow ser registrado
    ├→ Monitora build
    ├→ Download do APK
    ├→ Deleta repo privado
    └→ Status final com link ao APK
```

---

## Referências

### GitHub Actions
- Docs: https://docs.github.com/en/actions
- Workflow Syntax: https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions
- Marketplace: https://github.com/marketplace/actions/gradle-build-action

### Android Build Tools
- AGP: https://developer.android.com/build/gradle-tips
- Gradle: https://docs.gradle.org/current/userguide/
- Manifest: https://developer.android.com/guide/topics/manifest/manifest-intro
- Kotlin DSL: https://docs.gradle.org/current/userguide/kotlin_dsl.html

### Kotlin
- Package: https://kotlinlang.org/docs/packages.html
- Classes: https://kotlinlang.org/docs/classes.html
- Android: https://developer.android.com/kotlin

---

## Versões

### v8.0 (Atual)
- Estrutura espelho embutida (11 arquivos)
- Fluxo: Diagnosticar → Estruturar → Compilar
- 3 fontes de entrada (colar/ZIP/pasta)
- Token persistido
- Log detalhado
- RunSpace para paralelismo

### v7.0
- 3 fontes de entrada
- Fluxo inicial

### v6.2
- Correção de here-strings PowerShell
- UTF-8 BOM + CRLF

---

## O que NÃO está aqui

❌ Módulos Kotlin (github/, pipeline/, validator/, etc) — removidos  
❌ Testes Kotlin — removidos  
❌ Módulos core/* e feature-* — removidos  

**Razão**: Lógica duplicada em PowerShell v8.0. Decisão: manter só PowerShell.

Se houver necessidade de portabilidade (macOS/Linux) ou integração Kotlin no futuro, será necessário refatorar para Kotlin + Gradle.
