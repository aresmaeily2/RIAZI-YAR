import 'package:flutter_test/flutter_test.dart';
import 'package:riazi_yar/core/engine/lesson_session.dart';
import 'package:riazi_yar/core/guide/ai_guide_http.dart';
import 'package:riazi_yar/core/guide/guide_engine.dart';
import 'package:riazi_yar/core/models/models.dart';

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

GuideQuery _query(int wrongStreak, {String? utterance}) => GuideQuery(
      question: _lesson().allQuestions.first,
      activity: _lesson().activities.first,
      wrongStreak: wrongStreak,
      utterance: utterance,
    );

void main() {
  group('راهنمای محلی قواعد‌محور', () {
    final guide = LocalGuideEngine();

    test('اولین راهنما بدون لو دادن جواب مستقیم', () async {
      final reply = await guide.respond(_query(0));
      expect(reply.source, 'local');
      expect(reply.action, GuideAction.showHint);
      expect(reply.message, contains('راهنمای اول'));
    });

    test('اشتباه دوم → راهنمای دوم (پیشرفت مرحله‌ای)', () async {
      final reply = await guide.respond(_query(1));
      expect(reply.message, contains('راهنمای دوم'));
    });

    test('اشتباه سوم → استراتژی شمارش نزدیک‌تر', () async {
      final reply = await guide.respond(_query(3));
      expect(reply.action, GuideAction.showAnswerStrategy);
      expect(reply.message, contains('شمارش'));
    });

    test('«نمی‌دانم» → همدلی + راهنما، نه جواب', () async {
      final reply = await guide.respond(_query(0, utterance: 'نمی‌دانم'));
      expect(reply.action, GuideAction.showHint);
      expect(reply.message, contains('اشکالی ندارد'));
      expect(reply.message.contains('۳'), false);
    });

    test('«جواب را بگو» → راهنما، بدون پاسخ نهایی', () async {
      final reply = await guide.respond(_query(0, utterance: 'جواب را بگو'));
      expect(reply.message, isNot(contains('جواب ۳')));
      expect(reply.action, GuideAction.showHint);
    });

    test('حرف بی‌ربط → بازگشت محترمانه به درس', () async {
      final reply = await guide.respond(_query(0, utterance: 'کارتون بذار'));
      expect(reply.action, GuideAction.backToLesson);
      expect(reply.message, contains('برگردیم'));
    });

    test('گفتار نامفهوم → پیام امن', () async {
      final reply = await guide.respond(_query(0, utterance: 'جاژلگل'));
      expect(reply.action, GuideAction.safeFallback);
    });
  });

  group('راهنمای آنلاین (قرارداد)', () {
    test('بدون پیکربندی → خطای کنترل‌شده', () async {
      final client = HttpAiGuideClient(endpointProvider: () => null);
      expect(client.isConfigured, false);
      await expectLater(
        client.respond(_query(0)),
        throwsA(isA<GuideNotConfiguredException>()),
      );
    });

    test('ورودی بیش از حد طولانی → خطای قالب', () async {
      final client = HttpAiGuideClient(endpointProvider: () => Uri.parse('https://x.test'));
      final long = 'ف' * 200;
      await expectLater(
        client.respond(_query(0, utterance: long)),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('GuideReply.fromJson خروجی نامعتبر را رد می‌کند', () {
      expect(
        () => GuideReply.fromJson({'message': ''}, source: 'online'),
        throwsA(isA<GuideFormatException>()),
      );
      expect(
        () => GuideReply.fromJson({'message': 'x' * 400}, source: 'online'),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('GuideReply.fromJson اکشن نامعتبر → keepGoing (رفتار امن)', () {
      final r = GuideReply.fromJson({'message': 'سلام'}, source: 'online');
      expect(r.action, GuideAction.keepGoing);
      expect(r.source, 'online');
    });
  });

  group('صحت حالت جلسه برای راهنما', () {
    test('سطح راهنما با تعداد اشتباه هم‌گام است', () {
      final s = LessonSession(lesson: _lesson());
      s.submitAnswer(1);
      expect(s.wrongStreakCurrent, 1);
      s.advance();
      s.submitAnswer(1);
      expect(s.wrongStreakCurrent, 2);
    });
  });
}
