# گزارش مقایسه‌ای سورس زنده GitHub و بسته تحویلی ZIP (`GITHUB_VS_HANDOFF_COMPARISON.md`)

| محور مقایسه | وضعیت زنده مخزن GitHub (`aresmaeily2/RIAZI-YAR`) | وضعیت بسته ZIP (`RIAZI_YAR_NATIVE_V2_COMPLETE_HANDOFF.zip`) | تصمیم معماری و اقدام نهایی در `feat/android-native-v2` |
|---|---|---|---|
| **وضعیت دسترسی مخزن** | **Public** (برخلاف ادعای D-110 در `DECISION_LOG.md` که آن را Private نامیده بود) | فقط شامل راهنمای متنی انتقال به GitHub | ثبت تناقض در `DECISION_LOG.md` (D-201) و حفظ وضعیت مخزن بدون تغییر غیرمجاز |
| **شاخه‌ها و کامیت‌ها** | `master` (`932cdae`) و `fix/audit-v1.0.3-exec` (`7536074`)؛ شاخه `feat/android-native-v2` وجود نداشت | خارج از Git (فقط فایل‌های آرشیوی) | ایجاد تگ بازیابی `archive/flutter-v1.0.3` روی `932cdae` و انشعاب `feat/android-native-v2` از `master` |
| **پشته فناوری** | Flutter 3.47.7 (نسخه ۱.۰.۳)؛ `MainActivity.kt` صرفاً `FlutterActivity` است | Android Native (Kotlin 2.0.21 + Jetpack Compose + Room + DataStore) | انتقال کامل سورس Flutter به `legacy/flutter-v1.0.3/` و استقرار پروژه Native استاندارد در ریشه مخزن |
| **پوشش محتوای آموزشی** | ۳ فایل JSON نمونه (`lesson_l1_counting_1_5.json`، `lesson_l2_counting_6_9.json`، `quiz_final_short.json`) | ۲۳۵ فایل JSON (۸ فصل، ۳۹ درس، ۱۱۷۰ تمرین مستقل، ۱۹۵ جبرانی، ۱۹۵ سنجش) با نقایص قالب‌ای | بازنویسی و غنی‌سازی کامل ۲۳۵ فایل JSON (۱۱۷ مثال واقعی، ۱۱۷ فعالیت هدایت‌شده، ۱۱۷۰ تمرین، ۱۹۵ جبرانی بدون لو دادن پاسخ، ۱۹۵ سنجش) |
| **اجرای تست‌ها و بیلد** | گزارش‌های متناقض در اسناد Flutter (`75` در README، `107` در ACCEPTANCE، `126` در TESTING) | `NOT_RUN` برای تست‌ها و `BLOCKED` برای بیلد APK/AAB | اجرای واقعی `./gradlew testDebugUnitTest lintDebug assembleDebug assembleRelease bundleRelease` با OpenJDK 17 و Android SDK 35 (۱۱ تست جامع JUnit با ۰ خطا + تولید APK و AAB واقعی) |
| **مجوزهای AndroidManifest** | در نسخه Flutter دارای `INTERNET` برای راهنمای آنلاین | دارای مجوز غیرضروری `android.permission.POST_NOTIFICATIONS` | حذف کامل مجوزهای اضافی؛ **صفر مجوز سیستمی** در Merged Manifest نهایی |
