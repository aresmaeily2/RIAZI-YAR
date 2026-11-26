package com.mathmvp.riazi_yar

import android.app.Application
import com.mathmvp.riazi_yar.di.AppContainer

class RiaziYarApplication : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
    }
}
