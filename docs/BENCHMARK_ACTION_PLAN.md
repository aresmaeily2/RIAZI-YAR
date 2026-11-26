# برنامه اقدام حاصل از ممیزی تطبیقی (`docs/BENCHMARK_ACTION_PLAN.md`)

| کد اقدام | منشأ اقتباس | تغییر اعمال‌شده در کد و محتوای ریاضی‌یار V2 | فایل شاهد در مخزن | وضعیت |
|---|---|---|---|---|
| **BAP-01** | Khan Academy Kids + Brilliant | افزودن داستان شروع (`warm_up_story_fa`)، کشف مفهوم ۳ مرحله‌ای و ۳ فعالیت هدایت‌شده به هر ۳۹ درس | `app/src/main/assets/content_v2/lessons/G1-L*_lesson.json` و `AppNavigation.kt` | **TESTED** |
| **BAP-02** | DragonBox + ST Math | بازطراحی کامل ترازوی دوکفه‌ای با تکیه‌گاه، دو کفه، بلوک‌های وزنه رنگی و بازخورد زاویه تعادل | `InteractionRouter.kt` (`BalanceScaleView`) | **TESTED** |
| **BAP-03** | Math Learning Center | استانداردسازی چوب‌خط ۵تایی و محور اعداد ۰ تا ۲۰ با پرش‌های +۱، -۱ و +۵ | `InteractionRouter.kt` (`TallyMarkBuilderView`, `NumberLineJumpView`) | **TESTED** |
| **BAP-04** | Desmos + Prodigy | نگاشت خطاهای تعامل به ۷ رده `MathErrorCategory` و هدایت خودکار به ۵ سؤال جبرانی بدون برچسب لو دهنده | `ErrorTaxonomy.kt`, `AdaptiveLearningEngine.kt`, `remedial/*.json` | **TESTED** |
