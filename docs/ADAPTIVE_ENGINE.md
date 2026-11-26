# مستند موتور یادگیری تطبیقی و الگوریتم SM-2 (`docs/ADAPTIVE_ENGINE.md`)

## ۱. الگوریتم زمان‌بندی مرور فاصله‌دار (SuperMemo SM-2)
در `AdaptiveLearningEngine.computeSm2Schedule`:
- کیفیت پاسخ (`quality` از ۰ تا ۵): پاسخ صحیح بدون راهنما = `5`، با ۱ راهنما = `4`، با بیش از ۱ راهنما = `3`، پاسخ نادرست = `1`.
- اگر `quality < 3`: شمارنده تکرار (`repetitionCount`) به `0` و فاصله مرور (`intervalDays`) به `1` روز بازنشانی می‌شود و آیتم بلافاصله در صف مرور (`dueEpochMs = nowMs`) قرار می‌گیرد.
- اگر `quality >= 3`:
  - تکرار اول (`n = 1`): فاصله مرور = `1` روز
  - تکرار دوم (`n = 2`): فاصله مرور = `6` روز
  - تکرار سوم به بعد (`n > 2`): فاصله مرور = `round(currentIntervalDays * easeFactor)`
- ضریب آسانی (`easeFactor`): طبق فرمول استاندارد `EF' = max(1.3, EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))` در بازه `[1.3, 3.0]` به‌روز می‌شود.

## ۲. محاسبه تکمیل واقعی درس و ستاره‌ها (`evaluateLessonCompletion`)
یک درس تنها زمانی `completed = true` می‌شود که هر ۴ شرط زیر برقرار باشند:
1. `examplesViewed == true`
2. `guidedCompleted == true`
3. `practiceAnsweredCount >= totalPracticeQuestions`
4. `assessmentScorePercent >= passingThresholdPercent` (۸۰٪)
