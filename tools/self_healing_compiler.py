#!/usr/bin/env python3
import os
import re
import sys
import subprocess
import json
import urllib.request
from pathlib import Path

# Common imports mapping for Jetpack Compose, Kotlin, and AndroidX
IMPORT_MAP = {
    "clickable": "import androidx.compose.foundation.clickable",
    "fillMaxSize": "import androidx.compose.foundation.layout.fillMaxSize",
    "fillMaxWidth": "import androidx.compose.foundation.layout.fillMaxWidth",
    "fillMaxHeight": "import androidx.compose.foundation.layout.fillMaxHeight",
    "padding": "import androidx.compose.foundation.layout.padding",
    "Spacer": "import androidx.compose.foundation.layout.Spacer",
    "Column": "import androidx.compose.foundation.layout.Column",
    "Row": "import androidx.compose.foundation.layout.Row",
    "Box": "import androidx.compose.foundation.layout.Box",
    "Arrangement": "import androidx.compose.foundation.layout.Arrangement",
    "Alignment": "import androidx.compose.ui.Alignment",
    "Modifier": "import androidx.compose.ui.Modifier",
    "clip": "import androidx.compose.ui.draw.clip",
    "shadow": "import androidx.compose.ui.draw.shadow",
    "graphicsLayer": "import androidx.compose.ui.graphics.graphicsLayer",
    "Brush": "import androidx.compose.ui.graphics.Brush",
    "Color": "import androidx.compose.ui.graphics.Color",
    "ContentScale": "import androidx.compose.ui.layout.ContentScale",
    "dp": "import androidx.compose.ui.unit.dp",
    "sp": "import androidx.compose.ui.unit.sp",
    "Dp": "import androidx.compose.ui.unit.Dp",
    "FontWeight": "import androidx.compose.ui.text.font.FontWeight",
    "TextAlign": "import androidx.compose.ui.text.style.TextAlign",
    "TextOverflow": "import androidx.compose.ui.text.style.TextOverflow",
    "remember": "import androidx.compose.runtime.remember",
    "mutableStateOf": "import androidx.compose.runtime.mutableStateOf",
    "getValue": "import androidx.compose.runtime.getValue",
    "setValue": "import androidx.compose.runtime.setValue",
    "LaunchedEffect": "import androidx.compose.runtime.LaunchedEffect",
    "rememberCoroutineScope": "import androidx.compose.runtime.rememberCoroutineScope",
    "viewModel": "import androidx.lifecycle.viewmodel.compose.viewModel",
    "LocalContext": "import androidx.compose.ui.platform.LocalContext",
    "Icons": "import androidx.compose.material.icons.Icons",
    "Icon": "import androidx.compose.material3.Icon",
    "Text": "import androidx.compose.material3.Text",
    "Button": "import androidx.compose.material3.Button",
    "IconButton": "import androidx.compose.material3.IconButton",
    "Card": "import androidx.compose.material3.Card",
    "Scaffold": "import androidx.compose.material3.Scaffold",
    "CircularProgressIndicator": "import androidx.compose.material3.CircularProgressIndicator",
    "LinearProgressIndicator": "import androidx.compose.material3.LinearProgressIndicator",
    "Slider": "import androidx.compose.material3.Slider",
    "Switch": "import androidx.compose.material3.Switch",
    "Tab": "import androidx.compose.material3.Tab",
    "TabRow": "import androidx.compose.material3.TabRow",
    "tabIndicatorOffset": "import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset",
    "ModalBottomSheet": "import androidx.compose.material3.ModalBottomSheet",
    "rememberModalBottomSheetState": "import androidx.compose.material3.rememberModalBottomSheetState",
    "AlertDialog": "import androidx.compose.material3.AlertDialog",
    "DropdownMenu": "import androidx.compose.material3.DropdownMenu",
    "DropdownMenuItem": "import androidx.compose.material3.DropdownMenuItem",
    "AsyncImage": "import coil3.compose.AsyncImage",
    "Serializable": "import java.io.Serializable",
    "LocalBroadcastManager": "import androidx.localbroadcastmanager.content.LocalBroadcastManager",
    "IntentFilter": "import android.content.IntentFilter",
    "BroadcastReceiver": "import android.content.BroadcastReceiver",
    "Intent": "import android.content.Intent",
    "Context": "import android.content.Context",
    "Bundle": "import android.os.Bundle",
    "Log": "import android.util.Log",
    "Uri": "import android.net.Uri",
    "MediaPlayer": "import android.media.MediaPlayer",
    "AudioAttributes": "import android.media.AudioAttributes",
    "AudioFocusRequest": "import android.media.AudioFocusRequest",
    "AudioManager": "import android.media.AudioManager",
    "Equalizer": "import android.media.audiofx.Equalizer",
    "Notification": "import android.app.Notification",
    "NotificationChannel": "import android.app.NotificationChannel",
    "NotificationManager": "import android.app.NotificationManager",
    "PendingIntent": "import android.app.PendingIntent",
    "Service": "import android.app.Service",
    "IBinder": "import android.os.IBinder",
    "Handler": "import android.os.Handler",
    "Looper": "import android.os.Looper",
    "MediaSessionCompat": "import android.support.v4.media.session.MediaSessionCompat",
    "PlaybackStateCompat": "import android.support.v4.media.session.PlaybackStateCompat",
    "MediaMetadataCompat": "import android.support.v4.media.MediaMetadataCompat",
    "NotificationCompat": "import androidx.core.app.NotificationCompat",
    "ContextCompat": "import androidx.core.content.ContextCompat",
    "preferencesDataStore": "import androidx.datastore.preferences.preferencesDataStore"
}

