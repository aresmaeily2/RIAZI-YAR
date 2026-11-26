package com.mathmvp.riazi_yar.adaptive

import com.mathmvp.riazi_yar.data.*
import kotlin.math.max
import kotlin.math.roundToInt

enum class AdaptiveAction {
    CONTINUE_LESSON, SHOW_HINT, STEP_DOWN_DIFFICULTY, STEP_UP_DIFFICULTY,
    TRIGGER_REMEDIAL, ENTER_ASSESSMENT, SCHEDULE_FUTURE_REVIEW
}

data class Sm2ScheduleResult(
    val repetitionCount: Int,
    val intervalDays: Int,
    val easeFactor: Float
)

data class AdaptiveDecision(
    val updatedMastery: SkillMasteryEntity,
    val nextAction: AdaptiveAction,
    val errorCategory: MathErrorCategory?,
    val parentExplanationFa: String
)

class AdaptiveLearningEngine(private val dao: RiaziDao) {

    /**
     * Authentic SuperMemo SM-2 algorithm:
     * - If quality < 3: repetitionCount resets to 0, intervalDays resets to 1
     * - If quality >= 3:
     *     n = 1 -> interval = 1 day
     *     n = 2 -> interval = 6 days
     *     n > 2 -> interval = round(previousInterval * easeFactor)
     * - EF' = max(1.3, EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
     */
    fun computeSm2Schedule(
        currentRepetitionCount: Int,
        currentIntervalDays: Int,
        easeFactor: Float,
        quality: Int
    ): Sm2ScheduleResult {
        val clampedQ = quality.coerceIn(0, 5)
        val newEase = max(
            1.3f,
            easeFactor + (0.1f - (5 - clampedQ) * (0.08f + (5 - clampedQ) * 0.02f))
        ).coerceAtMost(3.0f)

        return if (clampedQ < 3) {
            Sm2ScheduleResult(
                repetitionCount = 0,
                intervalDays = 1,
                easeFactor = newEase
            )
        } else {
            val nextRep = currentRepetitionCount + 1
            val nextInterval = when (nextRep) {
                1 -> 1
                2 -> 6
                else -> max(1, (currentIntervalDays * newEase).roundToInt())
            }
            Sm2ScheduleResult(
                repetitionCount = nextRep,
                intervalDays = nextInterval,
                easeFactor = newEase
            )
        }
    }

