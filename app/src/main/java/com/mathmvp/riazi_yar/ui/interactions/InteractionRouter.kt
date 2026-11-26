package com.mathmvp.riazi_yar.ui.interactions

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.mathmvp.riazi_yar.R
import com.mathmvp.riazi_yar.content.PracticeQuestion
import com.mathmvp.riazi_yar.core.PersianUtils.toFa
import kotlin.math.roundToInt

@Composable
fun InteractionRouter(
    question: PracticeQuestion,
    onEvaluated: (outcome: ValidationOutcome, hintsUsed: Int) -> Unit
) {
    var hintsUsed by rememberSaveable(question.questionId) { mutableIntStateOf(0) }
    var hintStage by rememberSaveable(question.questionId) { mutableIntStateOf(0) }

    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        when (question.interactionType) {
            "drag_and_drop_count" -> DragAndDropCountView(question) { onEvaluated(it, hintsUsed) }
            "number_line_jump" -> NumberLineJumpView(question) { onEvaluated(it, hintsUsed) }
            "tally_mark_builder" -> TallyMarkBuilderView(question) { onEvaluated(it, hintsUsed) }
            "pattern_completer" -> PatternCompleterView(question) { onEvaluated(it, hintsUsed) }
            "balance_scale_equation" -> BalanceScaleView(question) { onEvaluated(it, hintsUsed) }
            "visual_multiple_choice" -> VisualMultipleChoiceView(question) { onEvaluated(it, hintsUsed) }
            else -> Card(
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = "خطای محتوا: نوع تعامل «${question.interactionType}» پشتیبانی نمی‌شود.",
                    color = MaterialTheme.colorScheme.onErrorContainer,
                    modifier = Modifier.padding(16.dp)
                )
            }
        }

        if (question.feedbackPolicy.showImmediateFeedback) {
            OutlinedButton(
                onClick = {
                    hintsUsed++
                    hintStage = (hintStage + 1).coerceAtMost(2)
                },
                modifier = Modifier
                    .heightIn(min = 56.dp)
                    .semantics { contentDescription = "درخواست راهنمایی مرحله‌ای" }
            ) {
                Text("💡 راهنمای گام‌به‌گام (${hintsUsed.toFa()})")
            }

            if (hintStage >= 1 && question.feedbackPolicy.hintOnFirstErrorFa.isNotBlank()) {
                Card(
                    colors = CardDefaults.cardColors(containerColor = Color(0xFFFFF8E1)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("راهنمای سطح ۱: ${question.feedbackPolicy.hintOnFirstErrorFa}", color = Color(0xFFE65100))
                        if (hintStage >= 2 && question.feedbackPolicy.scaffoldedHintFa.isNotBlank()) {
                            Text("راهنمای سطح ۲: ${question.feedbackPolicy.scaffoldedHintFa}", color = Color(0xFF2E7D32))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun DragAndDropCountView(q: PracticeQuestion, onResult: (ValidationOutcome) -> Unit) {
    val target = q.correctAnswer.value ?: q.payload.targetValue
    val totalPool = q.payload.itemsCount.coerceAtLeast(target + 2).coerceIn(3, 18)
    var droppedCount by rememberSaveable(q.questionId) { mutableIntStateOf(0) }

    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("سیب‌ها را لمس کنید یا به داخل سبد بکشید (${droppedCount.toFa()} سیب در سبد)")
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            val remaining = (totalPool - droppedCount).coerceIn(0, 8)
            for (idx in 1..remaining) {
                var offsetX by remember(q.questionId, droppedCount, idx) { mutableFloatStateOf(0f) }
                var offsetY by remember(q.questionId, droppedCount, idx) { mutableFloatStateOf(0f) }
                Box(
                    modifier = Modifier
                        .offset { IntOffset(offsetX.roundToInt(), offsetY.roundToInt()) }
                        .size(56.dp)
                        .clickable { if (droppedCount < totalPool) droppedCount++ }
                        .pointerInput(q.questionId, droppedCount, idx) {
                            detectDragGestures(
                                onDragEnd = {
                                    if (offsetY > 30f && droppedCount < totalPool) droppedCount++
                                    offsetX = 0f
                                    offsetY = 0f
                                },
                                onDrag = { change, dragAmount ->
                                    change.consume()
                                    offsetX += dragAmount.x
                                    offsetY += dragAmount.y
                                }
                            )
                        }
                        .semantics { contentDescription = "سیب شمارشی شماره ${idx.toFa()}" }
                ) {
                    Image(
                        painter = painterResource(R.drawable.ic_apple_counter),
                        contentDescription = null,
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(92.dp)
                .border(2.dp, MaterialTheme.colorScheme.primary, RoundedCornerShape(16.dp))
                .background(Color(0xFFE3F2FD), RoundedCornerShape(16.dp)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "🧺 سبد شمارش: ${droppedCount.toFa()} سیب",
                style = MaterialTheme.typography.titleMedium
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            OutlinedButton(
                onClick = { if (droppedCount > 0) droppedCount-- },
                modifier = Modifier.heightIn(min = 56.dp)
            ) { Text("➖ برداشتن یکی") }
            OutlinedButton(
                onClick = { if (droppedCount < totalPool) droppedCount++ },
                modifier = Modifier.heightIn(min = 56.dp)
            ) { Text("➕ افزودن یکی") }
            Button(
                onClick = { onResult(InteractionValidator.validateDragCount(droppedCount, target)) },
                modifier = Modifier.weight(1f).heightIn(min = 56.dp)
            ) { Text("بررسی پاسخ") }
        }
    }
}

@Composable
private fun NumberLineJumpView(q: PracticeQuestion, onResult: (ValidationOutcome) -> Unit) {
    var pos by rememberSaveable(q.questionId) { mutableIntStateOf(0) }
    val target = q.correctAnswer.value ?: q.payload.targetValue
    val maxTick = 20

    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("موقعیت فعلی مهره روی محور اعداد: ${pos.toFa()}", style = MaterialTheme.typography.titleMedium)
        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(80.dp)
                .semantics { contentDescription = "محور اعداد از ۰ تا ۲۰، مکان فعلی ${pos.toFa()}" }
        ) {
            val y = size.height * 0.65f
            drawLine(Color.DarkGray, Offset(20f, y), Offset(size.width - 20f, y), strokeWidth = 6f)
            val step = (size.width - 40f) / maxTick
            for (i in 0..maxTick) {
                val x = 20f + i * step
                val tickH = if (i % 5 == 0) 18f else 10f
                drawLine(Color.Gray, Offset(x, y - tickH), Offset(x, y + tickH), strokeWidth = if (i % 5 == 0) 4f else 2f)
            }
            val markerX = 20f + pos * step
            drawCircle(Color(0xFFFB8C00), radius = 16f, center = Offset(markerX, y - 16f))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            OutlinedButton(onClick = { pos = (pos - 1).coerceAtLeast(0) }, modifier = Modifier.weight(1f).heightIn(min = 56.dp)) { Text("⬅️ ۱ واحد چپ") }
            Button(onClick = { pos = (pos + 1).coerceAtMost(maxTick) }, modifier = Modifier.weight(1f).heightIn(min = 56.dp)) { Text("۱ واحد راست ➡️") }
            OutlinedButton(onClick = { pos = (pos + 5).coerceAtMost(maxTick) }, modifier = Modifier.heightIn(min = 56.dp)) { Text("+۵") }
        }
        Button(
            onClick = { onResult(InteractionValidator.validateNumberLine(pos, target)) },
            modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
        ) { Text("تأیید موقعیت روی محور") }
    }
}

@Composable
private fun TallyMarkBuilderView(q: PracticeQuestion, onResult: (ValidationOutcome) -> Unit) {
    var bundles by rememberSaveable(q.questionId) { mutableIntStateOf(0) }
    var singles by rememberSaveable(q.questionId) { mutableIntStateOf(0) }
    val target = q.correctAnswer.value ?: q.payload.targetValue
    val currentTotal = bundles * 5 + singles

    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("دسته‌های ۵تایی: ${bundles.toFa()} | چوب‌خط تکی: ${singles.toFa()} | مجموع فعلی: ${currentTotal.toFa()}")
        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(68.dp)
                .background(Color(0xFFF5F5F5), RoundedCornerShape(12.dp))
        ) {
            var x = 24f
            repeat(bundles) {
                for (i in 0..3) drawLine(Color(0xFF1E88E5), Offset(x + i * 10f, 12f), Offset(x + i * 10f, 54f), 5f)
                drawLine(Color(0xFFE53935), Offset(x - 4f, 48f), Offset(x + 36f, 16f), 5f)
                x += 58f
            }
            repeat(singles) {
                drawLine(Color(0xFF1E88E5), Offset(x, 12f), Offset(x, 54f), 5f)
                x += 12f
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Button(onClick = { bundles++ }, modifier = Modifier.weight(1f).heightIn(min = 56.dp)) { Text("+ دسته ۵تایی") }
            Button(onClick = { singles++ }, modifier = Modifier.weight(1f).heightIn(min = 56.dp)) { Text("+ چوب‌خط تکی") }
            OutlinedButton(onClick = { bundles = 0; singles = 0 }, modifier = Modifier.heightIn(min = 56.dp)) { Text("پاک کردن") }
        }
        Button(
            onClick = { onResult(InteractionValidator.validateTallyMarks(bundles, singles, target)) },
            modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
        ) { Text("بررسی چوب‌خط") }
    }
}

@Composable
private fun PatternCompleterView(q: PracticeQuestion, onResult: (ValidationOutcome) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Card(
            colors = CardDefaults.cardColors(containerColor = Color(0xFFE8F5E9)),
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(
                text = "الگو: ${q.payload.criteria}",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.padding(16.dp)
            )
        }
        if (q.options.isEmpty()) {
            Text(
                text = "خطای داده: گزینه‌های این الگو در فایل JSON تعریف نشده‌اند.",
                color = MaterialTheme.colorScheme.error
            )
        } else {
            q.options.forEach { opt ->
                Button(
                    onClick = {
                        onResult(InteractionValidator.validateOptionSelection(opt, q.correctAnswer, isPattern = true))
                    },
                    modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
                ) {
                    Text(opt.labelFa)
                }
            }
        }
    }
}

@Composable
private fun BalanceScaleView(q: PracticeQuestion, onResult: (ValidationOutcome) -> Unit) {
    var rightWeight by rememberSaveable(q.questionId) { mutableIntStateOf(0) }
    val leftTarget = q.correctAnswer.value ?: q.payload.targetValue
    val diff = rightWeight - leftTarget
    val tiltOffset = diff.coerceIn(-5, 5) * 7f

    val balanceStatusFa = when {
        diff == 0 -> "⚖️ ترازو کاملاً در حالت تعادل است! (${leftTarget.toFa()} = ${rightWeight.toFa()})"
        diff < 0 -> "⬇️ کفه چپ سنگین‌تر است؛ به کفه راست وزنه اضافه کن"
        else -> "⬇️ کفه راست سنگین‌تر شد؛ از کفه راست وزنه کم کن"
    }

    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            text = "کفه چپ (هدف): ${leftTarget.toFa()} | کفه راست (شما): ${rightWeight.toFa()}",
            style = MaterialTheme.typography.titleMedium
        )
        Text(
            text = balanceStatusFa,
            color = if (diff == 0) Color(0xFF2E7D32) else Color(0xFFE65100)
        )

        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(140.dp)
                .background(Color(0xFFF1F8E9), RoundedCornerShape(16.dp))
                .pointerInput(q.questionId) {
                    detectDragGestures(
                        onDragEnd = { rightWeight = (rightWeight + 1).coerceAtMost(25) },
                        onDrag = { change, _ -> change.consume() }
                    )
                }
                .semantics { contentDescription = "ترازوی دوکفه‌ای، کفه چپ ${leftTarget.toFa()} و کفه راست ${rightWeight.toFa()}" }
        ) {
            val cx = size.width / 2f
            val baseY = size.height - 20f
            val pivotY = size.height * 0.48f

            // Fulcrum triangle
            val triangle = Path().apply {
                moveTo(cx, pivotY)
                lineTo(cx - 28f, baseY)
                lineTo(cx + 28f, baseY)
                close()
            }
            drawPath(triangle, color = Color(0xFF5D4037))

            // Beam
            val leftBeamX = cx - 120f
            val rightBeamX = cx + 120f
            val leftBeamY = pivotY - tiltOffset
            val rightBeamY = pivotY + tiltOffset
            drawLine(
                color = if (diff == 0) Color(0xFF2E7D32) else Color(0xFF1E88E5),
                start = Offset(leftBeamX, leftBeamY),
                end = Offset(rightBeamX, rightBeamY),
                strokeWidth = 8f
            )

            // Left Pan & Target Blocks
            drawLine(Color.Gray, Offset(leftBeamX, leftBeamY), Offset(leftBeamX, leftBeamY + 28f), strokeWidth = 4f)
            drawRoundRect(
                color = Color(0xFF8D6E63),
                topLeft = Offset(leftBeamX - 44f, leftBeamY + 28f),
                size = Size(88f, 12f),
                cornerRadius = CornerRadius(6f, 6f)
            )
            val leftBlocks = leftTarget.coerceIn(1, 10)
            for (b in 0 until leftBlocks) {
                val bx = (leftBeamX - 36f) + (b % 5) * 15f
                val by = (leftBeamY + 12f) - (b / 5) * 15f
                drawRoundRect(
                    color = Color(0xFFFB8C00),
                    topLeft = Offset(bx, by),
                    size = Size(13f, 13f),
                    cornerRadius = CornerRadius(3f, 3f)
                )
            }

            // Right Pan & User Weight Blocks
            drawLine(Color.Gray, Offset(rightBeamX, rightBeamY), Offset(rightBeamX, rightBeamY + 28f), strokeWidth = 4f)
            drawRoundRect(
                color = Color(0xFF8D6E63),
                topLeft = Offset(rightBeamX - 44f, rightBeamY + 28f),
                size = Size(88f, 12f),
                cornerRadius = CornerRadius(6f, 6f)
            )
            val rightBlocks = rightWeight.coerceIn(0, 10)
            for (b in 0 until rightBlocks) {
                val bx = (rightBeamX - 36f) + (b % 5) * 15f
                val by = (rightBeamY + 12f) - (b / 5) * 15f
                drawRoundRect(
                    color = Color(0xFF1E88E5),
                    topLeft = Offset(bx, by),
                    size = Size(13f, 13f),
                    cornerRadius = CornerRadius(3f, 3f)
                )
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = { rightWeight = (rightWeight + 1).coerceAtMost(25) }, modifier = Modifier.weight(1f).heightIn(min = 56.dp)) { Text("+ وزنه ۱") }
            Button(onClick = { rightWeight = (rightWeight + 2).coerceAtMost(25) }, modifier = Modifier.weight(1f).heightIn(min = 56.dp)) { Text("+ وزنه ۲") }
            Button(onClick = { rightWeight = (rightWeight + 5).coerceAtMost(25) }, modifier = Modifier.weight(1f).heightIn(min = 56.dp)) { Text("+ وزنه ۵") }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(onClick = { if (rightWeight > 0) rightWeight-- }, modifier = Modifier.weight(1f).heightIn(min = 56.dp)) { Text("➖ کم کردن ۱") }
            OutlinedButton(onClick = { rightWeight = 0 }, modifier = Modifier.weight(1f).heightIn(min = 56.dp)) { Text("خالی کردن کفه") }
        }
        Button(
            onClick = { onResult(InteractionValidator.validateBalanceScale(rightWeight, leftTarget)) },
            modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
        ) { Text("بررسی تعادل ترازو") }
    }
}

@Composable
private fun VisualMultipleChoiceView(q: PracticeQuestion, onResult: (ValidationOutcome) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        if (q.options.isEmpty()) {
            Card(
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = "خطای محتوا: گزینه‌های سؤال چندگزینه‌ای در فایل JSON یافت نشد.",
                    color = MaterialTheme.colorScheme.onErrorContainer,
                    modifier = Modifier.padding(16.dp)
                )
            }
        } else {
            q.options.forEach { opt ->
                Button(
                    onClick = {
                        onResult(InteractionValidator.validateOptionSelection(opt, q.correctAnswer, isPattern = false))
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 56.dp)
                        .semantics { contentDescription = "گزینه ${opt.labelFa}" }
                ) {
                    Text(opt.labelFa)
                }
            }
        }
    }
}
