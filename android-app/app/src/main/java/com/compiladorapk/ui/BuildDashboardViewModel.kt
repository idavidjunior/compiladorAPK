package com.compiladorapk.ui

import android.app.Application
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.core.content.FileProvider
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.compiladorapk.artifact.InstallResult
import com.compiladorapk.pipeline.BuildPipelineManager
import com.compiladorapk.pipeline.PipelineEvent
import com.compiladorapk.pipeline.PipelineState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.io.File
import java.io.InputStream

class BuildDashboardViewModel(application: Application) : AndroidViewModel(application) {
    private val pipelineManager = BuildPipelineManager()
    private val appContext: Context = application.applicationContext

    private val _uiState = MutableStateFlow(BuildDashboardUiState())
    val uiState = _uiState.asStateFlow()

    init {
        pipelineManager.configureAndroidInstallHandler { apkFile ->
            installApk(apkFile)
        }

        viewModelScope.launch {
            pipelineManager.state.collect { state ->
                _uiState.update {
                    it.copy(
                        currentState = state,
                        statusText = statusFromState(state),
                        isBuildRunning = state == PipelineState.IMPORTING ||
                            state == PipelineState.VALIDATING ||
                            state == PipelineState.GENERATING_WORKFLOW ||
                            state == PipelineState.PUSHING ||
                            state == PipelineState.BUILDING ||
                            state == PipelineState.DOWNLOADING ||
                            state == PipelineState.INSTALLING
                    )
                }
            }
        }

        viewModelScope.launch {
            pipelineManager.events.collect { event ->
                when (event) {
                    is PipelineEvent.OnProjectImported -> appendLog("Projeto importado: ${event.path}")
                    is PipelineEvent.OnValidationSuccess -> appendLog("Validação concluída: ${event.messages.joinToString()}")
                    is PipelineEvent.OnValidationError -> appendLog("Erro de validação: ${event.errors.joinToString()}")
                    PipelineEvent.OnPushStarted -> appendLog("Iniciando commit/push no GitHub.")
                    PipelineEvent.OnBuildStarted -> appendLog("Aguardando execução do workflow remoto.")
                    is PipelineEvent.OnBuildSuccess -> {
                        appendLog("Build concluído: ${event.htmlUrl}")
                        _uiState.update { it.copy(buildUrl = event.htmlUrl) }
                    }
                    is PipelineEvent.OnBuildFailed -> appendLog("Falha no build remoto: ${event.reason}")
                    is PipelineEvent.OnArtifactDownloaded -> appendLog("APK baixado em: ${event.path}")
                    PipelineEvent.OnInstallStarted -> appendLog("Iniciando instalação do APK.")
                    is PipelineEvent.OnInstallFinished -> appendLog(event.message)
                }
            }
        }
    }

    fun updateGithubUrl(value: String) {
        _uiState.update { it.copy(githubUrl = value) }
    }

    fun updateGithubToken(value: String) {
        _uiState.update { it.copy(githubToken = value) }
    }

    fun updateOwner(value: String) {
        _uiState.update { it.copy(owner = value) }
    }

    fun updateRepo(value: String) {
        _uiState.update { it.copy(repo = value) }
    }

    fun updateBranch(value: String) {
        _uiState.update { it.copy(branch = value) }
    }

    fun updatePackageName(value: String) {
        _uiState.update { it.copy(packageName = value) }
    }

    fun updateAppName(value: String) {
        _uiState.update { it.copy(appName = value) }
    }

    fun updateSourceCode(value: String) {
        _uiState.update { it.copy(sourceCode = value) }
    }

    fun setImportMode(mode: ImportMode) {
        _uiState.update { it.copy(selectedMode = mode) }
    }

