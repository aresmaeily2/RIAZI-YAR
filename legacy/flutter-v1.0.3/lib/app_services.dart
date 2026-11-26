import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import 'core/content/lesson_content.dart';
import 'core/audio/stt_service.dart';
import 'core/audio/tts_service.dart';
import 'core/guide/ai_guide_http.dart';
import 'core/guide/guide_engine.dart';
import 'core/models/models.dart';
import 'core/storage/database.dart';
import 'core/storage/repositories.dart';

/// محفظه سرویس‌های اپلیکیشن — تزریق وابستگی ساده بدون پکیج اضافه.
///
/// در تست‌ها، سازنده با فیک‌ها/پایگاه داده حافظه‌ای ساخته می‌شود.
class AppServices {
  late final Database db;
  late final ProgressRepository progress;
  late final SettingsRepository settingsRepo;
  late final ParentReportRepository reports;
  late final SyncContract sync;
  late final GuideEngine localGuide;
  late final HttpAiGuideClient onlineGuide;
  late final TtsService tts;
  late final SttService stt;

  LearnerSettings settings = const LearnerSettings();
  List<Lesson> lessons = [];

  /// factory انتخابی برای تست — پیش‌فرض: واقعی
  final Future<Database> Function()? databaseOverride;
  final TtsService Function()? ttsOverride;
  final SttService Function()? sttOverride;

  AppServices({this.databaseOverride, this.ttsOverride, this.sttOverride});

  bool get initialized => _initialized;
  bool _initialized = false;

  /// ممیزی ۱.۰.۲: اگر init یک بار شکست بخورد، دوباره اجرا نمی‌شود؛
  /// اجرای مجدد روی state نیمه‌ساخت (late final های مقداردهی‌شده)
  /// LateInitializationError می‌دهد. اپ در حالت تنزل‌یافته امن می‌ماند
  /// و پیام کنترل‌شده نمایش داده می‌شود.
  bool _initAttempted = false;

  Future<void> init() async {
    if (_initialized || _initAttempted) return;
    _initAttempted = true;

    // پایگاه داده محلی
    db = databaseOverride != null
        ? await databaseOverride!()
        : await AppDatabase.open(
            factory: databaseFactory,
            path: await AppDatabase.defaultPath(),
          );

    progress = ProgressRepository(db);
    settingsRepo = SettingsRepository(db);
    reports = ParentReportRepository(db);
    sync = NoopSyncService();

    // راهنماها
    localGuide = LocalGuideEngine();
    onlineGuide = HttpAiGuideClient(
      endpointProvider: () => _onlineGuideEndpoint,
    );

    // صوت
    tts = ttsOverride?.call() ?? FlutterTtsService();
    // ممیزی ۱.۰.۱: ورودی گفتار به‌صورت امن غیرفعال است (مسیر داده صدا
    // قابل راستی‌آزمایی نیست). فقط با sttOverride در تست‌ها سرویس دیگر
    // تزریق می‌شود.
    stt = sttOverride?.call() ?? const DisabledSttService();

    // محتوای درس‌ها — اعتبارسنجی پیش از استفاده (مأموریت ۷)
    lessons = await LessonContentLoader.loadBundledLessons(
      (path) => rootBundle.loadString(path),
    );

    settings = await settingsRepo.load();
    if (ttsOverride == null) {
      final ok = await tts.init();
      if (ok) {
        (tts as FlutterTtsService).setEnabled(settings.voiceGuideEnabled);
      }
    }
    _initialized = true;
  }

  /// آدرس سرور راهنمای آنلاین — فقط از پیکربندی محیطی/دستگاه می‌آید.
  /// هیچ مقدار پیش‌فرض یا کلیدی در کد وجود ندارد (مأموریت ۸).
  static Uri? get _onlineGuideEndpoint {
    const v = String.fromEnvironment(
      'RIAZIYAR_GUIDE_ENDPOINT',
      defaultValue: '',
    );
    if (v.isEmpty) return null;
    return Uri.tryParse(v);
  }

  /// host سرور پیکربندی‌شده — فقط برای «نمایش شفاف مقصد» در دیالوگ
  /// رضایت والد (ممیزی ۱.۰.۲). اگر اعتبار HTTPS رد شود یا تنظیم نشده
  /// باشد null برمی‌گردد؛ نمایش مقدار null یعنی «پیکربندی نشده».
  String? get onlineGuideEndpointHost {
    final u = _onlineGuideEndpoint;
    if (u == null) return null;
    try {
      validateGuideEndpoint(u);
      return u.host;
    } on Object {
      return null;
    }
  }

  Future<void> saveSettings(LearnerSettings s) async {
    settings = s;
    await settingsRepo.save(s);
    if (tts is FlutterTtsService) {
      (tts as FlutterTtsService).setEnabled(s.voiceGuideEnabled);
    }
  }

  void speakInstruction(String text) {
    if (settings.voiceGuideEnabled) {
      tts.speak(text);
    }
  }
}
