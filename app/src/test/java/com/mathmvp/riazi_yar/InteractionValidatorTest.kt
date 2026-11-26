package com.mathmvp.riazi_yar

import com.mathmvp.riazi_yar.adaptive.*
import com.mathmvp.riazi_yar.content.*
import com.mathmvp.riazi_yar.core.PersianUtils.toAsciiDigits
import com.mathmvp.riazi_yar.core.PersianUtils.toFa
import com.mathmvp.riazi_yar.data.*
import com.mathmvp.riazi_yar.ui.interactions.InteractionValidator
import com.mathmvp.riazi_yar.ui.screens.ParentGateChallenge
import com.mathmvp.riazi_yar.ui.screens.ParentGateLogic
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import org.junit.Assert.*
import org.junit.Test
import java.io.File

class InteractionValidatorTest {

    private val json = Json { ignoreUnknownKeys = true }

    private fun resolveAssetsDir(): File {
        val candidates = listOf(
            File("src/main/assets/content_v2"),
            File("app/src/main/assets/content_v2")
        )
        return candidates.firstOrNull { it.exists() }
            ?: error("Could not locate src/main/assets/content_v2 from ${File(".").absolutePath}")
    }

    @Test
    fun dragCount_allCases() {
        assertTrue(InteractionValidator.validateDragCount(5, 5).isCorrect)
        assertNull(InteractionValidator.validateDragCount(5, 5).misconceptionCode)
        assertEquals("OVERCOUNT_BY_ONE", InteractionValidator.validateDragCount(6, 5).misconceptionCode)
        assertEquals("UNDERCOUNT_BY_ONE", InteractionValidator.validateDragCount(4, 5).misconceptionCode)
        assertEquals("COUNT_MISMATCH", InteractionValidator.validateDragCount(9, 5).misconceptionCode)
        assertEquals("INVALID_INPUT", InteractionValidator.validateDragCount(-1, 5).misconceptionCode)
    }

    @Test
    fun numberLine_allCases() {
        assertTrue(InteractionValidator.validateNumberLine(8, 8).isCorrect)
        assertEquals("COUNTING_START_NODE", InteractionValidator.validateNumberLine(7, 8).misconceptionCode)
        assertEquals("COUNTING_START_NODE", InteractionValidator.validateNumberLine(9, 8).misconceptionCode)
        assertEquals("WRONG_DIRECTION", InteractionValidator.validateNumberLine(2, 8).misconceptionCode)
        assertEquals("OUT_OF_RANGE", InteractionValidator.validateNumberLine(-1, 8).misconceptionCode)
        assertEquals("OUT_OF_RANGE", InteractionValidator.validateNumberLine(21, 8).misconceptionCode)
    }

    @Test
    fun tallyMarks_allCases() {
        assertTrue(InteractionValidator.validateTallyMarks(1, 2, 7).isCorrect)
        assertEquals("UNBUNDLED_FIVE", InteractionValidator.validateTallyMarks(0, 7, 7).misconceptionCode)
        assertEquals("BUNDLE_COUNTED_AS_ONE", InteractionValidator.validateTallyMarks(2, 5, 7).misconceptionCode)
        assertEquals("TALLY_MISMATCH", InteractionValidator.validateTallyMarks(1, 0, 7).misconceptionCode)
        assertEquals("INVALID_INPUT", InteractionValidator.validateTallyMarks(-1, 2, 7).misconceptionCode)
    }

    @Test
    fun balanceScale_allCases() {
        assertTrue(InteractionValidator.validateBalanceScale(6, 6).isCorrect)
        assertEquals("OFF_BY_ONE_BALANCE", InteractionValidator.validateBalanceScale(5, 6).misconceptionCode)
        assertEquals("OFF_BY_ONE_BALANCE", InteractionValidator.validateBalanceScale(7, 6).misconceptionCode)
        assertEquals("EQUILIBRIUM_ERROR", InteractionValidator.validateBalanceScale(2, 6).misconceptionCode)
        assertEquals("INVALID_INPUT", InteractionValidator.validateBalanceScale(-2, 6).misconceptionCode)
    }

    @Test
    fun optionSelection_validatesByOptionIdAndValue() {
        val correctById = CorrectAnswer(value = 4, optionId = "opt_2", canonicalForm = "VAL_4")
        val selectedCorrect = QuestionOption(id = "opt_2", labelFa = "۴ شکل", value = 4)
        val selectedWrong = QuestionOption(id = "opt_1", labelFa = "۳ شکل", value = 3)

        assertTrue(InteractionValidator.validateOptionSelection(selectedCorrect, correctById, isPattern = false).isCorrect)
        val wrongOutcome = InteractionValidator.validateOptionSelection(selectedWrong, correctById, isPattern = false)
        assertFalse(wrongOutcome.isCorrect)
        assertEquals("DISTRACTOR_SELECTED", wrongOutcome.misconceptionCode)

        val patternWrong = InteractionValidator.validateOptionSelection(selectedWrong, correctById, isPattern = true)
        assertFalse(patternWrong.isCorrect)
        assertEquals("PATTERN_MISMATCH", patternWrong.misconceptionCode)
    }

