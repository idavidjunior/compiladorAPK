# Compilador APK v8.0

**Orquestrador de compilação de APK Android via GitHub Actions**

> Selecione seu código Kotlin, deixe o programa diagnosticar e estruturar, e compile na nuvem com um clique.

---

## ⚡ Quick Start

### Windows (Recomendado)
```batch
# Duplo-clique em:
abrir-interface.bat

# Ou via PowerShell:
powershell -ExecutionPolicy Bypass -File scripts\apk-compiler-ui.ps1
```

### Pré-requisitos
- Windows 10+
- PowerShell 5.1+
- Token GitHub (crie em https://github.com/settings/tokens)

---

## 📋 Como Usar

### 1. DIAGNOSTICAR
Selecione a fonte do código:
- **Colar código**: Cole o .kt diretamente na área de texto
- **Arquivo ZIP**: Selecione um .zip com seu projeto
- **Pasta local**: Selecione uma pasta com arquivos .kt

Clique em **DIAGNOSTICAR** para:
- Validar package Kotlin
- Detectar Activity principal
- Verificar imports essenciais
- Comparar estrutura contra exigências

### 2. ESTRUTURAR
Clique em **ESTRUTURAR** para:
- Criar toda a árvore de diretórios
- Gerar 11 arquivos necessários (respeitando GitHub Actions + Android)
- Injetar package, activity name, etc automaticamente
- Validar estrutura final

### 3. COMPILAR NA NUVEM
Clique em **COMPILAR NA NUVEM** para:
- Enviar ao repositório privado no GitHub
- Disparar GitHub Actions
- Monitorar build em tempo real
- Baixar APK gerado automaticamente

---

## 🏗️ Arquitetura

**Componentes**:
- `scripts/apk-compiler-ui.ps1` — Interface PowerShell v8.0 (67 KB)
- `scripts/apk-compiler.ps1` — CLI: doctor, build, sign, find-apk
- `scripts/install-deps.ps1` — Instala dependências (JDK 17, Git, etc)
- `android-app/` — Aplicativo Android opcional (Jetpack Compose)

**Estrutura espelho embutida** (11 arquivos):
```
.github/workflows/android.yml
settings.gradle.kts
build.gradle.kts (raiz)
app/build.gradle.kts
gradle.properties
gradle/wrapper/gradle-wrapper.properties
gradlew / gradlew.bat
app/src/main/AndroidManifest.xml
app/src/main/res/values/strings.xml
.gitignore
```

**Leia mais**: [ARQUITETURA.md](ARQUITETURA.md)

---

## 📖 Documentação

- **[ARQUITETURA.md](ARQUITETURA.md)** — Visão geral, componentes, fluxo, referências
- **[DESENVOLVIMENTO.md](DESENVOLVIMENTO.md)** — Como editar, testar, debugar
- **[CHANGELOG.md](CHANGELOG.md)** — Histórico de versões e decisões

---

## ✅ Funcionalidades

- ✓ Estrutura espelho embutida (11 arquivos template)
- ✓ 3 fontes de entrada (colar/ZIP/pasta)
- ✓ Validação rigorosa de código + estrutura
- ✓ Fluxo completo: Diagnosticar → Estruturar → Compilar
- ✓ Token GitHub persistido (Base64)
- ✓ Log detalhado com cores (OK/AVISO/ERRO/INFO)
- ✓ RunSpace (UI nunca congela durante compilação)
- ✓ Repositório privado temporário (deletado automaticamente)
- ✓ Monitoramento de GitHub Actions (retry automático)

---

## 🔧 Instalação de Dependências

```powershell
.\scripts\install-deps.ps1
```

Instala:
- JDK 17 (Temurin)
- Git
- Gradle (opcional, wrapper é auto-extraído)

---

## 🛠️ Scripts Auxiliares

### apk-compiler.ps1 (CLI)

```powershell
# Verificar ambiente
.\scripts\apk-compiler.ps1 doctor

# Compilar APK
.\scripts\apk-compiler.ps1 build -apkPath "C:\projeto"

# Assinar APK
.\scripts\apk-compiler.ps1 sign -apkPath "app-debug.apk" -keystore "keystore.jks"

# Criar keystore
.\scripts\apk-compiler.ps1 create-keystore

# Localizar APK compilados
.\scripts\apk-compiler.ps1 find-apk
```

---

## 📊 Diagnóstico Detalhado

Exemplo de output:

```
[10:30:45][OK] Declaracao package: com.example.myapp
[10:30:45][OK] Activity encontrada: MainActivity (herda de ComponentActivity)
[10:30:45][OK] Import: android.os.Bundle
[10:30:45][OK] Import: androidx.activity.ComponentActivity
[10:30:45][OK] Metodo onCreate() declarado

[10:30:46][OK] settings.gradle.kts — conteudo validado
[10:30:46][FALTANDO] .github/workflows/android.yml — workflow GitHub Actions
[10:30:46][INVALIDO] app/build.gradle.kts — falta 'namespace'

RESULTADO: 1 problema encontrado(s). Clique em ESTRUTURAR para corrigir.
```

---

## 🚀 GitHub Actions

O programa gera um workflow automaticamente que:

1. **Checkout**: puxa o código
2. **Setup JDK 17**: Temurin distribution
3. **Gradle Wrapper**: Gradle 8.2
4. **Build Debug APK**: `assembleDebug --stacktrace`
5. **Upload Artifact**: APK para download

Reference: [GitHub Actions docs](https://docs.github.com/en/actions)

---

## 🔐 Token GitHub

Para compilar na nuvem, você precisa de um token GitHub com permissões:
- `repo` (controle total de repositórios privados)
- `workflow` (para disparar workflows)

**Gerar token**: https://github.com/settings/tokens/new

**No programa**:
- Cole o token em "Token GitHub"
- Clique "Salvar Token"
- Token é armazenado em `token.dat` (Base64, criptografado localmente)
- Nunca é enviado para terceiros

---

## 📱 Android App (Opcional)

Aplicação nativa Android em `android-app/`:
```bash
cd android-app
./gradlew assembleDebug
```

**Tecnologias**:
- Jetpack Compose (UI)
- MVVM Architecture
- Gradle 8.2, AGP 8.2.0, Kotlin 1.9.22

---

## ❌ O que NÃO está aqui

Módulos Kotlin (github/, pipeline/, validator/, etc) foram **removidos** porque:
- Lógica duplicada em PowerShell v8.0
- Não eram compilados nem testados
- Criavam confusão arquitetural

**Decisão**: Manter só PowerShell como implementação oficial.

Se houver necessidade de portabilidade (macOS/Linux), será necessário refatorar para Kotlin + Gradle no futuro.

---

## 🐛 Troubleshooting

| Problema | Solução |
|----------|---------|
| "Access Denied" ao abrir .bat | Verificar que scripts/ não é read-only |
| "System.Windows not found" | Verificar PowerShell 5.1+ (Get-Host) |
| Token não salva | Verificar pasta scripts/ tem permissão de escrita |
| Build falha silenciosamente | Verificar log no programa (ScrollBar para baixo) |
| GitHub Actions não inicia | Aguardar 30s (workflow demora para registrar) |

---

## 📞 Suporte

Dúvidas ou sugestões?
1. Abrir issue no GitHub
2. Verificar [DESENVOLVIMENTO.md](DESENVOLVIMENTO.md) para debug
3. Consultar [ARQUITETURA.md](ARQUITETURA.md) para detalhes técnicos

---

## 📜 Licença

[MIT License](LICENSE)

---

## 🎯 Roadmap

- [ ] v8.1: Validações mais rigorosas de Android manifest
- [ ] v8.2: Suporte a Gradle modules (multi-module projects)
- [ ] v9.0: Interface mobile (usando android-app/)
- [ ] v9.1: API REST para integração com apps

---

**Versão**: 8.0  
**Data**: 2026-05-26  
**Status**: ✅ Production Ready
