# Changelog - Compilador APK

## [9.1] - 2026-05-30

### Adicionado
- **AI Expert Self-Healing:** Motor de auto-cura atualizado com padrões de engenharia de nível especialista para Jetpack Compose e Kotlin.
- **Reparo Profundo de Importações (`Invoke-ImportRepairEngine`):** Substituição de substituições básicas por um injetor robusto baseado em regex de mais de 40 importações essenciais do Jetpack Compose, Lifecycle, Coils, Serialization e Material Design 3.
- **Resolução de Dependências Avançada (`Invoke-DependencyResolver`):** Suporte nativo para Coil3, Jetpack DataStore Preferences, Kotlinx Serialization JSON, AndroidX Media e Material Icons Extended, com mecanismo de inserção resiliente se `testImplementation` estiver ausente.
- **Intérprete de Erros Inteligente (`Invoke-ErrorInterpreter`):** Detecção automática de referências não resolvidas do Compose para disparar o AutoFix `RunImportRepairEngine` de forma totalmente autônoma.

## [8.0] - 2026-05-26

### Adicionado
- Estrutura espelho embutida (11 arquivos template)
- Fluxo completo: Diagnosticar → Estruturar → Compilar
- 3 fontes de entrada: colar código, ZIP, pasta
- Validação de conteúdo (não apenas existência)
- Token persistido em arquivo (Base64)
- Log detalhado em TextBox
- RunSpace para compilação paralela
- Validação rigorosa de package e Activity

### Modificado
- Reescrita completa do interface v7.0
- Diagnostico agora valida contra estrutura espelho
- Estruturacao corrige todos os problemas encontrados
- Compilacao monitora GitHub Actions com retry

### Removido
- Módulos Kotlin orphans (github/, pipeline/, validator/, importers/, artifacts/)
- Módulos core/* e feature-* (sem propósito)
- Cópia flat em app/ (duplicação)
- Testes Kotlin soltos (fora da arquitetura)

---

## [7.0] - 2026-05-20

### Adicionado
- 3 fontes de entrada: colar, ZIP, pasta
- Botões com habilitação progressiva
- Token salvo automaticamente
- Log com níveis [OK/AVISO/ERRO/INFO]

---

## [6.2] - 2026-05-10

### Corrigido
- Here-strings PowerShell (@"..."@ vs @'...'@)
- Encoding UTF-8 BOM + CRLF
- Foreground com BrushConverter (Brush, não string)
- Workflow YAML gerado corretamente

---

## [6.1] - 2026-05-05

### Adicionado
- Interface WPF funcional
- Botões DIAGNOSTICAR, ESTRUTURAR, COMPILAR
- Log em TextBox

---

## [6.0] - 2026-05-01

### Adicionado
- Interface PowerShell v6.0
- Suporte a GitHub Actions
- Compilação remota

---

## Decisões Arquiteturais

### Por que PowerShell e não Kotlin?

**v8.0 usa PowerShell puro** para:
1. **Interface nativa Windows**: WPF integrada
2. **Sem dependências Gradle complexas**: rápido para debug
3. **Simplicidade**: lógica em 1 linguagem
4. **Produção já funciona**: não há necessidade de refatorar

**Módulos Kotlin foram removidos** porque:
- Código duplicado (Diagnostico, Estruturacao, Compilacao em 2 linguagens)
- Nunca compilados (não estavam no settings.gradle.kts)
- Nunca testados (testes compilados com kotlinc direto)
- Confusão: qual era a implementação real?

### Futuro (Kotlin)

Se houver necessidade de portabilidade (macOS/Linux) ou integração com Android app, refatorar para Kotlin + Gradle será apropriado. Nesse momento:
1. Reescrever lógica em Kotlin (BuildPipelineManager, CodeImporter, etc)
2. Integrar testes ao Gradle
3. PowerShell chamaria a DLL/JAR compilada via Process
4. Ou remover PowerShell e usar Kotlin native ou JVM CLI

---

## Versões Futuras Planejadas

- **v8.1**: Validações mais rigorosas de Android manifest
- **v8.2**: Suporte a Gradle modules (multi-module projects)
- **v9.0**: Interface mobile (android-app/)
- **v9.1**: API REST para chamar do mobile

