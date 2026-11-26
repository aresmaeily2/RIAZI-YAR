# بسته محتوای آموزشی ریاضی‌یار — پایه اول ابتدایی (RIAZI-YAR COMPLETE CONTENT V2)

## ۱. معرفی بسته
این بسته شامل ساختار کامل، استاندارد و اعتبارسنجی‌شده محتوای آموزشی **۳۹ درس ریاضی پایه اول ابتدایی** به همراه بانک سؤالات تفکیک‌شده، مشخصات فنی ۶ نوع تعامل (Interaction) و گزارش‌های ممیزی است.

## ۲. ساختار پوشه‌ها (۲۳۵ فایل JSON + فایل‌های مستندات و کنترلی)
- `CONTENT_MANIFEST.json`: فهرست جامع ۳۹ درس، وضعیت بازبینی و تفکیک تعداد سؤالات.
- `schemas/`: شامل `enums.json` و `lesson_schema.json` برای اعتبارسنجی قرارداد داده.
- `interactions/`: شامل ۶ فایل مشخصات فنی تعامل‌ها (`drag_and_drop_count`, `number_line_jump`, `tally_mark_builder`, `pattern_completer`, `visual_multiple_choice`, `balance_scale_equation`).
- `lessons/`: شامل ۳۹ فایل اصلی درس (`G1-Lxx_lesson.json`)، ۳۹ فایل بانک ۳۰ سؤال تمرین مستقل (`G1-Lxx_independent_30q.json`) و ۳۹ فایل مثال‌های آموزشی (`G1-Lxx_examples.json`).
- `remedial/`: شامل ۳۹ فایل تمرین‌های جبرانی (`G1-Lxx_remedial.json`).
- `assessments/`: شامل ۳۹ فایل سؤالات سنجش پایانی (`G1-Lxx_assessment.json`).
- `curriculum_maps/`: شامل ۳۱ فایل نگاشت گره‌های مهارتی به موتور پیشرفت (`skill_node_G1_SNxx.json`).
- `CONTENT_VALIDATION_REPORT.md`: گزارش کامل اجرای Validator واقعی و بررسی مغایرت‌ها.
- `SHA256SUMS.txt`: کدهای درهم‌سازی SHA-256 برای تمامی فایل‌های بسته.

## ۳. تفکیک وضعیت تأیید فنی و علمی
- **وضعیت اعتبارسنجی فنی (`technical_validation`):** `TECH_VALIDATED_PASS`
- **وضعیت بازبینی علمی معلم (`pedagogical_review`):** `PEDAGOGICAL_PENDING_TEACHER_REVIEW`
- **وضعیت آماده‌سازی انتشار (`production_readiness`):** `TECH_READY_AWAITING_PEDAGOGICAL_SIGN_OFF`
- برچسب `APPROVED_FOR_PRODUCTION` تا زمان ثبت شناسه معلم بررسی‌کننده (`teacher_reviewer_id`) صادر نشده است.
