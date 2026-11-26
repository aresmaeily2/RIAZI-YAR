package com.mathmvp.riazi_yar.core

object PersianUtils {
    private val persianDigits = charArrayOf('۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹')

    fun toPersianDigits(input: String): String {
        val sb = StringBuilder(input.length)
        for (ch in input) {
            if (ch in '0'..'9') sb.append(persianDigits[ch - '0']) else sb.append(ch)
        }
        return sb.toString()
    }

    fun Int.toFa(): String = toPersianDigits(this.toString())
}
