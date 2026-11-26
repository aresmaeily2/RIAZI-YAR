package com.mathmvp.riazi_yar.core

object PersianUtils {
    private val enDigits = charArrayOf('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
    private val faDigits = charArrayOf('۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹')
    private val arDigits = charArrayOf('٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩')

    fun Int.toFa(): String = this.toString().toFa()
    fun Long.toFa(): String = this.toString().toFa()

    fun String.toFa(): String {
        val sb = StringBuilder(length)
        for (c in this) {
            val idx = enDigits.indexOf(c)
            val arIdx = arDigits.indexOf(c)
            when {
                idx >= 0 -> sb.append(faDigits[idx])
                arIdx >= 0 -> sb.append(faDigits[arIdx])
                else -> sb.append(c)
            }
        }
        return sb.toString()
    }

    fun String.toAsciiDigits(): String {
        val sb = StringBuilder(length)
        for (c in this) {
            val faIdx = faDigits.indexOf(c)
            val arIdx = arDigits.indexOf(c)
            when {
                faIdx >= 0 -> sb.append(enDigits[faIdx])
                arIdx >= 0 -> sb.append(enDigits[arIdx])
                else -> sb.append(c)
            }
        }
        return sb.toString()
    }
}
