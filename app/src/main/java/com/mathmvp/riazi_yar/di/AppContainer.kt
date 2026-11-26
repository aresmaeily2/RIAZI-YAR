package com.mathmvp.riazi_yar.di

import android.content.Context
import androidx.room.Room
import com.mathmvp.riazi_yar.adaptive.AdaptiveLearningEngine
import com.mathmvp.riazi_yar.audio.AudioEngine
import com.mathmvp.riazi_yar.content.ContentRepository
import com.mathmvp.riazi_yar.data.MIGRATION_1_2
import com.mathmvp.riazi_yar.data.MIGRATION_2_3
import com.mathmvp.riazi_yar.data.RiaziDatabase
import com.mathmvp.riazi_yar.settings.UserPreferencesRepository

class AppContainer(context: Context) {
    private val appContext = context.applicationContext

    val database: RiaziDatabase = Room.databaseBuilder(
        appContext,
        RiaziDatabase::class.java,
        "riazi_yar_v2.db"
    ).addMigrations(MIGRATION_1_2, MIGRATION_2_3).build()

    val contentRepository = ContentRepository(appContext)
    val preferencesRepository = UserPreferencesRepository(appContext)
    val adaptiveEngine = AdaptiveLearningEngine(database.riaziDao())
    val audioEngine = AudioEngine(appContext)
}
