# گزارش وضعیت اجرای Emulator و شبیه‌ساز تعاملی (`docs/EMULATOR_REPORT.md`)

## ۱. وضعیت صادقانه اجرای Android Emulator سخت‌افزاری (KVM)
- **وضعیت در سندباکس ابری فعلی:** `BLOCKED` (محیط کانتینر فاقد `/dev/kvm` برای بالا آوردن ماشین مجازی Android Emulator است).
- **راه‌حل‌های جایگزین پیاده‌سازی‌شده و فعال:**
  1. **Workflow خودکار GitHub Actions (`.github/workflows/android_native_ci.yml`):** شامل گام `reactivecircus/android-emulator-runner@v2` روی `macos-latest` با شتاب‌دهنده سخت‌افزاری برای اجرای `connectedDebugAndroidTest` (`MainNavigationUiTest`) و ضبط Logcat/Screenshots به محض Push شدن شاخه در GitHub.
  2. **شبیه‌ساز تعاملی زنده Android Native V2 در وب‌اپلیکیشن ممیزی (`/simulator`):** تمام صفحات، مسیر کامل یادگیری ۳۹ درس و هر ۶ ابزار دست‌ورزی دقیقاً از روی ۲۳۵ فایل JSON واقعی پروژه در محیط وب رندر و قابل تعامل مستقیم هستند.
