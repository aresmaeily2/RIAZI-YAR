import '../models/models.dart';

/// نتیجه ارزیابی یک پاسخ.
class EvaluationResult {
  final bool isCorrect;
  final int chosenValue;
  final int correctAnswer;
  final String message;

  const EvaluationResult({
    required this.isCorrect,
    required this.chosenValue,
    required this.correctAnswer,
    required this.message,
  });
}

/// منطق ارزیابی پاسخ‌ها — کاملاً مستقل از UI و قابل تست واحد.
class Evaluator {
  const Evaluator();

  /// ارزیابی پاسخ عددی کودک برای یک پرسش.
  EvaluationResult evaluate(Question q, int chosenValue) {
    final ok = chosenValue == q.correctAnswer;
    return EvaluationResult(
      isCorrect: ok,
      chosenValue: chosenValue,
      correctAnswer: q.correctAnswer,
      message: ok ? q.feedbackCorrect : q.feedbackWrong,
    );
  }

  /// آیا با این نسبتِ درست، فعالیت «تسلط‌شده» است؟
  ///
  /// معیار تسلط (قابل تنظیم از بخش والدین):
  ///   نسبت پاسخ‌های درست >= [threshold]  و  تعداد کل تلاش‌ها >= [minAttempts]
  /// این معیار «شاخص رفتاری ساده» است، نه ادعای روان‌سنجی.
  bool isMastered({
    required int correctCount,
    required int wrongCount,
    double threshold = 0.75,
    int minAttempts = 2,
  }) {
    final total = correctCount + wrongCount;
    if (total < minAttempts) return false;
    return correctCount / total >= threshold;
  }

  /// امتیاز جلسه از ۰ تا ۱ برای نمایش نتیجه.
  double sessionScore({required int correct, required int total}) {
    if (total <= 0) return 0;
    return correct / total;
  }

  /// پیام نتیجه بر اساس امتیاز — همیشه تشویقی، بدون سرزنش.
  String resultMessage(double score) {
    if (score >= 0.99) return 'همه را درست جواب دادی! چه حرفه‌ای!';
    if (score >= 0.75) return 'خیلی خوب بود! تو خیلی پیشرفت کردی.';
    if (score >= 0.5) return 'خوب تلاش کردی! بیا یک‌بار دیگر تمرین کنیم.';
    return 'تمرین کردی و یاد گرفتی! بیا دوباره بازی کنیم تا بهتر شوی.';
  }
}
