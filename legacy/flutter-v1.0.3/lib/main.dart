import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_services.dart';
import 'core/engine/lesson_session.dart';
import 'core/models/models.dart';
import 'ui/colors.dart' show AppColors;
import 'ui/privacy_texts.dart';
import 'ui/screens/activity_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/lesson_intro_screen.dart';
import 'ui/screens/parent_screen.dart';
import 'ui/screens/result_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = AppServices();
  runApp(RiaziYarApp(services: services));
}

/// ریشه اپلیکیشن — RTL فارسی، تم کودک‌پسند، بوت‌استرپ سرویس‌ها.
class RiaziYarApp extends StatelessWidget {
  final AppServices services;

  const RiaziYarApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ریاضی‌یار',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(),
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
      // ممیزی ۱.۰.۲ (کشف در تست ویجت): اپ fa_IR را «پشتیبانی‌شده» اعلام
      // می‌کرد ولی هیچ delegate ترجمه‌ای نداشت — هشدار Flutter و fallback
      // انگلیسی برای دیالوگ‌های سیستمی (مثلاً TextField). اکنون delegates
      // استاندارد (پشتیبانی فارسی دارند) متصل شدند.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // تضمین RTL در همه صفحات حتی در صورت locale دستگاه دیگر
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: _Bootstrapper(services: services),
    );
  }
}

class _Bootstrapper extends StatefulWidget {
  final AppServices services;
  const _Bootstrapper({required this.services});

  @override
  State<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<_Bootstrapper> {
  late Future<void> _init;

  @override
  void initState() {
    super.initState();
    _init = widget.services.init().catchError((Object e) {
      // خطای راه‌اندازی هرگز اپ را نمی‌بندد؛ پیام کنترل‌شده نمایش داده می‌شود.
      debugPrint('Init error: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, snap) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: snap.connectionState == ConnectionState.done
              ? _HomeFlow(services: widget.services)
              : SplashScreen(
                  key: const ValueKey('splash'),
                  onDone: () {},
                ),
        );
      },
    );
  }
}

/// جریان اصلی ناوبری: خانه ↔ معرفی درس ↔ فعالیت ↔ نتیجه + والدین/تنظیمات
class _HomeFlow extends StatefulWidget {
  final AppServices services;
  const _HomeFlow({required this.services});

  @override
  State<_HomeFlow> createState() => _HomeFlowState();
}

class _HomeFlowState extends State<_HomeFlow> {
  Map<String, LearningProgress> _progressMap = {};

  @override
  void initState() {
    super.initState();
    _refreshProgress();
  }

  Future<void> _refreshProgress() async {
    final list = await widget.services.progress.allProgress();
    if (!mounted) return;
    setState(() {
      _progressMap = {for (final p in list) '${p.lessonId}:${p.activityId}': p};
    });
  }


