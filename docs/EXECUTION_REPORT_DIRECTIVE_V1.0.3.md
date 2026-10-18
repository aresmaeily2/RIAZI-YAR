# گزارش اجرای دستورکار ۱.۰.۳ — ریاضی‌یار (پاسخ رسمی)

تاریخ: ۲۰۲۶-۱۰-۱۸ | نقش: developer-senior | شاخه: `fix/audit-v1.0.3-exec`
مبنای مأموریت: «دستورکار اجرایی توسعه‌دهنده ارشد پروژه ریاضی‌یار — نسخه ۱.۰.۳»

## ۰) شفاف‌سازی مهم درباره فایل‌های پیش‌نیاز
فایل‌های درخواستی برای مطالعه پیش از تغییر کد — `governance/PROJECT_CHARTER.md`،
`governance/PROJECT_MEMORY.md`، `governance/DECISION_LOG.md`،
`governance/TASK_BOARD.md`، `governance/QUALITY_GATES.md`،
`governance/AGENT_ROLES.md` و `docs/AUDIT_RIAZI_YAR_V1.0.3_INDEPENDENT.md` —
در ZIP سورس تحویلی v1.0.3 **وجود نداشتند** (فهرست کامل ۱۳۱ مدخل ZIP
بررسی شد). هیچ نسخه دیگری از آن‌ها در فایل‌سیستم هم یافت نشد؛ بنابراین
گزارش «ممیزی مستقل» به‌عنوان ورودی در دسترس نبوده و پاسخ این سند به
بندهای خود دستورکار است. هر شش فایل governance اکنون **با وضعیت واقعی**
در همین کامیت ساخته شده‌اند (DECISION_LOG D-101).

## ۱) وضعیت هر بند دستورکار

| بند | موضوع | وضعیت | فایل/شاهد |
|---|---|---|---|
| P0-۱ | سورس + نسخه ابزار + baseline | **PASS** | ZIP تأییدشده با SHA256SUMS_v1.0.3.txt → baseline کامیت `e790842`؛ baseline_analyze.txt (No issues، exit 0)؛ baseline_test.txt (**۱۰۷ پاس + ۲ skip، exit 0**). ابزارها: Flutter 3.47.7 stable / Dart 3.13.5 / JDK Temurin 21 / Android SDK platform 35+36 / Gradle 9.3.1 (PROJECT_MEMORY) |
| P0-۲ | بیلد APK متناظر + راستی‌آزمایی | **PASS** | APK: `riazi_yar_v1.0.3+5_internaltest_debugsigned.apk` — SHA-256 `7f0b9736554ffa77be0ba381d0c3a5f7080c827fa93bffcc873e35050be39071`؛ aapt2: `com.mathmvp.riazi_yar` versionCode **5** versionName **1.0.3-internal-test** minSdk 24 targetSdk(compile) 36؛ مجوز فقط `INTERNET` (+ مجوز داخلی خودِ اپ) — **بدون RECORD_AUDIO**؛ allowBackup=false؛ libapp.so arm+arm64؛ ۳ JSON درس؛ apksigner verify exit 0، گواهی **Android Debug (عمدی)** — خروجی کامل در `aapt2_badging_v1.0.3-exec.txt` و `apksigner_print_certs_v1.0.3-exec.txt`. keystore/رمزی وارد سورس/بسته نشد |
| P0-۳ | تأیید آموزشی معلم | **BLOCKED** | معلم پایه اول در دسترس نیست؛ محتوا صریحاً «نمونه، تأییدنشده» می‌ماند (`teacherReviewed=false`)؛ هیچ ادعای انطباق رسمی ثبت نشد |
| P0-۴ | تست دستگاه واقعی | **NOT RUN** | دستگاه اندروید در دسترس نیست؛ چک‌لیست اجرای میدانی در `docs/LIMITATIONS.md` آماده است |
| P1-۵ | هماهنگی متن رضایت با payload | **PASS** | `PrivacyTexts.onlineGuidePayloadFields` = منبع واحد شش فیلد دقیق (`utterance,prompt,hints,wrongStreak,activityType,lessonId`)؛ دیالوگ رضایت: هدف ارسال، دریافت‌کننده، نگهداری سمت سرور، خاموش‌کردن؛ ادعای نادرست «شناسه درس و پرسش» اصلاح شد (questionId ارسال نمی‌شود)؛ **تست: «دقیقاً شش فیلد payload اعلام‌شده ارسال می‌شود»** payload واقعی سرور را می‌سنجد |
| P1-۶ | امنیت endpoint / DNS rebinding | **PASS** | resolve پیش از اتصال + رد اگر «هر» آدرس ممنوع (شمارنده اتصال=۰ در تست)؛ بازه‌های جدید: **CGNAT 100.64.0.0/10**، TEST-NET-1/2/3، benchmarking 198.18/15، IETF 192.0.0.0/24، doc-IPv6 2001:db8::/32، discard 100::/64، پورت صفر؛ **پین مقصد** (TCP به آدرس تأییدشده + TLS با نام اصلی — بدون resolve مجدد)؛ `followRedirects=false` (3xx رد)؛ DIRECT بدون پروکسی؛ به‌سادگی MVP حفظ شد |
| P1-۷ | ماتریس تست HTTPS | **PASS (محلی) / NOT RUN (عملیاتی)** | هر ۸ سناریو روی **سرور HTTPS واقعی محلی** (سوکت+TLS واقعی): پاسخ موفق، timeout سرور معلق، TLS نامعتبر (requests=0)، بدنه بزرگ، قطع وسط بدنه، خطای DNS، redirect رد‌شده، مقصد IP ممنوع — دو NOT RUN قبلی به تست واقعی تبدیل شد. برچسب صادقانه: شبیه‌سازی «سرور» است؛ سناریوی endpoint عملیاتی پیکربندی‌نشده → **NOT RUN** |
| P2 | TTS فارسی | **NOT RUN** | دستگاه/موتور مناسب در دسترس نیست؛ قابلیت «کامل» اعلام نمی‌شود |
| GitHub | مخزن + push | **BLOCKED** | `https://github.com/aresmaeily2/riazi-yar` از وب بی‌احراز **404** (ناموجود یا private)؛ محیط فاقد هرگونه اعتبارنامه (gh CLI / token / credential)؛ به‌جای اقدام بدون اجازه: `riazi_yar_v1.0.3-exec.bundle` (تمام تاریخچه/شاخه‌ها) + دستورالعمل push آماده شد — مخزن Private بسازید و bundle را push کنید |

