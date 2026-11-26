package com.mathmvp.riazi_yar.ui.interactions

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
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
    var hintsUsed by remember(question.questionId) { mutableIntStateOf(0) }
    var showHint by remember(question.questionId) { mutableStateOf(false) }

    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        when (question.interactionType) {
            "drag_and_drop_count" -> DragAndDropCountView(question) { onEvaluated(it, hintsUsed) }
            "number_line_jump" -> NumberLineJumpView(question) { onEvaluated(it, hintsUsed) }
            "tally_mark_builder" -> TallyMarkBuilderView(question) { onEvaluated(it, hintsUsed) }
            "pattern_completer" -> PatternCompleterView(question) { onEvaluated(it, hintsUsed) }
            "balance_scale_equation" -> BalanceScaleView(question) { onEvaluated(it, hintsUsed) }
            "visual_multiple_choice" -> VisualMultipleChoiceView(question) { onEvaluated(it, hintsUsed) }
            else -> Text("نوع تعامل پشتیبانی‌نشده: ${question.interactionType}", color = MaterialTheme.colorScheme.error)
        }

        OutlinedButton(
            onClick = { hintsUsed++; showHint = true },
            modifier = Modifier.heightIn(min = 56.dp).semantics { contentDescription = "درخواست راهنمایی" }
        ) { Text("💡 راهنمایی (${hintsUsed.toFa()})") }

        if (showHint && question.feedbackPolicy.hintOnFirstErrorFa.isNotBlank()) {
            Text(question.feedbackPolicy.hintOnFirstErrorFa, color = MaterialTheme.colorScheme.secondary)
        }
    }
}

@Composable
private fun DragAndDropCountView(q: PracticeQuestion, onResult: (ValidationOutcome) -> Unit) {
    val totalPool = q.payload.itemsCount.coerceIn(2, 12)
    val droppedIds = remember(q.questionId) { mutableStateListOf<Int>() }
    val target = q.correctAnswer.value ?: q.payload.targetValue

    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("سیب‌ها را به داخل سبد بکشید یا لمس کنید (${droppedIds.size.toFa()} در سبد)")
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            for (id in 1..totalPool) {
                if (id !in droppedIds) {
                    var offsetX by remember(q.questionId, id) { mutableFloatStateOf(0f) }
                    var offsetY by remember(q.questionId, id) { mutableFloatStateOf(0f) }
                    Box(
                        modifier = Modifier
                            .offset { IntOffset(offsetX.roundToInt(), offsetY.roundToInt()) }
                            .size(56.dp)
                            .pointerInput(q.questionId, id) {
                                detectDragGestures(
                                    onDragEnd = {
                                        if (offsetY > 40f && id !in droppedIds) droppedIds.add(id)
                                        offsetX = 0f; offsetY = 0f
                                    },
                                    onDrag = { change, dragAmount ->
                                        change.consume()
                                        offsetX += dragAmount.x
                                        offsetY += dragAmount.y
                                    }
                                )
                            }
                            .semantics { contentDescription = "شیء شمارشی شماره $id" }
                    ) {
                        Image(painterResource(R.drawable.ic_apple_counter), contentDescription = null, modifier = Modifier.fillMaxSize())
                    }
                }
            }
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(84.dp)
                .border(2.dp, MaterialTheme.colorScheme.primary, RoundedCornerShape(16.dp))
                .background(Color(0xFFE3F2FD), RoundedCornerShape(16.dp)),
            contentAlignment = Alignment.Center
        ) {
            Text("سبد هدف: ${droppedIds.size.toFa()} شیء")
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            OutlinedButton(onClick = { if (droppedIds.isNotEmpty()) droppedIds.removeAt(droppedIds.lastIndex) }, modifier = Modifier.heightIn(min = 56.dp)) { Text("برداشتن یکی") }
            Button(onClick = { onResult(InteractionValidator.validateDragCount(droppedIds.size, target)) }, modifier = Modifier.weight(1f).heightIn(min = 56.dp)) { Text("بررسی پاسخ") }
        }
    }
}

@Composable
private fun NumberLineJumpView(q: PracticeQuestion, onResult: (ValidationOutcome) -> Unit) {
    var pos by remember(q.questionId) { mutableIntStateOf(0) }
    val target = q.correctAnswer.value ?: q.payload.targetValue
    val maxTick = 20

    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("موقعیت مهره روی محور: ${pos.toFa()}", style = MaterialTheme.typography.titleMedium)
        Canvas(modifier = Modifier.fillMaxWidth().height(64.dp)) {
            val y = size.height / 2f
            drawLine(Color.DarkGray, Offset(16f, y), Offset(size.width - 16f, y), strokeWidth = 6f)
            val step = (size.width - 32f) / maxTick
            for (i in 0..maxTick) {
                val x = 16f + i * step
                drawLine(Color.Gray, Offset(x, y - 12f), Offset(x, y + 12f), strokeWidth = 3f)
            }
            val markerX = 16f + pos * step
            drawCircle(Color(0xFFFB8C00), radius = 14f, center = Offset(markerX, y))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Button(onClick = { if (pos > 0) pos-- }, modifier = Modifier.heightIn(min = 56.dp)) { Text("⬅️ پرش چپ") }
            Button(onClick = { if (pos < maxTick) pos++ }, modifier = Modifier.heightIn(min = 56.dp)) { Text("پرش راست ➡️") }
        }
        Button(onClick = { onResult(InteractionValidator.validateNumberLine(pos, target)) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("تأیید پرش") }
    }
}