    suspend fun recordAttempt(
        lessonId: String,
        skillId: String,
        questionId: String,
        interactionType: String,
        isCorrect: Boolean,
        misconceptionCode: String? = null,
        hintsUsed: Int = 0,
        responseTimeMs: Long = 3000L,
        nowMs: Long = System.currentTimeMillis()
    ): AdaptiveDecision {
        val current = dao.getSkillMastery(skillId) ?: SkillMasteryEntity(skillId = skillId, lessonId = lessonId)
        val quality = when {
            isCorrect && hintsUsed == 0 -> 5
            isCorrect && hintsUsed == 1 -> 4
            isCorrect -> 3
            else -> 1
        }
        val delta = when {
            isCorrect && hintsUsed == 0 -> 0.14f
            isCorrect -> 0.08f
            else -> -0.10f
        }
        val newScore = (current.masteryScore + delta).coerceIn(0.0f, 1.0f)
        val newConsecErrors = if (isCorrect) 0 else current.consecutiveErrors + 1
        val sm2 = computeSm2Schedule(
            currentRepetitionCount = current.repetitionCount,
            currentIntervalDays = current.reviewIntervalDays,
            easeFactor = current.easeFactor,
            quality = quality
        )
        // If remediation is needed or answer was wrong, review is due immediately (nowMs) so child can practice it
        val nextReviewMs = if (isCorrect) {
            nowMs + sm2.intervalDays * 86_400_000L
        } else {
            nowMs
        }
        val needsRemedial = newConsecErrors >= 2 || (current.attemptsCount + 1 >= 3 && newScore < 0.50f)
        val difficulty = when {
            newScore < 0.45f -> "EASY"
            newScore < 0.80f -> "MEDIUM"
            else -> "CHALLENGE"
        }

        val updated = current.copy(
            masteryScore = newScore,
            attemptsCount = current.attemptsCount + 1,
            correctCount = current.correctCount + if (isCorrect) 1 else 0,
            wrongCount = current.wrongCount + if (!isCorrect) 1 else 0,
            totalResponseTimeMs = current.totalResponseTimeMs + responseTimeMs,
            hintsUsedTotal = current.hintsUsedTotal + hintsUsed,
            consecutiveErrors = newConsecErrors,
            repetitionCount = sm2.repetitionCount,
            easeFactor = sm2.easeFactor,
            reviewIntervalDays = sm2.intervalDays,
            nextReviewEpochMs = nextReviewMs,
            lastMisconceptionCode = if (isCorrect) null else misconceptionCode,
            difficultyLevel = difficulty,
            remedialRecommended = needsRemedial,
            updatedAtEpochMs = nowMs
        )

        val errCat = if (isCorrect) null else ErrorTaxonomy.classify(misconceptionCode)
        val action = when {
            needsRemedial -> AdaptiveAction.TRIGGER_REMEDIAL
            !isCorrect -> AdaptiveAction.SHOW_HINT
            newScore >= 0.85f -> AdaptiveAction.ENTER_ASSESSMENT
            newScore >= 0.65f -> AdaptiveAction.STEP_UP_DIFFICULTY
            else -> AdaptiveAction.CONTINUE_LESSON
        }

        val reasonFa = when {
            needsRemedial -> "نیاز به مرور فوری در «${errCat?.titleFa ?: "مفهوم"}»؛ راهبرد: ${errCat?.remedialStrategyFa ?: "تمرین جبرانی"}."
            !isCorrect -> "مرور تقویتی برای رفع «${errCat?.titleFa ?: "خطا"}»."
            newScore >= 0.85f -> "تسلط ${(newScore * 100).roundToInt()}٪؛ مرور بعدی طبق الگوریتم SM-2 در ${sm2.intervalDays} روز آینده."
            else -> "سطح فعلی: $difficulty (تسلط: ${(newScore * 100).roundToInt()}٪)."
        }

        val logEntity = AttemptLogEntity(
            lessonId = lessonId,
            skillId = skillId,
            questionId = questionId,
            interactionType = interactionType,
            isCorrect = isCorrect,
            misconceptionCode = misconceptionCode,
            hintsUsed = hintsUsed,
            responseTimeMs = responseTimeMs,
            timestampEpochMs = nowMs
        )
        val reviewEntity = ReviewQueueEntity(
            skillId = skillId,
            lessonId = lessonId,
            dueEpochMs = nextReviewMs,
            priorityReasonFa = reasonFa
        )
        val achievementEntity = if (newScore >= 0.85f) {
            AchievementEntity("ach_${lessonId}_$skillId", "تسلط بر مهارت $skillId در درس $lessonId", nowMs)
        } else null

        dao.recordAttemptTransaction(updated, logEntity, reviewEntity, achievementEntity)

        return AdaptiveDecision(updated, action, errCat, reasonFa)
    }

    companion object {
        /**
         * Pure function to compute real lesson completion and stars (0..3) without any hardcoded values.
         */
        fun evaluateLessonCompletion(
            existing: LessonProgressEntity?,
            lessonId: String,
            totalPracticeQuestions: Int,
            practiceAnsweredCount: Int,
            practiceCorrectCount: Int,
            examplesViewed: Boolean,
            guidedCompleted: Boolean,
            assessmentScorePercent: Int,
            passingThresholdPercent: Int = 80,
            nowMs: Long = System.currentTimeMillis()
        ): LessonProgressEntity {
            val safeTotal = max(1, totalPracticeQuestions)
            val assessmentPassed = assessmentScorePercent >= passingThresholdPercent
            val allPracticeDone = practiceAnsweredCount >= safeTotal
            val completed = examplesViewed && guidedCompleted && allPracticeDone && assessmentPassed

            val practiceAccuracy = (practiceCorrectCount.toFloat() / safeTotal.toFloat()).coerceIn(0f, 1f)
            val stars = when {
                !completed -> 0
                assessmentScorePercent >= 95 && practiceAccuracy >= 0.90f -> 3
                assessmentScorePercent >= 85 && practiceAccuracy >= 0.75f -> 2
                else -> 1
            }

            return LessonProgressEntity(
                lessonId = lessonId,
                currentQuestionIndex = (existing?.currentQuestionIndex ?: 0).coerceAtMost(safeTotal - 1),
                totalQuestionsCount = safeTotal,
                practiceAnsweredCount = practiceAnsweredCount,
                practiceCorrectCount = practiceCorrectCount,
                examplesViewed = examplesViewed,
                guidedCompleted = guidedCompleted,
                assessmentScorePercent = assessmentScorePercent,
                assessmentPassed = assessmentPassed,
                completed = completed,
                starsEarned = max(existing?.starsEarned ?: 0, stars),
                lastVisitedEpochMs = nowMs
            )
        }
    }
}
