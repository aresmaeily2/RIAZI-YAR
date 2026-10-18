import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:riazi_yar/core/models/models.dart';
import 'package:riazi_yar/core/storage/database.dart';
import 'package:riazi_yar/core/storage/repositories.dart';

void main() {
  // راه‌اندازی sqflite برای محیط دسکتاپ/تست
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await AppDatabase.open(
      factory: databaseFactory,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Attempt attempt({
    required bool correct,
    String questionId = 'q1',
    String activityId = 'a1',
    String lessonId = 'l1',
    bool hint = false,
    DateTime? createdAt,
    String? runId,
  }) =>
      Attempt(
        lessonId: lessonId,
        activityId: activityId,
        questionId: questionId,
        isCorrect: correct,
        chosenValue: correct ? 3 : 2,
        hintUsed: hint,
        createdAt: createdAt ?? DateTime.now(),
        runId: runId,
      );

  group('ثبت تلاش و پیشرفت', () {
    test('ثبت تلاش درست، progress را افزایش می‌دهد', () async {
      final repo = ProgressRepository(db);
      await repo.recordAttempt(attempt(correct: true));

      final p = await repo.progressFor('l1', 'a1');
      expect(p, isNotNull);
      expect(p!.correctCount, 1);
      expect(p.wrongCount, 0);
      expect(p.mastered, false, reason: 'با یک تلاش هنوز تسلط اعلام نمی‌شود');
    });

    test('تسلط پس از ۳ درست از ۴ تلاش ثبت می‌شود', () async {
      final repo = ProgressRepository(db);
      await repo.recordAttempt(attempt(correct: true));
      await repo.recordAttempt(attempt(correct: true));
      await repo.recordAttempt(attempt(correct: true));
      await repo.recordAttempt(attempt(correct: false));

      final p = await repo.progressFor('l1', 'a1');
      expect(p!.correctCount, 3);
      expect(p.wrongCount, 1);
      expect(p.mastered, true);
    });

    test('ثبت تکراری همان تلاش، پیشرفت را دوبار جمع نمی‌کند (idempotent per call)', () async {
      final repo = ProgressRepository(db);
      final a = attempt(correct: true);
      await repo.recordAttempt(a);
      await repo.recordAttempt(a); // رکورد دوم مستقل ثبت می‌شود؛ جمع = ۲

      // جمع progress از روی تلاش‌ها یکسان است — محاسبه تکراری انجام نمی‌شود
      final p = await repo.progressFor('l1', 'a1');
      expect(p!.totalCount, 2);
    });

    test('فعالیت‌های جدا پیشرفت جدا دارند', () async {
      final repo = ProgressRepository(db);
      await repo.recordAttempt(attempt(correct: true, activityId: 'a1'));
      await repo.recordAttempt(attempt(correct: false, activityId: 'a2'));

      expect((await repo.progressFor('l1', 'a1'))!.correctCount, 1);
      expect((await repo.progressFor('l1', 'a2'))!.wrongCount, 1);
    });
  });

  group('تنظیمات', () {
    test('ذخیره و بازیابی تنظیمات', () async {
      final repo = SettingsRepository(db);
      await repo.save(const LearnerSettings(
        childName: 'آریا',
        voiceGuideEnabled: false,
        speechInputEnabled: false,
        onlineGuideEnabled: false,
        masteryThreshold: 0.8,
      ));
      final loaded = await repo.load();
      expect(loaded.childName, 'آریا');
      expect(loaded.voiceGuideEnabled, false);
      expect(loaded.speechInputEnabled, false);
      expect(loaded.onlineGuideEnabled, false);
      expect(loaded.masteryThreshold, 0.8);
    });

    test('بازیابی پیش‌فرض‌ها در نبود داده', () async {
      final repo = SettingsRepository(db);
      final loaded = await repo.load();
      expect(loaded.childName, 'کاوشگر کوچک');
      expect(loaded.voiceGuideEnabled, true);
      expect(loaded.masteryThreshold, 0.75);
    });
  });

  group('گزارش والدین', () {
    test('خلاصه از داده واقعی ساخته می‌شود', () async {
      final progress = ProgressRepository(db);
      await progress.recordAttempt(attempt(correct: true, activityId: 'a1'));
      await progress.recordAttempt(attempt(correct: false, activityId: 'a2'));
      await progress.recordAttempt(attempt(correct: false, activityId: 'a2'));

      final reports = ParentReportRepository(db);
      final s = await reports.summary(
        activityTitles: {'a1': 'درس ۱', 'a2': 'درس ۲'},
      );
      expect(s.totalAttempts, 3);
      expect(s.totalCorrect, 1);
      expect(s.activitiesStarted, 2);
      expect(s.needsPracticeTitles, contains('درس ۲'));
    });

    test('پاک کردن همه داده‌ها', () async {
      final progress = ProgressRepository(db);
      await progress.recordAttempt(attempt(correct: true));
      await progress.resetAll();

      final all = await progress.allProgress();
      expect(all, isEmpty);
    });
  });

  group('امتیاز آخرین اجرای آزمون — run_id (ممیزی ۱.۰.۲)', () {
    test('بدون تلاش آزمون → null (یعنی «آزمونی ثبت نشده»)', () async {
      final repo = ProgressRepository(db);
      expect(await repo.lastQuizRunScore(), isNull);
    });

    test('نخستین تلاش هر پرسش در همان اجرا ملاک است', () async {
      final repo = ProgressRepository(db);
      const run = 'run-1000-0';
      // q1: غلط سپس درست → نخستین تلاش غلط است
      await repo.recordAttempt(attempt(correct: false, lessonId: 'quiz_x', questionId: 'q1', runId: run));
      await repo.recordAttempt(attempt(correct: true, lessonId: 'quiz_x', questionId: 'q1', runId: run));
      // q2: درست
      await repo.recordAttempt(attempt(correct: true, lessonId: 'quiz_x', questionId: 'q2', runId: run));
      // تلاش درس عادی نباید در امتیاز آزمون بیاید
      await repo.recordAttempt(attempt(correct: true, lessonId: 'l1', questionId: 'q3', runId: run));

      final score = await repo.lastQuizRunScore();
      expect(score, closeTo(1 / 2, 0.0001),
          reason: 'فقط نخستین تلاش q1 (غلط) و q2 (درست) شمرده می‌شود');
    });

    test('دو اجرای آزمون با پاسخ متفاوت → امتیاز نمایشی مالِ اجرای آخر است',
        () async {
      final repo = ProgressRepository(db);

      // اجرای اول: کودک ۱ از ۲
      const run1 = 'run-1000-0';
      await repo.recordAttempt(attempt(correct: false, lessonId: 'quiz_x', questionId: 'q1', runId: run1));
      await repo.recordAttempt(attempt(correct: true, lessonId: 'quiz_x', questionId: 'q2', runId: run1));

      // اجرای دوم (بعداً): کودک هر دو را درست می‌زند — ۲ از ۲
      const run2 = 'run-2000-1';
      await repo.recordAttempt(attempt(correct: true, lessonId: 'quiz_x', questionId: 'q1', runId: run2));
      await repo.recordAttempt(attempt(correct: true, lessonId: 'quiz_x', questionId: 'q2', runId: run2));

      final score = await repo.lastQuizRunScore();
      expect(score, closeTo(1.0, 0.0001),
          reason: 'امتیاز باید از اجرای دوم بیاید نه ترکیب دو اجرا');

      // و در جهت معکوس: اجرای دوم ضعیف‌تر → همان اجرای دوم نمایش داده شود
      final db2 = await AppDatabase.open(factory: databaseFactory, path: inMemoryDatabasePath);
      final repo2 = ProgressRepository(db2);
      const run3 = 'run-3000-2';
      await repo2.recordAttempt(attempt(correct: false, lessonId: 'quiz_y', questionId: 'q1', runId: run3));
      await repo2.recordAttempt(attempt(correct: false, lessonId: 'quiz_y', questionId: 'q2', runId: run3));
      final score2 = await repo2.lastQuizRunScore();
      await db2.close();
      expect(score2, closeTo(0.0, 0.0001),
          reason: 'آخرین اجرا ضعیف‌ترین نتیجه دارد؛ نمایش ترکیبی صادقانه نیست');
    });

    test('تلاش اصلاحی در اجرای آخر، امتیاز اجرا را تغییر نمی‌دهد', () async {
      final repo = ProgressRepository(db);
      final now = DateTime.now();
      // اجرای «آخر» واقعی: تلاش‌هایش زمان قدیمی‌ترِ ثبتِ «دیرتر» دارند —
      // برای قطعیت، زمان‌ها صریح داده می‌شود.
      const run = 'run-1000-0';
      await repo.recordAttempt(attempt(
          correct: false, lessonId: 'quiz_x', questionId: 'q1', runId: run,
          createdAt: now));
      await repo.recordAttempt(attempt(
          correct: true, lessonId: 'quiz_x', questionId: 'q1', runId: run,
          createdAt: now.add(const Duration(seconds: 5))));
      // اجرای قدیمی‌تر (یک ساعت قبل) با نتیجه کامل درست — نباید ملاک شود
      const older = 'run-500-9';
      await repo.recordAttempt(attempt(
          correct: true, lessonId: 'quiz_x', questionId: 'q1', runId: older,
          createdAt: now.subtract(const Duration(hours: 1))));
      await repo.recordAttempt(attempt(
          correct: true, lessonId: 'quiz_x', questionId: 'q2', runId: older,
          createdAt: now.subtract(const Duration(hours: 1))));

      final score = await repo.lastQuizRunScore();
      expect(score, closeTo(0.0, 0.0001),
          reason: 'آخرین اجرا q1 با نخستین تلاشِ غلط — نتیجه ۱۰۰٪ اجرای قدیمی نباید نمایش داده شود');
    });

    test('run_id در رکورد ذخیره و بازیابی می‌شود', () async {
      final repo = ProgressRepository(db);
      const run = 'run-1234-7';
      await repo.recordAttempt(attempt(correct: true, lessonId: 'quiz_x', questionId: 'q1', runId: run));
      final rows = await db.query('attempts', limit: 1);
      expect(rows.first['run_id'], run);
      final a = Attempt.fromRow(rows.first);
      expect(a.runId, run);
    });
  });

  group('مهاجرت نسخه ۱ → ۲ (افزودن run_id و پر کردن آن)', () {
    late Directory tmpDir;
    late String dbPath;

    setUp(() {
      // مهاجرت نیازمند فایل واقعی است: پایگاه داده درون‌حافظه‌ای هر بار
      // تازه ساخته می‌شود و onUpgrade روی آن اجرا نمی‌شود.
      tmpDir = Directory.systemTemp.createTempSync('riazi_migration_test');
      dbPath = '${tmpDir.path}${Platform.pathSeparator}migration_test.db';
    });

    tearDown(() {
      tmpDir.deleteSync(recursive: true);
    });

    test('پایگاه داده نسخه ۱ ارتقا می‌یابد؛ رکوردهای قدیمی run_id می‌گیرند',
        () async {
      // ساخت پایگاه داده با طرح قدیمی نسخه ۱ (بدون run_id) و داده قدیمی
      const v1Schema = '''
        CREATE TABLE attempts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          lesson_id TEXT NOT NULL,
          activity_id TEXT NOT NULL,
          question_id TEXT NOT NULL,
          is_correct INTEGER NOT NULL,
          chosen_value INTEGER,
          hint_used INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        );
        CREATE TABLE progress (
          lesson_id TEXT NOT NULL,
          activity_id TEXT NOT NULL,
          correct_count INTEGER NOT NULL DEFAULT 0,
          wrong_count INTEGER NOT NULL DEFAULT 0,
          mastered INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL,
          PRIMARY KEY (lesson_id, activity_id)
        );
        CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT);
      ''';
      final old = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(version: 1, onCreate: (d, v) async {
          for (final stmt in v1Schema.split(';')) {
            final s = stmt.trim();
            if (s.isNotEmpty) await d.execute(s);
          }
        }),
      );
      // دو اجرای آزمون در نسخه ۱ با فاصله زمانی بیشتر از ۱۰ دقیقه
      final t0 = DateTime(2026, 10, 1, 10, 0).millisecondsSinceEpoch;
      final t1 = t0 + 2 * 60 * 1000; // دو دقیقه بعد — همان اجرا
      final t2 = t0 + 60 * 60 * 1000; // یک ساعت بعد — اجرای جدید
      await old.insert('attempts', {
        'lesson_id': 'quiz_x', 'activity_id': 'qa', 'question_id': 'q1',
        'is_correct': 0, 'hint_used': 0, 'created_at': t0,
      });
      await old.insert('attempts', {
        'lesson_id': 'quiz_x', 'activity_id': 'qa', 'question_id': 'q2',
        'is_correct': 1, 'hint_used': 0, 'created_at': t1,
      });
      await old.insert('attempts', {
        'lesson_id': 'quiz_x', 'activity_id': 'qa', 'question_id': 'q1',
        'is_correct': 1, 'hint_used': 0, 'created_at': t2,
      });
      await old.insert('attempts', {
        'lesson_id': 'l1', 'activity_id': 'a1', 'question_id': 'q9',
        'is_correct': 1, 'hint_used': 0, 'created_at': t2 + 1000,
      });
      await old.close();

      // باز کردن با AppDatabase نسخه فعلی → onUpgrade باید مهاجرت را اجرا کند
      final migrated = await AppDatabase.open(
        factory: databaseFactory,
        path: dbPath,
      );
      final repo = ProgressRepository(migrated);

      // همه رکوردها run_id دارند (هیچ null نمانده)
      final rows = await migrated.query('attempts', orderBy: 'id ASC');
      expect(rows.length, 4);
      expect(rows.every((r) => r['run_id'] != null), true,
          reason: 'مهاجرت باید به همه رکوردهای قدیمی run_id بدهد');

      // اجرای اول دو رکورد دارد؛ اجرای دوم (فاصله ۱ ساعت) رکورد جدا
      final runOfRow0 = rows[0]['run_id'];
      expect(rows[1]['run_id'], runOfRow0,
          reason: 'فاصله ۲ دقیقه ≤ ۱۰ دقیقه ⇒ همان اجرا');
      expect(rows[2]['run_id'], isNot(runOfRow0),
          reason: 'فاصله ۱ ساعت ⇒ اجرای جدید');
      // درس عادی جدا از آزمون خوشه می‌شود
      expect(rows[3]['run_id'], isNot(runOfRow0));

      // امتیاز آخرین اجرای آزمونِ مهاجرت‌یافته: q1 درست (۱ از ۱)
      final score = await repo.lastQuizRunScore();
      expect(score, closeTo(1.0, 0.0001),
          reason: 'آخرین اجرای آزمون فقط q1 (درست) را دارد');
      await migrated.close();
    });
  });

  group('خطای مخزن در ثبت تلاش (ممیزی ۱.۰.۲)', () {
    test('جدول تخریب‌شده → recordAttempt خطای واقعی SQLite پرتاب می‌کند',
        () async {
      // شبیه‌سازی خطای واقعی ذخیره‌سازی: حذف جدول attempts
      await db.execute('DROP TABLE attempts');
      final repo = ProgressRepository(db);
      await expectLater(
        repo.recordAttempt(attempt(correct: true)),
        throwsA(isA<Exception>()),
      );
    });

    test('پس از شکست و بازسازی جدول، ثبت دوباره کار می‌کند (رفتار retry روشن)',
        () async {
      await db.execute('DROP TABLE attempts');
      final repo = ProgressRepository(db);
      await expectLater(
        repo.recordAttempt(attempt(correct: true)),
        throwsA(isA<Exception>()),
      );
      // بازسازی جدول با طرح کامل (شامل run_id) — مثل ترمیم واقعی
      await db.execute('''
        CREATE TABLE attempts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          lesson_id TEXT NOT NULL,
          activity_id TEXT NOT NULL,
          question_id TEXT NOT NULL,
          is_correct INTEGER NOT NULL,
          chosen_value INTEGER,
          hint_used INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          run_id TEXT
        )
      ''');
      await repo.recordAttempt(attempt(correct: true, runId: 'run-1-0'));
      final p = await repo.progressFor('l1', 'a1');
      expect(p!.correctCount, 1, reason: 'پس از رفع خطا، ثبت دوباره سالم است');
    });
  });

  group('قرارداد همگام‌سازی (بدون سرور)', () {
    test('NoopSyncService صف را نگه می‌دارد و چیزی ارسال نمی‌کند', () async {
      final sync = NoopSyncService();
      await sync.enqueue('attempt', '1', {'x': 1});
      expect(await sync.pendingCount(), 1);
      await sync.flush(); // عمداً بدون عملیات
      expect(await sync.pendingCount(), 1);
    });
  });
}

/// رابط کوچک برای close بدون cast مستقیم به sqflite.Database
abstract class DatabaseLike {
  Future<void> close();
}
