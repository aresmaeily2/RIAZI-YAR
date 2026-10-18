# PROJECT MEMORY — ریاضی‌یار

حافظه اجرایی پروژه. هر مأموریت پیش از تغییر کد این فایل را می‌خواند و
پس از پایان، وضعیت واقعی را اینجا ثبت می‌کند (فقط وضعیت دارای شاهد).

## وضعیت فعلی (به‌روزرسانی: ۲۰۲۶-۱۰-۱۸ — مأموریت دستورکار ۱.۰.۳)

### محیط ساخت (بازیابی‌شده از snapshot /tmp/my-project)
| ابزار | نسخه | محل |
|---|---|---|
| Flutter | 3.47.7 stable (Dart 3.13.5) | tools/flutter |
| JDK | Temurin 21.0.12+1 | /tmp/my-project/tools/jdk-21.0.12.1+1 |
| Android SDK | platform 35+36، build-tools 35/36، NDK 28.2 | /tmp/my-project/tools/android-sdk |
| Gradle | 9.3.1 | /tmp/my-project/tools/gradle-9.3.1 |

- Flutter پس از هر reset فضای کاری باید دوباره نصب شود (download از
  storage.flutter-io.cn سریع‌تر از googleapis است؛ آینه byte-range
  پشتیبانی نمی‌کند).
- فرآیندهای پس‌زمینه بین فراخوانی‌های ابزار کشته می‌شوند → دانلود/بیلد
  foreground انجام شود.
- نسخه بسته: `1.0.3+5` (versionCode 5) — تمایز artifactهای این اجرا از
  بستهٔ تحویلی قبلی (1.0.3+4).

### هویت گیت‌هاب
- مخزن مقصد: `https://github.com/aresmaeily2/riazi-yar` — **وجود ندارد
  (HTTP 404 از وب بی‌احراز؛ می‌تواند «وجود ندارد» یا «private» باشد)**.
- محیط فاقد اعتبارنامه (بدون gh CLI، بدون token، بدون credential helper)
  → ساخت مخزن/push در این محیط **BLOCKED**؛ git bundle آماده push فراهم شد.

### گیت‌های باز (همه دارای شاهد)
| گیت | وضعیت | توضیح |
|---|---|---|
| اعتبار آموزشی معلم | **BLOCKED** | معلم پایه اول در دسترس نیست؛ محتوا «نمونه، تأییدنشده» است |
| تست دستگاه واقعی | **NOT RUN** | دستگاه اندروید در دسترس نیست |
| TTS فارسی روی دستگاه | **NOT RUN** | همان |
| HTTPS روی endpoint عملیاتی | **NOT RUN** | سرور پیکربندی‌شده وجود ندارد (تست محلی TLS واقعی PASS شد) |
| مخزن GitHub | **BLOCKED** | بدون اعتبارنامه؛ bundle آماده |
| انتشار عمومی | **BLOCKED** | keystore منتشرکننده + گیت‌های بالا لازم است |

### نکات فنی مهم (پایدار)
- dart:io هنگام کارخانه اتصال سفارشی، TLS خودکار اعمال نمی‌کند؛ کارخانه
  باید خودش `SecureSocket.secure` با نام اصلی بسازد (پین مقصد + SNI).
- بیلد مستقیم gradle نیازمند `flutter.versionCode/Name` در
  `android/local.properties` است (gitignored؛ از pubspec مشتق شود) —
  وگرنه versionCode=1 ساخته می‌شود.
- تست ویجت با DB واقعی: ملاحظات FakeAsync/native-assets —
  docs/TESTING.md.
- ZIP سورس با `git archive` از کامیت مشخص ساخته می‌شود (بدون فایل محیطی).
