import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:riazi_yar/core/guide/guide_engine.dart';
import 'package:riazi_yar/core/guide/guide_resolver.dart';
import 'package:riazi_yar/core/models/models.dart';

// Helpers — همان الگوی guide_engine_test.dart
Lesson _lesson() => Lesson(
      id: 'l',
      title: 'تست',
      description: '',
      unit: '',
      contentVersion: '1.0.0',
      kind: LessonKind.regular,
      teacherReviewed: false,
      activities: [
        Activity(
          id: 'a1',
          type: ActivityType.countAndChoose,
          instruction: 'بشمار',
          difficulty: 1,
          questions: [
            Question(
              id: 'q1',
              prompt: 'چند سیب؟',
              itemShape: 'apple',
              itemCount: 3,
              options: const [
                AnswerOption(value: 2, label: '۲'),
                AnswerOption(value: 3, label: '۳'),
                AnswerOption(value: 4, label: '۴'),
              ],
              correctAnswer: 3,
              hints: const ['راهنمای اول', 'راهنمای دوم', 'راهنمای سوم'],
              feedbackCorrect: 'آفرین',
              feedbackWrong: 'دوباره',
            ),
          ],
        ),
      ],
    );

GuideQuery _query() => GuideQuery(
      question: _lesson().allQuestions.first,
      activity: _lesson().activities.first,
      wrongStreak: 0,
    );

/// موتور محلی فیک — پاسخ قابل تشخیص
class FakeLocalGuide implements GuideEngine {
  @override
  Future<GuideReply> respond(GuideQuery query) async =>
      const GuideReply(message: 'پاسخ محلی', action: GuideAction.showHint, source: 'local');
}

/// موتور آنلاین فیک با رفتار قابل کنترل
class FakeOnlineGuide implements GuideEngine {
  FakeOnlineGuide(this.behavior);

  final Future<GuideReply> Function() behavior;

  @override
  Future<GuideReply> respond(GuideQuery query) => behavior();
}

void main() {
  group('رفتار fallback راهنما (منطق منتقل‌شده از UI — ممیزی ۱.۰.۱)', () {
    test('راهنمای آنلاین غیرفعال → مستقیم موتور محلی', () async {
      final online = FakeOnlineGuide(
        () => throw UnimplementedError('نباید صدا زده شود'),
      );
      final reply = await resolveGuideReply(
        localGuide: FakeLocalGuide(),
        onlineGuide: online,
        onlineEnabled: false,
        onlineConfigured: true,
        query: _query(),
      );
      expect(reply.message, 'پاسخ محلی');
      expect(reply.source, 'local');
    });

    test('فعال ولی پیکربندی‌نشده → موتور محلی', () async {
      final reply = await resolveGuideReply(
        localGuide: FakeLocalGuide(),
        onlineGuide: FakeOnlineGuide(
          () => throw UnimplementedError('نباید صدا زده شود'),
        ),
        onlineEnabled: true,
        onlineConfigured: false,
        query: _query(),
      );
      expect(reply.message, 'پاسخ محلی');
    });

    test('خروجی نامعتبر سرور (GuideFormatException) → پیام «قابل فهم نبود» محلی', () async {
      final reply = await resolveGuideReply(
        localGuide: FakeLocalGuide(),
        onlineGuide: FakeOnlineGuide(
          () => throw const GuideFormatException('قالب بد'),
        ),
        onlineEnabled: true,
        onlineConfigured: true,
        query: _query(),
      );
      expect(reply.message, GuideMessages.invalidAiOutput);
      expect(reply.source, 'local');
      expect(reply.action, GuideAction.showHint);
    });

    test('خطای شبکه/نبود سرور → پیام «در دسترس نیست» محلی', () async {
      final reply = await resolveGuideReply(
        localGuide: FakeLocalGuide(),
        onlineGuide: FakeOnlineGuide(
          () => throw const GuideNotConfiguredException(),
        ),
        onlineEnabled: true,
        onlineConfigured: true,
        query: _query(),
      );
      expect(reply.message, GuideMessages.offline);
      expect(reply.source, 'local');
    });

    test('خطای عمومی دیگر → پیام «در دسترس نیست» (نه کرش)', () async {
      final reply = await resolveGuideReply(
        localGuide: FakeLocalGuide(),
        onlineGuide: FakeOnlineGuide(
          () => throw StateError('خطای غیرمنتظره'),
        ),
        onlineEnabled: true,
        onlineConfigured: true,
        query: _query(),
      );
      expect(reply.message, GuideMessages.offline);
    });

    test('پاسخ موفق آنلاین → عیناً استفاده می‌شود (source: online)', () async {
      final reply = await resolveGuideReply(
        localGuide: FakeLocalGuide(),
        onlineGuide: FakeOnlineGuide(
          () async => const GuideReply(
            message: 'پاسخ آنلاین',
            action: GuideAction.showHint,
            source: 'online',
          ),
        ),
        onlineEnabled: true,
        onlineConfigured: true,
        query: _query(),
      );
      expect(reply.message, 'پاسخ آنلاین');
      expect(reply.source, 'online');
    });

    // ممیزی ۱.۰.۲ (یافته timeout): پاسخ معلق/timeout سرور باید در زمان
    // محدود به fallback محلی برسد — نه انتظار بی‌نهایت در UI کودک.
    test('timeout سرور آنلاین (TimeoutException) → fallback محلی در زمان محدود',
        () async {
      final sw = Stopwatch()..start();
      final reply = await resolveGuideReply(
        localGuide: FakeLocalGuide(),
        onlineGuide: FakeOnlineGuide(
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 120));
            throw TimeoutException('اتصال طول کشید');
          },
        ),
        onlineEnabled: true,
        onlineConfigured: true,
        query: _query(),
      );
      sw.stop();
      expect(reply.message, GuideMessages.offline);
      expect(reply.source, 'local');
      expect(reply.action, GuideAction.showHint);
      expect(sw.elapsed, lessThan(const Duration(seconds: 3)));
    });

    test('موتور آنلاین معلق برای همیشه — resolver مستقیماً صدا زده نمی‌شود؛\n'
        'خود HttpAiGuideClient باید deadline را اجرا کند (پوشش در ai_guide_http_test)',
        () async {
      // این تست قرارداد معماری را مستند می‌کند: resolver منتظر بی‌نهایت
      // نمی‌ماند چون لایه کلاینت (respond) هرگز بیش از timeout معلق
      // نمی‌ماند. برای اطمینان، timeout واقعی همانجا تست شده است.
      final reply = await resolveGuideReply(
        localGuide: FakeLocalGuide(),
        onlineGuide: FakeOnlineGuide(
          () => Future<GuideReply>.delayed(
            const Duration(milliseconds: 50),
            () => const GuideReply(
                message: 'دیر پاسخ داد', action: GuideAction.showHint, source: 'online'),
          ),
        ),
        onlineEnabled: true,
        onlineConfigured: true,
        query: _query(),
      );
      expect(reply.message, 'دیر پاسخ داد');
    });
  });
}