    @Test
    fun sm2Schedule_followsSuperMemoSpecification() {
        val dao = InMemoryFakeRiaziDao()
        val engine = AdaptiveLearningEngine(dao)

        // First correct repetition (n=1 -> interval = 1 day)
        val r1 = engine.computeSm2Schedule(currentRepetitionCount = 0, currentIntervalDays = 1, easeFactor = 2.5f, quality = 5)
        assertEquals(1, r1.repetitionCount)
        assertEquals(1, r1.intervalDays)
        assertTrue(r1.easeFactor >= 2.5f)

        // Second correct repetition (n=2 -> interval = 6 days)
        val r2 = engine.computeSm2Schedule(currentRepetitionCount = r1.repetitionCount, currentIntervalDays = r1.intervalDays, easeFactor = r1.easeFactor, quality = 5)
        assertEquals(2, r2.repetitionCount)
        assertEquals(6, r2.intervalDays)

        // Third correct repetition (n=3 -> interval = round(6 * EF))
        val r3 = engine.computeSm2Schedule(currentRepetitionCount = r2.repetitionCount, currentIntervalDays = r2.intervalDays, easeFactor = r2.easeFactor, quality = 5)
        assertEquals(3, r3.repetitionCount)
        assertTrue(r3.intervalDays >= 15)

        // Failed repetition (quality < 3 -> resets repetitionCount to 0 and intervalDays to 1)
        val failed = engine.computeSm2Schedule(currentRepetitionCount = r3.repetitionCount, currentIntervalDays = r3.intervalDays, easeFactor = r3.easeFactor, quality = 1)
        assertEquals(0, failed.repetitionCount)
        assertEquals(1, failed.intervalDays)
    }

    @Test
    fun adaptiveEngine_recordsAttemptsAndSchedulesDueReviewsAccurately() = runBlocking {
        val dao = InMemoryFakeRiaziDao()
        val engine = AdaptiveLearningEngine(dao)
        val now = 1_700_000_000_000L

        // Wrong attempt -> due immediately (now)
        val dec1 = engine.recordAttempt(
            lessonId = "G1-L01",
            skillId = "G1_SN01_drag_and_drop_count",
            questionId = "G1-L01-IND-01",
            interactionType = "drag_and_drop_count",
            isCorrect = false,
            misconceptionCode = "OVERCOUNT_BY_ONE",
            hintsUsed = 1,
            nowMs = now
        )
        assertEquals(AdaptiveAction.SHOW_HINT, dec1.nextAction)
        assertEquals(MathErrorCategory.COUNTING_ERROR, dec1.errorCategory)
        assertEquals(1, dao.getDueReviewsSnapshot(now).size)

        // Second wrong attempt -> triggers remedial
        val dec2 = engine.recordAttempt(
            lessonId = "G1-L01",
            skillId = "G1_SN01_drag_and_drop_count",
            questionId = "G1-L01-IND-01",
            interactionType = "drag_and_drop_count",
            isCorrect = false,
            misconceptionCode = "OVERCOUNT_BY_ONE",
            hintsUsed = 2,
            nowMs = now + 1000L
        )
        assertEquals(AdaptiveAction.TRIGGER_REMEDIAL, dec2.nextAction)
        assertTrue(dec2.updatedMastery.remedialRecommended)
    }

