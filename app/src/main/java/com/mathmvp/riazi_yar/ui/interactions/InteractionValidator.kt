package com.mathmvp.riazi_yar.ui.interactions

import com.mathmvp.riazi_yar.content.CorrectAnswer
import com.mathmvp.riazi_yar.content.QuestionOption

data class ValidationOutcome(val isCorrect: Boolean, val misconceptionCode: String?)

object InteractionValidator {
    fun validateDragCount(dropped: Int, target: Int): ValidationOutcome = when {
        dropped < 0 -> ValidationOutcome(false, "INVALID_INPUT")
        dropped == target -> ValidationOutcome(true, null)
        dropped == target + 1 -> ValidationOutcome(false, "OVERCOUNT_BY_ONE")
        dropped == target - 1 -> ValidationOutcome(false, "UNDERCOUNT_BY_ONE")
        else -> ValidationOutcome(false, "COUNT_MISMATCH")
    }

    fun validateNumberLine(finalPos: Int, targetPos: Int): ValidationOutcome = when {
        finalPos < 0 || finalPos > 20 -> ValidationOutcome(false, "OUT_OF_RANGE")
        finalPos == targetPos -> ValidationOutcome(true, null)
        finalPos == targetPos - 1 || finalPos == targetPos + 1 -> ValidationOutcome(false, "COUNTING_START_NODE")
        else -> ValidationOutcome(false, "WRONG_DIRECTION")
    }

    fun validateTallyMarks(bundlesOfFive: Int, singles: Int, target: Int): ValidationOutcome {
        if (bundlesOfFive < 0 || singles < 0) return ValidationOutcome(false, "INVALID_INPUT")
        val total = bundlesOfFive * 5 + singles
        return when {
            total == target && singles < 5 -> ValidationOutcome(true, null)
            total == target && singles >= 5 -> ValidationOutcome(false, "UNBUNDLED_FIVE")
            bundlesOfFive + singles == target -> ValidationOutcome(false, "BUNDLE_COUNTED_AS_ONE")
            else -> ValidationOutcome(false, "TALLY_MISMATCH")
        }
    }

    fun validateBalanceScale(rightTotal: Int, leftTarget: Int): ValidationOutcome = when {
        rightTotal < 0 -> ValidationOutcome(false, "INVALID_INPUT")
        rightTotal == leftTarget -> ValidationOutcome(true, null)
        kotlin.math.abs(rightTotal - leftTarget) == 1 -> ValidationOutcome(false, "OFF_BY_ONE_BALANCE")
        else -> ValidationOutcome(false, "EQUILIBRIUM_ERROR")
    }

    fun validatePatternChoice(selected: Int, expected: Int): ValidationOutcome =
        if (selected == expected) ValidationOutcome(true, null) else ValidationOutcome(false, "PATTERN_MISMATCH")

    fun validateMultipleChoice(selected: Int, expected: Int): ValidationOutcome =
        if (selected == expected) ValidationOutcome(true, null) else ValidationOutcome(false, "DISTRACTOR_SELECTED")

    fun validateOptionSelection(
        selectedOption: QuestionOption,
        correctAnswer: CorrectAnswer,
        isPattern: Boolean = false
    ): ValidationOutcome {
        val mismatchCode = if (isPattern) "PATTERN_MISMATCH" else "DISTRACTOR_SELECTED"
        if (selectedOption.id.isBlank()) return ValidationOutcome(false, "INVALID_INPUT")
        val matchById = !correctAnswer.optionId.isNullOrBlank() && selectedOption.id == correctAnswer.optionId
        val matchByValue = correctAnswer.optionId.isNullOrBlank() &&
            correctAnswer.value != null &&
            selectedOption.value == correctAnswer.value
        return if (matchById || matchByValue) {
            ValidationOutcome(true, null)
        } else {
            ValidationOutcome(false, mismatchCode)
        }
    }
}
