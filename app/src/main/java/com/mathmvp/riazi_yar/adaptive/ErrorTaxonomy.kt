package com.mathmvp.riazi_yar.adaptive

enum class MathErrorCategory(val titleFa: String, val remedialStrategyFa: String) {
    COUNTING_ERROR("خطای شمارش", "شمارش آهسته یک‌به‌یک با لمس هر شیء"),
    ONE_TO_ONE_CORRESPONDENCE("خطای تناظر یک‌به‌یک", "تطبیق هر عدد با یک شیء مشخص در سبد"),
    DIRECTION_ERROR("خطای جهت روی محور", "جمع به سمت راست و تفریق به سمت چپ"),
    BUNDLING_PLACE_VALUE("خطای دسته‌بندی پنج‌تایی/ده‌تایی", "بستن هر ۵ چوب‌خط در یک دسته"),
    PATTERN_RECOGNITION("خطای تشخیص الگو", "بررسی تکرار رنگ و شکل از چپ به راست"),
    EQUILIBRIUM_EQUATION("خطای تعادل تساوی", "مقایسه مجموع وزنه‌های دو کفه ترازو"),
    GENERAL_CONCEPT("خطای مفهومی عمومی", "مرور مثال حل‌شده درس")
}

object ErrorTaxonomy {
    fun classify(code: String?): MathErrorCategory = when (code) {
        "OVERCOUNT_BY_ONE", "UNDERCOUNT_BY_ONE", "COUNT_MISMATCH" -> MathErrorCategory.COUNTING_ERROR
        "COUNTING_START_NODE", "WRONG_DIRECTION" -> MathErrorCategory.DIRECTION_ERROR
        "UNBUNDLED_FIVE", "BUNDLE_COUNTED_AS_ONE", "TALLY_MISMATCH" -> MathErrorCategory.BUNDLING_PLACE_VALUE
        "PATTERN_MISMATCH", "SYMMETRY_REVERSAL" -> MathErrorCategory.PATTERN_RECOGNITION
        "OFF_BY_ONE_BALANCE", "EQUILIBRIUM_ERROR" -> MathErrorCategory.EQUILIBRIUM_EQUATION
        else -> MathErrorCategory.GENERAL_CONCEPT
    }
}