    @Test
    fun lessonCompletion_neverHardcodesAndRequiresAllGates() {
        // Case 1: Assessment passed, but practice incomplete -> NOT completed, 0 stars
        val incompletePractice = AdaptiveLearningEngine.evaluateLessonCompletion(
            existing = null,
            lessonId = "G1-L01",
            totalPracticeQuestions = 30,
            practiceAnsweredCount = 12,
            practiceCorrectCount = 12,
            examplesViewed = true,
            guidedCompleted = true,
            assessmentScorePercent = 100
        )
        assertFalse(incompletePractice.completed)
        assertEquals(0, incompletePractice.starsEarned)

        // Case 2: All 30 practice done, but assessment failed (60% < 80%) -> NOT completed, 0 stars
        val failedAssessment = AdaptiveLearningEngine.evaluateLessonCompletion(
            existing = null,
            lessonId = "G1-L01",
            totalPracticeQuestions = 30,
            practiceAnsweredCount = 30,
            practiceCorrectCount = 28,
            examplesViewed = true,
            guidedCompleted = true,
            assessmentScorePercent = 60
        )
        assertFalse(failedAssessment.assessmentPassed)
        assertFalse(failedAssessment.completed)
        assertEquals(0, failedAssessment.starsEarned)

        // Case 3: Examples + Guided + 30/30 Practice + 100% Assessment -> Completed with 3 stars
        val fullMastery = AdaptiveLearningEngine.evaluateLessonCompletion(
            existing = null,
            lessonId = "G1-L01",
            totalPracticeQuestions = 30,
            practiceAnsweredCount = 30,
            practiceCorrectCount = 29,
            examplesViewed = true,
            guidedCompleted = true,
            assessmentScorePercent = 100
        )
        assertTrue(fullMastery.completed)
        assertTrue(fullMastery.assessmentPassed)
        assertEquals(3, fullMastery.starsEarned)
    }

    @Test
    fun parentGateLogic_generatesDynamicChallengesAndValidatesPersianDigits() {
        val c1 = ParentGateLogic.generateChallenge(100L)
        val c2 = ParentGateLogic.generateChallenge(200L)
        assertNotEquals(c1, c2)

        val expectedAscii = c1.expectedAnswer.toString()
        val expectedPersian = c1.expectedAnswer.toFa()
        assertTrue(ParentGateLogic.checkAnswer(expectedAscii, c1))
        assertTrue(ParentGateLogic.checkAnswer("  $expectedPersian  ", c1))
        assertFalse(ParentGateLogic.checkAnswer((c1.expectedAnswer + 1).toString(), c1))
        assertFalse(ParentGateLogic.checkAnswer("invalid", c1))
    }

    @Test
    fun persianUtils_convertsBidirectionally() {
        assertEquals("۱۲۳۴۵۶۷۸۹۰", "1234567890".toFa())
        assertEquals("1234567890", "۱۲۳۴۵۶۷۸۹۰".toAsciiDigits())
    }

    @Test
    fun contentV2_all39LessonsAndBanksPassFullAudit() {
        val baseDir = resolveAssetsDir()
        val manifestFile = File(baseDir, "CONTENT_MANIFEST.json")
        assertTrue("Manifest must exist", manifestFile.exists())

        val manifest = json.decodeFromString<ContentManifest>(manifestFile.readText())
        assertEquals(39, manifest.totalLessons)
        assertEquals(39, manifest.lessons.size)

        val chapters = manifest.lessons.map { it.chapterNumber }.distinct().sorted()
        assertEquals(listOf(1, 2, 3, 4, 5, 6, 7, 8), chapters)

        val seenIds = mutableSetOf<String>()
        var totalIndependent = 0
        var totalGuided = 0
        var totalRemedial = 0
        var totalAssessment = 0

        for (entry in manifest.lessons) {
            val lessonFile = File(baseDir, "lessons/${entry.lessonId}_lesson.json")
            assertTrue("Lesson file missing: ${lessonFile.path}", lessonFile.exists())
            val lesson = json.decodeFromString<LessonContentV2>(lessonFile.readText())
            assertEquals(entry.lessonId, lesson.lessonId)
            assertTrue(lesson.learningObjectivesFa.isNotEmpty())
            assertTrue(lesson.warmUpStoryFa.isNotBlank())
            assertEquals(3, lesson.workedExamples.size)
            assertEquals(3, lesson.guidedActivities.size)
            assertEquals(30, lesson.independentPracticeQuestions.size)

            lesson.workedExamples.forEach { ex ->
                assertTrue("Duplicate ID: ${ex.exampleId}", seenIds.add(ex.exampleId))
                assertFalse("Placeholder found in ${ex.exampleId}", ex.finalAnswer.contains("EX_ANS_"))
            }

            lesson.guidedActivities.forEach { gq ->
                assertTrue("Duplicate ID: ${gq.questionId}", seenIds.add(gq.questionId))
                totalGuided++
            }

            lesson.independentPracticeQuestions.forEach { iq ->
                assertTrue("Duplicate ID: ${iq.questionId}", seenIds.add(iq.questionId))
                if (iq.interactionType == "visual_multiple_choice" || iq.interactionType == "pattern_completer") {
                    assertTrue("Missing explicit options on ${iq.questionId}", iq.options.size >= 3)
                    assertNotNull("Missing correct optionId on ${iq.questionId}", iq.correctAnswer.optionId)
                }
                totalIndependent++
            }

            val remFile = File(baseDir, lesson.remedialQuestionsRef)
            assertTrue("Remedial file missing: ${remFile.path}", remFile.exists())
            val remBank = json.decodeFromString<RemedialBank>(remFile.readText())
            assertEquals(5, remBank.questions.size)
            remBank.questions.forEach { rq ->
                assertTrue("Duplicate ID: ${rq.questionId}", seenIds.add(rq.questionId))
                assertTrue("Remedial question must have options: ${rq.questionId}", rq.options.size >= 3)
                rq.options.forEach { opt ->
                    assertFalse("Spoiler found in ${rq.questionId}", opt.labelFa.contains("(صحیح)") || opt.labelFa.contains("(نادرست)"))
                }
                totalRemedial++
            }

            val asmFile = File(baseDir, lesson.assessmentQuestionsRef)
            assertTrue("Assessment file missing: ${asmFile.path}", asmFile.exists())
            val asmBank = json.decodeFromString<AssessmentBank>(asmFile.readText())
            assertEquals(5, asmBank.questions.size)
            assertEquals(80, asmBank.passingScorePercent)
            asmBank.questions.forEach { aq ->
                assertTrue("Duplicate ID: ${aq.questionId}", seenIds.add(aq.questionId))
                if (aq.interactionType == "visual_multiple_choice" || aq.interactionType == "pattern_completer") {
                    assertTrue("Assessment MC missing options: ${aq.questionId}", aq.options.size >= 3)
                }
                totalAssessment++
            }
        }

        assertEquals(1170, totalIndependent)
        assertEquals(117, totalGuided)
        assertEquals(195, totalRemedial)
        assertEquals(195, totalAssessment)
    }
}

