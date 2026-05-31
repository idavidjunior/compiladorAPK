package com.compiladorapk.ui

import com.compiladorapk.pipeline.PipelineState

enum class ImportMode {
    GITHUB,
    ZIP,
    CODE
}

data class BuildDashboardUiState(
    val currentState: PipelineState = PipelineState.IDLE,
    val statusText: String = "Pronto para iniciar o pipeline.",
    val logs: List<String> = emptyList(),
    val buildUrl: String = "",
    val downloadedApkPath: String? = null,
    val installMessage: String = "",
    val selectedMode: ImportMode = ImportMode.GITHUB,
    val githubUrl: String = "",
    val githubToken: String = "",
    val owner: String = "",
    val repo: String = "",
    val branch: String = "main",
    val packageName: String = "com.compiladorapk.remote",
    val appName: String = "RemoteAndroidBuild",
    val sourceCode: String = "",
    val zipLabel: String = "Nenhum ZIP selecionado",
    val zipPath: String? = null,
    val isBuildRunning: Boolean = false
)
