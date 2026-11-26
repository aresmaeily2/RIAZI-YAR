# گزارش امنیت و حریم خصوصی کودک (`docs/SECURITY_PRIVACY.md`)

## ۱. ممیزی Manifest نهایی و مجوزها
بررسی انجام‌شده با ابزار رسمی `aapt2 dump permissions app-release-unsigned.apk`:
- مجوز `android.permission.INTERNET`: **ندارد (حذف کامل)**
- مجوز `android.permission.RECORD_AUDIO`: **ندارد**
- مجوز `android.permission.POST_NOTIFICATIONS`: **حذف شد** (در کد اولیه برنامه‌نویس وجود داشت که برای رعایت حداقل‌گرایی حذف گردید).
- تنها مجوز موجود در فایل نهایی، مجوز داخلی AndroidX (`DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` با سطح حفاظت `signature`) است.

## ۲. محافظت از داده‌های کودک و غیرفعال‌سازی پشتیبان‌گیری
- در `AndroidManifest.xml`: ویژگی `android:allowBackup="false"` به همراه `@xml/backup_rules` و `@xml/data_extraction_rules` تنظیم شده است تا داده‌های کودک به هیچ فضای ابری یا دستگاه دیگری منتقل نشود.
- در بخش والدین (`PARENT_SETTINGS`): قابلیت حذف کامل و تراکنشی تمام داده‌های کودک (`resetAllChildData`) تعبیه شده است.

## ۳. شفافیت درباره ParentGate
گیت والدین (`ParentGate.kt`) دارای چالش تصادفی `(A × B) + C`، قفل ۶۰ ثانیه‌ای پس از ۳ خطا، قفل خودکار ۵ دقیقه‌ای و قفل خودکار هنگام رفتن برنامه به پس‌زمینه (`ON_PAUSE`) است. با این حال، در رابط کاربری و مستندات صریحاً اعلام شده است که هیچ گیت سمت کلاینت جایگزین احراز هویت رمزنگاری یا قفل سیستم‌عامل نیست.