    fun onZipSelected(uri: Uri) {
        viewModelScope.launch(Dispatchers.IO) {
            val target = File(appContext.cacheDir, "selected-project.zip")
            target.delete()
            appContext.contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output -> copyStream(input, output) }
            }
            _uiState.update { it.copy(zipLabel = target.name, zipPath = target.absolutePath) }
            appendLog("ZIP selecionado: ${target.absolutePath}")
        }
    }

    fun startBuild() {
        viewModelScope.launch(Dispatchers.IO) {
            val state = _uiState.value

            val projectPath = File(appContext.cacheDir, "remote-build-project")
            if (projectPath.exists()) {
                projectPath.deleteRecursively()
            }
            projectPath.mkdirs()

            val result = when (state.selectedMode) {
                ImportMode.GITHUB -> {
                    if (state.githubUrl.isBlank() || state.owner.isBlank() || state.repo.isBlank() || state.githubToken.isBlank()) {
                        appendLog("Informe URL, owner, repo e token para o modo GitHub.")
                        return@launch
                    }
                    pipelineManager.startPipeline(
                        BuildPipelineManager.PipelineRequest(
                            projectPath = projectPath,
                            repoUrl = state.githubUrl,
                            githubToken = state.githubToken,
                            owner = state.owner,
                            repo = state.repo,
                            branch = state.branch,
                            packageName = state.packageName,
                            appName = state.appName
                        )
                    )
                }

                ImportMode.ZIP -> {
                    if (state.zipPath.isNullOrBlank()) {
                        appendLog("Selecione um arquivo ZIP antes de compilar.")
                        return@launch
                    }
                    pipelineManager.startPipeline(
                        BuildPipelineManager.PipelineRequest(
                            projectPath = projectPath,
                            zipPath = state.zipPath,
                            githubToken = state.githubToken,
                            owner = state.owner,
                            repo = state.repo,
                            branch = state.branch,
                            packageName = state.packageName,
                            appName = state.appName
                        )
                    )
                }

                ImportMode.CODE -> {
                    if (state.sourceCode.isBlank()) {
                        appendLog("Cole o código para o modo Código antes de compilar.")
                        return@launch
                    }
                    pipelineManager.startPipeline(
                        BuildPipelineManager.PipelineRequest(
                            projectPath = projectPath,
                            sourceCode = state.sourceCode,
                            githubToken = state.githubToken,
                            owner = state.owner,
                            repo = state.repo,
                            branch = state.branch,
                            packageName = state.packageName,
                            appName = state.appName
                        )
                    )
                }
            }

            _uiState.update {
                it.copy(
                    statusText = result.message,
                    downloadedApkPath = result.downloadedApkPath,
                    installMessage = result.message
                )
            }

            if (!result.success) {
                appendLog("Pipeline finalizado com falha: ${result.message}")
            } else {
                appendLog("Pipeline finalizado com sucesso: ${result.message}")
            }
        }
    }

    private fun installApk(apkFile: File): InstallResult {
        return try {
            val uri = FileProvider.getUriForFile(
                appContext,
                "${appContext.packageName}.provider",
                apkFile
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            appContext.startActivity(intent)
            InstallResult(true, "Abrindo instalador do Android para concluir a instalação.")
        } catch (error: Throwable) {
            Log.e("BuildDashboard", "Falha ao iniciar instalação", error)
            InstallResult(false, "Não foi possível abrir o instalador do Android: ${error.message ?: "erro desconhecido"}")
        }
    }

    private fun appendLog(message: String) {
        _uiState.update { current ->
            current.copy(logs = (current.logs + message).takeLast(20))
        }
    }

    private fun statusFromState(state: PipelineState): String {
        return when (state) {
            PipelineState.IDLE -> "Pronto para iniciar o pipeline."
            PipelineState.IMPORTING -> "Importando projeto Android."
            PipelineState.VALIDATING -> "Validando estrutura Android."
            PipelineState.GENERATING_WORKFLOW -> "Gerando workflow do GitHub Actions."
            PipelineState.PUSHING -> "Fazendo commit e push remoto."
            PipelineState.BUILDING -> "Monitorando build remoto em tempo real."
            PipelineState.DOWNLOADING -> "Baixando APK gerado pelo CI."
            PipelineState.INSTALLING -> "Abrindo fluxo de instalação do APK."
            PipelineState.SUCCESS -> "Pipeline concluído com sucesso."
            PipelineState.ERROR -> "Pipeline finalizado com erro."
        }
    }

    private fun copyStream(input: InputStream, output: java.io.OutputStream) {
        input.copyTo(output)
    }
}
