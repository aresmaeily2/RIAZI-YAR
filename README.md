# ریاضی‌یار پایه اول ابتدایی — نسخه Android Native V2 (`2.1.0-beta.1`)

اپلیکیشن **Android Native** توسعه‌یافته با **Kotlin 2.0.21** و **Jetpack Compose**، کاملاً **فارسی و راست‌به‌چپ (RTL)**، **۱۰۰٪ آفلاین** و **بدون هیچ مجوز سیستمی** برای آموزش تعاملی کل کتاب ریاضی پایه اول ابتدایی (۸ فصل، ۳۹ درس، ۱۱۷ فعالیت هدایت‌شده، ۱۱۷۰ تمرین مستقل، ۱۹۵ تمرین جبرانی و ۱۹۵ سؤال سنجش پایانی).

> ⚠️ **وضعیت صادقانه انتشار:**
> - **تکمیل فنی، تست خودکار، تحلیل استاتیک (Lint) و بیلد APK/AAB:** **TESTED & VERIFIED** (اجراشده با OpenJDK 17.0.21، Gradle 8.10.2 و Android SDK 35؛ خروجی ۱۱ تست JUnit با ۰ خطا و بررسی کامل ۲۳۵ فایل JSON).
> - **امضای انتشار (Release Signing):** نسخه `app-debug.apk` با گواهی Debug امضا و با `apksigner` تأیید شده است؛ فایل‌های `app-release-unsigned.apk` و `app-release.aab` تولید شده‌اند اما امضای تجاری نهایی نیازمند Keystore مالک پروژه در محیط امن CI است (**BLOCKED** برای Stable Store Release تا تزریق Secretهای امضا).
> - **تأیید آموزشی معلم (G15):** محتوای ۳۹ درس از نظر فنی و ساختار آموزشی اعتبارسنجی شده اما بازبینی میدانی انسانی توسط معلم رسمی پایه اول هنوز در وضعیت `PEDAGOGICAL_PENDING_TEACHER_REVIEW` (**BLOCKED**) قرار دارد؛ بنابراین این نسخه به‌عنوان **Pre-release / Beta (`v2.1.0-beta.1`)** منتشر می‌شود.
> - **حفظ تاریخچه نسخه قبلی:** تمام کدها، تست‌ها و مستندات نسخه Flutter v1.0.3 بدون هیچ حذفی در مسیر `legacy/flutter-v1.0.3/` و تگ `archive/flutter-v1.0.3` (کامیت `932cdae`) محفوظ هستند.

## شاخص‌های کلیدی نسخه ۲.۱.۰ (تأییدشده با شواهد واقعی)

| شاخص | مقدار واقعی | روش محاسبه و شاهد |
|---|---|---|
| تعداد کل فایل‌های JSON محتوا | **۲۳۵ فایل** | `ContentIntegrityTest` در `InteractionValidatorTest.kt` |
| تعداد فصل‌ها و درس‌ها | **۸ فصل / ۳۹ درس** | `CONTENT_MANIFEST.json` (`G1-L01` تا `G1-L39`) |
| تعداد کل آیتم‌های آموزشی یکتا | **۱,۷۹۴ آیتم** | ۱۱۷ مثال + ۱۱۷ فعالیت هدایت‌شده + ۱,۱۷۰ تمرین مستقل + ۱۹۵ جبرانی + ۱۹۵ سنجش (۰ شناسه تکراری) |
| انواع تعامل بومی (Interactions) | **۶ نوع تعاملی واقعی** | `drag_and_drop_count`, `number_line_jump`, `tally_mark_builder`, `pattern_completer`, `balance_scale_equation`, `visual_multiple_choice` |
| تعداد مجوزهای سیستمی (`uses-permission`) | **صفر (۰)** | خروجی `aapt2 dump permissions app-release-unsigned.apk` |
| وضعیت تست‌های JUnit | **۱۱/۱۱ PASS (۰ شکست، ۰ Skip)** | `./gradlew testDebugUnitTest` (Exit Code `0`) |
| وضعیت بیلد APK و AAB | **BUILD SUCCESSFUL** | `app-debug.apk` (۱۱ مگابایت)، `app-release-unsigned.apk` (۲.۱ مگابایت)، `app-release.aab` (۴.۱ مگابایت) |

## دستورات بازتولید بیلد و تست‌ها

```bash
export ANDROID_HOME=/path/to/android-sdk
./gradlew testDebugUnitTest lintDebug assembleDebug assembleRelease bundleRelease
```
