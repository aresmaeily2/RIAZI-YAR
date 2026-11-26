package com.mathmvp.riazi_yar.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.mathmvp.riazi_yar.core.PersianUtils.toAsciiDigits
import com.mathmvp.riazi_yar.core.PersianUtils.toFa
import kotlinx.coroutines.delay
import kotlin.random.Random

data class ParentGateChallenge(
    val factorA: Int,
    val factorB: Int,
    val addendC: Int
) {
    val expectedAnswer: Int get() = factorA * factorB + addendC
    val promptFa: String get() = "(${factorA.toFa()} × ${factorB.toFa()}) + ${addendC.toFa()} = ؟"
}

object ParentGateLogic {
    const val MAX_FAILED_ATTEMPTS = 3
    const val LOCKOUT_DURATION_MS = 60_000L
    const val SESSION_TIMEOUT_MS = 300_000L // 5 minutes

    fun generateChallenge(seed: Long = System.currentTimeMillis()): ParentGateChallenge {
        val rng = Random(seed)
        return ParentGateChallenge(
            factorA = rng.nextInt(6, 10),
            factorB = rng.nextInt(6, 10),
            addendC = rng.nextInt(2, 9)
        )
    }

    fun checkAnswer(input: String, challenge: ParentGateChallenge): Boolean {
        val normalized = input.trim().toAsciiDigits().toIntOrNull() ?: return false
        return normalized == challenge.expectedAnswer
    }
}

@Composable
fun ParentGate(content: @Composable () -> Unit) {
    var unlocked by rememberSaveable { mutableStateOf(false) }
    var failedAttempts by rememberSaveable { mutableIntStateOf(0) }
    var lockoutRemainingSec by rememberSaveable { mutableIntStateOf(0) }
    var challengeSeed by rememberSaveable { mutableLongStateOf(System.currentTimeMillis()) }
    var answer by rememberSaveable { mutableStateOf("") }
    var feedbackMessage by rememberSaveable { mutableStateOf("") }

    val challenge = remember(challengeSeed) { ParentGateLogic.generateChallenge(challengeSeed) }
    val lifecycleOwner = LocalLifecycleOwner.current

    // Relock automatically when app goes to background (ON_PAUSE / ON_STOP)
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_PAUSE || event == Lifecycle.Event.ON_STOP) {
                unlocked = false
                answer = ""
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    // 5-minute session timeout relock
    LaunchedEffect(unlocked) {
        if (unlocked) {
            delay(ParentGateLogic.SESSION_TIMEOUT_MS)
            unlocked = false
            answer = ""
            feedbackMessage = "نشست والدین پس از ۵ دقیقه عدم فعالیت به صورت خودکار قفل شد."
        }
    }

    // Cooldown countdown after 3 failed attempts
    LaunchedEffect(lockoutRemainingSec) {
        if (lockoutRemainingSec > 0) {
            delay(1_000L)
            lockoutRemainingSec--
            if (lockoutRemainingSec == 0) {
                failedAttempts = 0
                challengeSeed = System.currentTimeMillis()
                feedbackMessage = ""
            }
        }
    }

    if (unlocked) {
        Column(Modifier.fillMaxSize()) {
            Surface(color = MaterialTheme.colorScheme.secondaryContainer, modifier = Modifier.fillMaxWidth()) {
                Row(
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "🔒 بخش والدین (قفل خودکار پس از ۵ دقیقه یا خروج از برنامه)",
                        style = MaterialTheme.typography.bodyLarge
                    )
                    TextButton(onClick = { unlocked = false; answer = "" }) {
                        Text("خروج و قفل")
                    }
                }
            }
            content()
        }
    } else {
        Column(Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("ورود ویژه والدین و مربی", style = MaterialTheme.typography.headlineSmall)
            Text(
                text = "توجه امنیتی: این گیت محاسباتی برای جلوگیری از ورود تصادفی کودک طراحی شده و جایگزین احراز هویت رمزنگاری سیستم‌عامل نیست.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.secondary
            )
            if (lockoutRemainingSec > 0) {
                Card(colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)) {
                    Text(
                        text = "تعداد تلاش‌های ناموفق بیش از حد مجاز بود. لطفاً ${lockoutRemainingSec.toFa()} ثانیه صبر کنید.",
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.padding(16.dp)
                    )
                }
            } else {
                Text("برای باز کردن قفل، عبارت زیر را محاسبه کنید:", style = MaterialTheme.typography.titleMedium)
                Text(challenge.promptFa, style = MaterialTheme.typography.headlineMedium)
                OutlinedTextField(
                    value = answer,
                    onValueChange = { answer = it },
                    label = { Text("پاسخ عددی") },
                    modifier = Modifier.fillMaxWidth()
                )
                if (feedbackMessage.isNotBlank()) {
                    Text(feedbackMessage, color = MaterialTheme.colorScheme.error)
                }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Button(
                        onClick = {
                            if (ParentGateLogic.checkAnswer(answer, challenge)) {
                                unlocked = true
                                failedAttempts = 0
                                feedbackMessage = ""
                                answer = ""
                            } else {
                                failedAttempts++
                                answer = ""
                                if (failedAttempts >= ParentGateLogic.MAX_FAILED_ATTEMPTS) {
                                    lockoutRemainingSec = (ParentGateLogic.LOCKOUT_DURATION_MS / 1000L).toInt()
                                } else {
                                    challengeSeed = System.currentTimeMillis() + failedAttempts
                                    val rem = ParentGateLogic.MAX_FAILED_ATTEMPTS - failedAttempts
                                    feedbackMessage = "پاسخ نادرست است. (${rem.toFa()} تلاش باقی‌مانده)"
                                }
                            }
                        },
                        modifier = Modifier.weight(1f).heightIn(min = 56.dp)
                    ) {
                        Text("تأیید و ورود")
                    }
                    OutlinedButton(
                        onClick = {
                            challengeSeed = System.currentTimeMillis() + 99L
                            answer = ""
                        },
                        modifier = Modifier.heightIn(min = 56.dp)
                    ) {
                        Text("سؤال جدید")
                    }
                }
            }
        }
    }
}
