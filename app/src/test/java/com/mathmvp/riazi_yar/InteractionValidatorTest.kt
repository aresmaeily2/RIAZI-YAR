package com.mathmvp.riazi_yar

import com.mathmvp.riazi_yar.ui.interactions.InteractionValidator
import org.junit.Assert.*
import org.junit.Test

class InteractionValidatorTest {
    @Test fun dragCount_allCases() {
        assertTrue(InteractionValidator.validateDragCount(5, 5).isCorrect)
        assertEquals("OVERCOUNT_BY_ONE", InteractionValidator.validateDragCount(6, 5).misconceptionCode)
        assertEquals("UNDERCOUNT_BY_ONE", InteractionValidator.validateDragCount(4, 5).misconceptionCode)
        assertEquals("INVALID_INPUT", InteractionValidator.validateDragCount(-1, 5).misconceptionCode)
    }
    @Test fun numberLine_allCases() {
        assertTrue(InteractionValidator.validateNumberLine(7, 7).isCorrect)
        assertEquals("COUNTING_START_NODE", InteractionValidator.validateNumberLine(6, 7).misconceptionCode)
        assertEquals("OUT_OF_RANGE", InteractionValidator.validateNumberLine(25, 7).misconceptionCode)
    }
    @Test fun tallyMarks_allCases() {
        assertTrue(InteractionValidator.validateTallyMarks(1, 3, 8).isCorrect)
        assertEquals("UNBUNDLED_FIVE", InteractionValidator.validateTallyMarks(0, 8, 8).misconceptionCode)
    }
    @Test fun balanceScale_allCases() {
        assertTrue(InteractionValidator.validateBalanceScale(9, 9).isCorrect)
        assertEquals("OFF_BY_ONE_BALANCE", InteractionValidator.validateBalanceScale(8, 9).misconceptionCode)
    }
}
