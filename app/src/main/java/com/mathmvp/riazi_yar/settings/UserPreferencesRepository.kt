package com.mathmvp.riazi_yar.settings

import android.content.Context
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore(name = "riazi_yar_prefs_v2")

data class AppSettings(
    val ttsEnabled: Boolean = true,
    val speechRate: Float = 0.9f,
    val musicEnabled: Boolean = false,
    val sfxEnabled: Boolean = true,
    val reduceMotion: Boolean = false,
    val parentRemindersEnabled: Boolean = false
)

class UserPreferencesRepository(private val context: Context) {
    private val kTts = booleanPreferencesKey("tts_enabled")
    private val kRate = floatPreferencesKey("speech_rate")
    private val kMusic = booleanPreferencesKey("music_enabled")
    private val kSfx = booleanPreferencesKey("sfx_enabled")
    private val kReduceMotion = booleanPreferencesKey("reduce_motion")
    private val kReminders = booleanPreferencesKey("parent_reminders_enabled")

    val settingsFlow: Flow<AppSettings> = context.dataStore.data.map { p ->
        AppSettings(
            ttsEnabled = p[kTts] ?: true,
            speechRate = p[kRate] ?: 0.9f,
            musicEnabled = p[kMusic] ?: false,
            sfxEnabled = p[kSfx] ?: true,
            reduceMotion = p[kReduceMotion] ?: false,
            parentRemindersEnabled = p[kReminders] ?: false
        )
    }

    suspend fun update(settings: AppSettings) {
        context.dataStore.edit { p ->
            p[kTts] = settings.ttsEnabled
            p[kRate] = settings.speechRate
            p[kMusic] = settings.musicEnabled
            p[kSfx] = settings.sfxEnabled
            p[kReduceMotion] = settings.reduceMotion
            p[kReminders] = settings.parentRemindersEnabled
        }
    }
}
