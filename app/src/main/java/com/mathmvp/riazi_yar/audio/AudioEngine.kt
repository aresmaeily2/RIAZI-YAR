package com.mathmvp.riazi_yar.audio

import android.content.Context
import android.speech.tts.TextToSpeech
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import java.util.Locale

class AudioEngine(context: Context) : TextToSpeech.OnInitListener, DefaultLifecycleObserver {
    private var tts: TextToSpeech? = TextToSpeech(context.applicationContext, this)
    var isPersianAvailable: Boolean = false
        private set
    var ttsEnabled: Boolean = true
    var speechRate: Float = 0.9f
        set(value) {
            field = value.coerceIn(0.5f, 1.5f)
            tts?.setSpeechRate(field)
        }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val res = tts?.setLanguage(Locale("fa", "IR"))
            isPersianAvailable = res != TextToSpeech.LANG_MISSING_DATA && res != TextToSpeech.LANG_NOT_SUPPORTED
            tts?.setSpeechRate(speechRate)
        }
    }

    fun speak(text: String) {
        if (ttsEnabled && isPersianAvailable) {
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "riazi_yar_tts")
        }
    }

    fun stop() { tts?.stop() }

    override fun onPause(owner: LifecycleOwner) { stop() }
    override fun onDestroy(owner: LifecycleOwner) { release() }

    fun release() {
        tts?.stop()
        tts?.shutdown()
        tts = null
    }
}
