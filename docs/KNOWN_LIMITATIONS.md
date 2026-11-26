# محدودیت‌های شناخته‌شده و موارد نیازمند اقدام مالک (`docs/KNOWN_LIMITATIONS.md`)

1. **امضای تجاری انتشار (Release Keystore — G14):** فایل‌های `app-release-unsigned.apk` و `app-release.aab` با R8 تولید شده‌اند، اما امضای تجاری نهایی نیازمند تعریف متغیرهای محیطی `KEYSTORE_PATH`، `KEYSTORE_PASSWORD`، `KEY_ALIAS` و `KEY_PASSWORD` توسط مالک پروژه است.
2. **بازبینی میدانی معلم پایه اول (Teacher Review — G15):** تمام ۲۳۵ فایل JSON از نظر فنی، ساختاری و صحت پاسخ‌ها ممیزی و اصلاح شده‌اند، اما تا زمان تأیید کتبی معلم رسمی پایه اول، وضعیت `PEDAGOGICAL_PENDING_TEACHER_REVIEW` حفظ می‌شود.
3. **اجرای Emulator سخت‌افزاری (G11):** به دلیل نبود مجازی‌ساز KVM در کانتینر لینوکس ابری، اجرای تست‌های UI روی شبیه‌ساز اندروید در `.github/workflows/android_native_ci.yml` (روی اجرای `macos-latest` در GitHub Actions) تنظیم شده است.
4. **اتصال و Push به مخزن GitHub (`aresmaeily2/RIAZI-YAR`):** شاخه `feat/android-native-v2` به همراه تمام کامیت‌های اتمیک و تگ `archive/flutter-v1.0.3` در مخزن محلی آماده است و از طریق درگاه انتشار زنده GitHub در وب‌اپلیکیشن (`/github-release`) با وارد کردن توکن دسترسی (PAT) مالک، به صورت خودکار Push، ایجاد PR و انتشار Release را انجام می‌دهد.
