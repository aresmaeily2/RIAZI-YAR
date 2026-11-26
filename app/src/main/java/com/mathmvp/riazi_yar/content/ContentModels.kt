package com.mathmvp.riazi_yar.content

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ContentManifest(
    @SerialName("package_name") val packageName: String,
    val version: String,
    @SerialName("total_lessons") val totalLessons: Int,
    @SerialName("total_json_files") val totalJsonFiles: Int,
    val lessons: List<ManifestLessonEntry>
)

@Serializable
data class ManifestLessonEntry(
    @SerialName("lesson_id") val lessonId: String,
    @SerialName("lesson_number") val lessonNumber: Int,
    @SerialName("chapter_number") val chapterNumber: Int,
    @SerialName("title_fa") val titleFa: String
)

@Serializable
data class LessonStatus(
    @SerialName("technical_validation") val technicalValidation: String,
    @SerialName("pedagogical_review") val pedagogicalReview: String,
    @SerialName("production_readiness") val productionReadiness: String,
    @SerialName("teacher_reviewer_id") val teacherReviewerId: String? = null
)

@Serializable
data class LessonSummary(
    @SerialName("key_concepts") val keyConcepts: List<String>,
    @SerialName("visual_takeaway") val visualTakeaway: String,
    @SerialName("parent_tip") val parentTip: String
)

@Serializable
data class WorkedExample(
    @SerialName("example_id") val exampleId: String,
    @SerialName("prompt_fa") val promptFa: String,
    @SerialName("step_by_step_solution_fa") val stepsFa: List<String>,
    @SerialName("final_answer") val finalAnswer: String
)

@Serializable
data class InteractionPayload(
    @SerialName("target_value") val targetValue: Int = 1,
    @SerialName("items_count") val itemsCount: Int = 3,
    val criteria: String = ""
)

@Serializable
data class CorrectAnswer(
    val value: Int? = null,
    @SerialName("option_id") val optionId: String? = null,
    @SerialName("canonical_form") val canonicalForm: String = ""
)

@Serializable
data class FeedbackPolicy(
    val mode: String = "IMMEDIATE",
    @SerialName("show_immediate_feedback") val showImmediateFeedback: Boolean = true,
    @SerialName("max_attempts") val maxAttempts: Int = 3,
    @SerialName("hint_on_first_error_fa") val hintOnFirstErrorFa: String = "",
    @SerialName("scaffolded_hint_fa") val scaffoldedHintFa: String = "",
    @SerialName("success_message_fa") val successMessageFa: String = "آفرین! پاسخ درست است.",
    @SerialName("post_submit_feedback_fa") val postSubmitFeedbackFa: String = ""
)

@Serializable
data class PracticeQuestion(
    @SerialName("question_id") val questionId: String,
    @SerialName("lesson_id") val lessonId: String,
    val section: String = "independent_practice",
    val difficulty: String = "easy",
    @SerialName("interaction_type") val interactionType: String,
    @SerialName("prompt_fa") val promptFa: String,
    @SerialName("interaction_payload") val payload: InteractionPayload = InteractionPayload(),
    @SerialName("correct_answer") val correctAnswer: CorrectAnswer,
    @SerialName("feedback_policy") val feedbackPolicy: FeedbackPolicy = FeedbackPolicy()
)

@Serializable
data class RemedialOption(
    val id: String,
    @SerialName("label_fa") val labelFa: String
)

@Serializable
data class RemedialQuestion(
    @SerialName("question_id") val questionId: String,
    @SerialName("lesson_id") val lessonId: String,
    @SerialName("target_misconception_code") val targetMisconceptionCode: String,
    @SerialName("interaction_type") val interactionType: String,
    @SerialName("prompt_fa") val promptFa: String,
    val options: List<RemedialOption> = emptyList(),
    @SerialName("correct_answer") val correctAnswer: CorrectAnswer,
    @SerialName("feedback_policy") val feedbackPolicy: FeedbackPolicy
)

@Serializable
data class RemedialBank(
    @SerialName("lesson_id") val lessonId: String,
    @SerialName("actual_count") val actualCount: Int,
    val questions: List<RemedialQuestion>
)

@Serializable
data class AssessmentBank(
    @SerialName("lesson_id") val lessonId: String,
    @SerialName("actual_count") val actualCount: Int,
    @SerialName("feedback_display_policy") val feedbackDisplayPolicy: String,
    val questions: List<PracticeQuestion>
)

@Serializable
data class LessonContentV2(
    @SerialName("lesson_id") val lessonId: String,
    @SerialName("lesson_number") val lessonNumber: Int,
    @SerialName("chapter_number") val chapterNumber: Int,
    @SerialName("title_fa") val titleFa: String,
    val status: LessonStatus,
    @SerialName("lesson_summary") val lessonSummary: LessonSummary,
    @SerialName("worked_examples") val workedExamples: List<WorkedExample>,
    @SerialName("independent_practice_questions") val independentPracticeQuestions: List<PracticeQuestion>,
    @SerialName("remedial_questions_ref") val remedialQuestionsRef: String,
    @SerialName("assessment_questions_ref") val assessmentQuestionsRef: String
)
