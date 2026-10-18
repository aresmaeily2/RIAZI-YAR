import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FontLoader, rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riazi_yar/app_services.dart';
import 'package:riazi_yar/core/audio/tts_service.dart';
import 'package:riazi_yar/core/models/models.dart';
import 'package:riazi_yar/core/storage/database.dart';
import 'package:riazi_yar/main.dart';
import 'package:riazi_yar/ui/privacy_texts.dart';
import 'package:riazi_yar/ui/screens/activity_screen.dart';
import 'package:riazi_yar/ui/screens/parent_screen.dart';
import 'package:riazi_yar/ui/screens/settings_screen.dart';
import 'package:riazi_yar/ui/widgets/object_painter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// تست‌های ویجت واقعی — ممیزی ۱.۰.۲ (یافته تست):
///  • RTL بودن واقعی UI
///  • مسیر اصلی کودک (خانه → معرفی → فعالیت → بازخورد → نتیجه)
///  • حالت راهنمای محلی (بدون آنلاین)
///  • خطای ذخیره تلاش (UI نمی‌ایستد و ثبت موفق القا نمی‌شود)
///  • گیت والدین
///  • متن حریم خصوصی (تمایز محلی/آنلاین)
///
/// همه تست‌ها با پایگاه داده واقعی درون‌حافظه‌ای (sqflite_common_ffi با
/// طرح کامل AppDatabase)، TTS پایدار (Stub) و محتوای درس واقعی assets
/// اجرا می‌شوند.
///
/// نکته اجرایی مهم: عملیات واقعی SQLite درون testWidgets (FakeAsync)
/// باید داخل `tester.runAsync` انجام شود وگرنه حلقه تست کامل نمی‌شود؛
/// پنجره‌های runAsync پس از هر لمسی که ثبت DB راه می‌اندازد گذاشته شده
/// است.

const _faDigits = '۰۱۲۳۴۵۶۷۸۹';

Future<AppServices> _makeServices(WidgetTester tester) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  // هر تست پایگاه داده «مستقل» می‌گیرد: مسیر in-memory مشترک با
  // singleInstance پیش‌فرض باعث نشتی داده بین تست‌ها می‌شود (کشف‌شده
  // در ممیزی ۱.۰.۲). مسیر فایل موقت یکتا = ایزولاسیون کامل.
  final tmpDir = Directory.systemTemp.createTempSync('riazi_widget_test');
  addTearDown(() {
    try {
      tmpDir.deleteSync(recursive: true);
    } catch (_) {}
  });
  final dbPath =
      '${tmpDir.path}${Platform.pathSeparator}test_${DateTime.now().microsecondsSinceEpoch}.db';
  late AppServices services;
  await tester.runAsync(() async {
    services = AppServices(
      // طرح کامل (جدول‌ها + نسخه ۲) — همان مسیر باز کردن واقعی اپ
      databaseOverride: () async => AppDatabase.open(
        factory: databaseFactory,
        path: dbPath,
      ),
      ttsOverride: () => StubTtsService(),
    );
    await services.init();
  });
  return services;
}

/// پنجره زمان واقعی برای کامل شدن عملیات SQLite واقعی که با لمس
/// شروع شده‌اند؛ سپس یک pump برای پردازش نتایج (دیالوگ و …).
Future<void> _flushDb(WidgetTester tester) async {
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump(const Duration(milliseconds: 200));
}

