/// مدل‌های دامنه اپلیکیشن — لایه خالص Dart (بدون هیچ وابستگی به Flutter).
///
/// این مدل‌ها با «قالب محتوای درس» (docs/DATA_MODEL.md) هم‌خوان هستند.
/// ساده‌سازی‌های آگاهانه نسبت به فهرست کامل مدل‌ها در مأموریت:
///  - LessonVersion: به‌صورت فیلد contentVersion داخل Lesson نگهداری می‌شود
///    (در MVP فقط یک نسخه فعال از هر درس توزیع می‌شود).
///  - AnswerOption: مدل مستقل AnswerOption برای گزینه‌ها.
library;

/// نوع فعالیت آموزشی. افزودن نوع جدید مستلزم تغییر موتور نیست؛
/// فقط UI رندر مربوطه و اعتبارسنج محتوا باید بداند.
enum ActivityType {
  /// شمارش اشیا و انتخاب عدد درست از میان گزینه‌ها.
  countAndChoose,

  /// نمایش یک عدد و انتخاب دسته‌ای از اشیا که همان تعداد دارد.
  matchCount,
}

ActivityType activityTypeFromString(String s) {
  switch (s) {
    case 'countAndChoose':
      return ActivityType.countAndChoose;
    case 'matchCount':
      return ActivityType.matchCount;
    default:
      throw ContentFormatException('نوع فعالیت نامعتبر است: "$s"');
  }
}

/// نوع درس: درس عادی یا ارزیابی پایانی کوتاه.
enum LessonKind { regular, quiz }

LessonKind lessonKindFromString(String s) {
  switch (s) {
    case 'regular':
      return LessonKind.regular;
    case 'quiz':
      return LessonKind.quiz;
    default:
      throw ContentFormatException('نوع درس نامعتبر است: "$s"');
  }
}

/// خطای قالب محتوا — هنگام اعتبارسنجی JSON درس پرتاب می‌شود.
class ContentFormatException implements Exception {
  final String message;
  ContentFormatException(this.message);
  @override
  String toString() => 'ContentFormatException: $message';
}

/// یک گزینه پاسخ (عددی) با متن صوتی/متنی برای بازخورد.
class AnswerOption {
  final int value;
  final String label;

  const AnswerOption({required this.value, required this.label});

  factory AnswerOption.fromJson(Map<String, dynamic> j) {
    final v = j['value'];
    if (v is! int) {
      throw ContentFormatException('AnswerOption.value باید int باشد');
    }
    return AnswerOption(value: v, label: (j['label'] ?? '$v').toString());
  }

  Map<String, dynamic> toJson() => {'value': value, 'label': label};
}

/// یک پرسش درون یک فعالیت.
class Question {
  final String id;
  final String prompt;

  /// شکل اشیا برای رندر برداری: apple | star | ball | flower | fish | bird
  final String itemShape;

  /// تعداد اشیای نمایشی (در matchCount: عدد هدف).
  final int itemCount;

  /// گزینه‌ها (برای matchCount: اندازه دسته‌های کاندید).
  final List<AnswerOption> options;

  /// مقدار صحیح (عدد یا اندازه دسته صحیح).
  final int correctAnswer;

  /// راهنمایی‌های مرحله‌ای — به‌ترتیب اشتباه‌ها مصرف می‌شوند.
  final List<String> hints;

  final String feedbackCorrect;
  final String feedbackWrong;

  const Question({
    required this.id,
    required this.prompt,
    required this.itemShape,
    required this.itemCount,
    required this.options,
    required this.correctAnswer,
    required this.hints,
    required this.feedbackCorrect,
    required this.feedbackWrong,
  });

