# Runbook de Incidentes - Compilador APK v9.0

## Visão Geral

Este runbook documenta procedimentos para diagnóstico e recuperação de incidentes comuns no Compilador APK.

## Incidentes Comuns

### 1. Token GitHub Inválido ou Expirado

**Sintomas:**
- Erro: "Token do GitHub inválido"
- Build não inicia
- Validação de token falha

**Diagnóstico:**
```powershell
# Verificar se token existe
Test-SecureToken

# Validar token
Test-GitHubToken -Token $token
```

**Recuperação:**
1. Gerar novo token em https://github.com/settings/tokens/new
2. Selecionar permissões: `repo` (full control) e `workflow`
3. Salvar token usando:
   ```powershell
   Save-SecureToken -Token "ghp_xxxxxxxxxxxx"
   ```
4. Reiniciar aplicação

**Prevenção:**
- Tokens expiram após 1 ano por padrão
- Configurar lembrete para renovação
- Usar GitHub Apps para produção (tokens mais longos)

---

### 2. GitHub API Rate Limit

**Sintomas:**
- Erro: "403 Forbidden" com mensagem "API rate limit exceeded"
- Circuit breaker abre após múltiplas falhas
- Chamadas à API falham consecutivamente

**Diagnóstico:**
```powershell
# Verificar estado do circuit breaker
Get-CircuitBreakerState

# Verificar contagem de falhas
$script:CircuitBreakerState.FailureCount
```

**Recuperação:**
1. Aguardar timeout do circuit breaker (60 segundos)
2. Reset manual do circuit breaker:
   ```powershell
   Reset-CircuitBreaker
   ```
3. Reduzir frequência de chamadas
4. Implementar cache de resultados

**Prevenção:**
- Implementar cache de respostas da API
- Usar pagination em vez de buscar tudo de uma vez
- Respeitar headers de rate limit da API

---

### 3. Build Timeout (30 minutos)

**Sintomas:**
- Erro: "Build excedeu timeout de 30 minutos"
- Build travado em "in_progress"
- Monitoramento não detecta conclusão

**Diagnóstico:**
```powershell
# Verificar tempo decorrido
$elapsed = (Get-Date) - $startTime

# Verificar status do workflow no GitHub
Get-GitHubWorkflowRuns -Owner $owner -Repo $repo -Token $token
```

**Recuperação:**
1. Cancelar workflow manualmente no GitHub
2. Verificar logs do workflow para identificar gargalo
3. Ajustar timeout se necessário (modificar `$script:BuildTimeoutMinutes`)
4. Reexecutar build

**Prevenção:**
- Otimizar Gradle cache
- Usar dependências locais quando possível
- Paralelizar tasks do Gradle
- Reduzir número de variantes de build

---

### 4. Falha ao Baixar Gradle Wrapper

**Sintomas:**
- Erro: "Falha crítica: não foi possível baixar gradle-wrapper.jar"
- Arquivo corrompido ou muito pequeno
- Build falha com "gradlew: command not found"

**Diagnóstico:**
```powershell
# Verificar tamanho do arquivo
$fileInfo = Get-Item "gradle/wrapper/gradle-wrapper.jar"
$fileInfo.Length  # Deve ser ~47KB

# Verificar magic bytes
$bytes = [System.IO.File]::ReadAllBytes("gradle/wrapper/gradle-wrapper.jar")
$bytes[0] -eq 0x50 -and $bytes[1] -eq 0x4B  # Deve ser PK (ZIP magic)
```

**Recuperação:**
1. Baixar manualmente do mirror alternativo:
   ```powershell
   Invoke-WebRequest -Uri "https://services.gradle.org/distributions/gradle-wrapper.jar" -OutFile "gradle/wrapper/gradle-wrapper.jar"
   ```
2. Validar arquivo após download
3. Reexecutar build

**Prevenção:**
- Usar mirror local corporativo
- Implementar checksum validation
- Cache do gradle-wrapper.jar

---

### 5. Repositório Temporário Não Deletado

**Sintomas:**
- Múltiplos repositórios "apk-build-*" no GitHub
- Espaço em disco consumido por diretórios temporários
- Erro: "Repositório já existe"

**Diagnóstico:**
```powershell
# Listar repositórios temporários no GitHub
Get-GitHubWorkflowRuns -Owner $owner -Repo "apk-build-*" -Token $token

# Verificar diretórios temporários locais
Get-ChildItem $env:TEMP -Filter "apk-build-*"
```

**Recuperação:**
1. Deletar repositórios órfãos manualmente no GitHub
2. Limpar diretórios temporários locais:
   ```powershell
   Get-ChildItem $env:TEMP -Filter "apk-build-*" | Remove-Item -Recurse -Force
   ```
3. Implementar cleanup automático no finally block

**Prevenção:**
- Garantir que `Remove-TemporaryRepository` sempre execute
- Implementar cleanup periódico (cron job)
- Usar tags para identificar repositórios temporários

---

### 6. Erro de Validação Pré-Build

**Sintomas:**
- Erro: "VALIDATION_FAILED"
- Arquivos essenciais ausentes
- Build não inicia

