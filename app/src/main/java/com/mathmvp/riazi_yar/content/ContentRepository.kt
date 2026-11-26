package com.mathmvp.riazi_yar.content

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

class ContentRepository(private val context: Context) {
    private val json = Json { ignoreUnknownKeys = true }

    private suspend fun readAsset(relPath: String): String = withContext(Dispatchers.IO) {
        context.assets.open("content_v2/$relPath").bufferedReader().use { it.readText() }
    }

    suspend fun loadManifest(): ContentManifest {
        val manifest = json.decodeFromString<ContentManifest>(readAsset("CONTENT_MANIFEST.json"))
        require(manifest.totalLessons == 39 && manifest.lessons.size == 39) {
            "Expected 39 lessons in V2 manifest, found ${manifest.lessons.size}"
        }
        return manifest
    }

    suspend fun loadLesson(lessonId: String): LessonContentV2 {
        val lesson = json.decodeFromString<LessonContentV2>(readAsset("lessons/${lessonId}_lesson.json"))
        require(lesson.independentPracticeQuestions.size == 30) {
            "Lesson $lessonId must have 30 independent questions"
        }
        return lesson
    }

    suspend fun loadRemedial(lesson: LessonContentV2): RemedialBank =
        json.decodeFromString(readAsset(lesson.remedialQuestionsRef))

    suspend fun loadAssessment(lesson: LessonContentV2): AssessmentBank =
        json.decodeFromString(readAsset(lesson.assessmentQuestionsRef))
}
