package com.mathmvp.riazi_yar.ui.navigation

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.compose.*
import com.mathmvp.riazi_yar.audio.AudioEngine
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
fun AppNavigation(viewModel: RiaziViewModel, audioEngine: AudioEngine) {
    val nav = rememberNavController()
    val manifestState by viewModel.manifestState.collectAsState()
    val masteryList by viewModel.masteryList.collectAsState()
    val dueReviews by viewModel.dueReviews.collectAsState()
    val achievements by viewModel.achievements.collectAsState()
    val settings by viewModel.settings.collectAsState()

    LaunchedEffect(settings) {
        audioEngine.ttsEnabled = settings.ttsEnabled
        audioEngine.speechRate = settings.speechRate
    }

    NavHost(navController = nav, startDestination = AppRoutes.SPLASH) {
        composable(AppRoutes.SPLASH) {
            LaunchedEffect(manifestState) {
                if (manifestState is UiState.Success) nav.navigate(AppRoutes.HOME) { popUpTo(AppRoutes.SPLASH) { inclusive = true } }
            }
            Box(Modifier.fillMaxSize().padding(24.dp)) { Text("در حال بارگذاری ریاضی‌یار پایه اول...") }
        }
        composable(AppRoutes.HOME) {
            LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                item { Text("ریاضی‌یار پایه اول (نسخه ۲.۰)", style = MaterialTheme.typography.headlineMedium) }
                item { Button(onClick = { nav.navigate(AppRoutes.CHAPTERS) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("شروع یادگیری (۸ فصل / ۳۹ درس)") } }
                item { Button(onClick = { nav.navigate(AppRoutes.REVIEW_QUEUE) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("صف مرور هوشمند (${dueReviews.size.toFa()})") } }
                item { Button(onClick = { nav.navigate(AppRoutes.PROGRESS_DASHBOARD) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("کارنامه پیشرفت") } }
                item { Button(onClick = { nav.navigate(AppRoutes.MASTERY_DASHBOARD) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("داشبورد تسلط مهارت‌ها") } }
                item { Button(onClick = { nav.navigate(AppRoutes.ACHIEVEMENTS) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("دستاوردها (${achievements.size.toFa()})") } }
                item { OutlinedButton(onClick = { nav.navigate(AppRoutes.PARENT_DASHBOARD) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("داشبورد والدین 🔒") } }
                item { OutlinedButton(onClick = { nav.navigate(AppRoutes.PARENT_SETTINGS) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("تنظیمات والدین 🔒") } }
                item { OutlinedButton(onClick = { nav.navigate(AppRoutes.AUDIO_SETTINGS) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("تنظیمات صدا و TTS") } }
                item { OutlinedButton(onClick = { nav.navigate(AppRoutes.ACCESSIBILITY_SETTINGS) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("تنظیمات دسترس‌پذیری") } }
                item { Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextButton(onClick = { nav.navigate(AppRoutes.HELP) }) { Text("راهنما") }
                    TextButton(onClick = { nav.navigate(AppRoutes.ABOUT) }) { Text("درباره ما") }
                } }
            }
        }
        composable(AppRoutes.CHAPTERS) {
            val chapters = (manifestState as? UiState.Success)?.data?.lessons?.map { it.chapterNumber }?.distinct()?.sorted().orEmpty()
            LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                item { Text("انتخاب فصل", style = MaterialTheme.typography.headlineSmall) }
                items(chapters) { ch ->
                    ElevatedCard(onClick = { nav.navigate("lessons/$ch") }, modifier = Modifier.fillMaxWidth().heightIn(min = 64.dp)) {
                        Text("فصل ${ch.toFa()}", modifier = Modifier.padding(16.dp), style = MaterialTheme.typography.titleMedium)
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
                    ElevatedCard(onClick = { nav.navigate("lesson_intro/${l.lessonId}") }, modifier = Modifier.fillMaxWidth().heightIn(min = 64.dp)) {
                        Text("درس ${l.lessonNumber.toFa()}: ${l.titleFa}", modifier = Modifier.padding(16.dp))
                    }
                }
            }
        }
        composable(AppRoutes.LESSON_INTRO) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            var lesson by remember { mutableStateOf<LessonContentV2?>(null) }
            LaunchedEffect(lid) { lesson = viewModel.loadLesson(lid) }
            lesson?.let { l ->
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(l.titleFa, style = MaterialTheme.typography.headlineSmall)
                    Text(l.lessonSummary.visualTakeaway)
                    Button(onClick = { audioEngine.speak(l.lessonSummary.visualTakeaway) }, modifier = Modifier.heightIn(min = 56.dp)) { Text("🔊 خواندن توضیح درس") }
                    Button(onClick = { nav.navigate("concept_discovery/$lid") }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("۱. کشف مفهوم") }
                    Button(onClick = { nav.navigate("worked_example/$lid") }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("۲. مثال‌های حل‌شده (${l.workedExamples.size.toFa()})") }
                    Button(onClick = { nav.navigate("independent_practice/$lid") }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("۳. ۳۰ تمرین مستقل") }
                    OutlinedButton(onClick = { nav.navigate("remedial/$lid") }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("۴. تمرین جبرانی (۵ سؤال)") }
                    OutlinedButton(onClick = { nav.navigate("assessment/$lid") }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("۵. سنجش پایانی (۵ سؤال)") }
                }
            }
        }
        composable(AppRoutes.CONCEPT_DISCOVERY) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            var lesson by remember { mutableStateOf<LessonContentV2?>(null) }
            LaunchedEffect(lid) { lesson = viewModel.loadLesson(lid) }
            lesson?.let { l ->
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("کشف مفهوم — ${l.titleFa}", style = MaterialTheme.typography.headlineSmall)
                    l.lessonSummary.keyConcepts.forEach { Text("• $it") }
                    Button(onClick = { nav.navigate("worked_example/$lid") }, modifier = Modifier.heightIn(min = 56.dp)) { Text("ادامه به مثال‌ها") }
                }
            }
        }
        composable(AppRoutes.WORKED_EXAMPLE) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            var lesson by remember { mutableStateOf<LessonContentV2?>(null) }
            LaunchedEffect(lid) { lesson = viewModel.loadLesson(lid) }
            lesson?.let { l ->
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("مثال‌های حل‌شده", style = MaterialTheme.typography.headlineSmall)
                    l.workedExamples.forEach { ex ->
                        Text(ex.promptFa, style = MaterialTheme.typography.titleMedium)
                        ex.stepsFa.forEach { s -> Text("  - $s") }
                    }
                    Button(onClick = { nav.navigate("learning_activity/$lid") }, modifier = Modifier.heightIn(min = 56.dp)) { Text("ورود به فعالیت هدایت‌شده") }
                }
            }
        }
        composable(AppRoutes.LEARNING_ACTIVITY) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("فعالیت هدایت‌شده درس $lid", style = MaterialTheme.typography.headlineSmall)
                Button(onClick = { nav.navigate("independent_practice/$lid") }, modifier = Modifier.heightIn(min = 56.dp)) { Text("شروع ۳۰ تمرین مستقل") }
            }
        }
        composable(AppRoutes.INDEPENDENT_PRACTICE) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            var lesson by remember { mutableStateOf<LessonContentV2?>(null) }
            LaunchedEffect(lid) { lesson = viewModel.loadLesson(lid) }
            var idx by remember(lid) { mutableIntStateOf(0) }
            var feedback by remember(lid) { mutableStateOf("") }
            lesson?.let { l ->
                val q = l.independentPracticeQuestions[idx]
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("تمرین ${(idx + 1).toFa()} از ۳۰", style = MaterialTheme.typography.titleMedium)
                    Text(q.promptFa)
                    InteractionRouter(q) { outcome, hints ->
                        viewModel.submitAnswer(lid, q.questionId, q.interactionType, outcome.isCorrect, outcome.misconceptionCode, hints)
                        if (outcome.isCorrect) {
                            feedback = q.feedbackPolicy.successMessageFa
                            audioEngine.speak(feedback)
                            if (idx < 29) idx++ else nav.navigate("assessment/$lid")
                        } else {
                            feedback = q.feedbackPolicy.hintOnFirstErrorFa
                            audioEngine.speak(feedback)
                        }
                    }
                    if (feedback.isNotEmpty()) Text(feedback, color = MaterialTheme.colorScheme.primary)
                }
            }
        }
        composable(AppRoutes.REMEDIAL) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            var rem by remember { mutableStateOf<RemedialBank?>(null) }
            LaunchedEffect(lid) { rem = viewModel.loadRemedial(viewModel.loadLesson(lid)) }
            rem?.let { r ->
                LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    item { Text("تمرین جبرانی (${r.actualCount.toFa()} سؤال)", style = MaterialTheme.typography.headlineSmall) }
                    items(r.questions) { rq -> Text("• ${rq.promptFa}") }
                }
            }
        }
        composable(AppRoutes.ASSESSMENT) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            var asm by remember { mutableStateOf<AssessmentBank?>(null) }
            LaunchedEffect(lid) { asm = viewModel.loadAssessment(viewModel.loadLesson(lid)) }
            var idx by remember(lid) { mutableIntStateOf(0) }
            asm?.let { a ->
                val q = a.questions[idx]
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("سنجش پایانی (${(idx + 1).toFa()} از ${a.actualCount.toFa()})")
                    Text(q.promptFa)
                    InteractionRouter(q) { outcome, hints ->
                        viewModel.submitAnswer(lid, q.questionId, q.interactionType, outcome.isCorrect, outcome.misconceptionCode, hints)
                        if (idx < a.questions.lastIndex) idx++ else {
                            viewModel.markLessonCompleted(lid)
                            nav.navigate("lesson_completion/$lid")
                        }
                    }
                }
            }
        }
        composable(AppRoutes.LESSON_COMPLETION) { bs ->
            val lid = bs.arguments?.getString("lessonId") ?: "G1-L01"
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("🎉 تبریک! درس $lid تکمیل شد.", style = MaterialTheme.typography.headlineSmall)
                Button(onClick = { nav.navigate("chapter_completion/1") }, modifier = Modifier.heightIn(min = 56.dp)) { Text("مشاهده وضعیت فصل") }
                Button(onClick = { nav.navigate(AppRoutes.HOME) }, modifier = Modifier.heightIn(min = 56.dp)) { Text("بازگشت به خانه") }
            }
        }
        composable(AppRoutes.CHAPTER_COMPLETION) { bs ->
            val ch = bs.arguments?.getString("chapter") ?: "1"
            Column(Modifier.padding(16.dp)) { Text("🏆 تبریک پایان فصل $ch", style = MaterialTheme.typography.headlineSmall) }
        }
        composable(AppRoutes.PROGRESS_DASHBOARD) {
            LazyColumn(contentPadding = PaddingValues(16.dp)) {
                item { Text("کارنامه پیشرفت", style = MaterialTheme.typography.headlineSmall) }
                items(masteryList) { m -> Text("${m.lessonId}: ${(m.masteryScore * 100).toInt().toFa()}٪") }
            }
        }
        composable(AppRoutes.MASTERY_DASHBOARD) {
            LazyColumn(contentPadding = PaddingValues(16.dp)) {
                item { Text("داشبورد تسلط مهارت‌ها", style = MaterialTheme.typography.headlineSmall) }
                items(masteryList) { m -> Text("${m.skillId} | سطح: ${m.difficultyLevel} | مرور هر ${m.reviewIntervalDays.toFa()} روز") }
            }
        }
        composable(AppRoutes.REVIEW_QUEUE) {
            LazyColumn(contentPadding = PaddingValues(16.dp)) {
                item { Text("صف مرور هوشمند (${dueReviews.size.toFa()})", style = MaterialTheme.typography.headlineSmall) }
                items(dueReviews) { r -> Text("${r.lessonId}: ${r.priorityReasonFa}") }
            }
        }
        composable(AppRoutes.ACHIEVEMENTS) {
            LazyColumn(contentPadding = PaddingValues(16.dp)) {
                item { Text("دستاوردها (${achievements.size.toFa()})", style = MaterialTheme.typography.headlineSmall) }
                items(achievements) { a -> Text("⭐ ${a.titleFa}") }
            }
        }
        composable(AppRoutes.PARENT_DASHBOARD) {
            ParentGate {
                LazyColumn(contentPadding = PaddingValues(16.dp)) {
                    item { Text("داشبورد والدین", style = MaterialTheme.typography.headlineSmall) }
                    items(masteryList) { m -> Text("${m.lessonId} | صحیح: ${m.correctCount.toFa()} | غلط: ${m.wrongCount.toFa()} | خطای اخیر: ${m.lastMisconceptionCode ?: "ندارد"}") }
                }
            }
        }
        composable(AppRoutes.PARENT_SETTINGS) {
            ParentGate {
                Column(Modifier.padding(16.dp)) {
                    Text("تنظیمات والدین", style = MaterialTheme.typography.headlineSmall)
                    Row {
                        Text("یادآورهای محلی با رضایت والد")
                        Switch(checked = settings.parentRemindersEnabled, onCheckedChange = { viewModel.updateSettings(settings.copy(parentRemindersEnabled = it)) })
                    }
                }
            }
        }
        composable(AppRoutes.AUDIO_SETTINGS) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("تنظیمات صدا و TTS", style = MaterialTheme.typography.headlineSmall)
                Row {
                    Text("خوانش صوتی فارسی (TTS)")
                    Switch(checked = settings.ttsEnabled, onCheckedChange = { viewModel.updateSettings(settings.copy(ttsEnabled = it)) })
                }
            }
        }
        composable(AppRoutes.ACCESSIBILITY_SETTINGS) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("تنظیمات دسترس‌پذیری", style = MaterialTheme.typography.headlineSmall)
                Row {
                    Text("کاهش انیمیشن (Reduce Motion)")
                    Switch(checked = settings.reduceMotion, onCheckedChange = { viewModel.updateSettings(settings.copy(reduceMotion = it)) })
                }
            }
        }
        composable(AppRoutes.ABOUT) { Column(Modifier.padding(16.dp)) { Text("ریاضی‌یار پایه اول — نسخه Native 2.0.0 — کاملاً آفلاین و ایمن برای کودکان.") } }
        composable(AppRoutes.HELP) { Column(Modifier.padding(16.dp)) { Text("راهنمای استفاده: فصل و درس را انتخاب کنید، مثال‌ها را ببینید و تمرین‌های تعاملی را انجام دهید.") } }
    }
}