# Dependencies mapping to inject into build.gradle.kts
DEPENDENCY_MAP = {
    "LocalBroadcastManager": "androidx.localbroadcastmanager:localbroadcastmanager:1.1.0",
    "MediaSessionCompat": "androidx.media:media:1.7.0",
    "PlaybackStateCompat": "androidx.media:media:1.7.0",
    "AsyncImage": "io.coil-kt.coil3:coil-compose:3.3.0",
    "coil3": "io.coil-kt.coil3:coil-network-okhttp:3.3.0",
    "preferencesDataStore": "androidx.datastore:datastore-preferences:1.2.0",
    "Serializable": "org.jetbrains.kotlinx:kotlinx-serialization-json:1.9.0",
    "Icons.Rounded": "androidx.compose.material:material-icons-extended",
    "Icons.Filled": "androidx.compose.material:material-icons-extended",
    "Icons.Outlined": "androidx.compose.material:material-icons-extended",
    "Icons.Default": "androidx.compose.material:material-icons-extended"
}

def log(msg, level="INFO"):
    colors = {"INFO": "\033[94m", "SUCCESS": "\033[92m", "WARN": "\033[93m", "ERROR": "\033[91m"}
    reset = "\033[0m"
    print(f"{colors.get(level, '')}[AI-AGENT][{level}] {msg}{reset}")

def run_build():
    log("Iniciando build do Gradle...")
    result = subprocess.run(["./gradlew", "assembleDebug", "--stacktrace"], capture_output=True, text=True)
    return result.returncode == 0, result.stdout + "\n" + result.stderr

def fix_missing_import(file_path, symbol):
    if symbol not in IMPORT_MAP:
        log(f"Não há regra de importação conhecida para o símbolo: '{symbol}'", "WARN")
        return False

    import_statement = IMPORT_MAP[symbol]
    path = Path(file_path)
    if not path.exists():
        return False

    content = path.read_text(encoding="utf-8")
    if import_statement in content:
        return False

    lines = content.splitlines()
    inserted = False

    # Insert below package declaration or at the top
    for i, line in enumerate(lines):
        if line.strip().startswith("package "):
            lines.insert(i + 1, import_statement)
            inserted = True
            break

    if not inserted:
        lines.insert(0, import_statement)

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    log(f"Injetado: '{import_statement}' em {path.name}", "SUCCESS")
    return True

def fix_missing_dependency(symbol):
    dep = None
    for key, value in DEPENDENCY_MAP.items():
        if key in symbol:
            dep = value
            break

    if not dep:
        return False

    build_gradle = Path("app/build.gradle.kts")
    if not build_gradle.exists():
        return False

    content = build_gradle.read_text(encoding="utf-8")
    dep_name = dep.split(":")[1] if ":" in dep else dep

    if dep_name in content:
        return False

    # Find dependencies block and insert
    if "dependencies {" in content:
        content = content.replace("dependencies {", f"dependencies {{\n    implementation(\"{dep}\")")
        build_gradle.write_text(content, encoding="utf-8")
        log(f"Adicionada dependência: '{dep}' no build.gradle.kts", "SUCCESS")
        return True

    return False