**Diagnóstico:**
```powershell
# Executar validação
Invoke-PreBuildValidator -RootPath $rootPath

# Verificar arquivos críticos
Test-Path "app/src/main/AndroidManifest.xml"
Test-Path "app/build.gradle.kts"
Test-Path "gradlew"
```

**Recuperação:**
1. Executar `Invoke-ReconstructionEngine` para gerar arquivos faltantes
2. Verificar se código fonte foi gravado corretamente
3. Reexecutar validação
4. Iniciar build

**Prevenção:**
- Executar validação antes de cada build
- Implementar auto-reconstrução em caso de falha
- Documentar estrutura mínima exigida

---

### 7. Circuit Breaker Aberto

**Sintomas:**
- Erro: "Circuit breaker ABERTO - chamada bloqueada"
- Chamadas à API não são executadas
- Sistema em modo degradação

**Diagnóstico:**
```powershell
# Verificar estado
Get-CircuitBreakerState

# Verificar histórico de falhas
$script:CircuitBreakerState.FailureCount
$script:CircuitBreakerState.LastFailureTime
```

**Recuperação:**
1. Identificar causa raiz das falhas
2. Corrigir problema (ex: token inválido, network issue)
3. Reset manual do circuit breaker:
   ```powershell
   Reset-CircuitBreaker
   ```
4. Monitorar próximas chamadas

**Prevenção:**
- Ajustar threshold de falhas
- Implementar health checks periódicos
- Usar exponential backoff mais agressivo
- Monitorar métricas de circuit breaker

---

### 8. Erro de Encoding UTF-8

**Sintomas:**
- Caracteres corrompidos em arquivos .kt
- Erro de compilação: "Invalid character"
- BOM (Byte Order Mark) causando problemas

**Diagnóstico:**
```powershell
# Verificar encoding de arquivo
$content = Get-Content "app/src/main/java/MainActivity.kt" -Raw -Encoding UTF8

# Verificar BOM
$bytes = [System.IO.File]::ReadAllBytes("app/src/main/java/MainActivity.kt")
$bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF  # UTF-8 BOM
```

**Recuperação:**
1. Normalizar encoding UTF-8 sem BOM:
   ```powershell
   Invoke-ProjectNormalizer -RootPath $rootPath
   ```
2. Recriar arquivos afetados
3. Validar com `git diff`

**Prevenção:**
- Configurar editor para UTF-8 sem BOM
- Implementar pre-commit hooks
- Validar encoding em CI/CD

---

## Procedimentos de Emergência

### Build Travado em "in_progress"

1. **Ação Imediata:**
   - Cancelar workflow no GitHub Actions
   - Verificar logs para identificar gargalo

2. **Diagnóstico:**
   - Checar se workflow está realmente rodando
   - Verificar se há deadlock no código
   - Checar recursos do runner

3. **Recuperação:**
   - Reexecutar workflow
   - Se persistir, ajustar código para evitar travamento
   - Considerar aumentar timeout

### Perda de Token GitHub

1. **Ação Imediata:**
   - Gerar novo token
   - Salvar usando `Save-SecureToken`

2. **Verificação:**
   - Testar com `Test-GitHubToken`
   - Verificar permissões do token

3. **Recuperação:**
   - Reexecutar operações que falharam
   - Limpar caches se necessário

### Repositório Temporário Não Deletado

1. **Ação Imediata:**
   - Listar repositórios "apk-build-*" no GitHub
   - Identificar quais são órfãos

2. **Limpeza:**
   - Deletar manualmente via UI do GitHub
   - Ou usar script de cleanup

3. **Prevenção:**
   - Adicionar tag de timestamp
   - Implementar cleanup automático

## Métricas e Monitoramento

### Métricas Chave

- **Taxa de Sucesso de Build:** % de builds que concluem com sucesso
- **Tempo Médio de Build:** Tempo médio do início ao fim
- **Taxa de Erro da API:** % de chamadas à GitHub API que falham
- **Circuit Breaker Opens:** Número de vezes que circuit breaker abriu
- **Tempo de Recuperação:** Tempo para recuperar de incidentes

### Alertas

- **Alerta Crítico:** Build timeout > 25 minutos
- **Alerta Crítico:** Circuit breaker aberto
- **Alerta Warning:** Taxa de erro da API > 10%
- **Alerta Warning:** Repositórios temporários > 5

## Contatos e Escalation

### Nível 1: Operações
- Diagnóstico inicial
- Recuperação básica
- Documentação de incidente

### Nível 2: Desenvolvimento
- Análise de código
- Correção de bugs
- Melhoria de resiliência

### Nível 3: Arquitetura
- Decisões de design
- Mudanças estruturais
- Revisão de arquitetura

## Checklist de Pós-Incidente

1. [ ] Documentar incidente (timestamp, sintomas, impacto)
2. [ ] Identificar causa raiz
3. [ ] Implementar correção
4. [ ] Testar correção
5. [ ] Atualizar runbook se necessário
6. [ ] Comunicar stakeholders se afetado
7. [ ] Implementar prevenção
8. [ ] Agendar revisão post-mortem

## Referências

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Gradle Build Tool](https://docs.gradle.org/)
- [Android Build Configuration](https://developer.android.com/build)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
