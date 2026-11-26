# وضعیت ۱۶ گیت کیفیت اجباری (`docs/QUALITY_GATES.md`)

| کد گیت | عنوان گیت | معیار عبور | وضعیت واقعی | شاهد و مستند |
|---|---|---|---|---|
| **G1** | Source Integrity | صحت ZIP، هش‌ها، حفظ تاریخچه Flutter و نبود فایل مفقود | **TESTED / VERIFIED** | `ZIP_INTEGRITY_REPORT.md`، تگ `archive/flutter-v1.0.3`، پوشه `legacy/flutter-v1.0.3/` |
| **G2** | Architecture | معماری Native لایه‌ای با Kotlin، Compose، Room v3 و DataStore | **TESTED / VERIFIED** | `docs/ARCHITECTURE.md`، بیلد موفق Gradle |
| **G3** | Content | اعتبارسنجی ۱۰۰٪ از ۲۳۵ فایل JSON و ۱,۷۹۴ آیتم (۰ خطا، ۰ تکرار، ۰ لو رفتن پاسخ) | **TESTED / VERIFIED** | تست `contentV2_all39LessonsAndBanksPassFullAudit` (Exit Code 0) |
| **G4** | Interaction | اجرای واقعی هر ۶ نوع Interaction با داده واقعی JSON | **TESTED / VERIFIED** | `InteractionRouter.kt`، `InteractionValidatorTest.kt` |
| **G5** | Educational Flow | مسیر کامل کشف مفهوم، مثال، فعالیت هدایت‌شده، تمرین، جبرانی و سنجش ۸۰٪ | **TESTED / VERIFIED** | `AppNavigation.kt`، تست `lessonCompletion_neverHardcodesAndRequiresAllGates` |
| **G6** | Persistence | ذخیره تراکنشی در Room، مهاجرت `MIGRATION_1_2` و `MIGRATION_2_3` و حفظ اندیس تمرین | **TESTED / VERIFIED** | `RiaziDatabase.kt`، `RiaziViewModel.kt` |
| **G7** | Adaptive Learning | الگوریتم استاندارد SuperMemo SM-2 و صف مرور واقعی (`dueEpochMs <= nowMs`) | **TESTED / VERIFIED** | تست `sm2Schedule_followsSuperMemoSpecification` |
| **G8** | UI/UX | رابط فارسی RTL، فونت وزیرمتن، اندازه لمس حداقل 56dp، TalkBack semantics | **IMPLEMENTED & TESTED** | `Theme.kt`، `InteractionRouter.kt`، `AppNavigation.kt` |
| **G9** | Unit/Integration Tests | صفر تست شکست‌خورده و صفر تست Skip در اجرای واقعی JUnit | **TESTED (11/11 PASS)** | `TEST-com.mathmvp.riazi_yar.InteractionValidatorTest.xml` |
| **G10** | Lint/Static Analysis | اجرای موفق `./gradlew lintDebug` و بیلد بدون خطای کامپایل | **TESTED (PASS)** | `app/build/reports/lint-results-debug.html` |
| **G11** | Emulator | اجرای شبیه‌ساز سخت‌افزاری Android | **BLOCKED (Local KVM) / CI Configured** | نبود `/dev/kvm` در کانتینر؛ تعبیه در `.github/workflows/android_native_ci.yml` + شبیه‌ساز وب |
| **G12** | Security/Privacy | صفر Secret افشاشده، صفر مجوز سیستمی و `allowBackup="false"` | **TESTED / VERIFIED** | خروجی `aapt2 dump permissions` در `docs/SECURITY_PRIVACY.md` |
| **G13** | CI/CD | فایل Workflow کامل و آماده اجرا در GitHub Actions | **IMPLEMENTED (Awaiting GitHub Push Token)** | `.github/workflows/android_native_ci.yml` |
| **G14** | Release Artifacts | تولید واقعی `app-debug.apk`، `app-release-unsigned.apk` و `app-release.aab` با هش SHA-256 | **TESTED / VERIFIED (Signing BLOCKED on Owner Keystore)** | فایل‌های تولیدشده در `app/build/outputs/` با هش‌های ثبت‌شده |
| **G15** | Teacher Review | تأیید کتبی انسانی متخصص آموزش پایه اول | **BLOCKED (`PEDAGOGICAL_PENDING_TEACHER_REVIEW`)** | طبق دستورالعمل، بدون تأیید انسانی معلم ادعای تأیید آموزشی نمی‌شود |
| **G16** | Independent Audit | بازبینی مستقل Diff، تست‌ها، بیلد و رفع تمام ۱۱ یافته بحرانی | **TESTED / VERIFIED** | `SOURCE_AUDIT.md` و `docs/FINAL_AUDIT_REPORT.md` |