  Future<void> _startLesson(Lesson lesson, {required bool trial}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonIntroScreen(
          lesson: lesson,
          trialMode: trial,
          onStart: () => _openActivity(lesson, trial: trial),
        ),
      ),
    );
  }

  /// حلقه تمرین: فعالیت ← نتیجه ← (تمرین دوباره) تا خروج به خانه
  Future<void> _openActivity(Lesson lesson, {required bool trial}) async {
    while (true) {
      if (!mounted) return; // جلوگیری از استفاده از context پس از جداشدن
      final session = await Navigator.of(context).push<LessonSession>(
        MaterialPageRoute(
          builder: (_) => ActivityScreen(
            lesson: lesson,
            services: widget.services,
            trialMode: trial,
            onAttempt: trial
                ? null
                : (attempt) => widget.services.progress.recordAttempt(attempt),
            onFinish: (session) => Navigator.of(context).pop(session),
          ),
        ),
      );
      if (session == null) return; // کاربر از میانه درس خارج شد
      await _refreshProgress();
      if (!mounted) return;
      final retry = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            lesson: lesson,
            session: session,
            onRetry: () => Navigator.of(context).pop(true),
            onHome: () => Navigator.of(context).pop(false),
          ),
        ),
      );
      if (retry != true) return;
    }
  }

  Future<void> _openParents() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentGateScreen(
          child: _ParentDashboardBuilder(services: widget.services),
        ),
      ),
    );
    _refreshProgress();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          voiceEnabled: widget.services.settings.voiceGuideEnabled,
          onToggleVoice: (v) async {
            await widget.services.saveSettings(
              widget.services.settings.copyWith(voiceGuideEnabled: v),
            );
          },
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lessons = widget.services.lessons;
    return HomeScreen(
      childName: widget.services.settings.childName,
      lessons: lessons,
      progressByActivity: {
        for (final entry in _progressMap.entries)
          entry.key.split(':').last: entry.value,
      },
      onStartLesson: (l) => _startLesson(l, trial: false),
      onTrialLesson: (l) => _startLesson(l, trial: true),
      onOpenParents: _openParents,
      onOpenSettings: _openSettings,
    );
  }
}

/// سازنده داشبورد والدین با داده واقعی از پایگاه داده.
class _ParentDashboardBuilder extends StatefulWidget {
  final AppServices services;
  const _ParentDashboardBuilder({required this.services});

  @override
  State<_ParentDashboardBuilder> createState() =>
      _ParentDashboardBuilderState();
}

class _ParentDashboardBuilderState extends State<_ParentDashboardBuilder> {
  ParentSummary? _summary;
  LearnerSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = widget.services;
    await _computeQuizScore();
    final summary = await s.reports.summary(
      activityTitles: {
        for (final lesson in s.lessons)
          for (final act in lesson.activities) act.id: lesson.title,
      },
      lastQuizScoreOf: _cachedQuizScore,
    );
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _settings = s.settings;
    });
  }

  double? _cachedQuizScore;

  /// امتیاز «آخرین اجرای آزمون» از داده واقعی تلاش‌ها — ممیزی ۱.۰.۲:
  /// شناسه یکتای اجرا (run_id) ملاک است تا نتیجه نمایشی دقیقاً متعلق به
  /// آخرین آزمون باشد، نه ترکیبی از تاریخچه. معیار امتیاز همان
  /// «نخستین تلاش هر پرسش» و سازگار با صفحه نتیجه همان اجراست.
  Future<void> _computeQuizScore() async {
    _cachedQuizScore = await widget.services.progress.lastQuizRunScore();
  }

  Future<void> _toggleVoice(bool v) async {
    await widget.services
        .saveSettings(widget.services.settings.copyWith(voiceGuideEnabled: v));
    await _load();
  }

  // ممیزی ۱.۰.۱: تابع _toggleSpeech حذف شد — ورودی گفتار در سطح بیلد
  // غیرفعال است و در صفحه والدین فقط توضیح صادقانه نمایش داده می‌شود.

  Future<void> _toggleOnlineGuide(bool v) async {
    // ممیزی ۱.۰.۲ (یافته حریم خصوصی): فعال‌سازی راهنمای آنلاین باید
    // «اقدام آگاهانه» والد باشد — مقصد و نوع داده ارسالی پیش از فعال‌سازی
    // توضیح داده می‌شود و فعال‌سازی فقط با تأیید صریح انجام می‌شود.
    if (v) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => _OnlineGuideConsentDialog(
          endpointHost: widget.services.onlineGuideEndpointHost,
        ),
      );
      if (ok != true) return; // بدون تأیید صریح، فعال نمی‌شود
    }
    await widget.services
        .saveSettings(widget.services.settings.copyWith(onlineGuideEnabled: v));
    await _load();
  }

  Future<void> _resetProgress() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('پاک کردن پیشرفت؟'),
        content: const Text(
          'همه تلاش‌ها و پیشرفت‌های ثبت‌شده روی این دستگاه حذف می‌شوند. این کار قابل بازگشت نیست.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('پاک کن', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.services.progress.resetAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('همه پیشرفت‌ها پاک شد.')),
        );
      }
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_summary == null || _settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: ParentDashboardScreen(
        summary: _summary!,
        settings: _settings!,
        onToggleVoice: _toggleVoice,
        onToggleOnlineGuide: _toggleOnlineGuide,
        onResetProgress: _resetProgress,
        // ممیزی ۱.۰.۲ (یافته حریم خصوصی): متن ذخیره‌سازی بر اساس وضعیت
        // واقعی انتخاب می‌شود — ادعای «همه داده‌ها همیشه محلی است» فقط
        // وقتی مطرح می‌شود که راهنمای آنلاین خاموش باشد.
        storageNotice:
            PrivacyTexts.storageNoticeFor(_settings!.onlineGuideEnabled),
      ),
    );
  }
}