def fix_manifest_exported():
    manifest_path = Path("app/src/main/AndroidManifest.xml")
    if not manifest_path.exists():
        return False

    content = manifest_path.read_text(encoding="utf-8")
    modified = False

    # Find tags without android:exported that contain intent-filter
    # Basic regex approach to find activities/services/receivers with intent-filters
    pattern = re.compile(r'<(activity|service|receiver)([^>]*?)>(.*?)<\/intent-filter>', re.DOTALL)
    
    def replace_tag(match):
        nonlocal modified
        tag_type = match.group(1)
        attributes = match.group(2)
        inner_content = match.group(3)

        if "android:exported" in attributes:
            return match.group(0)

        modified = True
        # If it's a main launcher activity, export it, otherwise don't
        if "android.intent.action.MAIN" in inner_content:
            exported_attr = ' android:exported="true"'
        else:
            exported_attr = ' android:exported="false"'

        return f"<{tag_type}{attributes}{exported_attr}>{inner_content}</intent-filter>"

    new_content = pattern.sub(replace_tag, content)
    if modified:
        manifest_path.write_text(new_content, encoding="utf-8")
        log("Manifest corrigido: Injetado android:exported nas tags necessárias.", "SUCCESS")
        return True

    return False

def call_llm_fallback(error_log):
    openai_key = os.getenv("OPENAI_API_KEY")
    gemini_key = os.getenv("GEMINI_API_KEY")
    anthropic_key = os.getenv("ANTHROPIC_API_KEY")
    
    api_key = openai_key or gemini_key or anthropic_key
    if not api_key:
        log("Nenhuma chave de API de IA encontrada (OPENAI_API_KEY / GEMINI_API_KEY / ANTHROPIC_API_KEY). Pulando fallback de IA.", "WARN")
        return False

    log("Chave de API de IA detectada! Iniciando agente de auto-cura cognitivo...", "INFO")
    
    # Coletar arquivos Kotlin relevantes para fornecer contexto à IA
    kt_files = list(Path("app/src").rglob("*.kt"))
    files_context = []
    for f in kt_files[:15]: # Limitar tamanho do contexto
        try:
            content = f.read_text(encoding="utf-8")
            files_context.append(f"--- ARQUIVO: {f} ---\n{content}")
        except Exception:
            pass
    files_context_str = "\n\n".join(files_context)

    prompt = f"""Você é um agente especialista em auto-cura de compilação Kotlin/Android.
Estamos compilando um aplicativo Android via Gradle, mas o build falhou com o seguinte log de erro:
{error_log[-4000:]}

Aqui estão os arquivos de código do projeto para contexto:
{files_context_str}

Analise o log de erro, identifique os arquivos que precisam ser modificados e forneça as substituições exatas.
A resposta deve ser APENAS um objeto JSON bruto (não coloque blocos de código markdown como ```json) no seguinte formato:
{{
  "files_to_modify": [
    {{
      "path": "app/src/main/java/com/agon/app/MainActivity.kt",
      "explanation": "Explicação breve da correção",
      "action": "replace",
      "old_string": "código antigo a ser substituído",
      "new_string": "novo código corrigido"
    }}
  ]
}}
"""

    import urllib.request
    import json

    text = None
    try:
        if gemini_key:
            log("Utilizando modelo Google Gemini para Auto-Cura...", "INFO")
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={gemini_key}"
            headers = {"Content-Type": "application/json"}
            payload = {
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {"responseMimeType": "application/json"}
            }
            req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers=headers, method="POST")
            with urllib.request.urlopen(req) as response:
                res_data = json.loads(response.read().decode("utf-8"))
                text = res_data["candidates"][0]["content"]["parts"][0]["text"]
        elif openai_key:
            log("Utilizando modelo OpenAI GPT para Auto-Cura...", "INFO")
            url = "https://api.openai.com/v1/chat/completions"
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {openai_key}"
            }
            payload = {
                "model": "gpt-4o-mini",
                "messages": [{"role": "user", "content": prompt}],
                "response_format": {"type": "json_object"}
            }
            req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers=headers, method="POST")
            with urllib.request.urlopen(req) as response:
                res_data = json.loads(response.read().decode("utf-8"))
                text = res_data["choices"][0]["message"]["content"]
        elif anthropic_key:
            log("Utilizando modelo Anthropic Claude para Auto-Cura...", "INFO")
            url = "https://api.anthropic.com/v1/messages"
            headers = {
                "Content-Type": "application/json",
                "X-API-Key": anthropic_key,
                "anthropic-version": "2023-06-01"
            }
            payload = {
                "model": "claude-3-5-haiku-20241022",
                "max_tokens": 4000,
                "messages": [{"role": "user", "content": prompt}]
            }
            req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers=headers, method="POST")
            with urllib.request.urlopen(req) as response:
                res_data = json.loads(response.read().decode("utf-8"))
                text = res_data["content"][0]["text"]
    except Exception as e:
        log(f"Erro ao chamar a API do modelo de linguagem: {e}", "ERROR")
        return False

    if not text:
        return False

    try:
        raw_response = text.strip()
        if raw_response.startswith("```"):
            raw_response = re.sub(r'^```(?:json)?\n', '', raw_response)
            raw_response = re.sub(r'\n```$', '', raw_response)
        
        result_json = json.loads(raw_response)
        modified = False
        for mod in result_json.get("files_to_modify", []):
            path = Path(mod["path"])
            if not path.exists():
                log(f"Arquivo proposto para modificação não existe: {path}", "WARN")
                continue
            
            content = path.read_text(encoding="utf-8")
            old_str = mod["old_string"]
            new_str = mod["new_string"]
            
            if old_str in content:
                content = content.replace(old_str, new_str)
                path.write_text(content, encoding="utf-8")
                log(f"Auto-Cura Cognitiva IA aplicada em {path.name}: {mod['explanation']}", "SUCCESS")
                modified = True
            else:
                log(f"Substituição proposta pela IA falhou em {path.name} (trecho 'old_string' não encontrado)", "WARN")
        return modified
    except Exception as e:
        log(f"Falha ao processar resposta do agente cognitivo de IA: {e}", "ERROR")
        return False