/// سطح تست به اندازه گوشی واقعی (۴۱۲×۸۴۰ logical) — پیش‌فرض تست ۸۰۰×۶۰۰
/// است و برای اپ کودک گوشی واقع‌بینانه‌تر است.
void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(412 * 3, 840 * 3);
  tester.view.devicePixelRatio = 3.0;
  tester.platformDispatcher.views.first.physicalSize = const Size(412 * 3, 840 * 3);
  tester.platformDispatcher.views.first.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpApp(WidgetTester tester, AppServices services) async {
  _usePhoneSurface(tester);
  await tester.pumpWidget(RiaziYarApp(services: services));
  // init + AnimatedSwitcher؛ از pumpAndSettle استفاده نمی‌کنیم چون
  // نوار پیشرفت نامعین (value=null) در خانه بی‌پایان انیمیت می‌شود.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// بهداشت پایان تست: تایمرهای فیک بازمانده (مثلاً از زیرساخت sqflite)
/// شلیک می‌شوند و اتصال پایگاه داده در پنجره واقعی بسته می‌شود تا
/// ناورداي «تایمر معلق» در flutter_test خراب نشود.
Future<void> _teardownApp(WidgetTester tester, AppServices services) async {
  await tester.pump(const Duration(minutes: 5));
  await tester.runAsync(() async {
    try {
      await services.db.close();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 50));
}

/// پاسخ درست پرسش جاری را لمس می‌کند (countAndChoose: گزینه عددی؛
/// matchCount: دسته با تعداد درست).
Future<void> _tapCorrectAnswer(WidgetTester tester, Question q) async {
  if (q.options.any((o) => o.label.startsWith('دسته'))) {
    await tester.tap(find.byWidgetPredicate(
      (w) => w is ObjectGroup && w.count == q.correctAnswer,
    ));
  } else {
    final label =
        q.options.firstWhere((o) => o.value == q.correctAnswer).label;
    await tester.tap(find.text(label).last);
  }
  await tester.pump(const Duration(milliseconds: 150));
}

Lesson _firstRegularLesson(AppServices services) =>
    services.lessons.firstWhere((l) => l.kind == LessonKind.regular);

void _noop(bool _) {}

/// بارگذاری فونت واقعی Vazirmatn برای متریک واقع‌بینانه متن — بدون آن،
/// فونت تست (≈۱em برای هر نویسه) عرض دکمه‌ها را متورم می‌کند و
/// overflow کاذب در تست‌ها رخ می‌دهد (کشف‌شده در ممیزی ۱.۰.۲).
Future<void> _loadRealFonts() async {
  final loader = FontLoader('Vazirmatn')
    ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Vazirmatn-ExtraBold.ttf'));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _loadRealFonts();
  });
  group('RTL و صفحه اصلی (ممیزی ۱.۰.۲ — تست ویجت واقعی)', () {
    testWidgets('کل اپ راست‌به‌چپ است و متن فارسی نمایش داده می‌شود',
        (tester) async {
      final services = await _makeServices(tester);
      await _pumpApp(tester, services);

      final ctx = tester.element(find.byType(Text).first);
      expect(Directionality.of(ctx), TextDirection.rtl,
          reason: 'اپ کودک فارسی باید واقعاً RTL باشد');
      expect(find.text('درس‌های من'), findsOneWidget);
      expect(find.textContaining('سلام'), findsWidgets);
      // محتوای درس واقعاً بارگذاری شده است — عنوان هم در کارت «ادامه»
      // و هم در کارت درس دیده می‌شود.
      expect(find.text('شمارش اشیا (۱ تا ۵)'), findsWidgets);
      await _teardownApp(tester, services);
    });
  });

  group('مسیر اصلی کودک — کامل با پایگاه داده واقعی', () {
    testWidgets('خانه → معرفی → ۳ پرسش با پاسخ درست → صفحه نتیجه → خانه',
        (tester) async {
      final services = await _makeServices(tester);
      final lesson = _firstRegularLesson(services);
      await _pumpApp(tester, services);

      // شروع درس اول از کارت درس (ترنزیشن مسیر: پمپ کافی لازم است)
      await tester.tap(find.widgetWithText(ElevatedButton, 'شروع').first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('این درس چیه؟'), findsOneWidget);

      await tester.tap(find.text('شروع می‌کنم!'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 400));

      // هر سه پرسش با گزینه درست پاسخ داده می‌شود؛ پس از هر ثبت DB،
      // پنجره runAsync برای کامل شدن نوشتن واقعی
      final questions = lesson.allQuestions;
      for (var i = 0; i < questions.length; i++) {
        expect(find.text(questions[i].prompt), findsOneWidget,
            reason: 'پرسش ${i + 1} باید نمایش داده شود');
        await _tapCorrectAnswer(tester, questions[i]);
        await _flushDb(tester);
        expect(find.text('آفرین!'), findsOneWidget,
            reason: 'بازخورد درست باید فوری نمایش داده شود');
        await tester.tap(find.text('بریم بعدی'));
        await tester.pump(const Duration(milliseconds: 300));
      }

      // صفحه نتیجه — پس از آخرین «بریم بعدی»، _openActivity پیشرفت را
      // دوباره می‌خواند (عملیات واقعی DB) و بعد نتیجه را push می‌کند؛
      // پنجره runAsync لازم است.
      await _flushDb(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('درس تمام شد!'), findsOneWidget);
      expect(find.textContaining('در نخستین تلاش درست'), findsOneWidget);

      // تلاش‌ها واقعاً در پایگاه داده ثبت شده‌اند (نه فقط UI)
      final progressList = (await tester.runAsync(
              () => services.progress.allProgress())) ??
          <LearningProgress>[];
      expect(progressList, isNotEmpty,
          reason: 'مسیر اصلی باید تلاش‌ها را واقعاً ذخیره کند');
      final totalAttempts =
          progressList.fold<int>(0, (sum, p) => sum + p.totalCount);
      expect(totalAttempts, greaterThanOrEqualTo(questions.length));

      // بازگشت: «برگشت به خانه» نتیجه را می‌بندد و به «معرفی درس» برمی‌گردد
      // (رفتار فعلی اپ: صفحه معرفی در پشته می‌ماند و دکمه بازگشت AppBar
      // راه به خانه است — مستند در تست، بدون تغییر رفتار خارج از دامنه ممیزی)
      await tester.tap(find.text('برگشت به خانه'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('این درس چیه؟'), findsOneWidget);

      // بازگشت از معرفی → خانه
      await tester.tap(find.byType(BackButton));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('درس‌های من'), findsOneWidget);
      await _teardownApp(tester, services);
    });
  });

  group('راهنمای محلی (ممیزی ۱.۰.۲ — تست ویجت واقعی)', () {
    testWidgets('دکمه راهنما → شیت راهنما با منبع محلی و hint درس',
        (tester) async {
      final services = await _makeServices(tester);
      final lesson = _firstRegularLesson(services);
      expect(services.settings.onlineGuideEnabled, false,
          reason: 'پیش‌فرض باید راهنمای محلی باشد');

      await _pumpApp(tester, services);
      await tester.tap(find.widgetWithText(ElevatedButton, 'شروع').first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('شروع می‌کنم!'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 400));

      // درخواست راهنما با wrongStreak=۰ → نخستین hint درس (موتور محلی)
      await tester.tap(find.byTooltip('کمک می‌خوام'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('راهنمای من'), findsOneWidget);
      expect(find.text('راهنمای محلی (روی همین گوشی)'), findsOneWidget,
          reason: 'منبع راهنما باید صادقانه «محلی» اعلام شود');
      // hint درس دو جا دیده می‌شود (رفتار درست): بنر «راهنما: …» روی صفحه
      // و متن داخل شیت راهنما.
      expect(find.textContaining(lesson.allQuestions.first.hints.first),
          findsWidgets,
          reason: 'محتوای راهنما باید از hint درس بیاید (موتور محلی)');

      // بستن شیت (چند فریم برای شروع و تکمیل انیمیشن بسته شدن)
      await tester.tap(find.text('فهمیدم، بریم بشماریم'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('راهنمای من'), findsNothing);
      await _teardownApp(tester, services);
    });
  });

  group('خطای ذخیره تلاش (ممیزی ۱.۰.۲ — تست ویجت واقعی)', () {
    testWidgets(
        'شکست SQLite → کودک متوقف نمی‌شود و «خطای ذخیره» صادقانه دیده می‌شود',
        (tester) async {
      final services = await _makeServices(tester);
      final lesson = _firstRegularLesson(services);
      var saveCalls = 0;

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('fa', 'IR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: ActivityScreen(
          lesson: lesson,
          services: services,
          trialMode: false,
          onAttempt: (_) async {
            saveCalls++;
            throw Exception('sqlite disk I/O error (تست)');
          },
          onFinish: (_) {},
        ),
      ));
      await tester.pump(const Duration(milliseconds: 200));

      final q = lesson.allQuestions.first;
      await _tapCorrectAnswer(tester, q);
      await tester.pump(const Duration(milliseconds: 200));

      // ۱) تلاش اول + تلاش مجدد = دو فراخوانی (رفتار retry)
      expect(saveCalls, 2);

      // ۲) بازخورد کودک همان‌طور نمایش داده می‌شود (جریان ادامه دارد)
      expect(find.text('آفرین!'), findsOneWidget);

      // ۳) پیام صادقانه خطا برای والد
      expect(find.textContaining('ثبت این تلاش در حافظه دستگاه ممکن نشد'),
          findsOneWidget);

      // ۴) پس از ادامه، نشانگر پایدار خطای ذخیره‌سازی دیده می‌شود
      await tester.tap(find.text('بریم بعدی'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('خطای ذخیره‌سازی — ثبت پیشرفت موقتاً قطع است'),
          findsOneWidget);

      // ۵) هیچ تلاشی در DB ثبت نشده (القای ثبت موفق ممنوع)
      final progressList = (await tester.runAsync(
              () => services.progress.allProgress())) ??
          <LearningProgress>[];
      expect(progressList, isEmpty);
    });

    testWidgets('ذخیره موفق → هیچ نشانگر خطا و هیچ SnackBar خطا',
        (tester) async {
      final services = await _makeServices(tester);
      final lesson = _firstRegularLesson(services);

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('fa', 'IR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: ActivityScreen(
          lesson: lesson,
          services: services,
          trialMode: false,
          onAttempt: (a) => services.progress.recordAttempt(a),
          onFinish: (_) {},
        ),
      ));
      await tester.pump(const Duration(milliseconds: 200));

      final q = lesson.allQuestions.first;
      await _tapCorrectAnswer(tester, q);
      await _flushDb(tester);
      expect(find.textContaining('ممکن نشد'), findsNothing);
      await tester.tap(find.text('بریم بعدی'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('خطای ذخیره‌سازی — ثبت پیشرفت موقتاً قطع است'),
          findsNothing);
    });
  });

  group('گیت والدین (ممیزی ۱.۰.۲ — تست ویجت واقعی)', () {
    /// عبارت سؤال گیت مثل «۳۱ + ۱۴ = ؟» → دو عملوند را جدا می‌خواند.
    (int, int) gateOperands(String qText) {
      final latin = qText.runes.map((ch) {
        final idx = _faDigits.indexOf(String.fromCharCode(ch));
        return idx >= 0 ? '$idx' : String.fromCharCode(ch);
      }).join();
      final m = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(latin)!;
      return (int.parse(m.group(1)!), int.parse(m.group(2)!));
    }

    testWidgets('پاسخ اشتباه → خطا و ورود نمی‌شود', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ParentGateScreen(child: Text('ناحیه والدین')),
      ));
      await tester.pump();

      final (a, b) = gateOperands(
          tester.widget<Text>(find.textContaining('= ؟')).data!);
      final wrongAnswer = a + b + 1; // عمداً اشتباه

      await tester.enterText(find.byType(TextField), '$wrongAnswer');
      await tester.tap(find.text('ورود'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('پاسخ درست نبود؛ سؤال جدید آماده شد.'), findsOneWidget);
      expect(find.text('ناحیه والدین'), findsNothing,
          reason: 'با پاسخ اشتباه نباید وارد بخش والدین شد');
    });

    testWidgets('پاسخ درست سؤال ریاضی → ورود به داشبورد والدین',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ParentGateScreen(child: Text('ناحیه والدین')),
      ));
      await tester.pump();

      // سؤال گیت از روی UI خوانده و حل می‌شود (همان مسیر والد واقعی)
      final (a, b) = gateOperands(
          tester.widget<Text>(find.textContaining('= ؟')).data!);

      await tester.enterText(find.byType(TextField), '${a + b}');
      await tester.tap(find.text('ورود'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ناحیه والدین'), findsOneWidget);
    });
  });

  group('متن حریم خصوصی (ممیزی ۱.۰.۲)', () {
    testWidgets('تنظیمات: ادعای بدون‌شرط «همه داده‌ها فقط...» حذف شده است',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: SettingsScreen(voiceEnabled: true, onToggleVoice: _noop),
      ));
      await tester.pump();

      // ادعای قدیمیِ بدون شرط نباید برگردد
      expect(
          find.textContaining(
              'همه داده‌ها فقط روی همین گوشی ذخیره می‌شوند.'),
          findsNothing,
          reason: 'ادعای بدون‌شرط با قابلیت اختیاری آنلاین ناسازگار است');
      // توضیح صادقانه جایگزین شده: پیش‌فرض محلی + استثنای آنلاین
      expect(find.textContaining('پیش‌فرض این اپ کاملاً محلی است'),
          findsOneWidget);
      expect(find.textContaining('استثنا'), findsOneWidget);
    });

    testWidgets(
        'داشبورد والدین: متن ذخیره‌سازی مطابق وضعیت آنلاین تغییر می‌کند',
        (tester) async {
      // منطق انتخاب (نقطه تصمیم واحد)
      expect(PrivacyTexts.storageNoticeFor(false),
          PrivacyTexts.storageNoticeLocal);
      expect(PrivacyTexts.storageNoticeFor(true),
          PrivacyTexts.storageNoticeOnline);

      final summary = ParentSummary(
        totalAttempts: 0,
        totalCorrect: 0,
        activitiesStarted: 0,
        activitiesMastered: 0,
        needsPracticeTitles: const [],
        generatedAt: DateTime(2026, 1, 1),
      );

      // حالت محلی (پیش‌فرض) — متن در پایین لیست است؛ اسکرول تا نمایان شدن
      await tester.pumpWidget(MaterialApp(
        home: ParentDashboardScreen(
          summary: summary,
          settings: const LearnerSettings(),
          onToggleOnlineGuide: _noop,
          onToggleVoice: _noop,
          onResetProgress: () {},
          storageNotice: PrivacyTexts.storageNoticeFor(false),
        ),
      ));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.textContaining('وضعیت فعلی: محلی'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      expect(find.textContaining('وضعیت فعلی: محلی'), findsOneWidget);

      // حالت آنلاین روشن
      await tester.pumpWidget(MaterialApp(
        home: ParentDashboardScreen(
          summary: summary,
          settings: const LearnerSettings(onlineGuideEnabled: true),
          onToggleOnlineGuide: _noop,
          onToggleVoice: _noop,
          onResetProgress: () {},
          storageNotice: PrivacyTexts.storageNoticeFor(true),
        ),
      ));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.textContaining('راهنمای آنلاین روشن است'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      expect(find.textContaining('راهنمای آنلاین روشن است'), findsOneWidget);
      expect(find.textContaining('متن پرسش'), findsWidgets,
          reason: 'در حالت آنلاین، نوع داده ارسالی باید توضیح داده شود '
              '(هم در پیام ذخیره‌سازی و هم زیرنویس سوییچ)');
    });
  });
}
