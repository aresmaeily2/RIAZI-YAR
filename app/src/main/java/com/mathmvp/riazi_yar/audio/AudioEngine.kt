package com.mathmvp.riazi_yar.audio

import android.content.Context
import android.speech.tts.TextToSpeech
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Locale

enum class TtsEngineStatus {
    INITIALIZING,
    READY_FA,
    FALLBACK_TEXT_ONLY,
    ERROR_UNAVAILABLE
}

class AudioEngine(context: Context) : TextToSpeech.OnInitListener, DefaultLifecycleObserver {
    private var tts: TextToSpeech? = runCatching { TextToSpeech(context.applicationContext, this) }.getOrNull()

    private val _status = MutableStateFlow(TtsEngineStatus.INITIALIZING)
    val status: StateFlow<TtsEngineStatus> = _status.asStateFlow()

    var isPersianAvailable: Boolean = false
        private set
    var ttsEnabled: Boolean = true
    var speechRate: Float = 0.9f
        set(value) {
            field = value.coerceIn(0.5f, 1.5f)
            tts?.setSpeechRate(field)
        }

    override fun onInit(initStatus: Int) {
        if (initStatus == TextToSpeech.SUCCESS && tts != null) {
            val res = tts?.setLanguage(Locale("fa", "IR"))
            isPersianAvailable = res != TextToSpeech.LANG_MISSING_DATA && res != TextToSpeech.LANG_NOT_SUPPORTED
            tts?.setSpeechRate(speechRate)
            _status.value = if (isPersianAvailable) TtsEngineStatus.READY_FA else TtsEngineStatus.FALLBACK_TEXT_ONLY
        } else {
            isPersianAvailable = false
            _status.value = TtsEngineStatus.ERROR_UNAVAILABLE
        }
    }

    fun speak(text: String): Boolean {
        if (!ttsEnabled || text.isBlank()) return false
        return if (isPersianAvailable && tts != null) {
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "riazi_yar_tts")
            true
        } else {
            false
        }
    }

    fun stop() {
        runCatching { tts?.stop() }
    }

    override fun onPause(owner: LifecycleOwner) { stop() }
    override fun onDestroy(owner: LifecycleOwner) { release() }

    fun release() {
        runCatching {
            tts?.stop()
            tts?.shutdown()
        }
        tts = null
    }
}