  factory Question.fromJson(Map<String, dynamic> j) {
    final optsRaw = j['options'];
    if (optsRaw is! List || optsRaw.isEmpty) {
      throw ContentFormatException('سوال «${j['id']}»: options باید لیست غیرخالی باشد');
    }
    final correct = j['correctAnswer'];
    if (correct is! int) {
      throw ContentFormatException('سوال «${j['id']}»: correctAnswer باید int باشد');
    }
    final options = optsRaw.map((e) => AnswerOption.fromJson(e as Map<String, dynamic>)).toList();
    if (!options.any((o) => o.value == correct)) {
      throw ContentFormatException('سوال «${j['id']}»: correctAnswer در options نیست');
    }
    final hints = (j['hints'] as List? ?? []).map((e) => e.toString()).toList();
    if (hints.isEmpty) {
      throw ContentFormatException('سوال «${j['id']}»: دست‌کم یک hint لازم است');
    }
    return Question(
      id: j['id'].toString(),
      prompt: (j['prompt'] ?? '').toString(),
      itemShape: (j['itemShape'] ?? 'ball').toString(),
      itemCount: j['itemCount'] is int ? j['itemCount'] as int : 0,
      options: options,
      correctAnswer: correct,
      hints: hints,
      feedbackCorrect: (j['feedbackCorrect'] ?? 'آفرین! درست بود.').toString(),
      feedbackWrong: (j['feedbackWrong'] ?? 'اشکالی ندارد، دوباره امتحان کن.').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'itemShape': itemShape,
        'itemCount': itemCount,
        'options': options.map((o) => o.toJson()).toList(),
        'correctAnswer': correctAnswer,
        'hints': hints,
        'feedbackCorrect': feedbackCorrect,
        'feedbackWrong': feedbackWrong,
      };
}

/// یک فعالیت آموزشی؛ در MVP هر فعالیت یک پرسش دارد، اما ساختار
/// چندپرسشی را پشتیبانی می‌کند تا افزودن تمرین‌های چندمرحله‌ای آسان باشد.
class Activity {
  final String id;
  final ActivityType type;
  final String instruction;

  /// سطح دشواری ۱ تا ۳.
  final int difficulty;

  final List<Question> questions;

  const Activity({
    required this.id,
    required this.type,
    required this.instruction,
    required this.difficulty,
    required this.questions,
  });

