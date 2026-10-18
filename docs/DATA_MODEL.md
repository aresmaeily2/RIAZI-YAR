# مدل داده و قالب محتوای درس — ریاضی‌یار (MVP)

نسخه سند: ۱.۰.۰

## ۱) مدل داده

### ۱.۱) مدل منطقی (کلاس‌های Dart — `lib/core/models/models.dart`)

| کلاس | فیلدهای کلیدی | نقش |
|---|---|---|
| `Lesson` | `id, title, description, unit, contentVersion, kind(regular/quiz), teacherReviewed, activities[]` | ریشه محتوای یک درس؛ `contentVersion` همان «LessonVersion» ساده‌شده است |
| `Activity` | `id, type(countAndChoose/matchCount), instruction, difficulty, questions[]` | یک فعالیت آموزشی |
| `Question` | `id, prompt, itemShape, itemCount, options[], correctAnswer, hints[3], feedbackCorrect, feedbackWrong` | یک پرسش با راهنمای مرحله‌ای |
| `AnswerOption` | `value, label` | یک گزینه (ساده‌سازی مستندشده: گزینه عددی است) |
| `Attempt` | `id, lessonId, activityId, questionId, isCorrect, chosenValue, hintUsed, createdAt` | هر تک‌تلاش کودک (تاریخچه کامل) |
| `LearningProgress` | `lessonId, activityId, correctCount, wrongCount, mastered, updatedAt` | تجمعیِ هر فعالیت |
| `LearnerSettings` | `childName, voiceGuideEnabled, speechInputEnabled, onlineGuideEnabled, masteryThreshold` | تنظیمات غیرحساس |
| `ParentSummary` | `totalAttempts, totalCorrect, activitiesStarted, activitiesMastered, lastQuizTitle/Score, needsPracticeTitles[]` | خروجی داشبورد والدین |

### ۱.۲) طرح SQLite (نسخه ۱ — `lib/core/storage/database.dart`)

```sql
attempts(id PK AUTOINCREMENT, lesson_id, activity_id, question_id,
         is_correct, chosen_value, hint_used, created_at,
         INDEX idx_attempts_question, INDEX idx_attempts_time)
progress(lesson_id+activity_id PK, correct_count, wrong_count, mastered, updated_at)
settings(key PK, value)                    -- فقط داده غیرحساس
sync_queue(id, entity, entity_id, payload, created_at, synced)  -- برای همگام‌سازی آینده
```

اصل ثبت: **افزایشی و در تراکنش** — هر `recordAttempt` یک ردیف در `attempts` می‌سازد
و `progress` را همان‌جا به‌روز می‌کند؛ هیچ محاسبه تکراری پیشرفت وجود ندارد و ثبت
دوبارهٔ همان تلاش، پیشرفت را دوباره جمع نمی‌زند (تست‌شده).

### ۱.۳) معناشناسی امتیاز (مهم)

- **امتیاز جلسه/آزمون** = نسبتِ پرسش‌هایی که «نخستین تلاششان درست» بوده به کل پرسش‌ها.
- تلاش‌های اصلاحی همان پرسش ثبت می‌شوند (در `attempts` و در گزارش والدین) اما
  امتیاز را افزایش نمی‌دهند. این تصمیم عمدی و در تست واحد پوشش داده شده است.
- امتیاز آزمون والدین از نخستین تلاش هر پرسش در DB محاسبه می‌شود
  (`ProgressRepository.quizFirstTryScore`).
- «تسلط» یک فعالیت: `accuracy ≥ masteryThreshold (پیش‌فرض ۰.۷۵)` و `حداقل ۲ تلاش`.

## ۲) قالب فایل محتوای درس (JSON)

فایل‌ها در `assets/lessons/` و نام‌گذاری `lesson_<id>.json`. ساختار کامل:

