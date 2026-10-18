import '../models/models.dart';
import 'evaluator.dart';

/// وضعیت لحظه‌ای نمایش یک پرسش در UI.
enum QuestionPhase { asking, feedback }

/// یک آیتم قابل نمایش در جلسه (فعالیت + پرسش تخت‌شده).
class SessionItem {
  final Activity activity;
  final Question question;
  final int flatIndex; // شماره پرسش در کل جلسه (از ۰)

  const SessionItem({
    required this.activity,
    required this.question,
    required this.flatIndex,
  });
}

/// موتور جلسه درس — ماشین حالت خالص Dart، مستقل از UI.
///
/// مسئولیت‌ها:
///  - ترتیب پرسش‌ها و پیمایش جلسه
///  - قفل پاسخ پس از submit (جلوگیری از ثبت چندباره — نیازمند مأموریت ۵.۹)
///  - شمارش تلاش هر پرسش و سطح راهنما
///  - محاسبه نتیجه نهایی جلسه
///
/// ممیزی ۱.۰.۲ (یافته امتیاز آخرین آزمون): هر جلسه هنگام ساخت یک
/// [runId] یکتا می‌گیرد؛ همه تلاش‌های ثبت‌شده در همین جلسه این شناسه را
/// حمل می‌کنند تا امتیاز آزمون در گزارش والدین دقیقاً از تلاش‌های «همین
/// اجرا» محاسبه شود، نه از تاریخچه تجمیعی همه اجراها.
class LessonSession {
  final Lesson lesson;
  final Evaluator evaluator;
  final DateTime Function() clock;

  /// شناسه یکتای این اجرا — پیش‌فرض تولید خودکار؛ در تست‌ها قابل
  /// تزریق برای رفتار قطعی.
  final String runId;

  final List<SessionItem> items;
  int _index = 0;
  bool _locked = false;
  bool _finished = false;

  /// شمارنده ساخت جلسه برای تضمین یکتایی run_id در همان پروسه.
  static int _sessionCounter = 0;

  /// نتیجه هر پرسش بر اساس «نخستین تلاش» آن (کلید: flatIndex).
  ///
  /// تصمیم طراحی (مستندشده): امتیاز جلسه فقط نتیجه نخستین تلاش هر پرسش را
  /// می‌شمارد؛ تلاش‌های اصلاحی بعدی برای تمرین و یادگیری هستند و امتیاز را
  /// بالا نمی‌برند تا تصویر واقعی یادگیری کودک حفظ شود. همه تلاش‌ها (نه فقط
  /// نخستین) در لایه storage ثبت می‌شوند و در گزارش والدین دیده می‌شوند.
  final Map<int, bool> _questionOutcome = {};

  /// تعداد کل تلاش‌های ثبت‌شده در این جلسه (برای ثبت در پایگاه داده).
  int totalAttempts = 0;

  /// شمار پرسش‌هایی که نخستین تلاششان درست بود.
  int get correctCount =>
      _questionOutcome.values.where((ok) => ok).length;

  /// شمار پرسش‌هایی که نخستین تلاششان اشتباه بود.
  int get wrongCount =>
      _questionOutcome.values.where((ok) => !ok).length;

  /// تعداد پاسخ اشتباه پشت‌سرهم برای پرسش جاری (سطح راهنما را تعیین می‌کند).
  int wrongStreakCurrent = 0;

  /// نتیجه آخرین ارزیابی برای نمایش در UI.
  EvaluationResult? lastResult;

  LessonSession({
    required this.lesson,
    this.evaluator = const Evaluator(),
    DateTime Function()? clock,
    String? runId,
  })  : clock = clock ?? DateTime.now,
        runId = runId ??
            'run-${(clock ?? DateTime.now)().millisecondsSinceEpoch}-${_sessionCounter++}',
        items = _flatten(lesson);

  static List<SessionItem> _flatten(Lesson lesson) {
    final out = <SessionItem>[];
    var i = 0;
    for (final a in lesson.activities) {
      for (final q in a.questions) {
        out.add(SessionItem(activity: a, question: q, flatIndex: i++));
      }
    }
    return out;
  }

  // ---------- وضعیت ----------
  bool get isLocked => _locked;
  bool get isFinished => _finished;
  int get currentIndex => _index;
  int get totalQuestions => items.length;
  SessionItem get currentItem => items[_index];

  /// پرسش فعلی؛ اگر جلسه تمام شده باشد null.
  SessionItem? get currentOrNull => _finished ? null : items[_index];

  /// آیا همه پرسش‌های فعلی فعالیت‌ها پاس شده‌اند؟
  bool get answeredCurrent => _locked;

  // ---------- عملیات ----------
  /// ثبت پاسخ کودک. اگر قفل باشد یا جلسه تمام باشد، null برمی‌گرداند
  /// (جلوگیری از دابل‌کلیک و ثبت چندباره).
  EvaluationResult? submitAnswer(int value) {
    if (_locked || _finished) return null;
    final q = currentItem.question;
    final result = evaluator.evaluate(q, value);
    lastResult = result;
    _locked = true;
    totalAttempts++;
    // نتیجه پرسش فقط با نخستین تلاش تعیین می‌شود و بعداً تغییر نمی‌کند.
    if (!_questionOutcome.containsKey(_index)) {
      _questionOutcome[_index] = result.isCorrect;
    }
    if (result.isCorrect) {
      wrongStreakCurrent = 0;
    } else {
      wrongStreakCurrent++;
    }
    return result;
  }

  /// رفتن به مرحله بعد. در فعالیت‌های چندتلاشی، اشتباه یعنی
  /// «همان پرسش دوباره نمایش داده شود» تا کودک فرصت اصلاح داشته باشد
  /// (بازخورد محترمانه + امکان تکرار تمرین). اگر پاسخ درست بود یا
  /// پرسش اجباری نیست، پیش می‌رویم.
  ///
  /// قاعده پیشروی MVP:
  ///  - پاسخ درست → پرسش بعدی
  ///  - پاسخ اشتباه → همان پرسش تا حداکثر [maxTriesPerQuestion] بار؛
  ///    پس از آن با ثبت «نیازمند تمرین» به پرسش بعدی می‌رویم.
  bool advance({int maxTriesPerQuestion = 3}) {
    if (!_locked || _finished) return false;
    final result = lastResult!;
    if (result.isCorrect || wrongStreakCurrent >= maxTriesPerQuestion) {
      wrongStreakCurrent = 0;
      if (_index + 1 >= items.length) {
        _finished = true;
        _locked = false;
        return true;
      }
      _index++;
    }
    _locked = false; // اجازه پاسخ دوباره (همان پرسش یا بعدی)
    return true;
  }

  /// امتیاز نهایی جلسه از ۰ تا ۱ بر اساس «نخستین تلاشِ درستِ» هر پرسش نسبت به
  /// کل پرسش‌های جلسه.
  ///
  /// صادقانه و مستند: تلاش‌های اصلاحیِ همان پرسش امتیاز اضافه نمی‌کنند؛
  /// بنابراین امتیاز، تصویر واقعی عملکرد نخستین کودک را نشان می‌دهد. تاریخچه
  /// کامل تلاش‌ها جداگانه در پایگاه داده ثبت و در گزارش والدین نمایش داده می‌شود.
  double score() => evaluator.sessionScore(correct: correctCount, total: totalQuestions);
}
