import 'package:sqflite/sqlite_api.dart';

import '../engine/evaluator.dart';
import '../models/models.dart';

/// مخزن پیشرفت یادگیری.
///
/// اصل مهم (نیازمند مأموریت ۵.۵): ثبت تلاش «افزایشی» است؛ progress از
/// روی attempts جمع می‌شود و عملیات تکراری هرگز پیشرفت را دوباره محاسبه
/// نمی‌کند (نمایش صادقانه: sync پیاده نشده؛ رکوردهای sync_queue فقط صف
/// آینده است).
class ProgressRepository {
  final Database db;

  ProgressRepository(this.db);

  /// ثبت یک تلاش و به‌روزرسانی تجمعی progress در یک تراکنش.
  Future<void> recordAttempt(Attempt attempt) async {
    await db.transaction((txn) async {
      await txn.insert('attempts', attempt.toRow());

      final rows = await txn.query(
        'progress',
        where: 'lesson_id = ? AND activity_id = ?',
        whereArgs: [attempt.lessonId, attempt.activityId],
        limit: 1,
      );

      var p = rows.isEmpty
          ? LearningProgress(
              lessonId: attempt.lessonId,
              activityId: attempt.activityId,
              correctCount: 0,
              wrongCount: 0,
              mastered: false,
              updatedAt: attempt.createdAt,
            )
          : LearningProgress.fromRow(rows.first);

      p = attempt.isCorrect
          ? p.copyWith(correctCount: p.correctCount + 1, updatedAt: attempt.createdAt)
          : p.copyWith(wrongCount: p.wrongCount + 1, updatedAt: attempt.createdAt);

      final mastered = const Evaluator().isMastered(
        correctCount: p.correctCount,
        wrongCount: p.wrongCount,
      );
      p = p.copyWith(mastered: p.mastered || mastered);

      await txn.insert(
        'progress',
        p.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<LearningProgress?> progressFor(String lessonId, String activityId) async {
    final rows = await db.query(
      'progress',
      where: 'lesson_id = ? AND activity_id = ?',
      whereArgs: [lessonId, activityId],
      limit: 1,
    );
    return rows.isEmpty ? null : LearningProgress.fromRow(rows.first);
  }

  Future<List<LearningProgress>> allProgress() async {
    final rows = await db.query('progress', orderBy: 'updated_at DESC');
    return rows.map(LearningProgress.fromRow).toList();
  }

  /// آخرین تلاش‌های یک پرسش (برای تشخیص «نیازمند تمرین بیشتر»).
  Future<List<Attempt>> recentAttemptsForQuestion(String questionId, {int limit = 10}) async {
    final rows = await db.query(
      'attempts',
      where: 'question_id = ?',
      whereArgs: [questionId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(Attempt.fromRow).toList();
  }

  /// امتیاز «آخرین اجرای آزمون» — ممیزی ۱.۰.۲ (یافته امتیاز آخرین آزمون).
  ///
  /// مشکل نسخه قبل: quizFirstTryScore برای هر question_id از «تمام
  /// تاریخچه» نخستین تلاش را می‌گرفت؛ با دو بار آزمون دادن کودک، امتیاز
  /// نمایشی ترکیبی از دو اجرا و ناسازگار با نتیجه‌ای بود که کودک در
  /// آخرین آزمون دید.
  ///
  /// راهکار ترجیحی ممیزی (اجراشده): شناسه یکتای اجرا (run_id) روی هر
  /// تلاش ثبت می‌شود (تولید در LessonSession همان اجرا) و امتیاز فقط
  /// از تلاش‌های «آخرین اجرای ثبت‌شده» محاسبه می‌شود:
  ///  ۱) آخرین اجرا = اجرای تلاشی با بیشترین (created_at، id) از درس‌های
  ///     آزمون (lesson_id LIKE [lessonIdPattern]).
  ///  ۲) ملاک امتیاز همان «نخستین تلاش هر پرسش در همان اجراست» (سازگار
  ///     با منطق امتیاز جلسه).
  ///  ۳) اگر هیچ تلاش آزمونی ثبت نشده باشد null برمی‌گردد (یعنی
  ///     «آزمونی ثبت نشده» — نباید با امتیاز صفر اشتباه شود).
  Future<double?> lastQuizRunScore({String lessonIdPattern = 'quiz%'}) async {
    final lastRunRows = await db.rawQuery(
      '''
      SELECT a.run_id AS rid
      FROM attempts a
      WHERE a.lesson_id LIKE ? AND a.run_id IS NOT NULL
      ORDER BY a.created_at DESC, a.id DESC
      LIMIT 1
      ''',
      [lessonIdPattern],
    );
    if (lastRunRows.isEmpty) return null;
    final runId = lastRunRows.first['rid'] as String;

    final rows = await db.rawQuery(
      '''
      SELECT a.question_id AS qid, a.is_correct AS ok
      FROM attempts a
      WHERE a.run_id = ? AND a.lesson_id LIKE ?
        AND a.id = (
          SELECT b.id FROM attempts b
          WHERE b.question_id = a.question_id AND b.run_id = a.run_id
          ORDER BY b.created_at ASC, b.id ASC
          LIMIT 1
        )
      ORDER BY a.id ASC
      ''',
      [runId, lessonIdPattern],
    );
    if (rows.isEmpty) return null;
    final firstOk = rows.where((r) => (r['ok'] as int) == 1).length;
    return firstOk / rows.length;
  }

  /// حذف همه داده‌های یادگیری (از بخش والدین، با تأیید).
  Future<void> resetAll() async {
    await db.transaction((txn) async {
      await txn.delete('attempts');
      await txn.delete('progress');
      await txn.delete('sync_queue');
    });
  }
}

/// مخزن تنظیمات (کلید/مقدار) — فقط داده‌های غیرحساس.
class SettingsRepository {
  final Database db;

  SettingsRepository(this.db);

  Future<LearnerSettings> load() async {
    final rows = await db.query('settings');
    final map = {for (final r in rows) r['key'] as String: r['value'] as String?};
    return LearnerSettings.fromMap(map);
  }

  Future<void> save(LearnerSettings s) async {
    final map = s.toMap();
    await db.transaction((txn) async {
      for (final e in map.entries) {
        await txn.insert(
          'settings',
          {'key': e.key, 'value': e.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}

/// خلاصه والدین — محاسبه از روی داده واقعی ثبت‌شده.
class ParentReportRepository {
  final Database db;

  ParentReportRepository(this.db);

  Future<ParentSummary> summary({
    required Map<String, String> activityTitles,
    double? lastQuizScoreOf,
  }) async {
    final attemptsCount = await db.rawQuery(
        'SELECT COUNT(*) AS c, SUM(is_correct) AS ok FROM attempts');
    final total = attemptsCount.first['c'] as int? ?? 0;
    final okCount = attemptsCount.first['ok'] as int? ?? 0;

    final progressRows = await db.query('progress');
    final progressList = progressRows.map(LearningProgress.fromRow).toList();

    final started = progressList.length;
    final mastered = progressList.where((p) => p.mastered).length;

    // «نیازمند تمرین بیشتر»: فعالیت‌های با دقت کمتر از ۷۵٪ و حداقل ۲ تلاش
    final needs = <String>[];
    for (final p in progressList) {
      if (p.totalCount >= 2 && p.accuracy < 0.75 && !p.mastered) {
        final title = activityTitles[p.activityId] ?? p.activityId;
        if (!needs.contains(title)) needs.add(title);
      }
    }

    // آخرین آزمون ثبت‌شده — امتیازش از قبل (lastQuizRunScore) می‌آید تا
    // دقیقاً همان «آخرین اجرای آزمون» باشد (ممیزی ۱.۰.۲). پس از مهاجرت،
    // هر رکورد آزمون run_id دارد؛ بنابراین وجود رکورد آزمون یعنی امتیاز
    // آخرین اجرا قابل محاسبه است.
    String? lastQuizTitle;
    double? lastQuizScore;
    final quizRows = await db.query(
      'attempts',
      where: 'lesson_id LIKE ?',
      whereArgs: ['quiz%'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (quizRows.isNotEmpty) {
      lastQuizTitle = 'آزمون کوتاه پایان واحد';
      lastQuizScore = lastQuizScoreOf;
    }

    return ParentSummary(
      totalAttempts: total,
      totalCorrect: okCount,
      activitiesStarted: started,
      activitiesMastered: mastered,
      lastQuizTitle: lastQuizTitle,
      lastQuizScore: lastQuizScore,
      needsPracticeTitles: needs,
      generatedAt: DateTime.now(),
    );
  }
}

/// قرارداد همگام‌سازی آینده — در MVP پیاده‌سازی نشده است.
///
/// وضعیت صادقانه: [NoopSyncService] هیچ ارسال شبکه‌ای انجام نمی‌دهد.
/// معماری قرارداد اکنون تعریف شده تا نسخه بعدی بتواند بدون تغییر مدل‌ها
/// سرور متصل کند (نیازمند مأموریت: «قابلیت را تکمیل‌شده معرفی نکن»).
abstract class SyncContract {
  Future<void> enqueue(String entity, String entityId, Map<String, dynamic> payload);
  Future<int> pendingCount();
  Future<void> flush();
}

class NoopSyncService implements SyncContract {
  final List<_SyncEntry> _queue = [];

  @override
  Future<void> enqueue(String entity, String entityId, Map<String, dynamic> payload) async {
    _queue.add(_SyncEntry(entity, entityId, payload));
  }

  @override
  Future<int> pendingCount() async => _queue.length;

  @override
  Future<void> flush() async {
    // عمداً بدون عملیات: سروری برای همگام‌سازی وجود ندارد.
    // رسیدگی آینده: ارسال batch به سرور + علامت‌گذاری synced + جلوگیری
    // از محاسبه دوباره progress روی سمت سرور (idempotent by entity_id).
  }
}

class _SyncEntry {
  final String entity;
  final String entityId;
  final Map<String, dynamic> payload;
  _SyncEntry(this.entity, this.entityId, this.payload);
}