## ۲) نتایج رسمی روی کامیت نهایی کد `6b1704f`
- `flutter analyze` → **No issues found!** — exit **0** (`analyze_output_v1.0.3-exec.txt`)
- `flutter test` → **۱۲۶ پاس، ۰ شکست، ۰ skip** — exit **0** (`test_output_v1.0.3-exec.txt`)
- مقایسه با baseline سورس تحویلی (`e790842`): ۱۰۷+۲skip → ۱۲۶/۱۲۶
  (دو skip با تست واقعی جایگزین + ۱۷ تست جدید امنیتی/حریم خصوصی)
- بیلد: `gradle assembleInternalTest -Ptarget-platform=android-arm,android-arm64` → BUILD SUCCESSFUL (log در بسته)
- کامیت‌ها: `e790842`(baseline) → `c24cf47`(P1-6+P1-7) → `d915b93`(P1-5)
  → `2d95e8d`(.gitignore) → `88ad605`(docs) → `6b1704f`(version+TESTING)
  → `37dcf8d`(governance) — commit آخر (این سند) صرفاً مستندات است و
  **هیچ تغییر کد پس از `6b1704f`** رخ نداده است.

## ۳) قواعد رعایت‌شده
- هیچ قابلیت جدیدی به MVP اضافه نشد؛ سه seam تزریق تستی با پیش‌فرض
  سخت‌گیرانه (DECISION_LOG D-104) بدون تغییر رفتار تولیدی.
- بدون API key/keystore/رمز/داده کودک در سورس، commit، log و APK.
- درس/ذخیره/راهنمای محلی بدون اینترنت کار می‌کنند؛ fallback محلی حفظ شد.
- dependency جدید اضافه **نشد**.
- متن و رابط فارسی RTL دست‌نخورده.
- کنترل‌های موجود تضعیف نشد (RECORD_AUDIO حذف/STT خاموش/allowBackup=false/
  endpoint پیش‌فرض خالی — همه در APK جدید راستی‌آزمایی شد).
- گواهی تست `test/fixtures/tls/` گواهی دورریز self-signed برای سرور
  تست محلی است — غیرمحرمانه، بدون ارزش امنیتی، مستند در خود فایل تست.

## ۴) NOT RUN / BLOCKED (علت + گام بعدی)
| مورد | وضعیت | علت | گام بعدی |
|---|---|---|---|
| تأیید معلم | BLOCKED | دسترسی ندارد | جلسه بازبینی + ثبت تأیید کتبی |
| تست دستگاه واقعی | NOT RUN | دستگاه نیست | اجرای چک‌لیست `docs/LIMITATIONS.md` |
| TTS فارسی | NOT RUN | دستگاه/موتور نیست | آزمون روی گوشی با موتور فارسی |
| HTTPS عملیاتی | NOT RUN | سرور پیکربندی‌نشده | فراهم‌کردن endpoint + تست چرخه واقعی |
| GitHub push | BLOCKED | بدون اعتبارنامه | token بسازید → repo Private → `git clone bundle → push` |
| انتشار عمومی | BLOCKED | g4/g6 باز + تست میدانی | پس از گیت‌ها + تأیید مالک |

## ۵) روش بازتولید
```bash
# محیط: Flutter 3.47.7 / Dart 3.13.5 / JDK 21 / Android SDK 35+36 / Gradle 9.3.1
git clone riazi_yar_v1.0.3-exec.bundle riazi_yar && cd riazi_yar
git checkout fix/audit-v1.0.3-exec
flutter pub get
flutter analyze                 # → No issues found! (exit 0)
flutter test                    # → +126 All tests passed! (exit 0)
printf 'sdk.dir=<SDK>\nflutter.sdk=<FLUTTER>\nflutter.versionCode=5\nflutter.versionName=1.0.3\n' > android/local.properties
cd android && gradle assembleInternalTest -Ptarget-platform=android-arm,android-arm64
# → build/app/outputs/apk/internalTest/app-internalTest.apk (SHA-256 بالا)
```
