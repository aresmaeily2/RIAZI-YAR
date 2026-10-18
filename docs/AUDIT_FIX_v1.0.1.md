# گزارش اصلاح ممیزی — ریاضی‌یار ۱.۰.۰ → ۱.۰.۱

نسخه: ۱.۰.۱+۲ | تاریخ: ۲۰۲۶-۱۰-۱۷ | دامنه: فقط رفع ایرادهای ممیزی؛ بدون قابلیت جدید

## ۱) فهرست فایل‌های تغییرکرده و علت هر تغییر

### امنیت — STT (بند ۱-۱ ممیزی)

| فایل | تغییر | علت |
|---|---|---|
| `android/app/src/main/AndroidManifest.xml` | حذف `RECORD_AUDIO` + حذف query `RecognitionService` + افزودن سیاست backup | اپ نباید به میکروفون دسترسی داشته باشد وقتی مسیر داده صدا قابل راستی‌آزمایی نیست |
| `pubspec.yaml` / `pubspec.lock` | حذف وابستگی `speech_to_text`؛ نسخه → `1.0.1+2` | هیچ کدی از مسیر STT نباید در APK باشد؛ برچسب نسخه ممیزی |
| `lib/core/audio/stt_service.dart` | بازنویسی: حذف `AndroidSttService` (پلاگین‌محور)؛ افزودن `DisabledSttService` + ثابت `kSpeechInputAvailable=false` | غیرفعال‌سازی امن با پاسخ صادقانه «در دسترس نیست»؛ حفظ قرارداد برای فعال‌سازی آینده |
| `lib/app_services.dart` | تزریق `DisabledSttService` به‌جای `AndroidSttService` | پیش‌فرض امن؛ مسیر لمسی دست‌نخورده |
| `lib/core/models/models.dart` | پیش‌فرض `speechInputEnabled` → `false` + مستند | پیش‌فرض‌های امن؛ فیلد برای سازگاری داده حفظ شد |
| `lib/ui/screens/activity_screen.dart` | دکمه‌ها/متن میکروفون gated با `kSpeechInputAvailable`؛ منطق fallback راهنما به هسته منتقل شد | UI پنهان در سطح بیلد؛ تست‌پذیری fallback |
| `lib/ui/screens/parent_screen.dart` | سوییچ میکروفون → توضیح صادقانه «غیرفعال در این نسخه»؛ زیرنویس TTS بدون ادعای آفلاین | توضیح قابل فهم برای والد (الزام ممیزی)؛ حذف ادعای غیرقابل اثبات |
| `lib/main.dart` | حذف `_toggleSpeech` و پاس دادن آن | قابلیت غیرفعال است؛ سوییچ بی‌معنا |

### امنیت — Backup (بند ۱-۲)

| فایل | تغییر | علت |
|---|---|---|
| `android/app/src/main/AndroidManifest.xml` | `allowBackup="false"` + `dataExtractionRules` + `fullBackupContent` | داده کودک نباید در پشتیبان ابری/D2D برود |
| `android/app/src/main/res/xml/data_extraction_rules.xml` | **جدید** — exclude همه دامنه‌ها برای cloud-backup و device-transfer | قواعد صریح API 31+ |
| `android/app/src/main/res/xml/full_backup_content.xml` | **جدید** — exclude همه دامنه‌ها | قواعد صریح API 23-30 (سازگاری) |

### امنیت — کلاینت HTTP (بند ۱-۳)

| فایل | تغییر | علت |
|---|---|---|
| `lib/core/guide/ai_guide_http.dart` | افزودن `validateGuideEndpoint` (فقط HTTPS، host معتبر، رد user:pass/fragment — قبل از اتصال) و `readCappedUtf8` (سقف ۸KB جریانی بدون انباشت کامل)؛ اتصال هر دو به `respond()`؛ `isConfigured` مبتنی بر اعتبارسنجی | الزامات صریح ممیزی |
| `lib/core/guide/guide_resolver.dart` | **جدید** — منطق انتخاب موتور/fallback از UI به هسته | تست‌پذیری مستقیم رفتار fallback (الزام ممیزی) |
| `test/ai_guide_http_test.dart` | **جدید** — ۱۳ تست فعال + ۲ skip (NOT RUN ثبت‌شده) | پوشش الزامات: سقف، رد HTTP، endpoint نامعتبر، قطع زودهنگام جریان (سوکت واقعی) |
| `test/guide_resolver_test.dart` | **جدید** — ۶ تست fallback | پوشش بند «رفتار fallback» ممیزی |

### امنیت — امضا (بند ۱-۴)

| فایل | تغییر | علت |
|---|---|---|
| `android/app/build.gradle.kts` | release: `signingConfig=null` (امضانشده)؛ build type جدید `internalTest` با امضای debug + پسوند `-internal-test` + `isDebuggable=false` | جداسازی تست داخلی از انتشار؛ عدم استفاده از کلید debug برای انتشار؛ بدون keystore ساختگی — انتشار BLOCKED |

