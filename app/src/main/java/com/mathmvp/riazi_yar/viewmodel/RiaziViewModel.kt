package com.mathmvp.riazi_yar.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.mathmvp.riazi_yar.adaptive.AdaptiveDecision
import com.mathmvp.riazi_yar.adaptive.AdaptiveLearningEngine
import com.mathmvp.riazi_yar.content.*
import com.mathmvp.riazi_yar.data.*
import com.mathmvp.riazi_yar.settings.AppSettings
import com.mathmvp.riazi_yar.settings.UserPreferencesRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Success<T>(val data: T) : UiState<T>
    data class Error(val message: String) : UiState<Nothing>
}

class RiaziViewModel(
    private val contentRepo: ContentRepository,
    private val adaptiveEngine: AdaptiveLearningEngine,
    private val dao: RiaziDao,
    private val prefsRepo: UserPreferencesRepository
) : ViewModel() {

    private val _manifestState = MutableStateFlow<UiState<ContentManifest>>(UiState.Loading)
    val manifestState: StateFlow<UiState<ContentManifest>> = _manifestState.asStateFlow()

    val masteryList: StateFlow<List<SkillMasteryEntity>> =
        dao.observeAllMastery().stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val lessonProgressList: StateFlow<List<LessonProgressEntity>> =
        dao.observeLessonProgress().stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Fixed (Section 7.10): Query only reviews due up to current time (System.currentTimeMillis()), not +30 days
    val dueReviews: StateFlow<List<ReviewQueueEntity>> =
        dao.observeDueReviews(System.currentTimeMillis())
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val achievements: StateFlow<List<AchievementEntity>> =
        dao.observeAchievements().stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val settings: StateFlow<AppSettings> =
        prefsRepo.settingsFlow.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), AppSettings())

    private val _lastDecision = MutableStateFlow<AdaptiveDecision?>(null)
    val lastDecision: StateFlow<AdaptiveDecision?> = _lastDecision.asStateFlow()

    init {
        retryLoadManifest()
    }

    fun retryLoadManifest() {
        _manifestState.value = UiState.Loading
        viewModelScope.launch {
            runCatching { contentRepo.loadManifest() }
                .onSuccess { _manifestState.value = UiState.Success(it) }
                .onFailure { _manifestState.value = UiState.Error(it.message ?: "خطا در بارگذاری محتوای V2") }
        }
    }

    suspend fun loadLessonState(lessonId: String): UiState<LessonContentV2> =
        runCatching { UiState.Success(contentRepo.loadLesson(lessonId)) }
            .getOrElse { UiState.Error(it.message ?: "خطا در بارگذاری درس $lessonId") }

    suspend fun loadRemedialState(lesson: LessonContentV2): UiState<RemedialBank> =
        runCatching { UiState.Success(contentRepo.loadRemedial(lesson)) }
            .getOrElse { UiState.Error(it.message ?: "خطا در بارگذاری تمرین جبرانی") }

    suspend fun loadAssessmentState(lesson: LessonContentV2): UiState<AssessmentBank> =
        runCatching { UiState.Success(contentRepo.loadAssessment(lesson)) }
            .getOrElse { UiState.Error(it.message ?: "خطا در بارگذاری سنجش پایانی") }

    suspend fun getOrInitLessonProgress(lessonId: String, totalQuestions: Int): LessonProgressEntity {
        val existing = dao.getLessonProgress(lessonId)
        if (existing != null) return existing
        val initial = LessonProgressEntity(
            lessonId = lessonId,
            totalQuestionsCount = totalQuestions
        )
        dao.upsertLessonProgress(initial)
        return initial
    }

    fun markExamplesViewed(lessonId: String, totalQuestions: Int) {
        viewModelScope.launch {
            val cur = getOrInitLessonProgress(lessonId, totalQuestions)
            dao.upsertLessonProgress(cur.copy(examplesViewed = true, lastVisitedEpochMs = System.currentTimeMillis()))
        }
    }

    fun markGuidedActivityCompleted(lessonId: String, totalQuestions: Int) {
        viewModelScope.launch {
            val cur = getOrInitLessonProgress(lessonId, totalQuestions)
            dao.upsertLessonProgress(cur.copy(guidedCompleted = true, lastVisitedEpochMs = System.currentTimeMillis()))
        }
    }

    fun submitAnswer(
        lessonId: String,
        skillCode: String,
        questionId: String,
        interactionType: String,
        isCorrect: Boolean,
        misconceptionCode: String?,
        hintsUsed: Int,
        questionIndex: Int = 0,
        totalQuestions: Int = 0,
        isIndependentPractice: Boolean = true
    ) {
        viewModelScope.launch {
            val resolvedSkillId = if (skillCode.isNotBlank()) {
                "${skillCode}_${interactionType}"
            } else {
                "SKILL_${lessonId}_$interactionType"
            }
            _lastDecision.value = adaptiveEngine.recordAttempt(
                lessonId = lessonId,
                skillId = resolvedSkillId,
                questionId = questionId,
                interactionType = interactionType,
                isCorrect = isCorrect,
                misconceptionCode = misconceptionCode,
                hintsUsed = hintsUsed
            )
            if (isIndependentPractice && totalQuestions > 0) {
                val cur = getOrInitLessonProgress(lessonId, totalQuestions)
                val nextIndex = if (isCorrect && questionIndex + 1 < totalQuestions) questionIndex + 1 else cur.currentQuestionIndex
                val newAnswered = maxOf(cur.practiceAnsweredCount, if (isCorrect) questionIndex + 1 else cur.practiceAnsweredCount)
                val newCorrect = if (isCorrect) maxOf(cur.practiceCorrectCount, questionIndex + 1) else cur.practiceCorrectCount
                dao.upsertLessonProgress(
                    cur.copy(
                        currentQuestionIndex = nextIndex,
                        totalQuestionsCount = totalQuestions,
                        practiceAnsweredCount = newAnswered,
                        practiceCorrectCount = newCorrect,
                        lastVisitedEpochMs = System.currentTimeMillis()
                    )
                )
            }
        }
    }

    /**
     * Fixed (Section 7.5 & 7.6): Computes lesson completion and stars strictly from real practice & assessment outcomes.
     */
    fun recordAssessmentAndEvaluateCompletion(
        lessonId: String,
        totalPracticeQuestions: Int,
        assessmentCorrectCount: Int,
        assessmentTotalCount: Int,
        passingThresholdPercent: Int = 80
    ) {
        viewModelScope.launch {
            val existing = getOrInitLessonProgress(lessonId, totalPracticeQuestions)
            val scorePct = if (assessmentTotalCount > 0) {
                ((assessmentCorrectCount * 100f) / assessmentTotalCount.toFloat()).toInt()
            } else 0
            val updated = AdaptiveLearningEngine.evaluateLessonCompletion(
                existing = existing,
                lessonId = lessonId,
                totalPracticeQuestions = totalPracticeQuestions,
                practiceAnsweredCount = existing.practiceAnsweredCount,
                practiceCorrectCount = existing.practiceCorrectCount,
                examplesViewed = existing.examplesViewed,
                guidedCompleted = existing.guidedCompleted,
                assessmentScorePercent = scorePct,
                passingThresholdPercent = passingThresholdPercent
            )
            dao.upsertLessonProgress(updated)
            if (updated.completed) {
                dao.insertAchievement(
                    AchievementEntity(
                        achievementId = "lesson_done_$lessonId",
                        titleFa = "تکمیل واقعی درس $lessonId با ${updated.starsEarned} ستاره (سنجش: $scorePct٪)",
                        unlockedAtEpochMs = System.currentTimeMillis()
                    )
                )
            }
        }
    }

    fun updateSettings(newSettings: AppSettings) {
        viewModelScope.launch { prefsRepo.update(newSettings) }
    }

    fun resetAllChildProgress() {
        viewModelScope.launch { dao.resetAllChildData() }
    }
}

class RiaziViewModelFactory(
    private val contentRepo: ContentRepository,
    private val adaptiveEngine: AdaptiveLearningEngine,
    private val dao: RiaziDao,
    private val prefsRepo: UserPreferencesRepository
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T =
        RiaziViewModel(contentRepo, adaptiveEngine, dao, prefsRepo) as T
}