  factory Activity.fromJson(Map<String, dynamic> j) {
    final qsRaw = j['questions'];
    if (qsRaw is! List || qsRaw.isEmpty) {
      throw ContentFormatException('فعالیت «${j['id']}»: questions باید لیست غیرخالی باشد');
    }
    final diff = j['difficulty'];
    if (diff is! int || diff < 1 || diff > 3) {
      throw ContentFormatException('فعالیت «${j['id']}»: difficulty باید ۱ تا ۳ باشد');
    }
    return Activity(
      id: j['id'].toString(),
      type: activityTypeFromString((j['type'] ?? '').toString()),
      instruction: (j['instruction'] ?? '').toString(),
      difficulty: diff,
      questions: qsRaw.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'instruction': instruction,
        'difficulty': difficulty,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}

/// درس با نسخه محتوا. [teacherReviewed]=false یعنی محتوای نمونه است
/// و در UI باید برچسب «نیازمند بازبینی معلم» نمایش داده شود.
class Lesson {
  final String id;
  final String title;
  final String description;
  final String unit;
  final String contentVersion;
  final LessonKind kind;
  final bool teacherReviewed;
  final List<Activity> activities;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.unit,
    required this.contentVersion,
    required this.kind,
    required this.teacherReviewed,
    required this.activities,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    final title = j['title'];
    final ver = j['contentVersion'];
    final actsRaw = j['activities'];
    if (id is! String || id.isEmpty) throw ContentFormatException('id درس لازم است');
    if (title is! String || title.isEmpty) throw ContentFormatException('title درس لازم است');
    if (ver is! String || ver.isEmpty) {
      throw ContentFormatException('contentVersion درس لازم است (مثلاً "1.0.0")');
    }
    if (actsRaw is! List || actsRaw.isEmpty) {
      throw ContentFormatException('درس «$id»: activities باید لیست غیرخالی باشد');
    }
    return Lesson(
      id: id,
      title: title,
      description: (j['description'] ?? '').toString(),
      unit: (j['unit'] ?? '').toString(),
      contentVersion: ver,
      kind: lessonKindFromString((j['kind'] ?? 'regular').toString()),
      teacherReviewed: j['teacherReviewed'] == true,
      activities: actsRaw.map((e) => Activity.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'unit': unit,
        'contentVersion': contentVersion,
        'kind': kind.name,
        'teacherReviewed': teacherReviewed,
        'activities': activities.map((a) => a.toJson()).toList(),
      };

  /// همه پرسش‌های درس به‌ترتیب فعالیت‌ها.
  List<Question> get allQuestions =>
      [for (final a in activities) ...a.questions];
}

/// یک تلاش ثبت‌شده کودک برای یک پرسش.
///
/// ممیزی ۱.۰.۲ (یافته امتیاز آخرین آزمون): هر تلاش به [runId] یعنی
/// «شناسه یکتای اجرای درس/آزمون» متصل است تا امتیاز آزمون دقیقاً از
/// تلاش‌های همان اجرا محاسبه شود، نه از تاریخچه تجمیعی.
class Attempt {
  final int? id;
  final String lessonId;
  final String activityId;
  final String questionId;
  final bool isCorrect;
  final int? chosenValue;
  final bool hintUsed;
  final DateTime createdAt;

  /// شناسه یکتای اجرای جلسه (خالق: LessonSession).
  /// رکوردهای قدیمی مهاجرت‌یافته از نسخه ۱ هم توسط مهاجرت ۱→۲
  /// run_id مصنوعی می‌گیرند و null باقی نمی‌مانند.
  final String? runId;

  const Attempt({
    this.id,
    required this.lessonId,
    required this.activityId,
    required this.questionId,
    required this.isCorrect,
    required this.chosenValue,
    required this.hintUsed,
    required this.createdAt,
    this.runId,
  });

  Map<String, dynamic> toRow() => {
        'lesson_id': lessonId,
        'activity_id': activityId,
        'question_id': questionId,
        'is_correct': isCorrect ? 1 : 0,
        'chosen_value': chosenValue,
        'hint_used': hintUsed ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'run_id': runId,
      };

  static Attempt fromRow(Map<String, Object?> row) => Attempt(
        id: row['id'] as int?,
        lessonId: row['lesson_id'] as String,
        activityId: row['activity_id'] as String,
        questionId: row['question_id'] as String,
        isCorrect: row['is_correct'] == 1,
        chosenValue: row['chosen_value'] as int?,
        hintUsed: row['hint_used'] == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        runId: row['run_id'] as String?,
      );
}

/// پیشرفت یادگیری برای یک فعالیت (تجمعی).
class LearningProgress {
  final String lessonId;
  final String activityId;
  final int correctCount;
  final int wrongCount;
  final bool mastered;
  final DateTime updatedAt;

  const LearningProgress({
    required this.lessonId,
    required this.activityId,
    required this.correctCount,
    required this.wrongCount,
    required this.mastered,
    required this.updatedAt,
  });

  int get totalCount => correctCount + wrongCount;

  double get accuracy => totalCount == 0 ? 0 : correctCount / totalCount;

  Map<String, dynamic> toRow() => {
        'lesson_id': lessonId,
        'activity_id': activityId,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'mastered': mastered ? 1 : 0,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  static LearningProgress fromRow(Map<String, Object?> row) => LearningProgress(
        lessonId: row['lesson_id'] as String,
        activityId: row['activity_id'] as String,
        correctCount: row['correct_count'] as int? ?? 0,
        wrongCount: row['wrong_count'] as int? ?? 0,
        mastered: row['mastered'] == 1,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int? ?? 0),
      );

  LearningProgress copyWith({
    int? correctCount,
    int? wrongCount,
    bool? mastered,
    DateTime? updatedAt,
  }) =>
      LearningProgress(
        lessonId: lessonId,
        activityId: activityId,
        correctCount: correctCount ?? this.correctCount,
        wrongCount: wrongCount ?? this.wrongCount,
        mastered: mastered ?? this.mastered,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// تنظیمات یادگیرنده — فقط داده‌های غیرحساس و محلی.
class LearnerSettings {
  /// نام نمایشی محلی (پیش‌فرض غیرحساس: «کاوشگر کوچک»).
  final String childName;

  /// فعال بودن خواندن دستورها با صدا (TTS).
  final bool voiceGuideEnabled;

  /// فعال بودن ورودی گفتار (STT) — ترجیح والدین.
  ///
  /// ممیزی ۱.۰.۱: پیش‌فرض به «خاموش» تغییر کرد و خود قابلیت در سطح بیلد
  /// هم غیرفعال است (kSpeechInputAvailable = false)؛ این فیلد برای
  /// حفظ سازگاری داده‌ها و فعال‌سازی آینده پس از تأیید حریم خصوصی نگه
  /// داشته شده است.
  final bool speechInputEnabled;

  /// فعال بودن راهنمای آنلاین — فقط در صورت پیکربندی سرور؛ پیش‌فرض خاموش.
  final bool onlineGuideEnabled;

  /// آستانه تسلط (نسبت درست از ۰ تا ۱) — از بخش والدین قابل تنظیم.
  final double masteryThreshold;

  const LearnerSettings({
    this.childName = 'کاوشگر کوچک',
    this.voiceGuideEnabled = true,
    this.speechInputEnabled = false, // ممیزی ۱.۰.۱: پیش‌فرض خاموش
    this.onlineGuideEnabled = false,
    this.masteryThreshold = 0.75,
  });

  LearnerSettings copyWith({
    String? childName,
    bool? voiceGuideEnabled,
    bool? speechInputEnabled,
    bool? onlineGuideEnabled,
    double? masteryThreshold,
  }) =>
      LearnerSettings(
        childName: childName ?? this.childName,
        voiceGuideEnabled: voiceGuideEnabled ?? this.voiceGuideEnabled,
        speechInputEnabled: speechInputEnabled ?? this.speechInputEnabled,
        onlineGuideEnabled: onlineGuideEnabled ?? this.onlineGuideEnabled,
        masteryThreshold: masteryThreshold ?? this.masteryThreshold,
      );

  Map<String, String> toMap() => {
        'childName': childName,
        'voiceGuideEnabled': voiceGuideEnabled ? '1' : '0',
        'speechInputEnabled': speechInputEnabled ? '1' : '0',
        'onlineGuideEnabled': onlineGuideEnabled ? '1' : '0',
        'masteryThreshold': masteryThreshold.toString(),
      };

  static LearnerSettings fromMap(Map<String, String?> m) => LearnerSettings(
        childName: m['childName']?.isNotEmpty == true ? m['childName']! : 'کاوشگر کوچک',
        voiceGuideEnabled: m['voiceGuideEnabled'] != '0',
        speechInputEnabled: m['speechInputEnabled'] != '0',
        onlineGuideEnabled: m['onlineGuideEnabled'] == '1',
        masteryThreshold: double.tryParse(m['masteryThreshold'] ?? '') ?? 0.75,
      );
}

/// خلاصه گزارش والدین — بدون تشخیص یا برچسب روان‌شناختی.
class ParentSummary {
  final int totalAttempts;
  final int totalCorrect;
  final int activitiesStarted;
  final int activitiesMastered;
  final String? lastQuizTitle;
  final double? lastQuizScore;
  final List<String> needsPracticeTitles;
  final DateTime generatedAt;

  const ParentSummary({
    required this.totalAttempts,
    required this.totalCorrect,
    required this.activitiesStarted,
    required this.activitiesMastered,
    this.lastQuizTitle,
    this.lastQuizScore,
    required this.needsPracticeTitles,
    required this.generatedAt,
  });

  double get overallAccuracy => totalAttempts == 0 ? 0 : totalCorrect / totalAttempts;
}
