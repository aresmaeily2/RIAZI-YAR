package com.mathmvp.riazi_yar

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.lifecycle.ViewModelProvider
import com.mathmvp.riazi_yar.ui.navigation.AppNavigation
import com.mathmvp.riazi_yar.ui.theme.RiaziYarTheme
import com.mathmvp.riazi_yar.viewmodel.RiaziViewModel
import com.mathmvp.riazi_yar.viewmodel.RiaziViewModelFactory

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val container = (application as RiaziYarApplication).container
        lifecycle.addObserver(container.audioEngine)

        val factory = RiaziViewModelFactory(
            contentRepo = container.contentRepository,
            adaptiveEngine = container.adaptiveEngine,
            dao = container.database.riaziDao(),
            prefsRepo = container.preferencesRepository
        )
        val viewModel = ViewModelProvider(this, factory)[RiaziViewModel::class.java]

        setContent {
            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
                RiaziYarTheme {
                    AppNavigation(viewModel = viewModel, audioEngine = container.audioEngine)
                }
            }
        }
    }
}
