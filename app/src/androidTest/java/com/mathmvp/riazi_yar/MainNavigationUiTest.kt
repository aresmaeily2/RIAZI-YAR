package com.mathmvp.riazi_yar

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import org.junit.Rule
import org.junit.Test

class MainNavigationUiTest {
    @get:Rule val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test fun homeScreen_displaysChaptersButton() {
        composeTestRule.onNodeWithText("شروع یادگیری (۸ فصل / ۳۹ درس)").assertIsDisplayed().performClick()
        composeTestRule.onNodeWithText("انتخاب فصل").assertIsDisplayed()
    }
}
