# معماری فنی Android Native V2 (`docs/ARCHITECTURE.md`)

## ۱. ساختار لایه‌ای (Layered Clean Architecture)
- **لایه رابط کاربری (`com.mathmvp.riazi_yar.ui`):**
  - `navigation/AppNavigation.kt`: مدیریت کامل مسیر یادگیری کودک (`SPLASH` -> `HOME` -> `CHAPTERS` -> `LESSONS` -> `LESSON_INTRO` -> `CONCEPT_DISCOVERY` -> `WORKED_EXAMPLE` -> `LEARNING_ACTIVITY` -> `INDEPENDENT_PRACTICE` -> `REMEDIAL` -> `ASSESSMENT` -> `LESSON_COMPLETION`) و صفحات والدین/تنظیمات با حفظ State در چرخش صفحه (`rememberSaveable`).
  - `interactions/InteractionRouter.kt` و `InteractionValidator.kt`: پیاده‌سازی بومی ۶ ابزار دست‌ورزی با Jetpack Compose Canvas و Gesture API.
  - `screens/ParentGate.kt`: گیت محافظ والدین با چالش تصادفی `(A × B) + C`، قفل ۶۰ ثانیه‌ای پس از ۳ خطا، قفل خودکار ۵ دقیقه‌ای و قفل خودکار در `ON_PAUSE`.
- **لایه مدیریت حالت (`com.mathmvp.riazi_yar.viewmodel`):**
  - `RiaziViewModel.kt`: مبتنی بر `StateFlow` و `UiState<T>` (`Loading`, `Success`, `Error`) با قابلیت تلاش مجدد (`Retry`).
- **لایه موتور آموزشی تطبیقی (`com.mathmvp.riazi_yar.adaptive`):**
  - `AdaptiveLearningEngine.kt`: اجرای الگوریتم استاندارد SM-2، تشخیص نیاز به مسیر جبرانی و محاسبه خالص تکمیل درس (`evaluateLessonCompletion`).
  - `ErrorTaxonomy.kt`: طبقه‌بندی خطاهای ریاضی کودک در ۷ رده تخصصی.
- **لایه داده و ذخیره‌سازی (`com.mathmvp.riazi_yar.data` & `content` & `settings`):**
  - `RiaziDatabase.kt`: دیتابیس Room نسخه ۳ همراه با مهاجرت‌های واقعی `MIGRATION_1_2` و `MIGRATION_2_3` و تراکنش اتمیک `@Transaction recordAttemptTransaction`.
  - `ContentRepository.kt`: بارگذاری و اعتبارسنجی ۲۳۵ فایل JSON از `assets/content_v2/`.
  - `UserPreferencesRepository.kt`: ذخیره‌سازی تنظیمات با Jetpack DataStore.