class InMemoryFakeRiaziDao : RiaziDao {
    private val masteryMap = mutableMapOf<String, SkillMasteryEntity>()
    private val masteryFlow = MutableStateFlow<List<SkillMasteryEntity>>(emptyList())
    private val logs = mutableListOf<AttemptLogEntity>()
    private val progressMap = mutableMapOf<String, LessonProgressEntity>()
    private val progressFlow = MutableStateFlow<List<LessonProgressEntity>>(emptyList())
    private val reviewsMap = mutableMapOf<String, ReviewQueueEntity>()
    private val reviewsFlow = MutableStateFlow<List<ReviewQueueEntity>>(emptyList())
    private val achievementsMap = mutableMapOf<String, AchievementEntity>()
    private val achievementsFlow = MutableStateFlow<List<AchievementEntity>>(emptyList())

    override fun observeAllMastery(): Flow<List<SkillMasteryEntity>> = masteryFlow
    override suspend fun getSkillMastery(skillId: String): SkillMasteryEntity? = masteryMap[skillId]
    override suspend fun upsertSkillMastery(entity: SkillMasteryEntity) {
        masteryMap[entity.skillId] = entity
        masteryFlow.value = masteryMap.values.toList()
    }
    override suspend fun insertAttemptLog(log: AttemptLogEntity) { logs.add(log) }
    override fun observeLessonProgress(): Flow<List<LessonProgressEntity>> = progressFlow
    override suspend fun getLessonProgress(lessonId: String): LessonProgressEntity? = progressMap[lessonId]
    override suspend fun upsertLessonProgress(progress: LessonProgressEntity) {
        progressMap[progress.lessonId] = progress
        progressFlow.value = progressMap.values.toList()
    }
    override fun observeDueReviews(nowMs: Long): Flow<List<ReviewQueueEntity>> =
        reviewsFlow.map { list -> list.filter { it.dueEpochMs <= nowMs } }
    fun getDueReviewsSnapshot(nowMs: Long): List<ReviewQueueEntity> =
        reviewsMap.values.filter { it.dueEpochMs <= nowMs }
    override suspend fun upsertReviewQueue(item: ReviewQueueEntity) {
        reviewsMap[item.skillId] = item
        reviewsFlow.value = reviewsMap.values.toList()
    }
    override fun observeAchievements(): Flow<List<AchievementEntity>> = achievementsFlow
    override suspend fun insertAchievement(achievement: AchievementEntity) {
        achievementsMap.putIfAbsent(achievement.achievementId, achievement)
        achievementsFlow.value = achievementsMap.values.toList()
    }
    override suspend fun insertSession(session: LearningSessionEntity): Long = 1L
    override suspend fun clearAllMastery() { masteryMap.clear(); masteryFlow.value = emptyList() }
    override suspend fun clearAllAttemptLogs() { logs.clear() }
    override suspend fun clearAllLessonProgress() { progressMap.clear(); progressFlow.value = emptyList() }
    override suspend fun clearAllReviews() { reviewsMap.clear(); reviewsFlow.value = emptyList() }
    override suspend fun clearAllAchievements() { achievementsMap.clear(); achievementsFlow.value = emptyList() }
}
