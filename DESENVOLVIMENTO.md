# Guia de Desenvolvimento

## Configuração Local

### Pré-requisitos
- Windows 10+
- PowerShell 5.1+
- Git 2.30+
- (Opcional) PowerShell ISE ou VS Code para editar

### Clone e Execução
```bash
git clone https://github.com/idavidjunior/Compilador-APK.git
cd Compilador-APK
# Duplo-clique em abrir-interface.bat
# Ou via PowerShell:
powershell -ExecutionPolicy Bypass -File scripts/apk-compiler-ui.ps1
```

---

## Estrutura do Arquivo PS1

**Arquivo**: `scripts/apk-compiler-ui.ps1` (1461 linhas)

### Seções

1. **Cabeçalho & Estado Global** (linhas 1-50)
   - Variáveis globais
   - Estrutura espelho embutida (ESTRUTURA_ESPELHO)

2. **Utilitários** (linhas 51-150)
   - Write-Log, Set-StatusUI, Set-Status
   - Load-Token, Save-Token
   - Get-CodigoDeZip, Get-CodigoDePasta

3. **Diagnostico** (linhas 151-350)
   - Invoke-Diagnostico: analisa código + estrutura
   - Retorna PSCustomObject com erros/avisos/arquivos

4. **Estruturacao** (linhas 351-800)
   - Invoke-Estruturacao: cria 11 arquivos
   - Injeta variáveis (package, activity, app name)
   - Valida estrutura final

5. **Compilacao (RunSpace)** (linhas 801-1100)
   - Start-CompilacaoBackground: executa em paralelo
   - Git commit + push
   - Monitoramento GitHub Actions

6. **Interface WPF** (linhas 1101-1461)
   - XAML inline (cards, botões, TextBox, PasswordBox)
   - Eventos de click
   - Binding de controles

---

## Como Editar

### Usando VS Code
```powershell
code scripts/apk-compiler-ui.ps1
```

### Usando PowerShell ISE
```powershell
powershell_ise.exe scripts/apk-compiler-ui.ps1
```
- F5: Executar (vai abrir a UI)
- F7: Debug (passo a passo)
- Ctrl+Shift+F2: Ponto de interrupção

### Syntax Highlighting
- VS Code: extensão "PowerShell" (Microsoft)
- ISE: nativo

---

## Testing

### Teste Manual
1. Abrir UI
2. Testar cada fonte:
   - Colar código: copiar um .kt simples
   - ZIP: criar ZIP com .kt e testar
   - Pasta: criar pasta com .kt e testar
3. Clicar DIAGNOSTICAR (deve habilitar ESTRUTURAR)
4. Clicar ESTRUTURAR (deve criar 11 arquivos em `%Desktop%\ProjetoAndroid`)
5. Verificar log detalhado
6. (Opcional) Clicar COMPILAR com token GitHub real

### Teste do Log
```powershell
# No PS1, após fazer uma ação, verificar:
Write-Log "[OK] Package: com.example.app"
Write-Log "FALTANDO: .github/workflows/android.yml" "ERRO"
```

### Teste de Token
```powershell
# Verificar que token.dat existe e é Base64
[System.Convert]::FromBase64String((Get-Content token.dat)).Length
```

---

## Debugging

### Ativar Debug Logging
Adicionar no início do script:
```powershell
$DebugPreference = "Continue"
```

### Breakpoint no ISE
1. Clicar na linha desejada
2. Pressionar Ctrl+B ou clicar na margem
3. F5 para executar
4. Quando parar, usar F10 (step) ou F5 (continue)

### Log de Erros
Todos os Try-Catch têm:
```powershell
} catch {
    Write-Log "Erro: $($_.Exception.Message)" "ERRO"
    Write-Log $_.ScriptStackTrace "ERRO"
}
```

---

## Modificações Comuns

### Adicionar Novo Arquivo à Estrutura Espelho
1. Editar a tabela `$ESTRUTURA_ESPELHO` (linhas ~60-120)
2. Adicionar nova entrada:
```powershell
"meuArquivo" = @{
    Caminho      = "caminho/relativo/meuArquivo.txt"
    Obrigatorio  = $true
    ValidarContem = @("token1", "token2")
    Descricao    = "Descrição do arquivo"
}
```
3. Adicionar geração em `Invoke-Estruturacao` (linhas ~600-750)
4. Testar Diagnostico e Estruturacao

### Adicionar Novo Botão
1. Adicionar no XAML (linhas ~1200-1400)
```xml
<Button x:Name="btnMeuBotao" Content="Meu Botão" />
```
2. Obter referência:
```powershell
$btnMeuBotao = $window.FindName("btnMeuBotao")
```
3. Adicionar evento:
```powershell
$btnMeuBotao.Add_Click({
    # Lógica aqui
})
```

### Mudar Cores
- Sucesso: `#28A745` (verde)
- Aviso: `#FF8C00` (laranja)
- Erro: `#DC3545` (vermelho)
- Info: `#0078D7` (azul)

Editar em `Set-StatusUI`:
```powershell
Set-StatusUI "Mensagem" "#CODIGO_COR"
```

---

## Publicação

### Versioning
- v8.0 (atual)
- v7.0, v6.2, etc (histórico)

### Commit
```bash
git add scripts/apk-compiler-ui.ps1
git commit -m "feat: adicionar nova funcionalidade

Descrição detalhada aqui"
git push origin main
```

### Release
```bash
git tag v8.1
git push origin v8.1
```

---

## Troubleshooting

### "Expression is not recognized" ao abrir .bat
- Verificar que `scripts/apk-compiler-ui.ps1` tem BOM UTF-8 + CRLF
- Verificar que o arquivo não está corrompido (cat -A no git bash)

### "Access Denied" ao salvar token
- Verificar que `token.dat` não está read-only
- Verificar permissões da pasta `scripts/`

### "System.Windows assembly not found"
- Verificar que PowerShell é 5.1+ (Get-Host)
- Verificar que WPF está instalado (Get-Module -ListAvailable | grep -i xaml)

### UI não abre
```powershell
# Testar XAML:
[System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new(([xml]$xaml)))
```

---

## Contato

Para dúvidas ou sugestões, abrir issue no GitHub.
