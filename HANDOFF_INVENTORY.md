# سیاهه کامل محتویات بسته تحویلی برنامه‌نویس (`HANDOFF_INVENTORY.md`)

- **نام فایل ورودی اصلی:** `RIAZI_YAR_NATIVE_V2_COMPLETE_HANDOFF.zip`
- **حجم دقیق:** ۱۵,۲۱۶,۷۸۲ بایت (۱۵ مگابایت)
- **هش SHA-256 واقعی محاسبه‌شده:** `f1d8e0de75f9448e5dfb98c96d22ff9c7c5b47ddfde81bdf73a2150818263804`
- **تطابق با هش گزارش‌شده قبلی:** ۱۰۰٪ منطبق (`MATCH`)
- **تعداد کل فایل‌های استخراج‌شده:** ۵۵۳ فایل

## تفکیک پوشه‌های بسته تحویلی

| ردیف | مسیر پوشه | تعداد فایل | شرح محتوا و وضعیت واقعی در ممیزی |
|---|---|---|---|
| ۱ | `00_MASTER_INDEX/` | ۴ | فهرست فایل‌ها، ماتریس شکاف اولیه و `SHA256SUMS.txt` |
| ۲ | `01_ANDROID_NATIVE_SOURCE/` | ۲۵۷ | سورس Kotlin/Jetpack Compose (۱۵ فایل `.kt` اصلی + ۲ فایل تست) و ۲۳۵ فایل JSON در `assets/content_v2`؛ فاقد `gradle-wrapper.jar` |
| ۳ | `02_CONTENT_V2/` | ۲۳۸ | کپی مستقل ۲۳۵ فایل JSON محتوای آموزشی پایه اول + اسناد اعتبارسنجی |
| ۴ | `03_ASSETS/` | ۱۵ | ۳ فونت وزیرمتن (`Regular`, `Bold`, `ExtraBold`) + ۱۲ آیکون برداری/تصویر آموزشی |
| ۵ | `04_TESTS/` | ۲ | کپی `InteractionValidatorTest.kt` و `MainNavigationUiTest.kt` |
| ۶ | `05_ARCHITECTURE/` | ۷ | اسناد معماری، مدل داده، موتور تطبیقی و ۴ سند ADR |
| ۷ | `06_EDUCATIONAL_AUDIT/` | ۱ | گزارش ممیزی آموزشی ۳۹ درس |
| ۸ | `07_BENCHMARK/` | ۱ | گزارش مقایسه تطبیقی ۸ محصول |
| ۹ | `08_SECURITY/` | ۱ | گزارش امنیت و حریم خصوصی |
| ۱۰ | `09_QA_REPORTS/` | ۱ | خلاصه وضعیت QA (ثبت‌شده به‌عنوان `NOT_RUN` / `BLOCKED`) |
| ۱۱ | `10_GITHUB_HANDOFF/` | ۳ | راهنمای انتقال به GitHub و CI/CD |
| ۱۲ | `11_RELEASE/` | ۱ | راهنمای بیلد و امضا |
| ۱۳ | `12_PROJECT_HISTORY/` | ۱۹ | آرشیو سورس Flutter اولیه، نسخه‌های میانی و ۴ فایل ZIP قبلی |
| ۱۴ | `13_FINAL_REPORTS/` | ۳ | گزارش تحویل نهایی، محدودیت‌ها و موارد مسدود (`BLOCKED_ITEMS.md`) |

## آرشیوهای مکمل بررسی‌شده از لینک‌های MediaFire
1. `RIAZI_YAR_COMPLETE_PROJECT_HISTORY_AND_DELIVERY.zip` — حجم: ۳.۷ مگابایت — SHA-256: `ec3a413783271d0ea29740808c3d368f9946bebd653e2828131df2facce2d3e1` (۵۶۶ فایل)
2. `RIAZI_YAR_COMPLETE_PROJECT_HISTORY_AND_FINAL_DELIVERY.zip` — حجم: ۷.۱ مگابایت — SHA-256: `e237b2033a2313f6338f102f388ac018dec22f92133ce9a74996bfbe9619986d` (۵۸۰ فایل)
