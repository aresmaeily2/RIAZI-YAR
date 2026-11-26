package com.mathmvp.riazi_yar.adaptive

import com.mathmvp.riazi_yar.data.*
import kotlin.math.max
import kotlin.math.roundToInt

enum class AdaptiveAction {
    CONTINUE_LESSON, SHOW_HINT, STEP_DOWN_DIFFICULTY, STEP_UP_DIFFICULTY,
    TRIGGER_REMEDIAL, ENTER_ASSESSMENT, SCHEDULE_FUTURE_REVIEW
}

data class AdaptiveDecision(
    val updatedMastery: SkillMasteryEntity,
    val nextAction: AdaptiveAction,
    val errorCategory: MathErrorCategory?,
    val parentExplanationFa: String
)

class AdaptiveLearningEngine(private val dao: RiaziDao) {

    fun computeSm2NextInterval(currentIntervalDays: Int, easeFactor: Float, quality: Int): Pair<Int, Float> {
        if (quality < 3) {
            return 1 to max(1.3f, easeFactor - 0.2f)
        }
        val nextInterval = when {
            currentIntervalDays <= 1 -> 3
            currentIntervalDays <= 3 -> 7
            else -> (currentIntervalDays * easeFactor).roundToInt()
        }
        val newEase = (easeFactor + (0.1f - (5 - quality) * (0.08f + (5 - quality) * 0.02f))).coerceIn(1.3f, 3.0f)
        return nextInterval to newEase
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
        val (nextInterval, nextEase) = computeSm2NextInterval(current.reviewIntervalDays, current.easeFactor, quality)
        val nextReviewMs = nowMs + nextInterval * 86_400_000L
        val needsRemedial = newConsecErrors >= 2 || (current.attemptsCount >= 3 && newScore < 0.50f)
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
            easeFactor = nextEase,
            reviewIntervalDays = nextInterval,
            nextReviewEpochMs = nextReviewMs,
            lastMisconceptionCode = if (isCorrect) null else misconceptionCode,
            difficultyLevel = difficulty,
            remedialRecommended = needsRemedial,
            updatedAtEpochMs = nowMs
        )
        dao.upsertSkillMastery(updated)
        dao.insertAttemptLog(
            AttemptLogEntity(
                lessonId = lessonId, skillId = skillId, questionId = questionId,
                interactionType = interactionType, isCorrect = isCorrect,
                misconceptionCode = misconceptionCode, hintsUsed = hintsUsed,
                responseTimeMs = responseTimeMs, timestampEpochMs = nowMs
            )
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
            needsRemedial -> "خطای تکراری در «${errCat?.titleFa ?: "مفهوم"}»؛ پیشنهاد: ${errCat?.remedialStrategyFa ?: "تمرین جبرانی"}."
            newScore >= 0.85f -> "تسلط ${(newScore * 100).roundToInt()}٪ حاصل شد؛ آماده سنجش پایانی و مرور در $nextInterval روز آینده."
            else -> "ادامه تمرین در سطح $difficulty (تسلط فعلی: ${(newScore * 100).roundToInt()}٪)."
        }

        dao.upsertReviewQueue(
            ReviewQueueEntity(
                skillId = skillId,
                lessonId = lessonId,
                dueEpochMs = nextReviewMs,
                priorityReasonFa = reasonFa
            )
        )

        if (newScore >= 0.85f) {
            dao.insertAchievement(AchievementEntity("ach_$lessonId", "تسلط بر درس $lessonId", nowMs))
        }

        return AdaptiveDecision(updated, action, errCat, reasonFa)
    }
}
