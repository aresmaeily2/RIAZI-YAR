# TASK BOARD — ریاضی‌یار

به‌روزرسانی: ۲۰۲۶-۱۰-۱۸ (مأموریت دستورکار ۱.۰.۳)
وضعیت‌های مجاز: TODO / DOING / PASS / NOT RUN / BLOCKED

## P0 — موانع اصلی
| # | کار | وضعیت | شاهد |
|---|---|---|---|
| ۰-۱ | استخراج سورس ۱.۰.۳ + تعیین نسخه ابزار + baseline پیش از اصلاح | **PASS** | baseline_analyze/test.txt (exit 0، ۱۰۷+۲skip)؛ PROJECT_MEMORY (ابزارها) |
| ۰-۲ | بیلد APK متناظر سورس + راستی‌آزمایی (badging/certs/hash) | **PASS** | APK versionCode 5 / 1.0.3-internal-test؛ aapt2_badging*.txt؛ apksigner_print_certs*.txt؛ SHA-256 `7f0b9736...` |
| ۰-۳ | بازبینی معلم پایه اول (اهداف، متن‌ها، دشواری، بازخورد، تناسب سنی) | **BLOCKED** | معلم در دسترس نیست؛ محتوا «نمونه، تأییدنشده» (teacherReviewed=false) |
| ۰-۴ | تست دستگاه واقعی (مسیر کامل، آفلاین، رفتار خطا) | **NOT RUN** | دستگاه در دسترس نیست؛ چک‌لیست اجرای میدانی در docs/LIMITATIONS |

## P1 — امنیت و کیفیت
| # | کار | وضعیت | شاهد |
|---|---|---|---|
| ۱-۵ | هماهنگی متن رضایت با payload واقعی | **PASS** | privacy_texts.dart؛ دیالوگ main.dart؛ تست «دقیقاً شش فیلد» |
| ۱-۶ | سخت‌سازی endpoint (DNS rebinding/۱۰۰.۶۴/۱۰/reserved/redirect) | **PASS** | ai_guide_http.dart؛ تست‌های رد مقصد ممنوع با شمارنده اتصال=۰ |
| ۱-۷ | ماتریس تست HTTPS (۸ سناریو) | **PASS (محلی)** | ماتریس روی سرور TLS واقعی محلی؛ سناریوی endpoint عملیاتی **NOT RUN** |

## P2 — گفتار فارسی
| # | کار | وضعیت | شاهد |
|---|---|---|---|
| ۲-۱ | آزمون TTS فارسی روی دستگاه | **NOT RUN** | دستگاه/موتور مناسب در دسترس نیست؛ قابلیت «کامل» اعلام نمی‌شود |

## زیرساخت و تحویل
| # | کار | وضعیت | شاهد |
|---|---|---|---|
| ۳-۱ | بررسی مخزن GitHub + ایجاد Private | **BLOCKED** | 404 بی‌احراز؛ بدون token/gh؛ D-108 |
| ۳-۲ | آماده‌سازی push-ready (bundle + دستورالعمل) | **PASS** | riazi_yar_v1.0.3-exec.bundle |
| ۳-۳ | governance (charter/memory/decisions/board/gates/roles) | **PASS** | همین پوشه — ساخته‌شده در این مأموریت |
| ۳-۴ | manifest هش‌ها + بسته تحویل | **PASS** | SHA256SUMS_v1.0.3-exec.txt |
| ۳-۵ | انتشار عمومی | **BLOCKED** | QUALITY_GATES: g2/g4/g5/g6 باز |

## TODO بعدی (مالک/تیم)
1. تأمین اعتبارنامه GitHub (token با دسترسی repo) → ساخت Private repo → push bundle.
2. هماهنگی جلسه بازبینی با معلم پایه اول → گیت ۰-۳.
3. اجرای چک‌لیست دستگاه (docs/LIMITATIONS) روی گوشی واقعی → گیت ۰-۴ و P2.
4. ایجاد keystore منتشرکننده + بیلد release امضاشده → رفع BLOCKED انتشار.
5. فراهم‌کردن endpoint عملیاتی (سرور واسط) → تست چرخه واقعی HTTPS.
