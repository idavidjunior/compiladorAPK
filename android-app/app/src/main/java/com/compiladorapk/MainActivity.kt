package com.compiladorapk

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.material3.MaterialTheme
import com.compiladorapk.ui.BuildDashboardScreen
import com.compiladorapk.ui.BuildDashboardViewModel

class MainActivity : ComponentActivity() {
    private val viewModel: BuildDashboardViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                BuildDashboardScreen(viewModel = viewModel)
            }
        }
    }
}
