# Quick Start - Compilador APK v9.0

## 🚀 Início Rápido (5 minutos)

### Pré-requisitos
- ✅ Windows 10+
- ✅ PowerShell 5.1+ (geralmente incluído)
- ✅ Token GitHub (gere em https://github.com/settings/tokens)
- ✅ Git instalado (opcional, script baixa automaticamente)

### Passo 1: Abrir o Programa

**Opção A: Duplo-clique (Recomendado)**
```
C:\Compilador-APK\abrir-interface.bat
```

**Opção B: PowerShell**
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Compilador-APK\scripts\apk-compiler-ui.ps1"
```

### Passo 2: Configurar Token GitHub

1. Gere token em: https://github.com/settings/tokens/new
   - Selecione escopos: `repo`, `workflow`
   - Copie o token

2. Na interface:
   - Cole o token no campo "Token GitHub"
   - Clique "Salvar Token"
   - Token é armazenado localmente (não é enviado para terceiros)

### Passo 3: Selecionar Código

Escolha uma opção:

**A) Colar Código**
```
1. RadioButton "Colar" (padrão)
2. Cole seu arquivo .kt no TextBox
3. Exemplo:
   package com.example.app
   import androidx.activity.ComponentActivity
   class MainActivity : ComponentActivity()
```

**B) Arquivo ZIP**
```
1. RadioButton "ZIP"
2. Clique "Selecionar ZIP"
3. Selecione seu arquivo .zip com projeto
```

**C) Pasta Local**
```
1. RadioButton "Pasta"
2. Clique "Selecionar Pasta"
3. Aponte para pasta com arquivos .kt
```

**D) GitHub/Git URL**
```
1. RadioButton "GitHub/Git"
2. Cole a URL do repositório (ex: https://github.com/usuario/projeto)
3. O programa irá automaticamente clonar e preparar os arquivos
```

### Passo 4: ANALISAR

```
1. Clique botão verde "ANALISAR"
2. Aguarde análise completa
3. Veja no log:
   - Integridade estrutural (%)
   - Tecnologias detectadas
   - Erros encontrados
   - Ações sugeridas
4. Se integridade >= 75%, botão "RECONSTRUIR" fica habilitado
```

**Exemplo de saída:**
```
[10:30:45][OK] InputGateway: Código colado (1250 chars)
[10:30:45][OK] TechnologyDetector: Kotlin detectado
[10:30:46][OK] ErrorScanner: Encontrou 0 erro(s)
[10:30:46][OK] IntegrityAnalyzer: Integridade = 100%
════ ANALYSISENGINE concluído OK ════
Integridade: 100% | Compilável: true
```

### Passo 5: RECONSTRUIR

```
1. Clique botão laranja "RECONSTRUIR"
2. Sistema:
   - Cria estrutura Android completa
   - Reconstrói AndroidManifest.xml
   - Gera build.gradle.kts moderno
   - Repara imports (android.support → androidx)
3. Se sucesso, botão "GERAR APK" fica habilitado
```

**Exemplo de saída:**
```
[10:31:00][OK] ProjectNormalizer: Estrutura normalizada
[10:31:00][OK] GradleRebuilder: Gradle reconstruído
[10:31:00][OK] ManifestRebuilder: Manifest reconstruído
[10:31:01][OK] ReconstructionEngine concluído
════ Projeto reconstruído com sucesso ════
```

### Passo 6: GERAR APK

```
1. Clique botão vermelho "GERAR APK"
2. Sistema:
   - Envia código ao GitHub
   - Dispara GitHub Actions
   - Compila com Gradle 8.2
   - Baixa APK automaticamente
3. Aguarde 2-5 minutos
```

**Exemplo de saída:**
```
[10:32:00] Repositório GitHub criado: username/apk-build-20260527
[10:32:15] Código pushed to GitHub
[10:32:45] Build: queued | Tempo: 30s
[10:33:15] Build: in_progress | Tempo: 60s
[10:34:45] Build: completed | Tempo: 120s
[10:34:46] BUILD SUCESSO!
[10:34:47] APK BAIXADO: C:\ProjetoAndroid\app-debug.zip
══════════��══════════════════════════════
BUILDORCHESTRATOR CONCLUIDO
═════════════════════════════════════════
```

---

## 📊 Fluxo Visual

```
┌─────────────────────────────────────────────────────────────┐
│                  COMPILADOR APK v9.0                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Token GitHub: [••••••••••••••] Salvar | Alterar          │
│                                                             │
│  Fonte: ◉ Colar  ○ ZIP  ○ Pasta  ○ GitHub/Git             │
│  ┌────────────────────────────────────────────────┐        │
│  │ package com.example.app                        │        │
│  │ import androidx.activity.ComponentActivity     │        │
│  │ class MainActivity : ComponentActivity() { ... │        │
│  └────────────────────────────────────────────────┘        │
│                                                             │
│  Destino: C:\Users\...\Desktop\ProjetoAndroid  [Alterar]  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  [1 — ANALISAR]  [2 — RECONSTRUIR]  [3 — GERAR APK] │  │
│  │                                                      │  │
│  │  Status: Pronto para análise.                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  Log:                                                   [Limpar] │
│  ┌─────────────────────────────────────────────────���──┐   │
│  │ [10:30:45][OK] Código colado (1250 chars)         │   │
│  │ [10:30:46][OK] Integridade = 100%                 │   │
│  │ [10:30:47][OK] ANALISAR concluído                 │   │
│  │ [10:31:00][OK] Clique RECONSTRUIR...              │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ Validação de Saída

### ANALISAR (Output JSON)
```json
{
  "Timestamp": "2026-05-27T10:30:45Z",
  "Linguagens": ["Kotlin"],
  "Frameworks": ["Jetpack Compose", "AndroidX"],
  "Dependencias": ["Firebase"],
  "IntegridadePercentual": 100,
  "Compilavel": true,
  "Erros": []
}
```

### RECONSTRUIR (Output JSON)
```json
{
  "Timestamp": "2026-05-27T10:31:00Z",
  "Package": "com.example.app",
  "Activity": "MainActivity",
  "Status": "READY_FOR_BUILD",
  "ArquivosCriados": [
    "build.gradle.kts",
    "AndroidManifest.xml",
    "settings.gradle.kts",
    "gradlew"
  ]
}
```

### GERAR APK (Output JSON)
```json
{
  "Status": "SUCCESS",
  "APKGerado": true,
  "DownloadDisponivel": true,
  "CaminhoAPK": "C:\\ProjetoAndroid\\app-debug.zip",
  "TempoBuild": "2min 30s"
}
```

---

## 🔧 Troubleshooting

### "Access Denied" ao abrir .bat
```
Solução: Clique direito em abrir-interface.bat → "Executar como administrador"
```

### "Token vazio" no programa
```
Solução: Cole o token completo (sem espaços)
         Veja https://github.com/settings/tokens
```

### "Código vazio" ao clicar ANALISAR
```
Solução A (Colar): Cole .kt válido no TextBox
Solução B (ZIP): Selecione arquivo ZIP que contém .kt files
Solução C (Pasta): Selecione pasta com arquivos .kt
Solução D (GitHub/Git): Cole uma URL válida do repositório
```

### Build falha no GitHub Actions
```
Verificar log no programa:
  • Procure por "ERRO:" no log
  • Veja mensagem de compilação
  • Corrija imports ou syntax
  • Clique ANALISAR novamente
```

### APK não baixa
```
Verificar:
  1. Token GitHub está correto
  2. Repositório foi criado (veja em github.com)
  3. Build completou (procure por "BUILD SUCESSO")
  4. Conexão internet está ativa
```

---

## 💡 Dicas & Truques

### Dica 1: Usar Código Simples para Testar
```kotlin
package com.example.test

import androidx.activity.ComponentActivity

class MainActivity : ComponentActivity()
```
✅ Vai detectar tudo automaticamente e compilar

### Dica 2: Verificar Token no GitHub
```
1. Vá para https://github.com/settings/tokens
2. Procure token com nome "Compilador APK"
3. Se espirado, gere novo
4. Copie e cole no programa
```

### Dica 3: Limpar Repositórios Temporários
```
O programa delete automaticamente, mas se houver erro:
  1. Vá para https://github.com/settings/repositories
  2. Delete repositórios "apk-build-*" manualmente
  3. Tente novamente
```

### Dica 4: Salvar APK Final
```
Após download:
  1. APK está em: C:\ProjetoAndroid\app-debug.zip
  2. Extraia o ZIP
  3. Encontre: app-debug.apk
  4. Copie para seu dispositivo Android
  5. Instale (com "Origens desconhecidas" habilitado)
```

---

## 🚨 Erros Comuns

| Erro | Causa | Solução |
|------|-------|---------|
| "Package não declarada" | Código sem package | Adicione `package com.example.app` |
| "Activity não encontrada" | Nenhuma classe Activity | Crie classe que herda ComponentActivity |
| "android.support detectado" | Imports desatualizado | RECONSTRUIR corrige automaticamente |
| "Manifest inválido" | AndroidManifest.xml corrompido | RECONSTRUIR reconstrói |
| "Build timeout" | Levou mais de 20 min | GitHub Actions pode ser lento, tente novamente |
| "APK não encontrado" | Build falhou silenciosamente | Veja log para erros Gradle |

---

## 📞 Suporte

- 📖 Documentação completa: `ARQUITETURA.md`
- 🔧 Guia de desenvolvimento: `DESENVOLVIMENTO.md`
- 📜 Histórico: `CHANGELOG.md`
- 🌐 GitHub: https://github.com/idavidjunior/Compilador-APK

---

## ⏱️ Tempo Esperado

| Etapa | Tempo |
|-------|-------|
| ANALISAR | 5-10 seg |
| RECONSTRUIR | 5-10 seg |
| GERAR APK | 2-5 min (depende do GitHub Actions) |
| **Total** | **~3-6 minutos** |

---

## 🎯 Próximos Passos

✅ Implementação v9.0 concluída
📅 Futuro (v9.1):
  - Reparar XML/layouts automaticamente
  - Suporte a DOCX, PDF
  - Detecção de Flutter, React Native

---

**Status: ✅ Production Ready**
**Versão: 9.0**
**Data: 2026-05-27**