@Composable
private fun TallyMarkBuilderView(q: PracticeQuestion, onResult: (ValidationOutcome) -> Unit) {
    var bundles by remember(q.questionId) { mutableIntStateOf(0) }
    var singles by remember(q.questionId) { mutableIntStateOf(0) }
    val target = q.correctAnswer.value ?: q.payload.targetValue

    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("دسته‌های ۵تایی: ${bundles.toFa()} | چوب‌خط تکی: ${singles.toFa()}")
        Canvas(modifier = Modifier.fillMaxWidth().height(56.dp)) {
            var x = 24f
            repeat(bundles) {
                for (i in 0..3) drawLine(Color(0xFF1E88E5), Offset(x + i * 10f, 8f), Offset(x + i * 10f, 48f), 5f)
                drawLine(Color(0xFFE53935), Offset(x - 4f, 44f), Offset(x + 36f, 12f), 5f)
                x += 56f
            }
            repeat(singles) {
                drawLine(Color(0xFF1E88E5), Offset(x, 8f), Offset(x, 48f), 5f)
                x += 12f
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Button(onClick = { bundles++ }, modifier = Modifier.heightIn(min = 56.dp)) { Text("+ دسته ۵تایی") }
            Button(onClick = { singles++ }, modifier = Modifier.heightIn(min = 56.dp)) { Text("+ چوب‌خط") }
            OutlinedButton(onClick = { bundles = 0; singles = 0 }, modifier = Modifier.heightIn(min = 56.dp)) { Text("پاک کردن") }
        }
        Button(onClick = { onResult(InteractionValidator.validateTallyMarks(bundles, singles, target)) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("بررسی چوب‌خط") }
    }
}

@Composable
private fun PatternCompleterView(q: PracticeQuestion, onResult: (ValidationOutcome) -> Unit) {
    val expected = q.correctAnswer.value ?: q.payload.targetValue
    val options = remember(q.questionId) { listOf(expected, expected + 1, (expected - 1).coerceAtLeast(1)).distinct().sorted() }
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("عنصر بعدی الگوی «${q.payload.criteria}» کدام است؟")
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            options.forEach { opt ->
                Button(
                    onClick = { onResult(InteractionValidator.validatePatternChoice(opt, expected)) },
                    modifier = Modifier.weight(1f).heightIn(min = 56.dp)
                ) { Text(opt.toFa()) }
            }
        }
    }
}

@Composable
private fun BalanceScaleView(q: PracticeQuestion, onResult: (ValidationOutcome) -> Unit) {
    var rightWeight by remember(q.questionId) { mutableIntStateOf(0) }
    val target = q.correctAnswer.value ?: q.payload.targetValue
    val tilt = (rightWeight - target).coerceIn(-3, 3) * 8f

    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("ترازو را به تعادل برسانید (وزنه راست: ${rightWeight.toFa()})")
        Canvas(modifier = Modifier.fillMaxWidth().height(72.dp)) {
            val cx = size.width / 2f
            val cy = size.height / 2f
            drawLine(Color(0xFF2E7D32), Offset(cx - 100f, cy - tilt), Offset(cx + 100f, cy + tilt), strokeWidth = 8f)
            drawCircle(Color.DarkGray, radius = 10f, center = Offset(cx, cy))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Button(onClick = { rightWeight++ }, modifier = Modifier.heightIn(min = 56.dp)) { Text("+ وزنه") }
            OutlinedButton(onClick = { if (rightWeight > 0) rightWeight-- }, modifier = Modifier.heightIn(min = 56.dp)) { Text("- وزنه") }
        }
        Button(onClick = { onResult(InteractionValidator.validateBalanceScale(rightWeight, target)) }, modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)) { Text("بررسی تعادل") }
    }
}

@Composable
private fun VisualMultipleChoiceView(q: PracticeQuestion, onResult: (ValidationOutcome) -> Unit) {
    val expected = q.correctAnswer.value ?: q.payload.targetValue
    val options = remember(q.questionId) { listOf(expected, expected + 1, expected + 2, (expected - 1).coerceAtLeast(0)).distinct().sorted() }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        options.forEach { opt ->
            Button(
                onClick = { onResult(InteractionValidator.validateMultipleChoice(opt, expected)) },
                modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp)
            ) { Text("گزینه ${opt.toFa()}") }
        }
    }
}
