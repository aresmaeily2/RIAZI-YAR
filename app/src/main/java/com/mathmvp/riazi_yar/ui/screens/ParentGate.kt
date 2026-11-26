package com.mathmvp.riazi_yar.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun ParentGate(content: @Composable () -> Unit) {
    var unlocked by remember { mutableStateOf(false) }
    var answer by remember { mutableStateOf("") }
    if (unlocked) {
        content()
    } else {
        Column(Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("ورود ویژه والدین", style = MaterialTheme.typography.headlineSmall)
            Text("برای ورود، حاصل ضرب ۷ × ۸ را وارد کنید:")
            OutlinedTextField(value = answer, onValueChange = { answer = it }, label = { Text("پاسخ") })
            Button(onClick = { if (answer.trim() == "56" || answer.trim() == "۵۶") unlocked = true }, modifier = Modifier.heightIn(min = 56.dp)) {
                Text("تأیید و ورود")
            }
        }
    }
}