### پاک‌سازی و بازتولیدپذیری (بند ۲ ممیزی)

| فایل | تغییر | علت |
|---|---|---|
| `.gitignore` | افزودن `android/local.properties`، `GeneratedPluginRegistrant*`، `.cxx/`، `.gradle/`، `.flutter-plugins*` | فایل‌های محیطی/تولیدشده هرگز در سورس نباشند |
| `android/local.properties`، `*.iml` | از بسته سورس حذف شدند (git archive فقط فایل‌های ردیابی‌شده) | نشت مسیرهای مطلق ماشین سازنده در ZIP ۱.۰.۰ |
| `docs/TESTING.md`، `docs/FINAL_REPORT.md` | حذف مسیرهای مطلق از دستورالعمل؛ دستور عمومی | بازتولیدپذیری روی محیط دیگر |
| ZIP تحویلی | بازسازی با `git archive` از کامیت | تضمین نبود فایل‌های محیطی |

### مستندات

| فایل | تغییر |
|---|---|
| `docs/SECURITY_PRIVACY.md` | **جدید** — گزارش امنیت/حریم خصوصی/محدودیت‌ها |
| `docs/AI_STT_TTS.md` | تحلیل مسیر داده STT + چک‌لیست فعال‌سازی مجدد + صداقت TTS + قواعد جدید HTTP |
| `docs/ACCEPTANCE.md` | وضعیت PASS/FAIL/NOT RUN/BLOCKED برای ۱۳ بند + بندهای ممیزی |
| `docs/TESTING.md` | پوشش تست‌های جدید + نتایج ۷۵ + دستور عمومی بازتولید |
| `README.md` | به‌روزرسانی نسخه و وضعیت ممیزی |

## ۲) چیزی که تغییر نکرد (عمدی)

- منطق آموزشی، محتوای درس‌ها، مدل داده، صفحه‌ها — خارج از دامنه ممیزی.
- مسیر پاسخ‌دهی کودک با دکمه‌های لمسی — باید کامل و آفلاین می‌ماند (شد).
- `contentVersion` محتوای درس‌ها (۱.۰.۰) — محتوا تغییر نکرده؛ جدا از نسخه اپ.

## ۳) هش‌ها و صحت‌سنجی خروجی (محاسبه واقعی پس از بیلد — ۲۰۲۶-۱۰-۱۷)

**APK تست داخلی** — `riazi_yar_v1.0.1+2_internaltest_debugsigned.apk` (۵۳.۶MB، بدون minify):
- SHA-256: `adb6dbc5e6fc422925b7771c73fdce9c8136796141a5dbff7f7b3ae6bd9830d1`
- aapt2 badging: `com.mathmvp.riazi_yar`، versionCode **2**، versionName
  **1.0.1-internal-test**، minSdk **24**، targetSdk **36**، compileSdk **36**
- مجوزها: فقط `INTERNET` (+ مجوز سیستمی DYNAMIC_RECEIVER) —
  **RECORD_AUDIO وجود ندارد** ✓
- Manifest: `allowBackup=false`، `dataExtractionRules` و `fullBackupContent`
  هر دو متصل ✓
- امضا: apksigner verify — معتبر؛ گواهی **Android Debug** (عمداً؛ فقط تست داخلی)
- انتشار عمومی: **BLOCKED** — بدون keystore منتشرکننده؛ build type `release`
  امضانشده تولید می‌شود.

**ZIP سورس تمیز** — `riazi_yar_source_v1.0.1.zip` (۱۲۷ فایل، ۳۷۷KB؛ از git archive):
- SHA-256: `896aa7b3b6cd249f39adbf05a37703ce60bca5096d0e03ca03194942129a96c1`
- فاقد: `local.properties`، `*.iml`، `.idea/`، `.dart_tool/`، `build/`، هر keystore
- اسکن الگوی راز (password/api_key/secret/PRIVATE KEY): فقط واژه «keystore»
  در کامنت سیاست امضا — هیچ راز واقعی

**خروجی خام تست/تحلیل** — `test_output_v1.0.1.txt`:
- SHA-256: `63f162d491600d15580d8d97041ca55a6dbfe594b8f90653ce8218a1a82fd453`
- `flutter analyze` → No issues found
- `flutter test` → **۷۵ پاس، ۰ شکست، ۲ skip (NOT RUN ثبت‌شده)**

**یادداشت بیلد:** minify/shrink برای build type «internalTest» صریحاً خاموش
شد (محدودیت حافظه/دیسک محیط با R8؛ برای تست داخلی ضرورتی ندارد).
build type «release» طبق پیکربندی پلاگین Flutter بهینه می‌ماند.

## ۴) وضعیت‌های غیر PASS (خلاصه)

- **NOT RUN**: اجرا روی دستگاه/شبیه‌ساز؛ چرخه کامل HTTPS؛ بازیابی پشتیبان واقعی؛ کیفیت صوت.
- **BLOCKED**: انتشار عمومی امضادار (نیازمند keystore منتشرکننده).
- **FAIL**: هیچ‌کدام.
