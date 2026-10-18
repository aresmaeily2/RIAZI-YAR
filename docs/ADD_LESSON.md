# راهنمای افزودن درس جدید — ریاضی‌یار (MVP)

نسخه سند: ۱.۰.۰

**اصل:** افزودن درس نیازی به تغییر موتور، صفحه یا منطق ارزیابی ندارد.
فقط محتوا + یک خط ثبت.

## مراحل

### ۱) فایل JSON را بسازید

مسیر: `assets/lessons/lesson_<نام>.json` — قالب کامل و قواعد اعتبارسنجی در
`docs/DATA_MODEL.md` (بخش ۲). الگو را از `assets/lessons/lesson_l1_counting_1_5.json`
کپی کنید و مقادیر را عوض کنید.

نکته‌های مهم:
- `id` هر درس/فعالیت/پرسش باید در **کل اپ** یکتا باشد (تغییر ندهید بعد از انتشار؛
  شناسه‌ها کلید پیشرفت‌اند).
- `contentVersion` را بالا ببرید وقتی محتوای یک درس موجود را تغییر می‌دهید.
- `hints` نباید پاسخ را لو بدهد (قاعده اعتبارسنجی/تربیتی).
- ارقام گزینه‌ها باید فارسی باشند (۰۱۲۳۴۵۶۷۸۹).

### ۲) فایل را در فهرست ثبت کنید

در `lib/core/content/lesson_content.dart`:

```dart
static const List<String> bundledLessonAssets = [
  'assets/lessons/lesson_l1_counting_1_5.json',
  'assets/lessons/lesson_l2_counting_6_9.json',
  'assets/lessons/quiz_final_short.json',
  'assets/lessons/lesson_<نام>.json',   // ← خط جدید
];
```

(خودکار کردن این فهرست برای نسخه بعدی در نظر گرفته شده است — `LIMITATIONS.md`)

### ۳) اعتبارسنجی و تست

```bash
flutter test test/lesson_content_test.dart   # قواعد محتوا
flutter test                                  # کل مجموعه
flutter analyze
```

تست پیشنهادی برای درس جدید — به `test/lesson_content_test.dart` یک مورد اضافه کنید
که فایل جدید را از دیسک می‌خواند و `LessonContentLoader.loadFromJsonString` را صدا می‌زند.

### ۴) بیلد دوباره

```bash
flutter build apk --release --target-platform android-arm,android-arm64
```

محتوای جدید داخل APK قرار می‌گیرد (کاملاً آفلاین).

## جدول عیب‌یابی

| پیام خطا | علت | اصلاح |
|---|---|---|
| `اعتبارسنجی "…" ناموفق: itemCount باید ۰ تا ۲۰ باشد` | تعداد اشیای خارج از بازه پایه اول | `itemCount` را اصلاح کنید |
| `در countAndChoose تعداد اشیا باید با پاسخ صحیح برابر باشد` | ناسازگاری `itemCount` و `correctAnswer` | یکی را اصلاح کنید |
| `در matchCount دقیقاً یک دسته با تعداد درست لازم است` | دو گزینه با مقدار درست یا هیچ | گزینه‌ها را اصلاح کنید |
| `گزینه‌های تکراری مجاز نیست` | دو `value` برابر | مقادیر گزینه‌ها |
| `JSON نامعتبر در "…"` | خطای نحوی | ویرایشگر JSON با اعتبارسنج |
