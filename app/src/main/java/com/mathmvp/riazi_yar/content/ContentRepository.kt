package com.mathmvp.riazi_yar.content

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

class ContentValidationException(message: String, cause: Throwable? = null) : IllegalStateException(message, cause)

class ContentRepository(private val context: Context) {
    private val json = Json { ignoreUnknownKeys = true }

    private suspend fun readAsset(relPath: String): String = withContext(Dispatchers.IO) {
        runCatching {
            context.assets.open("content_v2/$relPath").bufferedReader().use { it.readText() }
        }.getOrElse { e ->
            throw ContentValidationException("فایل محتوا یافت نشد یا قابل خواندن نیست: $relPath", e)
        }
    }

    suspend fun loadManifest(): ContentManifest {
        val manifest = runCatching {
            json.decodeFromString<ContentManifest>(readAsset("CONTENT_MANIFEST.json"))
        }.getOrElse { e ->
            throw ContentValidationException("ساختار فهرست محتوا (CONTENT_MANIFEST.json) نامعتبر است", e)
        }
        if (manifest.lessons.isEmpty() || manifest.lessons.size != manifest.totalLessons) {
            throw ContentValidationException("عدم تطابق تعداد درس‌ها در مانیفست (${manifest.lessons.size} در برابر ${manifest.totalLessons})")
        }
        return manifest
    }

    suspend fun loadLesson(lessonId: String): LessonContentV2 {
        if (!lessonId.matches(Regex("^G1-L\\d{2}$"))) {
            throw ContentValidationException("شناسه درس نامعتبر است: $lessonId")
        }
        val lesson = runCatching {
            json.decodeFromString<LessonContentV2>(readAsset("lessons/${lessonId}_lesson.json"))
        }.getOrElse { e ->
            throw ContentValidationException("خطا در خواندن محتوای درس $lessonId", e)
        }
        if (lesson.independentPracticeQuestions.isEmpty()) {
            throw ContentValidationException("فهرست تمرین‌های مستقل درس $lessonId خالی است")
        }
        return lesson
    }

    suspend fun loadRemedial(lesson: LessonContentV2): RemedialBank {
        val bank = runCatching {
            json.decodeFromString<RemedialBank>(readAsset(lesson.remedialQuestionsRef))
        }.getOrElse { e ->
            throw ContentValidationException("خطا در بارگذاری تمرین جبرانی درس ${lesson.lessonId}", e)
        }
        if (bank.questions.isEmpty()) {
            throw ContentValidationException("بانک جبرانی درس ${lesson.lessonId} فاقد سؤال است")
        }
        return bank
    }

    suspend fun loadAssessment(lesson: LessonContentV2): AssessmentBank {
        val bank = runCatching {
            json.decodeFromString<AssessmentBank>(readAsset(lesson.assessmentQuestionsRef))
        }.getOrElse { e ->
            throw ContentValidationException("خطا در بارگذاری سنجش پایانی درس ${lesson.lessonId}", e)
        }
        if (bank.questions.isEmpty()) {
            throw ContentValidationException("بانک سنجش درس ${lesson.lessonId} فاقد سؤال است")
        }
        return bank
    }
}
