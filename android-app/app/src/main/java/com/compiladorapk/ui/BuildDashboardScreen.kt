package com.compiladorapk.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun BuildDashboardScreen(viewModel: BuildDashboardViewModel) {
    val uiState by viewModel.uiState.collectAsState()
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) {
            viewModel.onZipSelected(uri)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = "Remote Android Build Orchestrator",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )

        Text(
            text = "Importe o projeto, acione o pipeline e acompanhe o build remoto em tempo real.",
            style = MaterialTheme.typography.bodyMedium
        )

        Surface(
            tonalElevation = 2.dp,
            color = MaterialTheme.colorScheme.primaryContainer,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(
                text = uiState.statusText,
                modifier = Modifier.padding(16.dp),
                style = MaterialTheme.typography.bodyLarge
            )
        }

        Text(text = "Estado atual: ${uiState.currentState.name}")

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(onClick = { viewModel.setImportMode(ImportMode.GITHUB) }) {
                Text("GitHub")
            }
            OutlinedButton(onClick = { viewModel.setImportMode(ImportMode.ZIP) }) {
                Text("ZIP")
            }
            OutlinedButton(onClick = { viewModel.setImportMode(ImportMode.CODE) }) {
                Text("Código")
            }
        }

        when (uiState.selectedMode) {
            ImportMode.GITHUB -> {
                OutlinedTextField(
                    value = uiState.githubUrl,
                    onValueChange = viewModel::updateGithubUrl,
                    label = { Text("URL do repositório GitHub") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = uiState.githubToken,
                    onValueChange = viewModel::updateGithubToken,
                    label = { Text("Token GitHub") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = uiState.owner,
                    onValueChange = viewModel::updateOwner,
                    label = { Text("Owner") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = uiState.repo,
                    onValueChange = viewModel::updateRepo,
                    label = { Text("Repo") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = uiState.branch,
                    onValueChange = viewModel::updateBranch,
                    label = { Text("Branch") },
                    modifier = Modifier.fillMaxWidth()
                )
            }

            ImportMode.ZIP -> {
                Button(onClick = { picker.launch(arrayOf("application/zip")) }) {
                    Text("Selecionar ZIP")
                }
                Text(text = uiState.zipLabel)
            }

            ImportMode.CODE -> {
                OutlinedTextField(
                    value = uiState.sourceCode,
                    onValueChange = viewModel::updateSourceCode,
                    label = { Text("Cole o código do projeto") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(220.dp),
                    maxLines = 12
                )
            }
        }

        OutlinedTextField(
            value = uiState.packageName,
            onValueChange = viewModel::updatePackageName,
            label = { Text("Package Name") },
            modifier = Modifier.fillMaxWidth()
        )

        OutlinedTextField(
            value = uiState.appName,
            onValueChange = viewModel::updateAppName,
            label = { Text("Nome do app") },
            modifier = Modifier.fillMaxWidth()
        )

        Button(
            onClick = viewModel::startBuild,
            enabled = !uiState.isBuildRunning,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(if (uiState.isBuildRunning) "Processando..." else "Compilar")
        }

        if (uiState.downloadedApkPath != null) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
            ) {
                Text(
                    text = "APK baixado: ${uiState.downloadedApkPath}",
                    modifier = Modifier.padding(16.dp)
                )
                Text(
                    text = uiState.installMessage,
                    modifier = Modifier.padding(start = 16.dp, end = 16.dp, bottom = 16.dp)
                )
            }
        }

        if (uiState.buildUrl.isNotBlank()) {
            Text(text = "Workflow: ${uiState.buildUrl}")
        }

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = "Logs em tempo real",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                uiState.logs.forEach { log ->
                    Text(text = log, style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}
