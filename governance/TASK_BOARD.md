# تابلو وضعیت وظایف و ایجنت‌ها (`governance/TASK_BOARD.md`)

| کد وظیفه | ایجنت مسئول | شرح وظیفه | وضعیت دقیق | شاهد واقعی |
|---|---|---|---|---|
| **T-01** | Agent 1 (Forensic GitHub Auditor) | ممیزی زنده GitHub، بررسی کامیت‌های `932cdae` و `7536074`، بررسی ZIP و محاسبه SHA-256 | **TESTED** | `HANDOFF_INVENTORY.md`, `ZIP_INTEGRITY_REPORT.md` |
| **T-02** | Agent 2 (Android Native Architect) | حفظ Flutter در `legacy/`، استقرار معماری Kotlin + Compose + Room v3 + DataStore | **TESTED** | کامیت‌های `144b429` و `d5d2bd3` در شاخه `feat/android-native-v2` |
| **T-03** | Agent 3 & 6 (Educational & Content) | بازنویسی و غنی‌سازی ۲۳۵ فایل JSON (حذف `EX_ANS_` و `(صحیح)`، افزودن گزینه‌های واقعی و فعالیت هدایت‌شده) | **TESTED** | کامیت `0515cd9` + تست `contentV2_all39LessonsAndBanksPassFullAudit` |
| **T-04** | Agent 4 & 5 (Interactions & Child UX) | بازطراحی ترازوی دوکفه‌ای، محور اعداد، چوب‌خط، الگو، سبد شمارش و چندگزینه‌ای با RTL کامل | **TESTED** | `InteractionRouter.kt`, `InteractionValidator.kt` |
| **T-05** | Agent 7 (Adaptive Learning Engineer) | پیاده‌سازی دقیق الگوریتم SM-2، اصلاح `dueReviews` و محاسبه واقعی تکمیل درس و ستاره‌ها | **TESTED** | `AdaptiveLearningEngine.kt`, `RiaziDatabase.kt` |
| **T-06** | Agent 8 (QA / Test Automation) | اجرای واقعی `./gradlew testDebugUnitTest` و `./gradlew lintDebug` با OpenJDK 17 و SDK 35 | **TESTED** | `TEST-com.mathmvp.riazi_yar.InteractionValidatorTest.xml` (11/11 PASS) |
| **T-07** | Agent 9 (Security & Privacy Auditor) | حذف مجوز `POST_NOTIFICATIONS`، افزودن قواعد منع Backup و ارتقای `ParentGate` | **TESTED** | `aapt2 dump permissions` (`docs/SECURITY_PRIVACY.md`) |
| **T-08** | Agent 10 (CI/CD & Release Engineer) | بیلد واقعی `app-debug.apk`، `app-release-unsigned.apk` و `app-release.aab` و آماده‌سازی Workflow | **TESTED** | فایل‌های `app/build/outputs/` با هش SHA-256 |
| **T-09** | Agent 11 (Independent Reviewer) | بازبینی مستقل Diff، تطبیق شواهد با کد و تأیید عبور از گیت‌های فنی | **TESTED** | `SOURCE_AUDIT.md`, `docs/QUALITY_GATES.md` |
| **T-10** | Human Teacher Reviewer | بازبینی میدانی و تأیید کتبی معلم رسمی پایه اول | **BLOCKED** | `PEDAGOGICAL_PENDING_TEACHER_REVIEW` |