def parse_and_heal(log_content):
    healed = False

    # 1. Check for Unresolved reference
    # Pattern: e: file://.../FileName.kt: (line, col): Unresolved reference: symbol
    unresolved_matches = re.findall(r'Unresolved reference:\s*(\w+)', log_content)
    file_matches = re.findall(r'e:\s*file://([^\s:]+)', log_content)

    if unresolved_matches and file_matches:
        for file_path, symbol in zip(file_matches, unresolved_matches):
            if fix_missing_import(file_path, symbol):
                healed = True
            if fix_missing_dependency(symbol):
                healed = True

    # 2. Check for missing dependency in imports (e.g., package does not exist)
    package_matches = re.findall(r'error: package ([\w\.]+) does not exist', log_content)
    if package_matches:
        for pkg in package_matches:
            if fix_missing_dependency(pkg):
                healed = True

    # 3. Check for Manifest exported error
    if "android:exported" in log_content or "exported" in log_content.lower():
        if fix_manifest_exported():
            healed = True

    return healed

def generate_code_from_prompt():
    prompt_path = Path("prompt.txt")
    if not prompt_path.exists():
        return False
    
    log("Prompt de geração detectado! Solicitando ao agente cognitivo a geração do código do aplicativo...", "INFO")
    prompt_content = prompt_path.read_text(encoding="utf-8").strip()
    if not prompt_content:
        log("O arquivo prompt.txt está vazio. Pulando geração.", "WARN")
        prompt_path.unlink()
        return False

    openai_key = os.getenv("OPENAI_API_KEY")
    gemini_key = os.getenv("GEMINI_API_KEY")
    anthropic_key = os.getenv("ANTHROPIC_API_KEY")

    api_key = openai_key or gemini_key or anthropic_key
    if not api_key:
        log("Nenhuma chave de API de IA (GEMINI_API_KEY, OPENAI_API_KEY, ANTHROPIC_API_KEY) encontrada. Pulando geração.", "ERROR")
        return False

    system_prompt = (
        "Você é um engenheiro de software Android sênior especialista em Kotlin, Jetpack Compose e Material 3.\n"
        "O usuário deseja gerar um aplicativo Android completo com base nas seguintes instruções:\n"
        f"\"\"\"\n{prompt_content}\n\"\"\"\n\n"
        "Gere todo o código-fonte necessário para criar este aplicativo, incluindo MainActivity.kt, telas composables (ex: HomeScreen.kt, etc.), e modelos de dados necessários em 'app/src/main/java/com/agon/app/'.\n"
        "Certifique-se de que o pacote correto seja usado: 'package com.agon.app'.\n"
        "Importante: NÃO use placeholders ou // ... rest. Escreva o código completo e funcional.\n\n"
        "A resposta deve ser um objeto JSON bruto (sem markdown, sem blocos de código ```json) no seguinte formato exato:\n"
        "{\n"
        "  \"files\": [\n"
        "    {\n"
        "      \"path\": \"app/src/main/java/com/agon/app/MainActivity.kt\",\n"
        "      \"content\": \"...código completo...\"\n"
        "    },\n"
        "    {\n"
        "      \"path\": \"app/src/main/java/com/agon/app/ui/screens/HomeScreen.kt\",\n"
        "      \"content\": \"...código completo...\"\n"
        "    }\n"
        "  ]\n"
        "}"
    )

    text = None
    try:
        if gemini_key:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={gemini_key}"
            headers = {"Content-Type": "application/json"}
            payload = {
                "contents": [{"parts": [{"text": system_prompt}]}],
                "generationConfig": {"responseMimeType": "application/json"}
            }
            req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers=headers, method="POST")
            with urllib.request.urlopen(req) as response:
                res_data = json.loads(response.read().decode("utf-8"))
                text = res_data["candidates"][0]["content"]["parts"][0]["text"]
        elif openai_key:
            url = "https://api.openai.com/v1/chat/completions"
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {openai_key}"
            }
            payload = {
                "model": "gpt-4o",
                "response_format": {"type": "json_object"},
                "messages": [{"role": "user", "content": system_prompt}]
            }
            req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers=headers, method="POST")
            with urllib.request.urlopen(req) as response:
                res_data = json.loads(response.read().decode("utf-8"))
                text = res_data["choices"][0]["message"]["content"]
        elif anthropic_key:
            url = "https://api.anthropic.com/v1/messages"
            headers = {
                "Content-Type": "application/json",
                "X-API-Key": anthropic_key,
                "anthropic-version": "2023-06-01"
            }
            payload = {
                "model": "claude-3-5-sonnet-20241022",
                "max_tokens": 8000,
                "messages": [{"role": "user", "content": system_prompt}]
            }
            req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers=headers, method="POST")
            with urllib.request.urlopen(req) as response:
                res_data = json.loads(response.read().decode("utf-8"))
                text = res_data["content"][0]["text"]
    except Exception as e:
        log(f"Erro ao chamar a API do modelo de linguagem para geração: {e}", "ERROR")
        return False

    if not text:
        log("O modelo de linguagem retornou uma resposta vazia para a geração.", "ERROR")
        return False

    try:
        raw_response = text.strip()
        if raw_response.startswith("```"):
            raw_response = re.sub(r'^```(?:json)?\n', '', raw_response)
            raw_response = re.sub(r'\n```$', '', raw_response)
        
        result_json = json.loads(raw_response)
        files = result_json.get("files", [])
        if not files:
            log("Nenhum arquivo encontrado no JSON retornado pela IA.", "WARN")
            return False

        for f in files:
            path = Path(f["path"])
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(f["content"], encoding="utf-8")
            log(f"Arquivo gerado com sucesso pela IA: {path}", "SUCCESS")
        
        prompt_path.unlink()
        log("Geração de código concluída com sucesso!", "SUCCESS")
        return True
    except Exception as e:
        log(f"Falha ao processar e salvar arquivos gerados pela IA: {e}", "ERROR")
        return False

