# مشخصات طرح‌واره محتوای آموزشی نسخه ۲ (`docs/CONTENT_SCHEMA.md`)

## ۱. ساختار کلی ۲۳۵ فایل JSON در `app/src/main/assets/content_v2/`
- `CONTENT_MANIFEST.json`: فهرست کل ۳۹ درس در ۸ فصل (`G1-L01` تا `G1-L39`).
- `lessons/G1-LXX_lesson.json` (۳۹ فایل): شامل اهداف یادگیری (`learning_objectives_fa`)، پیش‌نیازها (`prerequisites_fa`)، داستان شروع (`warm_up_story_fa`)، بخش کشف مفهوم (`concept_discovery`)، ۳ مثال حل‌شده (`worked_examples`)، ۳ فعالیت هدایت‌شده (`guided_activities`) و ۳۰ تمرین مستقل (`independent_practice_questions`).
- `lessons/G1-LXX_examples.json` (۳۹ فایل) و `lessons/G1-LXX_independent_30q.json` (۳۹ فایل).
- `remedial/G1-LXX_remedial.json` (۳۹ فایل): هر فایل شامل ۵ سؤال جبرانی هدفمند متصل به کد کج‌فهمی (`target_misconception_code`) با ۴ گزینه واقعی و بدون برچسب لو دهنده.
- `assessments/G1-LXX_assessment.json` (۳۹ فایل): هر فایل شامل ۵ سؤال سنجش پایانی با حد نصاب قبولی `passing_score_percent = 80` و سیاست بازخورد `DEFERRED_UNTIL_ASSESSMENT_SUBMIT`.
- `curriculum_maps/skill_node_G1_SN01.json` تا `G1_SN31.json` (۳۱ فایل): گره‌های مهارتی برنامه درسی.
- `interactions/*.json` (۶ فایل) و `schemas/*.json` (۲ فایل).
