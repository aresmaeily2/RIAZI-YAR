import 'dart:convert';

import '../models/models.dart';

/// نتیجه اعتبارسنجی محتوا.
class ContentValidationResult {
  final bool ok;
  final List<String> errors;
  const ContentValidationResult(this.ok, this.errors);
}

/// بارگذار و اعتبارسنج محتوای درس از JSON.
///
/// محتوای درس از کد UI کاملاً جدا است؛ افزودن درس جدید فقط با
/// افزودن یک فایل JSON در assets/lessons/ و ثبت آن در فهرست انجام می‌شود
/// (راهنمای کامل: docs/ADD_LESSON.md).
class LessonContentLoader {
  /// فهرست شناسه‌های فایل محتوای تعبیه‌شده در نسخه فعلی.
  static const List<String> bundledLessonAssets = [
    'assets/lessons/lesson_l1_counting_1_5.json',
    'assets/lessons/lesson_l2_counting_6_9.json',
    'assets/lessons/quiz_final_short.json',
  ];

  /// اعتبارسنجی ساختاری و معنایی یک سند JSON درس.
  ///
  /// فراتر از schema (که در fromJson انجام می‌شود) اینجا قواعد آموزشی
  /// MVP را کنترل می‌کنیم: محدوده اعداد ۰..۲۰، حداکثر ۶ گزینه و …
  static ContentValidationResult validate(Map<String, dynamic> doc) {
    final errors = <String>[];
    Lesson? lesson;
    try {
      lesson = Lesson.fromJson(doc);
    } on ContentFormatException catch (e) {
      return ContentValidationResult(false, [e.message]);
    } catch (e) {
      return ContentValidationResult(false, ['خطای ناشناخته تجزیه: $e']);
    }

    for (final a in lesson.activities) {
      for (final q in a.questions) {
        if (q.itemCount < 0 || q.itemCount > 20) {
          errors.add('«${q.id}»: itemCount باید ۰ تا ۲۰ باشد (تناسب با پایه اول)');
        }
        if (q.correctAnswer < 0 || q.correctAnswer > 20) {
          errors.add('«${q.id}»: correctAnswer باید ۰ تا ۲۰ باشد');
        }
        if (q.options.length > 6) {
          errors.add('«${q.id}»: بیش از ۶ گزینه برای کودک مناسب نیست');
        }
        if (a.type == ActivityType.countAndChoose && q.itemCount != q.correctAnswer) {
          errors.add('«${q.id}»: در countAndChoose تعداد اشیا باید با پاسخ صحیح برابر باشد');
        }
        if (a.type == ActivityType.matchCount) {
          final same = q.options.where((o) => o.value == q.correctAnswer).length;
          if (same != 1) {
            errors.add('«${q.id}»: در matchCount دقیقاً یک دسته با تعداد درست لازم است');
          }
        }
        if (q.options.map((o) => o.value).toSet().length != q.options.length) {
          errors.add('«${q.id}»: گزینه‌های تکراری مجاز نیست');
        }
      }
    }
    return ContentValidationResult(errors.isEmpty, errors);
  }

  /// تجزیه + اعتبارسنجی؛ در صورت خطا ContentFormatException پرتاب می‌شود.
  static Lesson loadFromJsonString(String raw, {String source = 'inline'}) {
    Map<String, dynamic> doc;
    try {
      doc = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      throw ContentFormatException('JSON نامعتبر در "$source": $e');
    }
    final v = validate(doc);
    if (!v.ok) {
      throw ContentFormatException('اعتبارسنجی "$source" ناموفق:\n- ${v.errors.join('\n- ')}');
    }
    return Lesson.fromJson(doc);
  }

  /// بارگذاری همه درس‌های تعبیه‌شده از assets (نیازمند Flutter rootBundle).
  /// در تست‌ها فایل‌ها مستقیم از دیسک خوانده می‌شوند.
  static Future<List<Lesson>> loadBundledLessons(
      Future<String> Function(String path) readAsset) async {
    final lessons = <Lesson>[];
    for (final path in bundledLessonAssets) {
      final raw = await readAsset(path);
      lessons.add(loadFromJsonString(raw, source: path));
    }
    return lessons;
  }
}
