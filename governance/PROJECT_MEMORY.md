# حافظه پروژه ریاضی‌یار (`governance/PROJECT_MEMORY.md`)

## ۱. زنجیره نسخه‌ها و تاریخچه واقعی
- **نسخه ۱.۰.۰ تا ۱.۰.۳ (Flutter MVP — شاخه `master` کامیت `932cdae` و شاخه `fix/audit-v1.0.3-exec` کامیت `7536074`):**
  شامل ۲ درس شمارش (`lesson_l1_counting_1_5.json` و `lesson_l2_counting_6_9.json`) و ۱ آزمون کوتاه (`quiz_final_short.json`). تمام کدها و مستندات این نسخه در تگ `archive/flutter-v1.0.3` و پوشه `legacy/flutter-v1.0.3/` حفظ شده‌اند.
- **بسته تحویلی اولیه برنامه‌نویس (`RIAZI_YAR_NATIVE_V2_COMPLETE_HANDOFF.zip`):**
  دارای هش SHA-256 تأییدشده `f1d8e0de75f9448e5dfb98c96d22ff9c7c5b47ddfde81bdf73a2150818263804` شامل ۵۵۳ فایل؛ اما دارای ۱۰ نقص جدی در کد Kotlin/JSON و فاقد `gradle-wrapper.jar` و بیلد واقعی.
- **نسخه نهایی ممیزی و تکمیل‌شده (`v2.1.0-beta.1` روی شاخه `feat/android-native-v2`):**
  اصلاح کامل ۲۳۵ فایل JSON (۱,۷۹۴ آیتم یکتا)، بازنویسی و اصلاح ۱۰ نقطه پرخطر در Kotlin/Jetpack Compose، اجرای واقعی ۱۱ سوئیت تست JUnit (با ۰ خطا) و بیلد واقعی `app-debug.apk`، `app-release-unsigned.apk` و `app-release.aab` با OpenJDK 17.0.21، Gradle 8.10.2 و Android SDK 35.
