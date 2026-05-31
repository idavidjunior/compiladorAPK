package com.compiladorapk

import android.app.Application

class CompiladorApkApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Inicialização global da aplicação (logs, DI, analytics podem ser configurados aqui)
    }
}