```jsonc
{
  "id": "l1_counting_1_5",              // یکتا، لاتین، بدون فاصله
  "title": "شمارش اشیا (۱ تا ۵)",
  "description": "…",                    // نمایش در خانه
  "unit": "…",                           // واحد آموزشی
  "contentVersion": "1.0.0",             // نسخه محتوا (semver)
  "kind": "regular",                     // "regular" یا "quiz"
  "teacherReviewed": false,              // false ⇒ برچسب «نیازمند بازبینی معلم»
  "activities": [
    {
      "id": "l1_a1",                     // یکتا در کل اپ
      "type": "countAndChoose",          // یا "matchCount"
      "instruction": "…",                // دستور فعالیت (خوانده می‌شود)
      "difficulty": 1,
      "questions": [
        {
          "id": "l1_a1_q1",
          "prompt": "چند سیب می‌بینی؟",
          "itemShape": "apple",          // apple|star|ball|flower|fish|bird
          "itemCount": 3,                // تعداد اشیای رسم‌شده
          "options": [
            {"value": 2, "label": "۲"},  // label باید ارقام فارسی باشد
            {"value": 3, "label": "۳"},
            {"value": 4, "label": "۴"}
          ],
          "correctAnswer": 3,
          "hints": ["هینت ۱", "هینت ۲", "هینت ۳"],   // دقیقاً مرحله‌ای؛ بدون لو دادن پاسخ
          "feedbackCorrect": "آفرین! …",
          "feedbackWrong": "اشکالی ندارد! …"
        }
      ]
    }
  ]
}
```

### ۲.۱) قواعد اعتبارسنجی (اجباری — در `LessonContentLoader.validate`)

- `itemCount` و `correctAnswer`: عدد صحیح ۰ تا ۲۰ (تناسب پایه اول).
- حداکثر ۶ گزینه برای هر پرسش؛ مقادیر گزینه‌ها یکتا.
- در `countAndChoose`: `itemCount == correctAnswer` (اجباری).
- در `matchCount`: دقیقاً یک گزینه با `value == correctAnswer`.
- هر فایل هنگام بارگذاری اعتبارسنجی می‌شود؛ خطا ⇒ اپ با پیام کنترل‌شده پیام می‌دهد
  و درس بارگذاری نمی‌شود (تست: `lesson_content_test`).
- **قاعده تربیتی الزامی:** راهنماها (`hints`) نباید پاسخ را مستقیماً بگویند؛
  باید «چگونه شمردن» را آموزش دهند.

## ۳) حفظ حریم خصوصی در مدل داده

- فقط پیشرفت یادگیری، تنظیمات غیرحساس (نام مستعار کودک) و تلاش‌ها ذخیره می‌شود.
- هیچ داده‌ای خارج از دستگاه ارسال نمی‌شود (`NoopSyncService`).
- ردیابی کاربر/دستگاه، تبلیغات، تحلیل‌گر شخص ثالث: وجود ندارد.

## ۴) طرح پایگاه داده نسخه ۲ — شناسه اجرا (ممیزی ۱.۰.۲)

جدول `attempts` ستون `run_id TEXT` دارد (ایندکس `idx_attempts_run`):

- **منشأ**: هر `LessonSession` هنگام ساخت یک `runId` یکتا می‌گیرد و همه
  تلاش‌های همان جلسه آن را حمل می‌کنند.
- **مصرف**: امتیاز آزمون در گزارش والدین از `lastQuizRunScore` محاسبه
  می‌شود — فقط تلاش‌های «آخرین اجرا»، با ملاک نخستین تلاش هر پرسش در همان
  اجرا (سازگار با امتیاز صفحه نتیجه همان اجرا).
- **مهاجرت ۱→۲** (`AppDatabase.migrateV1ToV2`):
  - `ALTER TABLE attempts ADD COLUMN run_id TEXT` + ایندکس.
  - backfill قطعی: رکوردها بر اساس (created_at، id) مرتب؛ رکوردهای
    هم‌درس با فاصله ≤ ۱۰ دقیقه یک اجرا فرض و run_id مصنوعی
    (`migrated_<lesson_id>_<ts>`) می‌گیرند.
  - کل مهاجرت در یک تراکنش است؛ تست واقعی مهاجرت روی فایل DB نسخه ۱
    در `storage_test` موجود است.
