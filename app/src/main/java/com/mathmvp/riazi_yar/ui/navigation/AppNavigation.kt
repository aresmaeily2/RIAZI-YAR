package com.mathmvp.riazi_yar.ui.navigation

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.navigation.compose.*
import com.mathmvp.riazi_yar.audio.AudioEngine
import com.mathmvp.riazi_yar.audio.TtsEngineStatus
import com.mathmvp.riazi_yar.content.AssessmentBank
import com.mathmvp.riazi_yar.content.LessonContentV2
import com.mathmvp.riazi_yar.content.RemedialBank
import com.mathmvp.riazi_yar.core.PersianUtils.toFa
import com.mathmvp.riazi_yar.ui.interactions.InteractionRouter
import com.mathmvp.riazi_yar.ui.screens.ParentGate
import com.mathmvp.riazi_yar.viewmodel.RiaziViewModel
import com.mathmvp.riazi_yar.viewmodel.UiState

object AppRoutes {
    const val SPLASH = "splash"
    const val HOME = "home"
    const val CHAPTERS = "chapters"
    const val LESSONS = "lessons/{chapter}"
    const val LESSON_INTRO = "lesson_intro/{lessonId}"
    const val CONCEPT_DISCOVERY = "concept_discovery/{lessonId}"
    const val WORKED_EXAMPLE = "worked_example/{lessonId}"
    const val LEARNING_ACTIVITY = "learning_activity/{lessonId}"
    const val INDEPENDENT_PRACTICE = "independent_practice/{lessonId}"
    const val REMEDIAL = "remedial/{lessonId}"
    const val ASSESSMENT = "assessment/{lessonId}"
    const val LESSON_COMPLETION = "lesson_completion/{lessonId}"
    const val CHAPTER_COMPLETION = "chapter_completion/{chapter}"
    const val PROGRESS_DASHBOARD = "progress_dashboard"
    const val MASTERY_DASHBOARD = "mastery_dashboard"
    const val REVIEW_QUEUE = "review_queue"
    const val ACHIEVEMENTS = "achievements"
    const val PARENT_DASHBOARD = "parent_dashboard"
    const val PARENT_SETTINGS = "parent_settings"
    const val AUDIO_SETTINGS = "audio_settings"
    const val ACCESSIBILITY_SETTINGS = "accessibility_settings"
    const val ABOUT = "about"
    const val HELP = "help"
}

@Composable
private fun ErrorRetryCard(message: String, onRetry: () -> Unit) {
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
        modifier = Modifier.fillMaxWidth().padding(16.dp)
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(message, color = MaterialTheme.colorScheme.onErrorContainer, style = MaterialTheme.typography.titleMedium)
            Button(onClick = onRetry, modifier = Modifier.heightIn(min = 56.dp)) {
                Text("🔄 تلاش مجدد")
            }
        }
    }
}