def main():
    log("=== Iniciando Orquestrador de Compilação com Auto-Cura IA ===")
    
    # Executar geração de código baseada em prompt antes de tentar compilar
    generate_code_from_prompt()
    
    max_attempts = 5
    attempt = 1
    
    while attempt <= max_attempts:
        log(f"Tentativa de compilação {attempt}/{max_attempts}...")
        success, build_log = run_build()
        
        if success:
            log("=== COMPILAÇÃO CONCLUÍDA COM SUCESSO! ===", "SUCCESS")
            sys.exit(0)
            
        log(f"A compilação falhou na tentativa {attempt}. Iniciando análise de erros...", "WARN")
        
        # Try local rule-based self-healing
        healed = parse_and_heal(build_log)
        
        # If rule-based didn't work, try LLM fallback
        if not healed:
            healed = call_llm_fallback(build_log)
            
        if not healed:
            log("Não foi possível curar o erro automaticamente. Encerrando compilação com falha.", "ERROR")
            print(build_log[-2000:]) # Print last 2000 chars of build log for debugging
            sys.exit(1)
            
        log("Correções aplicadas com sucesso! Reiniciando ciclo de build...", "SUCCESS")
        attempt += 1

    log("Excedeu o número máximo de tentativas de auto-cura sem sucesso.", "ERROR")
    sys.exit(1)

if __name__ == "__main__":
    main()