/// دیالوگ رضایت آگاهانه برای فعال‌سازی راهنمای آنلاین — ممیزی ۱.۰.۲.
///
/// مقصد (آدرس سرور پیکربندی‌شده) و نوع داده ارسالی صریحاً توضیح داده
/// می‌شود؛ فعال‌سازی تنها با دکمه «فعال می‌کنم» انجام می‌شود.
///
/// ممیزی ۱.۰.۳ (دستورکار P1-۵): فهرست داده‌ها دقیقاً با payload واقعی
/// (شش فیلد JSON در ai_guide_http.dart) هماهنگ شد و هدف ارسال،
/// دریافت‌کننده، وضعیت نگهداری و روش خاموش‌کردن صریح ذکر می‌شود.
class _OnlineGuideConsentDialog extends StatelessWidget {
  final String? endpointHost;

  const _OnlineGuideConsentDialog({this.endpointHost});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('فعال‌سازی راهنمای آنلاین'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              endpointHost == null
                  ? 'در این نسخه آدرس سرور راهنما پیکربندی نشده است؛ '
                      'فعال‌سازی اثری ندارد و راهنمای محلی استفاده می‌شود.'
                  : 'با فعال‌سازی، هنگام درخواست راهنما توسط کودک، داده‌های '
                      'زیر به سرور «$endpointHost» (تنها دریافت‌کننده) '
                      'ارسال می‌شود:',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              '• utterance — متن گفتار کودک (حداکثر ۱۲۰ نویسه؛ فقط اگر '
                  'ورود گفتاری استفاده شود، وگرنه خالی)\n'
                  '• prompt — متن پرسش فعلی\n'
                  '• hints — راهنماهای همان پرسش (بدون گفتن پاسخ)\n'
                  '• wrongStreak — تعداد پاسخ‌های اشتباه پیاپی\n'
                  '• activityType — نوع فعالیت آموزشی\n'
                  '• lessonId — شناسه فعالیت درسی',
            ),
            const SizedBox(height: 10),
            const Text(
              'هدف ارسال: تولید پیام راهنما برای همان پرسش. این داده‌ها '
              'فقط با همین درخواست ارسال می‌شوند و سیاست نگهداری سمت سرور '
              'به پیکربندی آن سرور بستگی دارد (خارج از کنترل اپ).',
            ),
            const SizedBox(height: 10),
            const Text(
              'پیشرفت و تلاش‌ها همچنان فقط روی همین دستگاه ذخیره می‌شود. '
              'نام، عکس، شناسه دستگاه، موقعیت و تاریخچه کودک ارسال '
              'نمی‌شود. در هر خطای شبکه، راهنمای محلی (روی همین گوشی) '
              'جایگزین می‌شود. در هر لحظه با خاموش‌کردن کلید «راهنمای '
              'آنلاین» از همین صفحه، ارسال داده قطع می‌شود.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('صرف‌نظر'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('فعال می‌کنم'),
        ),
      ],
    );
  }
}
