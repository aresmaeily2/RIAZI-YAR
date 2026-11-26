package com.mathmvp.riazi_yar.ui.theme

import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.mathmvp.riazi_yar.R

val RiaziBlue = Color(0xFF1E88E5)
val RiaziOrange = Color(0xFFFB8C00)
val RiaziGreen = Color(0xFF2E7D32)
val RiaziHintYellow = Color(0xFFF9A825)
val RiaziCreamSurface = Color(0xFFFAF9F6)

val VazirmatnFamily = FontFamily(
    Font(R.font.vazirmatn_regular, FontWeight.Normal),
    Font(R.font.vazirmatn_bold, FontWeight.Bold),
    Font(R.font.vazirmatn_extrabold, FontWeight.ExtraBold)
)

private val ChildTypography = Typography(
    headlineMedium = TextStyle(fontFamily = VazirmatnFamily, fontWeight = FontWeight.ExtraBold, fontSize = 24.sp),
    headlineSmall = TextStyle(fontFamily = VazirmatnFamily, fontWeight = FontWeight.Bold, fontSize = 20.sp),
    titleMedium = TextStyle(fontFamily = VazirmatnFamily, fontWeight = FontWeight.Bold, fontSize = 18.sp),
    bodyLarge = TextStyle(fontFamily = VazirmatnFamily, fontWeight = FontWeight.Normal, fontSize = 16.sp),
    labelLarge = TextStyle(fontFamily = VazirmatnFamily, fontWeight = FontWeight.Bold, fontSize = 16.sp)
)

private val ChildColorScheme = lightColorScheme(
    primary = RiaziBlue,
    secondary = RiaziOrange,
    tertiary = RiaziGreen,
    background = RiaziCreamSurface,
    surface = RiaziCreamSurface
)

@Composable
fun RiaziYarTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = ChildColorScheme, typography = ChildTypography, content = content)
}