@Composable
fun AppNavigation(viewModel: RiaziViewModel, audioEngine: AudioEngine) {
    val nav = rememberNavController()
    val manifestState by viewModel.manifestState.collectAsState()
    val masteryList by viewModel.masteryList.collectAsState()
    val progressList by viewModel.lessonProgressList.collectAsState()
    val dueReviews by viewModel.dueReviews.collectAsState()
    val achievements by viewModel.achievements.collectAsState()
    val settings by viewModel.settings.collectAsState()
    val ttsStatus by audioEngine.status.collectAsState()

    LaunchedEffect(settings) {
        audioEngine.ttsEnabled = settings.ttsEnabled
        audioEngine.speechRate = settings.speechRate
    }

    NavHost(navController = nav, startDestination = AppRoutes.SPLASH) {
        composable(AppRoutes.SPLASH) {
            when (val st = manifestState) {
                is UiState.Loading -> {
                    Box(Modifier.fillMaxSize().padding(24.dp)) {
                        Text("در حال بارگذاری و اعتبارسنجی محتوای ریاضی‌یار پایه اول...")
                    }
                }
                is UiState.Error -> {
                    ErrorRetryCard(st.message, onRetry = { viewModel.retryLoadManifest() })
                }
                is UiState.Success -> {
                    LaunchedEffect(st) {
                        nav.navigate(AppRoutes.HOME) { popUpTo(AppRoutes.SPLASH) { inclusive = true } }
                    }
                }
            }
        }

        composable(AppRoutes.HOME) {
            val totalLessonsCount = (manifestState as? UiState.Success)?.data?.lessons?.size ?: 0
            val completedLessonsCount = progressList.count { it.completed }
            val totalStars = progressList.sumOf { it.starsEarned }

            LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                item {
                    Text("ریاضی‌یار پایه اول (نسخه ۲.۱)", style = MaterialTheme.typography.headlineMedium)
                    Text(
                        text = "پیشرفت واقعی: ${completedLessonsCount.toFa()} از ${totalLessonsCount.toFa()} درس تکمیل‌شده | ⭐ ${totalStars.toFa()} ستاره",
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
                if (ttsStatus == TtsEngineStatus.FALLBACK_TEXT_ONLY || ttsStatus == TtsEngineStatus.ERROR_UNAVAILABLE) {
                    item {
                        Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFFFF8E1))) {
                            Text(
                                text = "ℹ️ موتور خوانش صوتی فارسی (TTS) روی این دستگاه فعال نیست؛ راهنمای متنی و تصویری کامل فعال است.",
                                modifier = Modifier.padding(12.dp)
                            )
                        }
                    }
                }
                item {
                    Button(
                        onClick = { nav.navigate(AppRoutes.CHAPTERS) },
                        modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                    ) { Text("شروع یادگیری (۸ فصل / ${totalLessonsCount.toFa()} درس)") }
                }
                item {
                    Button(
                        onClick = { nav.navigate(AppRoutes.REVIEW_QUEUE) },
                        modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                    ) { Text("صف مرور هوشمند امروز (${dueReviews.size.toFa()})") }
                }
                item {
                    Button(
                        onClick = { nav.navigate(AppRoutes.PROGRESS_DASHBOARD) },
                        modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                    ) { Text("کارنامه پیشرفت درس‌ها") }
                }
                item {
                    Button(
                        onClick = { nav.navigate(AppRoutes.MASTERY_DASHBOARD) },
                        modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                    ) { Text("داشبورد تسلط مهارت‌ها (SM-2)") }
                }
                item {
                    Button(
                        onClick = { nav.navigate(AppRoutes.ACHIEVEMENTS) },
                        modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                    ) { Text("دستاوردها (${achievements.size.toFa()})") }
                }
                item {
                    OutlinedButton(
                        onClick = { nav.navigate(AppRoutes.PARENT_DASHBOARD) },
                        modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                    ) { Text("داشبورد والدین و مربی 🔒") }
                }
                item {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedButton(onClick = { nav.navigate(AppRoutes.AUDIO_SETTINGS) }, modifier = Modifier.weight(1f).heightIn(min = 56.dp)) { Text("تنظیمات صدا") }
                        OutlinedButton(onClick = { nav.navigate(AppRoutes.ACCESSIBILITY_SETTINGS) }, modifier = Modifier.weight(1f).heightIn(min = 56.dp)) { Text("دسترس‌پذیری") }
                    }
                }
                item {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        TextButton(onClick = { nav.navigate(AppRoutes.HELP) }) { Text("راهنمای یادگیری") }
                        TextButton(onClick = { nav.navigate(AppRoutes.ABOUT) }) { Text("درباره و حریم خصوصی") }
                    }
                }
            }
        }

        composable(AppRoutes.CHAPTERS) {
            val lessonsAll = (manifestState as? UiState.Success)?.data?.lessons.orEmpty()
            val chapters = lessonsAll.map { it.chapterNumber }.distinct().sorted()
            LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                item { Text("انتخاب فصل", style = MaterialTheme.typography.headlineSmall) }
                items(chapters) { ch ->
                    val chLessons = lessonsAll.filter { it.chapterNumber == ch }
                    val doneCount = chLessons.count { entry -> progressList.any { it.lessonId == entry.lessonId && it.completed } }
                    ElevatedCard(
                        onClick = { nav.navigate("lessons/$ch") },
                        modifier = Modifier.fillMaxWidth().heightIn(min = 68.dp)
                    ) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text("فصل ${ch.toFa()} (${chLessons.size.toFa()} درس)", style = MaterialTheme.typography.titleMedium)
                            Text("تکمیل‌شده: ${doneCount.toFa()} از ${chLessons.size.toFa()} درس")
                        }
                    }
                }
            }
        }

        composable(AppRoutes.LESSONS) { bs ->
            val ch = bs.arguments?.getString("chapter")?.toIntOrNull() ?: 1
            val lessons = (manifestState as? UiState.Success)?.data?.lessons?.filter { it.chapterNumber == ch }.orEmpty()
            LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                item { Text("درس‌های فصل ${ch.toFa()}", style = MaterialTheme.typography.headlineSmall) }
                items(lessons) { l ->
                    val prog = progressList.find { it.lessonId == l.lessonId }
                    val statusBadge = when {
                        prog?.completed == true -> "✅ تکمیل‌شده (${"⭐".repeat(prog.starsEarned)})"
                        (prog?.practiceAnsweredCount ?: 0) > 0 -> "⏳ در حال یادگیری (${prog?.practiceAnsweredCount?.toFa()} تمرین)"
                        else -> "🆕 شروع‌نشده"
                    }
                    ElevatedCard(
                        onClick = { nav.navigate("lesson_intro/${l.lessonId}") },
                        modifier = Modifier.fillMaxWidth().heightIn(min = 68.dp)
                    ) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text("درس ${l.lessonNumber.toFa()}: ${l.titleFa}", style = MaterialTheme.typography.titleMedium)
                            Text(statusBadge)
                        }
                    }
                }
            }
        }

        composable(AppRoutes.LESSON_INTRO) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            var lessonState by remember(lid) { mutableStateOf<UiState<LessonContentV2>>(UiState.Loading) }
            var reloadTrigger by rememberSaveable(lid) { mutableIntStateOf(0) }
            LaunchedEffect(lid, reloadTrigger) {
                lessonState = UiState.Loading
                lessonState = viewModel.loadLessonState(lid)
            }
            when (val st = lessonState) {
                is UiState.Loading -> Box(Modifier.padding(24.dp)) { Text("در حال بارگذاری درس...") }
                is UiState.Error -> ErrorRetryCard(st.message, onRetry = { reloadTrigger++ })
                is UiState.Success -> {
                    val l = st.data
                    val totalQ = l.independentPracticeQuestions.size
                    val prog = progressList.find { it.lessonId == lid }
                    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        item {
                            Text(l.titleFa, style = MaterialTheme.typography.headlineSmall)
                            Text(l.lessonSummary.visualTakeaway)
                        }
                        if (l.learningObjectivesFa.isNotEmpty()) {
                            item {
                                Card(modifier = Modifier.fillMaxWidth()) {
                                    Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                        Text("🎯 هدف‌های یادگیری این درس:", style = MaterialTheme.typography.titleMedium)
                                        l.learningObjectivesFa.forEach { obj -> Text("• $obj") }
                                    }
                                }
                            }
                        }
                        item {
                            Button(
                                onClick = { audioEngine.speak(l.lessonSummary.visualTakeaway) },
                                modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                            ) { Text("🔊 خواندن صوتی معرفی درس") }
                        }
                        item {
                            Button(
                                onClick = { nav.navigate("concept_discovery/$lid") },
                                modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                            ) { Text("۱. شروع داستان و کشف مفهوم") }
                        }
                        item {
                            Button(
                                onClick = { nav.navigate("worked_example/$lid") },
                                modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                            ) { Text("۲. مثال‌های حل‌شده گام‌به‌گام (${l.workedExamples.size.toFa()})") }
                        }
                        item {
                            Button(
                                onClick = { nav.navigate("learning_activity/$lid") },
                                modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                            ) { Text("۳. فعالیت هدایت‌شده تعاملی (${l.guidedActivities.size.toFa()} گام)") }
                        }
                        item {
                            Button(
                                onClick = { nav.navigate("independent_practice/$lid") },
                                modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                            ) {
                                val doneQ = prog?.practiceAnsweredCount ?: 0
                                Text("۴. تمرین مستقل (${doneQ.toFa()} از ${totalQ.toFa()} سؤال)")
                            }
                        }
                        item {
                            OutlinedButton(
                                onClick = { nav.navigate("remedial/$lid") },
                                modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                            ) { Text("۵. مسیر جبرانی هدفمند") }
                        }
                        item {
                            OutlinedButton(
                                onClick = { nav.navigate("assessment/$lid") },
                                modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                            ) { Text("۶. سنجش پایانی درس") }
                        }
                    }
                }
            }
        }

        composable(AppRoutes.CONCEPT_DISCOVERY) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            var lessonState by remember(lid) { mutableStateOf<UiState<LessonContentV2>>(UiState.Loading) }
            LaunchedEffect(lid) { lessonState = viewModel.loadLessonState(lid) }
            when (val st = lessonState) {
                is UiState.Loading -> Box(Modifier.padding(24.dp)) { Text("در حال بارگذاری بخش کشف مفهوم...") }
                is UiState.Error -> ErrorRetryCard(st.message, onRetry = {})
                is UiState.Success -> {
                    val l = st.data
                    var activeStep by rememberSaveable(lid) { mutableIntStateOf(0) }
                    val steps = l.conceptDiscovery.discoveryStepsFa.ifEmpty { l.lessonSummary.keyConcepts }
                    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        item {
                            Text("کشف مفهوم — ${l.titleFa}", style = MaterialTheme.typography.headlineSmall)
                            if (l.warmUpStoryFa.isNotBlank()) {
                                Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFE3F2FD))) {
                                    Text(l.warmUpStoryFa, modifier = Modifier.padding(14.dp))
                                }
                            }
                        }
                        item {
                            Text(l.conceptDiscovery.visualExplanationFa.ifBlank { l.lessonSummary.visualTakeaway })
                        }
                        items(steps.take(activeStep + 1)) { stepText ->
                            Card(modifier = Modifier.fillMaxWidth()) {
                                Text("🔍 $stepText", modifier = Modifier.padding(12.dp))
                            }
                        }
                        item {
                            if (activeStep < steps.lastIndex) {
                                Button(
                                    onClick = { activeStep++ },
                                    modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                                ) { Text("گام بعدی کشف مفهوم (${(activeStep + 1).toFa()} از ${steps.size.toFa()})") }
                            } else {
                                Button(
                                    onClick = { nav.navigate("worked_example/$lid") },
                                    modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                                ) { Text("ادامه به مثال‌های حل‌شده ➡️") }
                            }
                        }
                    }
                }
            }
        }

        composable(AppRoutes.WORKED_EXAMPLE) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            var lessonState by remember(lid) { mutableStateOf<UiState<LessonContentV2>>(UiState.Loading) }
            LaunchedEffect(lid) { lessonState = viewModel.loadLessonState(lid) }
            when (val st = lessonState) {
                is UiState.Loading -> Box(Modifier.padding(24.dp)) { Text("در حال بارگذاری مثال‌های حل‌شده...") }
                is UiState.Error -> ErrorRetryCard(st.message, onRetry = {})
                is UiState.Success -> {
                    val l = st.data
                    var exIndex by rememberSaveable(lid) { mutableIntStateOf(0) }
                    val examples = l.workedExamples
                    if (examples.isEmpty()) {
                        ErrorRetryCard("هیچ مثال حل‌شده‌ای برای این درس ثبت نشده است.") { nav.popBackStack() }
                    } else {
                        val ex = examples[exIndex.coerceIn(0, examples.lastIndex)]
                        LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            item {
                                Text(
                                    "مثال حل‌شده ${(exIndex + 1).toFa()} از ${examples.size.toFa()}",
                                    style = MaterialTheme.typography.headlineSmall
                                )
                                Text(ex.promptFa, style = MaterialTheme.typography.titleMedium)
                            }
                            items(ex.stepsFa) { step ->
                                Card(modifier = Modifier.fillMaxWidth()) {
                                    Text(step, modifier = Modifier.padding(12.dp))
                                }
                            }
                            item {
                                Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFE8F5E9))) {
                                    Text("✅ پاسخ نهایی: ${ex.finalAnswer}", modifier = Modifier.padding(14.dp), style = MaterialTheme.typography.titleMedium)
                                }
                            }
                            item {
                                if (exIndex < examples.lastIndex) {
                                    Button(
                                        onClick = { exIndex++ },
                                        modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                                    ) { Text("مشاهده مثال بعدی") }
                                } else {
                                    Button(
                                        onClick = {
                                            viewModel.markExamplesViewed(lid, l.independentPracticeQuestions.size)
                                            nav.navigate("learning_activity/$lid")
                                        },
                                        modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                                    ) { Text("ورود به فعالیت هدایت‌شده تعاملی ➡️") }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Fixed (Section 7.3): Real interactive Guided Activity before Independent Practice
        composable(AppRoutes.LEARNING_ACTIVITY) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            var lessonState by remember(lid) { mutableStateOf<UiState<LessonContentV2>>(UiState.Loading) }
            LaunchedEffect(lid) { lessonState = viewModel.loadLessonState(lid) }
            var guidedIdx by rememberSaveable(lid) { mutableIntStateOf(0) }
            var guidedFeedback by rememberSaveable(lid) { mutableStateOf("") }

            when (val st = lessonState) {
                is UiState.Loading -> Box(Modifier.padding(24.dp)) { Text("در حال بارگذاری فعالیت هدایت‌شده...") }
                is UiState.Error -> ErrorRetryCard(st.message, onRetry = {})
                is UiState.Success -> {
                    val l = st.data
                    val guidedList = l.guidedActivities.ifEmpty { l.independentPracticeQuestions.take(3) }
                    if (guidedList.isEmpty()) {
                        ErrorRetryCard("فعالیت هدایت‌شده برای این درس یافت نشد.") { nav.popBackStack() }
                    } else {
                        val gq = guidedList[guidedIdx.coerceIn(0, guidedList.lastIndex)]
                        LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            item {
                                Text(
                                    "فعالیت هدایت‌شده (${(guidedIdx + 1).toFa()} از ${guidedList.size.toFa()})",
                                    style = MaterialTheme.typography.headlineSmall
                                )
                                Text("در این بخش، با کمک راهنما ابزارها را امتحان کن تا آماده تمرین مستقل شوی.")
                                Text(gq.promptFa, style = MaterialTheme.typography.titleMedium)
                            }
                            item {
                                InteractionRouter(gq) { outcome, hints ->
                                    viewModel.submitAnswer(
                                        lessonId = lid,
                                        skillCode = gq.skillCode,
                                        questionId = gq.questionId,
                                        interactionType = gq.interactionType,
                                        isCorrect = outcome.isCorrect,
                                        misconceptionCode = outcome.misconceptionCode,
                                        hintsUsed = hints,
                                        isIndependentPractice = false
                                    )
                                    if (outcome.isCorrect) {
                                        guidedFeedback = gq.feedbackPolicy.successMessageFa
                                        audioEngine.speak(guidedFeedback)
                                        if (guidedIdx < guidedList.lastIndex) {
                                            guidedIdx++
                                        } else {
                                            viewModel.markGuidedActivityCompleted(lid, l.independentPracticeQuestions.size)
                                            nav.navigate("independent_practice/$lid")
                                        }
                                    } else {
                                        guidedFeedback = gq.feedbackPolicy.hintOnFirstErrorFa
                                        audioEngine.speak(guidedFeedback)
                                    }
                                }
                            }
                            if (guidedFeedback.isNotBlank()) {
                                item {
                                    Text(guidedFeedback, color = MaterialTheme.colorScheme.primary)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Fixed (Section 7.7): Reads dynamic question count from content, saves/restores index, handles errors gracefully
        composable(AppRoutes.INDEPENDENT_PRACTICE) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            var lessonState by remember(lid) { mutableStateOf<UiState<LessonContentV2>>(UiState.Loading) }
            var idx by rememberSaveable(lid) { mutableIntStateOf(0) }
            var initializedFromDb by rememberSaveable(lid) { mutableStateOf(false) }
            var feedback by rememberSaveable(lid) { mutableStateOf("") }
            var consecutiveWrongOnCurrent by rememberSaveable(lid) { mutableIntStateOf(0) }

            LaunchedEffect(lid) {
                val loaded = viewModel.loadLessonState(lid)
                lessonState = loaded
                if (loaded is UiState.Success && !initializedFromDb) {
                    val savedProg = viewModel.getOrInitLessonProgress(lid, loaded.data.independentPracticeQuestions.size)
                    idx = savedProg.currentQuestionIndex.coerceIn(0, loaded.data.independentPracticeQuestions.lastIndex)
                    initializedFromDb = true
                }
            }

            when (val st = lessonState) {
                is UiState.Loading -> Box(Modifier.padding(24.dp)) { Text("در حال بارگذاری تمرین‌های مستقل...") }
                is UiState.Error -> ErrorRetryCard(st.message, onRetry = {})
                is UiState.Success -> {
                    val l = st.data
                    val questions = l.independentPracticeQuestions
                    if (questions.isEmpty()) {
                        ErrorRetryCard("فهرست تمرین‌های این درس خالی است.") { nav.popBackStack() }
                    } else {
                        val totalQuestions = questions.size
                        val safeIdx = idx.coerceIn(0, questions.lastIndex)
                        val q = questions[safeIdx]

                        LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            item {
                                LinearProgressIndicator(
                                    progress = { (safeIdx + 1).toFloat() / totalQuestions.toFloat() },
                                    modifier = Modifier.fillMaxWidth()
                                )
                                Text(
                                    "تمرین مستقل ${(safeIdx + 1).toFa()} از ${totalQuestions.toFa()} | سطح: ${q.difficulty}",
                                    style = MaterialTheme.typography.titleMedium
                                )
                                Text(q.promptFa, style = MaterialTheme.typography.bodyLarge)
                            }
                            item {
                                InteractionRouter(q) { outcome, hints ->
                                    viewModel.submitAnswer(
                                        lessonId = lid,
                                        skillCode = q.skillCode,
                                        questionId = q.questionId,
                                        interactionType = q.interactionType,
                                        isCorrect = outcome.isCorrect,
                                        misconceptionCode = outcome.misconceptionCode,
                                        hintsUsed = hints,
                                        questionIndex = safeIdx,
                                        totalQuestions = totalQuestions,
                                        isIndependentPractice = true
                                    )
                                    if (outcome.isCorrect) {
                                        consecutiveWrongOnCurrent = 0
                                        feedback = q.feedbackPolicy.successMessageFa
                                        audioEngine.speak(feedback)
                                        if (safeIdx < questions.lastIndex) {
                                            idx = safeIdx + 1
                                        } else {
                                            nav.navigate("assessment/$lid")
                                        }
                                    } else {
                                        consecutiveWrongOnCurrent++
                                        feedback = if (consecutiveWrongOnCurrent >= 2 && q.feedbackPolicy.scaffoldedHintFa.isNotBlank()) {
                                            q.feedbackPolicy.scaffoldedHintFa
                                        } else {
                                            q.feedbackPolicy.hintOnFirstErrorFa
                                        }
                                        audioEngine.speak(feedback)
                                    }
                                }
                            }
                            if (feedback.isNotEmpty()) {
                                item {
                                    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFE3F2FD))) {
                                        Text(feedback, modifier = Modifier.padding(12.dp))
                                    }
                                }
                            }
                            if (consecutiveWrongOnCurrent >= 2) {
                                item {
                                    OutlinedButton(
                                        onClick = { nav.navigate("remedial/$lid") },
                                        modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                                    ) {
                                        Text("🛠️ ورود به تمرین جبرانی برای رفع اشکال این مهارت")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Fixed (Section 7.4): Full interactive Remedial path with InteractionRouter, step-by-step hints, retry, and feedback
        composable(AppRoutes.REMEDIAL) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            var remState by remember(lid) { mutableStateOf<UiState<RemedialBank>>(UiState.Loading) }
            var remIdx by rememberSaveable(lid) { mutableIntStateOf(0) }
            var remFeedback by rememberSaveable(lid) { mutableStateOf("") }
            var remCompleted by rememberSaveable(lid) { mutableStateOf(false) }

            LaunchedEffect(lid) {
                val lState = viewModel.loadLessonState(lid)
                remState = when (lState) {
                    is UiState.Success -> viewModel.loadRemedialState(lState.data)
                    is UiState.Error -> UiState.Error(lState.message)
                    is UiState.Loading -> UiState.Loading
                }
            }

            when (val st = remState) {
                is UiState.Loading -> Box(Modifier.padding(24.dp)) { Text("در حال بارگذاری مسیر جبرانی...") }
                is UiState.Error -> ErrorRetryCard(st.message, onRetry = {})
                is UiState.Success -> {
                    val bank = st.data
                    val totalRem = bank.questions.size
                    if (remCompleted) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            Text("🌟 آفرین! مسیر جبرانی (${totalRem.toFa()} سؤال) با موفقیت کامل شد.", style = MaterialTheme.typography.headlineSmall)
                            Button(
                                onClick = { nav.navigate("independent_practice/$lid") },
                                modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                            ) { Text("بازگشت به ادامه تمرین مستقل") }
                        }
                    } else {
                        val rq = bank.questions[remIdx.coerceIn(0, bank.questions.lastIndex)]
                        val pq = rq.toPracticeQuestion()
                        LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            item {
                                Text(
                                    "تمرین جبرانی (${(remIdx + 1).toFa()} از ${totalRem.toFa()})",
                                    style = MaterialTheme.typography.headlineSmall
                                )
                                Text("هدف رفع خطا: ${rq.targetMisconceptionCode}", color = MaterialTheme.colorScheme.secondary)
                                Text(rq.promptFa, style = MaterialTheme.typography.titleMedium)
                            }
                            item {
                                InteractionRouter(pq) { outcome, hints ->
                                    viewModel.submitAnswer(
                                        lessonId = lid,
                                        skillCode = rq.skillCode,
                                        questionId = rq.questionId,
                                        interactionType = rq.interactionType,
                                        isCorrect = outcome.isCorrect,
                                        misconceptionCode = if (outcome.isCorrect) null else rq.targetMisconceptionCode,
                                        hintsUsed = hints,
                                        isIndependentPractice = false
                                    )
                                    if (outcome.isCorrect) {
                                        remFeedback = rq.feedbackPolicy.successMessageFa
                                        audioEngine.speak(remFeedback)
                                        if (remIdx < bank.questions.lastIndex) {
                                            remIdx++
                                        } else {
                                            remCompleted = true
                                        }
                                    } else {
                                        remFeedback = rq.feedbackPolicy.scaffoldedHintFa.ifBlank { rq.feedbackPolicy.hintOnFirstErrorFa }
                                        audioEngine.speak(remFeedback)
                                    }
                                }
                            }
                            if (remFeedback.isNotBlank()) {
                                item {
                                    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFFFF8E1))) {
                                        Text(remFeedback, modifier = Modifier.padding(12.dp))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Fixed (Section 7.5 & 7.6): Tracks real assessment score, enforces passing threshold, shows post-submit review, allows retry
        composable(AppRoutes.ASSESSMENT) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            var lessonObj by remember(lid) { mutableStateOf<LessonContentV2?>(null) }
            var asmState by remember(lid) { mutableStateOf<UiState<AssessmentBank>>(UiState.Loading) }
            var idx by rememberSaveable(lid) { mutableIntStateOf(0) }
            var correctCount by rememberSaveable(lid) { mutableIntStateOf(0) }
            var submitted by rememberSaveable(lid) { mutableStateOf(false) }

            LaunchedEffect(lid) {
                val lState = viewModel.loadLessonState(lid)
                if (lState is UiState.Success) {
                    lessonObj = lState.data
                    asmState = viewModel.loadAssessmentState(lState.data)
                } else if (lState is UiState.Error) {
                    asmState = UiState.Error(lState.message)
                }
            }

            when (val st = asmState) {
                is UiState.Loading -> Box(Modifier.padding(24.dp)) { Text("در حال بارگذاری سنجش پایانی...") }
                is UiState.Error -> ErrorRetryCard(st.message, onRetry = {})
                is UiState.Success -> {
                    val a = st.data
                    val totalQ = a.questions.size
                    val thresholdPct = a.passingScorePercent
                    val scorePct = if (totalQ > 0) ((correctCount * 100f) / totalQ.toFloat()).toInt() else 0
                    val passed = scorePct >= thresholdPct

                    if (submitted) {
                        LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            item {
                                Text(
                                    text = if (passed) "🎉 قبول شدی! امتیاز سنجش: ${scorePct.toFa()}٪" else "💡 نیاز به تلاش مجدد — امتیاز سنجش: ${scorePct.toFa()}٪",
                                    style = MaterialTheme.typography.headlineSmall
                                )
                                Text(
                                    text = "پاسخ صحیح: ${correctCount.toFa()} از ${totalQ.toFa()} سؤال (حد نصاب قبولی: ${thresholdPct.toFa()}٪)"
                                )
                            }
                            items(a.questions) { qItem ->
                                if (qItem.feedbackPolicy.postSubmitFeedbackFa.isNotBlank()) {
                                    Card(modifier = Modifier.fillMaxWidth()) {
                                        Text(qItem.feedbackPolicy.postSubmitFeedbackFa, modifier = Modifier.padding(12.dp))
                                    }
                                }
                            }
                            item {
                                if (passed) {
                                    Button(
                                        onClick = { nav.navigate("lesson_completion/$lid") },
                                        modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                                    ) { Text("مشاهده لوح پایان درس ➡️") }
                                } else {
                                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                        Button(
                                            onClick = {
                                                idx = 0
                                                correctCount = 0
                                                submitted = false
                                            },
                                            modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                                        ) { Text("🔄 تلاش دوباره در سنجش پایانی") }
                                        OutlinedButton(
                                            onClick = { nav.navigate("remedial/$lid") },
                                            modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                                        ) { Text("ورود به تمرین جبرانی پیش از آزمون مجدد") }
                                    }
                                }
                            }
                        }
                    } else {
                        val q = a.questions[idx.coerceIn(0, a.questions.lastIndex)]
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            Text("سنجش پایانی (${(idx + 1).toFa()} از ${totalQ.toFa()})", style = MaterialTheme.typography.headlineSmall)
                            Text(q.promptFa, style = MaterialTheme.typography.titleMedium)
                            InteractionRouter(q) { outcome, hints ->
                                val updatedCorrect = if (outcome.isCorrect) correctCount + 1 else correctCount
                                correctCount = updatedCorrect
                                viewModel.submitAnswer(
                                    lessonId = lid,
                                    skillCode = q.skillCode,
                                    questionId = q.questionId,
                                    interactionType = q.interactionType,
                                    isCorrect = outcome.isCorrect,
                                    misconceptionCode = outcome.misconceptionCode,
                                    hintsUsed = hints,
                                    isIndependentPractice = false
                                )
                                if (idx < a.questions.lastIndex) {
                                    idx++
                                } else {
                                    val practiceTotal = lessonObj?.independentPracticeQuestions?.size ?: 30
                                    viewModel.recordAssessmentAndEvaluateCompletion(
                                        lessonId = lid,
                                        totalPracticeQuestions = practiceTotal,
                                        assessmentCorrectCount = updatedCorrect,
                                        assessmentTotalCount = totalQ,
                                        passingThresholdPercent = thresholdPct
                                    )
                                    submitted = true
                                }
                            }
                        }
                    }
                }
            }
        }

        composable(AppRoutes.LESSON_COMPLETION) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            val prog = progressList.find { it.lessonId == lid }
            val stars = prog?.starsEarned ?: 0
            val scorePct = prog?.assessmentScorePercent ?: 0
            val fullyCompleted = prog?.completed == true

            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    text = if (fullyCompleted) "🎉 تبریک! درس $lid با موفقیت کامل شد." else "📋 وضعیت پیشرفت درس $lid",
                    style = MaterialTheme.typography.headlineSmall
                )
                Text("ستاره‌های کسب‌شده بر اساس عملکرد واقعی: ${if (stars > 0) "⭐".repeat(stars) else "بدون ستاره"}")
                Text("امتیاز سنجش پایانی: ${scorePct.toFa()}٪ | تمرین‌های حل‌شده: ${(prog?.practiceAnsweredCount ?: 0).toFa()}")
                if (!fullyCompleted) {
                    Text(
                        "توجه: برای ثبت تکمیل نهایی درس، مشاهده مثال‌ها، فعالیت هدایت‌شده، تمام تمرین‌های مستقل و کسب حداقل ۸۰٪ در سنجش الزامی است.",
                        color = MaterialTheme.colorScheme.secondary
                    )
                }
                Button(onClick = { nav.navigate(AppRoutes.HOME) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) {
                    Text("بازگشت به خانه")
                }
            }
        }

        composable(AppRoutes.CHAPTER_COMPLETION) { bs ->
            val ch = bs.arguments?.getString("chapter") ?: "1"
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("🏆 وضعیت پایان فصل ${ch.toFa()}", style = MaterialTheme.typography.headlineSmall)
                Button(onClick = { nav.navigate(AppRoutes.HOME) }, modifier = Modifier.heightIn(min = 56.dp)) { Text("بازگشت به خانه") }
            }
        }

        composable(AppRoutes.PROGRESS_DASHBOARD) {
            LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                item { Text("کارنامه پیشرفت واقعی درس‌ها", style = MaterialTheme.typography.headlineSmall) }
                if (progressList.isEmpty()) {
                    item { Text("هنوز هیچ درسی شروع نشده است.") }
                }
                items(progressList) { p ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(12.dp)) {
                            Text("${p.lessonId} — ${if (p.completed) "✅ تکمیل‌شده" else "⏳ در جریان"}")
                            Text("تمرین: ${p.practiceAnsweredCount.toFa()}/${p.totalQuestionsCount.toFa()} | سنجش: ${p.assessmentScorePercent.toFa()}٪ | ستاره: ${p.starsEarned.toFa()}")
                        }
                    }
                }
            }
        }

        composable(AppRoutes.MASTERY_DASHBOARD) {
            LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                item { Text("داشبورد تسلط مهارت‌ها (موتور SM-2)", style = MaterialTheme.typography.headlineSmall) }
                if (masteryList.isEmpty()) {
                    item { Text("هنوز تلاشی برای محاسبه تسلط ثبت نشده است.") }
                }
                items(masteryList) { m ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(12.dp)) {
                            Text("${m.skillId} | تسلط: ${(m.masteryScore * 100).toInt().toFa()}٪")
                            Text("سطح: ${m.difficultyLevel} | تکرار موفق: ${m.repetitionCount.toFa()} | فاصله مرور بعدی: ${m.reviewIntervalDays.toFa()} روز")
                        }
                    }
                }
            }
        }

        composable(AppRoutes.REVIEW_QUEUE) {
            LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                item { Text("صف مرور هوشمند سررسیدشده (${dueReviews.size.toFa()})", style = MaterialTheme.typography.headlineSmall) }
                if (dueReviews.isEmpty()) {
                    item { Text("هیچ مرور سررسیدشده‌ای برای امروز وجود ندارد.") }
                }
                items(dueReviews) { r ->
                    ElevatedCard(
                        onClick = { nav.navigate("lesson_intro/${r.lessonId}") },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(Modifier.padding(12.dp)) {
                            Text("درس ${r.lessonId} (${r.skillId})", style = MaterialTheme.typography.titleMedium)
                            Text(r.priorityReasonFa)
                        }
                    }
                }
            }
        }

        composable(AppRoutes.ACHIEVEMENTS) {
            LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                item { Text("دستاوردها (${achievements.size.toFa()})", style = MaterialTheme.typography.headlineSmall) }
                if (achievements.isEmpty()) {
                    item { Text("با تکمیل واقعی درس‌ها و کسب تسلط، دستاوردهای جدید باز می‌شوند.") }
                }
                items(achievements) { a -> Text("⭐ ${a.titleFa}") }
            }
        }

        composable(AppRoutes.PARENT_DASHBOARD) {
            ParentGate {
                LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    item {
                        Text("داشبورد تحلیلی والدین و مربی", style = MaterialTheme.typography.headlineSmall)
                        Text("تمام داده‌ها ۱۰۰٪ محلی روی همین دستگاه ذخیره شده‌اند و به هیچ سروری ارسال نمی‌شوند.")
                    }
                    item {
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            OutlinedButton(onClick = { nav.navigate(AppRoutes.PARENT_SETTINGS) }, modifier = Modifier.weight(1f).heightIn(min = 56.dp)) {
                                Text("تنظیمات و مدیریت داده")
                            }
                        }
                    }
                    items(masteryList) { m ->
                        Card(modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(12.dp)) {
                                Text("درس ${m.lessonId} (${m.skillId})", style = MaterialTheme.typography.titleMedium)
                                Text("صحیح: ${m.correctCount.toFa()} | غلط: ${m.wrongCount.toFa()} | راهنما: ${m.hintsUsedTotal.toFa()}")
                                Text("خطای اخیر: ${m.lastMisconceptionCode ?: "ندارد"} | نیاز به جبرانی: ${if (m.remedialRecommended) "بله" else "خیر"}")
                            }
                        }
                    }
                }
            }
        }

        composable(AppRoutes.PARENT_SETTINGS) {
            ParentGate {
                var confirmReset by rememberSaveable { mutableStateOf(false) }
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("تنظیمات والدین و حریم خصوصی", style = MaterialTheme.typography.headlineSmall)
                    Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                        Text("یادآورهای محلی تمرین")
                        Switch(
                            checked = settings.parentRemindersEnabled,
                            onCheckedChange = { viewModel.updateSettings(settings.copy(parentRemindersEnabled = it)) }
                        )
                    }
                    HorizontalDivider()
                    Text("حذف کامل داده‌های محلی کودک", style = MaterialTheme.typography.titleMedium)
                    if (!confirmReset) {
                        OutlinedButton(
                            onClick = { confirmReset = true },
                            modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                        ) { Text("🗑️ پاک کردن تمام رکوردهای پیشرفت و تسلط") }
                    } else {
                        Text("آیا از حذف کامل تمام داده‌های آموزشی کودک مطمئن هستید؟", color = MaterialTheme.colorScheme.error)
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Button(
                                onClick = {
                                    viewModel.resetAllChildProgress()
                                    confirmReset = false
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
                                modifier = Modifier.weight(1f).heightIn(min = 56.dp)
                            ) { Text("بله، حذف شود") }
                            OutlinedButton(
                                onClick = { confirmReset = false },
                                modifier = Modifier.weight(1f).heightIn(min = 56.dp)
                            ) { Text("انصراف") }
                        }
                    }
                }
            }
        }

        composable(AppRoutes.AUDIO_SETTINGS) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("تنظیمات صدا و خوانش صوتی (TTS)", style = MaterialTheme.typography.headlineSmall)
                Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                    Text("خوانش صوتی فارسی (TTS)")
                    Switch(
                        checked = settings.ttsEnabled,
                        onCheckedChange = { viewModel.updateSettings(settings.copy(ttsEnabled = it)) }
                    )
                }
                Text("وضعیت موتور TTS دستگاه: $ttsStatus")
            }
        }

        composable(AppRoutes.ACCESSIBILITY_SETTINGS) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("تنظیمات دسترس‌پذیری", style = MaterialTheme.typography.headlineSmall)
                Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                    Text("کاهش انیمیشن (Reduce Motion)")
                    Switch(
                        checked = settings.reduceMotion,
                        onCheckedChange = { viewModel.updateSettings(settings.copy(reduceMotion = it)) }
                    )
                }
            }
        }

        composable(AppRoutes.ABOUT) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("درباره ریاضی‌یار پایه اول — نسخه Native 2.1.0", style = MaterialTheme.typography.headlineSmall)
                Text("• کاملاً آفلاین، بدون دسترسی اینترنت، بدون تبلیغات و بدون ردیابی کودک.")
                Text("• حداقل‌گرایی داده: تمام پیشرفت‌ها فقط روی حافظه داخلی دستگاه ذخیره می‌شوند و از طریق بخش والدین قابل حذف کامل هستند.")
                Text("• وضعیت آموزشی: فنی و تعاملی اعتبارسنجی‌شده؛ نیازمند تأیید نهایی میدانی معلم پایه اول (PEDAGOGICAL_PENDING_TEACHER_REVIEW).")
            }
        }

        composable(AppRoutes.HELP) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("راهنمای استفاده از ریاضی‌یار", style = MaterialTheme.typography.headlineSmall)
                Text("۱. فصل و درس مورد نظر را انتخاب کنید.")
                Text("۲. داستان شروع و کشف مفهوم را ببینید.")
                Text("۳. مثال‌های حل‌شده و فعالیت هدایت‌شده را انجام دهید.")
                Text("۴. تمرین‌های مستقل را با ابزارهای لمسی (سبد شمارش، محور اعداد، چوب‌خط، الگو و ترازوی دوکفه‌ای) حل کنید.")
                Text("۵. در سنجش پایانی شرکت کنید تا ستاره‌های واقعی درس را دریافت کنید.")
            }
        }
    }
}
