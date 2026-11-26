# گزارش جامع تست و تضمین کیفیت (`docs/TESTING.md`)

## ۱. رفع تناقض گزارش‌های قدیمی مخزن (یافته بخش ۳ مأموریت)
در بررسی اسناد قدیمی نسخه Flutter در شاخه `master`:
- فایل `README.md` عدد `75/75 پاس + 2 NOT RUN` (مربوط به تگ v1.0.1) را ذکر کرده بود.
- فایل `docs/ACCEPTANCE.md` عدد `107 پاس + 2 skip` (مربوط به تگ v1.0.2) را ذکر کرده بود.
- فایل `docs/TESTING.md` عدد `126/126 پاس، 0 skip` (مربوط به کامیت `6b1704f` در v1.0.3 پس از افزودن ۱۹ تست ماتریس HTTPS) را ثبت کرده بود.
این اختلاف ناشی از عدم به‌روزرسانی هم‌زمان README و ACCEPTANCE در کامیت `6b1704f` بوده و در `DECISION_LOG.md` مستند شد.

## ۲. نتایج اجرای واقعی تست‌های نسخه Android Native V2 (`2.1.0-beta.1`)
فرمان اجراشده در محیط لینوکس Debian 12 با OpenJDK 17.0.21 و Android SDK 35:
```bash
./gradlew testDebugUnitTest lintDebug assembleDebug assembleRelease bundleRelease --no-daemon
```
- **Exit Code:** `0` (`BUILD SUCCESSFUL`)
- **فایل گزارش خام JUnit XML:** `app/build/test-results/testDebugUnitTest/TEST-com.mathmvp.riazi_yar.InteractionValidatorTest.xml`
- **تعداد کل تست‌های جامع JUnit:** **۱۱ سوئیت تست (شامل ممیزی خودکار تک‌تک ۲۳۵ فایل JSON و ۱,۷۹۴ آیتم آموزشی)** — **۱۱ موفق، ۰ شکست، ۰ Skip**.

| نام تست در `InteractionValidatorTest` | موضوع مورد آزمون | زمان اجرا | وضعیت |
|---|---|---|---|
| `contentV2_all39LessonsAndBanksPassFullAudit` | پارس و اعتبارسنجی ۲۳۵ فایل JSON، ۸ فصل، ۳۹ درس، ۱۱۷ مثال، ۱۱۷ فعالیت هدایت‌شده، ۱۱۷۰ تمرین مستقل، ۱۹۵ جبرانی، ۱۹۵ سنجش، ۰ شناسه تکراری، ۰ گزینه مفقود، ۰ برچسب لو دهنده | `0.335s` | **PASS** |
| `adaptiveEngine_recordsAttemptsAndSchedulesDueReviewsAccurately` | ثبت تلاش با DAO، تشخیص خطای شمارش، صف مرور فوری و فعال‌سازی مسیر جبرانی | `0.119s` | **PASS** |
| `lessonCompletion_neverHardcodesAndRequiresAllGates` | اثبات عدم Hardcode در تکمیل درس و محاسبه ستاره‌ها (رد تکمیل در صورت تمرین ناقص یا سنجش زیر ۸۰٪) | `0.019s` | **PASS** |
| `sm2Schedule_followsSuperMemoSpecification` | صحت ریاضی الگوریتم SM-2 (`n=1->1d, n=2->6d, n=3->round(6*EF)` و بازنشانی در `q<3`) | `0.001s` | **PASS** |
| `parentGateLogic_generatesDynamicChallengesAndValidatesPersianDigits` | تولید چالش پویا و پذیرش ارقام فارسی و انگلیسی در گیت والدین | `0.010s` | **PASS** |
| `dragCount_allCases` | اعتبارسنجی تعامل کشیدن و شمارش (`OVERCOUNT_BY_ONE`, `UNDERCOUNT_BY_ONE`, `INVALID_INPUT`) | `0.001s` | **PASS** |
| `numberLine_allCases` | اعتبارسنجی پرش روی محور اعداد (`COUNTING_START_NODE`, `WRONG_DIRECTION`, `OUT_OF_RANGE`) | `0.001s` | **PASS** |
| `tallyMarks_allCases` | اعتبارسنجی چوب‌خط (`UNBUNDLED_FIVE`, `BUNDLE_COUNTED_AS_ONE`, `TALLY_MISMATCH`) | `0.001s` | **PASS** |
| `balanceScale_allCases` | اعتبارسنجی ترازوی دوکفه‌ای (`OFF_BY_ONE_BALANCE`, `EQUILIBRIUM_ERROR`) | `0.001s` | **PASS** |
| `optionSelection_validatesByOptionIdAndValue` | اعتبارسنجی انتخاب گزینه واقعی از JSON برای چندگزینه‌ای و الگو | `0.001s` | **PASS** |
| `persianUtils_convertsBidirectionally` | تبدیل دوطرفه ارقام فارسی، عربی و انگلیسی | `0.013s` | **PASS** |
