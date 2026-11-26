import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// باز کردن پایگاه داده محلی (SQLite).
///
/// مسیر و DatabaseFactory تزریق‌پذیر است تا در تست‌های واحد از
/// sqflite_common_ffi (پایگاه داده درون‌حافظه‌ای) استفاده شود و
/// روی دستگاه واقعی از sqflite اندروید.
class AppDatabase {
  /// ممیزی ۱.۰.۲ (یافته امتیاز آخرین آزمون): نسخه ۲ — افزودن
  /// run_id به attempts برای شناسایی «اجرای آزمون» و محاسبه امتیاز
  /// آخرین اجرا (نه تاریخچه تجمیعی). مهاجرت داده در [migrateV1ToV2].
  static const int dbVersion = 2;
  static const String dbName = 'riazi_yar.db';

  /// فاصله زمانی جداسازی دو «اجرای» مهاجرت‌یافته (۱۰ دقیقه).
  /// رکوردهای قدیمی نسخه ۱ شناسه اجرا نداشتند؛ در مهاجرت، تلاش‌های
  /// هم‌درسی که فاصله‌شان کمتر از این حد باشد یک اجرا فرض می‌شوند.
  static const Duration migrationRunGap = Duration(minutes: 10);

  /// طرح جداول — مستند کامل در docs/DATA_MODEL.md
  static const String schemaSql = '''
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
    );
    CREATE INDEX idx_attempts_question ON attempts(question_id);
    CREATE INDEX idx_attempts_time ON attempts(created_at);
    CREATE INDEX idx_attempts_run ON attempts(run_id);

    CREATE TABLE progress (
      lesson_id TEXT NOT NULL,
      activity_id TEXT NOT NULL,
      correct_count INTEGER NOT NULL DEFAULT 0,
      wrong_count INTEGER NOT NULL DEFAULT 0,
      mastered INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (lesson_id, activity_id)
    );

    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT
    );

    CREATE TABLE sync_queue (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entity TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      payload TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      synced INTEGER NOT NULL DEFAULT 0
    );
  ''';

  /// باز کردن (یا ساخت) پایگاه داده. برای تست، databaseFactory را
  /// با inMemoryDatabasePath صدا بزنید.
  static Future<Database> open({
    required DatabaseFactory factory,
    required String path,
  }) async {
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: dbVersion,
        onCreate: (db, version) async {
          for (final stmt in schemaSql.split(';')) {
            final s = stmt.trim();
            if (s.isNotEmpty) await db.execute(s);
          }
        },
        onUpgrade: (db, oldV, newV) async {
          if (oldV < 2) {
            await migrateV1ToV2(db);
          }
          // مهاجرت‌های آینده اینجا اضافه می‌شوند.
        },
      ),
    );
  }

  /// مهاجرت ۱ → ۲: افزودن ستون run_id و پر کردن آن برای رکوردهای قدیمی.
  ///
  /// راهبرد پر کردن (deterministic و تست‌پذیر):
  ///  • همه رکوردهای attempts بر اساس (created_at، id) مرتب می‌شوند.
  ///  • رکوردهای یک `lesson_id` که فاصله زمانی‌شان کمتر از [gapMs] باشد
  ///    «یک اجرا» فرض می‌شوند و run_id مشترک می‌گیرند.
  ///  • run_id مصنوعی شکل: `migrated_<lesson_id>_<ts اولین رکورد اجرا>`
  ///    تا با run_id های زنده (`run-...`) تداخل نکند.
  ///  • عملیات در یک تراکنش است: یا کامل انجام می‌شود یا نه.
  static Future<void> migrateV1ToV2(Database db, {int gapMs = 600000}) async {
    await db.transaction((txn) async {
      // ستون ممکن است در برخی مسیرها (بازسازی جزئی) از قبل موجود باشد.
      final cols = await txn.query('sqlite_master',
          columns: ['sql'], where: "name = 'attempts'");
      final hasRunId = cols.isNotEmpty &&
          (cols.first['sql']?.toString().contains('run_id') ?? false);
      if (!hasRunId) {
        await txn.execute('ALTER TABLE attempts ADD COLUMN run_id TEXT');
      }
      await txn.execute(
          'CREATE INDEX IF NOT EXISTS idx_attempts_run ON attempts(run_id)');

      final rows = await txn.query('attempts',
          columns: ['id', 'lesson_id', 'created_at'],
          orderBy: 'created_at ASC, id ASC');
      String? currentRun;
      String? currentLesson;
      int prevTs = 0;
      for (final r in rows) {
        final id = r['id'] as int;
        final lesson = r['lesson_id'] as String;
        final ts = r['created_at'] as int;
        if (lesson != currentLesson || ts - prevTs > gapMs) {
          currentRun = 'migrated_${lesson}_$ts';
          currentLesson = lesson;
        }
        prevTs = ts;
        await txn.update('attempts', {'run_id': currentRun},
            where: 'id = ?', whereArgs: [id]);
      }
    });
  }

  /// مسیر استاندارد پایگاه داده روی دستگاه (نیازمند path_provider).
  static Future<String> defaultPath() async {
    final dir = await databaseFactory.getDatabasesPath();
    return p.join(dir, dbName);
  }
}
