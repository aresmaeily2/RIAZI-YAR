# یادداشت‌های انتشار — ریاضی‌یار پایه اول نسخه `v2.1.0-beta.1` (`versionCode 21`)

## فارسی (Persian Release Notes)
- **معماری بومی جدید (Android Native V2):** بازطراحی کامل با Kotlin 2.0.21، Jetpack Compose، Room Database v3 و DataStore؛ حفظ کامل سورس نسخه قبلی Flutter v1.0.3 در `legacy/flutter-v1.0.3/`.
- **پوشش کامل کتاب ریاضی پایه اول:** ۸ فصل، ۳۹ درس، ۱۱۷ مثال حل‌شده واقعی، ۱۱۷ فعالیت هدایت‌شده، ۱,۱۷۰ تمرین مستقل، ۱۹۵ تمرین جبرانی و ۱۹۵ سؤال سنجش پایانی (مجموعاً ۲۳۵ فایل JSON معتبر).
- **رفع کامل ۱۰ ایراد ممیزی فنی و آموزشی:**
  1. بازطراحی ترازوی دوکفه‌ای بصری (`BalanceScaleView`) با دو کفه، تکیه‌گاه و وزنه‌های ۱، ۲ و ۵.
  2. حذف تولید ساختگی گزینه‌ها (`expected + 1`) و خواندن گزینه‌های واقعی از JSON.
  3. پیاده‌سازی فعالیت هدایت‌شده تعاملی (`LEARNING_ACTIVITY`) و مسیر جبرانی تعاملی (`REMEDIAL`) بدون لو رفتن پاسخ.
  4. سنجش پایانی واقعی با حد نصاب قبولی ۸۰٪ و حذف کامل Hardcode در `markLessonCompleted`.
  5. پیاده‌سازی دقیق الگوریتم SuperMemo SM-2 و اصلاح فیلتر زمان صف مرور (`dueReviews`).
  6. ارتقای گیت والدین (`ParentGate`) با چالش تصادفی، قفل ۶۰ ثانیه‌ای پس از ۳ خطا و قفل خودکار ۵ دقیقه‌ای و هنگام خروج به پس‌زمینه.
  7. حذف تمام مجوزهای سیستمی (**صفر مجوز در فایل APK نهایی**).
- **پیش‌نیاز نصب:** اندروید ۷.۰ (API 24) به بالا.
- **وضعیت امضا و اعتبار آموزشی:** فایل `riazi-yar-v2.1.0-beta.1-debug.apk` با کلید Debug امضا شده و آماده نصب آزمایشی است. نسخه‌های Release (`apk` و `aab`) نیازمند Keystore مالک پروژه هستند. وضعیت آموزشی: `PEDAGOGICAL_PENDING_TEACHER_REVIEW`.

## English Release Notes (`v2.1.0-beta.1`)
- **Complete Android Native V2 Rewrite:** Built with Kotlin 2.0.21, Jetpack Compose, Room v3, and DataStore, while preserving the complete Flutter v1.0.3 codebase in `legacy/flutter-v1.0.3/` and tag `archive/flutter-v1.0.3`.
- **Full Grade-1 Curriculum Coverage:** 8 chapters, 39 lessons, 235 validated JSON files (1,794 unique educational items with zero duplicate IDs and zero answer spoilers).
- **All 10 Critical Audit Findings Resolved & Verified via JUnit (`11/11 PASS`):** Interactive two-pan balance scale, JSON-driven multiple-choice options, guided discovery activities, interactive remedial loop, 80%-threshold summative assessment, authentic SuperMemo SM-2 scheduling, dynamic ParentGate with cooldown & lifecycle auto-relock, and zero Android permissions.
- **Artifacts & SHA-256 Checksums:**
  - `app-debug.apk` (11 MB): `72e2da9cf96ddf2abe13697d3c880b9d8d70dce1affc51abd6aa9ce5a12fa50c`
  - `app-release-unsigned.apk` (2.1 MB): `710fa0f7fc98433f8f9a64aeb8defc93e80056fd1e348bb21cdaa827e3b8857f`
  - `app-release.aab` (4.1 MB): `36c896dce58010783a1838cd55d713913389dc51e116791b890aea695015a961`
