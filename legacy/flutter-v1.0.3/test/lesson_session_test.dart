import 'package:flutter_test/flutter_test.dart';
import 'package:riazi_yar/core/engine/lesson_session.dart';
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
            _question('q1', 2),
            _question('q2', 4),
          ],
        ),
        Activity(
          id: 'a2',
          type: ActivityType.matchCount,
          instruction: 'تطبیق بده',
          difficulty: 2,
          questions: [
            _question('q3', 5),
          ],
        ),
      ],
    );

Question _question(String id, int correct) => Question(
      id: id,
      prompt: 'p',
      itemShape: 'ball',
      itemCount: correct,
      options: [
        for (final o in [correct - 1, correct, correct + 1])
          AnswerOption(value: o, label: '$o'),
      ],
      correctAnswer: correct,
      hints: const ['h1', 'h2', 'h3'],
      feedbackCorrect: 'درست',
      feedbackWrong: 'دوباره',
    );

void main() {
  group('جلسه درس', () {
    test('ترتیب و شمار پرسش‌ها', () {
      final s = LessonSession(lesson: _lesson());
      expect(s.totalQuestions, 3);
      expect(s.currentItem.question.id, 'q1');
      expect(s.currentItem.activity.id, 'a1');
    });

    test('پاسخ درست → پیشروی', () {
      final s = LessonSession(lesson: _lesson());
      s.submitAnswer(2);
      expect(s.isLocked, true, reason: 'قفل ضد دابل‌کلیک پس از submit');
      expect(s.submitAnswer(4), isNull, reason: 'submit دوباره مجاز نیست');
      s.advance();
      expect(s.isLocked, false);
      expect(s.currentItem.question.id, 'q2');
      expect(s.correctCount, 1);
    });

    test('پاسخ اشتباه → همان پرسش تکرار می‌شود تا سقف تلاش', () {
      final s = LessonSession(lesson: _lesson());
      s.submitAnswer(1); // غلط
      s.advance();
      expect(s.currentItem.question.id, 'q1');
      expect(s.wrongCount, 1);
      // دوباره غلط
      s.submitAnswer(1);
      s.advance();
      expect(s.currentItem.question.id, 'q1');
      // سومین غلط → پیشروی اجباری
      s.submitAnswer(1);
      s.advance();
      expect(s.currentItem.question.id, 'q2');
      expect(s.wrongStreakCurrent, 0, reason: 'شمارنده اشتباه پرسش جدید صفر می‌شود');
    });

    test('پاسخ درست پس از اشتباه → پیشروی و امتیاز نهایی واقعی', () {
      final s = LessonSession(lesson: _lesson());
      // q1: غلط بعد درست
      s.submitAnswer(1);
      s.advance();
      s.submitAnswer(2);
      s.advance();
      // q2: درست
      s.submitAnswer(4);
      s.advance();
      // q3: درست
      s.submitAnswer(5);
      s.advance();
      expect(s.isFinished, true);
      expect(s.correctCount, 2, reason: 'درستِ نهایی هر پرسش');
      expect(s.wrongCount, 1);
      expect(s.score(), closeTo(2 / 3, 0.001));
    });

    test('advance قبل از submit کار نمی‌کند', () {
      final s = LessonSession(lesson: _lesson());
      expect(s.advance(), false);
    });

    test('جلسه تمام‌شده پاسخ نمی‌پذیرد', () {
      final s = LessonSession(lesson: _lesson());
      s.submitAnswer(2);
      s.advance();
      s.submitAnswer(4);
      s.advance();
      s.submitAnswer(5);
      s.advance();
      expect(s.isFinished, true);
      expect(s.submitAnswer(2), isNull);
    });
  });
}
