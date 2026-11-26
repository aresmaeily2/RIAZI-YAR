import 'package:flutter_test/flutter_test.dart';
import 'package:riazi_yar/core/engine/evaluator.dart';
import 'package:riazi_yar/core/models/models.dart';

Question _q({int correct = 3, List<int> options = const [2, 3, 4]}) => Question(
      id: 'q1',
      prompt: 'چند سیب؟',
      itemShape: 'apple',
      itemCount: correct,
      options: [for (final o in options) AnswerOption(value: o, label: '$o')],
      correctAnswer: correct,
      hints: const ['hint1', 'hint2'],
      feedbackCorrect: 'آفرین',
      feedbackWrong: 'دوباره تلاش کن',
    );

void main() {
  const evaluator = Evaluator();

  group('ارزیابی پاسخ', () {
    test('پاسخ درست', () {
      final r = evaluator.evaluate(_q(), 3);
      expect(r.isCorrect, true);
      expect(r.message, 'آفرین');
    });

    test('پاسخ اشتباه', () {
      final r = evaluator.evaluate(_q(), 2);
      expect(r.isCorrect, false);
      expect(r.chosenValue, 2);
      expect(r.correctAnswer, 3);
      expect(r.message, 'دوباره تلاش کن');
    });
  });

  group('معیار تسلط', () {
    test('سه درست از چهار = ۰.۷۵ → تسلط', () {
      expect(
        evaluator.isMastered(correctCount: 3, wrongCount: 1),
        true,
      );
    });

    test('دو درست از چهار = ۰.۵ → بدون تسلط', () {
      expect(
        evaluator.isMastered(correctCount: 2, wrongCount: 2),
        false,
      );
    });

    test('کمتر از حداقل تلاش → بدون تسلط حتی با ۱۰۰٪', () {
      expect(
        evaluator.isMastered(correctCount: 1, wrongCount: 0),
        false,
      );
    });

    test('آستانه سفارشی والدین اعمال می‌شود', () {
      expect(
        evaluator.isMastered(
          correctCount: 2,
          wrongCount: 1,
          threshold: 0.6,
        ),
        true,
      );
      expect(
        evaluator.isMastered(
          correctCount: 2,
          wrongCount: 1,
          threshold: 0.9,
        ),
        false,
      );
    });
  });

  group('امتیاز جلسه', () {
    test('صفر پرسش → صفر', () {
      expect(evaluator.sessionScore(correct: 0, total: 0), 0);
    });

    test('نسبت درست', () {
      expect(evaluator.sessionScore(correct: 3, total: 4), 0.75);
    });
  });

  group('پیام نتیجه', () {
    test('بدون سرزنش در همه سطوح', () {
      for (final s in [0.0, 0.3, 0.6, 0.8, 1.0]) {
        final m = evaluator.resultMessage(s);
        expect(m, isNotEmpty);
        // هیچ پیامی کلمه سرزنش‌آمیز ندارد
        expect(m.contains('تنبل'), false);
        expect(m.contains('بد'), false);
      }
    });
  });
}
