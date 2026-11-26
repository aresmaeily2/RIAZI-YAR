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

    val dueReviews: StateFlow<List<ReviewQueueEntity>> =
        dao.observeDueReviews(System.currentTimeMillis() + 86_400_000L * 30)
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val achievements: StateFlow<List<AchievementEntity>> =
        dao.observeAchievements().stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val settings: StateFlow<AppSettings> =
        prefsRepo.settingsFlow.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), AppSettings())

    private val _lastDecision = MutableStateFlow<AdaptiveDecision?>(null)
    val lastDecision: StateFlow<AdaptiveDecision?> = _lastDecision.asStateFlow()

    init {
        viewModelScope.launch {
            runCatching { contentRepo.loadManifest() }
                .onSuccess { _manifestState.value = UiState.Success(it) }
                .onFailure { _manifestState.value = UiState.Error(it.message ?: "خطا در بارگذاری محتوای V2") }
        }
    }

    suspend fun loadLesson(lessonId: String): LessonContentV2 = contentRepo.loadLesson(lessonId)
    suspend fun loadRemedial(lesson: LessonContentV2): RemedialBank = contentRepo.loadRemedial(lesson)
    suspend fun loadAssessment(lesson: LessonContentV2): AssessmentBank = contentRepo.loadAssessment(lesson)

    fun submitAnswer(
        lessonId: String,
        questionId: String,
        interactionType: String,
        isCorrect: Boolean,
        misconceptionCode: String?,
        hintsUsed: Int
    ) {
        viewModelScope.launch {
            val skillId = "SKILL_${lessonId}_$interactionType"
            _lastDecision.value = adaptiveEngine.recordAttempt(
                lessonId = lessonId,
                skillId = skillId,
                questionId = questionId,
                interactionType = interactionType,
                isCorrect = isCorrect,
                misconceptionCode = misconceptionCode,
                hintsUsed = hintsUsed
            )
        }
    }

    fun markLessonCompleted(lessonId: String) {
        viewModelScope.launch {
            dao.upsertLessonProgress(
                LessonProgressEntity(lessonId = lessonId, currentQuestionIndex = 30, examplesViewed = true, assessmentPassed = true, completed = true, starsEarned = 3)
            )
        }
    }

    fun updateSettings(newSettings: AppSettings) {
        viewModelScope.launch { prefsRepo.update(newSettings) }
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
