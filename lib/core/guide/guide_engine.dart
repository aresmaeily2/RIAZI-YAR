import 'dart:async';
import 'dart:math';

import '../models/models.dart';

/// اکشن پیشنهادی راهنما به UI.
enum GuideAction { keepGoing, showHint, showAnswerStrategy, backToLesson, safeFallback }

/// پاسخ ساختاریافته راهنما — هم محلی و هم آنلاین باید به همین قالب برگردند
/// تا UI بدون تغییر بتواند هر دو را نمایش دهد (قرارداد مأموریت ۵.۶).
class GuideReply {
  final String message;
  final GuideAction action;
  final String source; // 'local' | 'online' — برای نمایش صادقانه منبع

  const GuideReply({
    required this.message,
    required this.action,
    required this.source,
  });

  factory GuideReply.fromJson(Map<String, dynamic> j, {required String source}) {
    final msg = (j['message'] ?? '').toString();
    if (msg.isEmpty || msg.length > 300) {
      throw const GuideFormatException('پیام راهنما خالی یا بیش از حد طولانی است');
    }
    final act = switch (j['action']) {
      'showHint' => GuideAction.showHint,
      'showAnswerStrategy' => GuideAction.showAnswerStrategy,
      'backToLesson' => GuideAction.backToLesson,
      'safeFallback' => GuideAction.safeFallback,
      _ => GuideAction.keepGoing,
    };
    return GuideReply(message: msg, action: act, source: source);
  }
}

class GuideFormatException implements Exception {
  final String message;
  const GuideFormatException(this.message);
  @override
  String toString() => 'GuideFormatException: $message';
}

/// درخواست راهنما — همه زمینه لازم برای مشاوره.
class GuideQuery {
  final Question question;
  final Activity activity;
  final int wrongStreak;

  /// متن گفتار/تایپ کودک (اختیاری — از STT یا دکمه‌های سریع).
  final String? utterance;

  /// آیا پس از چند اشتباه اجازه دهیم مستقیم‌تر به پاسخ نزدیک شویم؟
  final bool allowCloserHint;

  const GuideQuery({
    required this.question,
    required this.activity,
    required this.wrongStreak,
    this.utterance,
    this.allowCloserHint = true,
  });
}

/// قرارداد مشترک موتورهای راهنما (محلی و آنلاین).
abstract class GuideEngine {
  Future<GuideReply> respond(GuideQuery query);
}

/// موتور راهنمای «محلی» مبتنی بر قواعد و محتوای تأییدشده درس.
///
/// صادقانه «راهنمای محلی» است، نه هوش مصنوعی متصل به مدل خارجی.
/// قواعد:
///  ۱) منظور‌یابی گفتار کودک (نمی‌دانم / جواب را بگو / بی‌ربط)
///  ۲) پیشرفت مرحله‌ای راهنما بر اساس تعداد اشتباه‌ها (hint ها از محتوای درس)
///  ۳) پاسخ نهایی بلافاصله گفته نمی‌شود؛ فقط استراتژی شمارش
///  ۴) ورودی نامطمئن → پیام امن و بازگشت به درس
class LocalGuideEngine implements GuideEngine {
  static const List<String> _dontKnow = [
    'نمی‌دانم', 'نمیدانم', 'بلد نیستم', 'مبارک', 'نمی دونم',
  ];
  static const List<String> _giveAnswer = [
    'جواب را بگو', 'جواب چیه', 'بگو جواب', 'کمک کن', 'راهنمایی کن', 'کمکم کن',
  ];
  static const List<String> _offTopic = [
    'داستان', 'کارتون', 'بازی دیگه', 'آهنگ', 'شعر', 'ماشین بخر',
    'بازی جدید', 'ویديو', 'ویدیو',
  ];

  final Random random;

  LocalGuideEngine({Random? random}) : random = random ?? Random();

  bool _containsAny(String text, List<String> keys) =>
      keys.any((k) => text.contains(k));

  @override
  Future<GuideReply> respond(GuideQuery query) async {
    final q = query.question;
    final utter = query.utterance?.trim() ?? '';

    // ۱) اولویت: فهم منظور کودک
    if (utter.isNotEmpty) {
      if (_containsAny(utter, _offTopic)) {
        return GuideReply(
          message: 'چه صحبت جالبی! ولی حالا وقت شمردن است. بیا برگردیم به شکل‌ها و با هم بشماریم.',
          action: GuideAction.backToLesson,
          source: 'local',
        );
      }
      if (_containsAny(utter, _dontKnow)) {
        return GuideReply(
          message: 'اشکالی ندارد که ندانی! بیا با هم بشماریم: ${_firstHint(q)}',
          action: GuideAction.showHint,
          source: 'local',
        );
      }
      if (_containsAny(utter, _giveAnswer)) {
        return GuideReply(
          message: 'من جواب را نمی‌گویم، ولی راهش را به تو یاد می‌دهم: ${_nextHint(query)}',
          action: GuideAction.showHint,
          source: 'local',
        );
      }
      // گفتار نامفهوم
      return GuideReply(
        message: 'صدای تو را خوب نفهمیدم. اشکالی ندارد! بیا شکل‌ها را یکی‌یکی بشماریم.',
        action: GuideAction.safeFallback,
        source: 'local',
      );
    }

    // ۲) راهنمای مرحله‌ای بر اساس اشتباه‌ها
    if (query.wrongStreak >= 3 && query.allowCloserHint) {
      return GuideReply(
        message: 'بیا با هم نزدیک‌تر شویم: ${_finalStrategy(q)}',
        action: GuideAction.showAnswerStrategy,
        source: 'local',
      );
    }
    return GuideReply(
      message: _nextHint(query),
      action: GuideAction.showHint,
      source: 'local',
    );
  }

  String _firstHint(Question q) =>
      q.hints.isNotEmpty ? q.hints.first : 'شکل‌ها را یکی‌یکی بشمار.';

  /// راهنمای بعدی = راهنمای شماره (تعداد اشتباه + ۱) از محتوای درس.
  String _nextHint(GuideQuery query) {
    final q = query.question;
    if (q.hints.isEmpty) return 'شکل‌ها را یکی‌یکی بشمار و ادامه بده.';
    final idx = min(query.wrongStreak, q.hints.length - 1);
    return q.hints[idx];
  }

  /// پس از سه اشتباه: استراتژی شمارش نزدیک به پاسخ — بدون گفتن عدد نهایی.
  String _finalStrategy(Question q) {
    return 'شکل‌ها را با انگشت لمس کن و هر بار فقط یکی را بشمار: '
        '«یکی»، «دو تا»، «سه تا»… ادامه بده تا همه شمرده شوند. '
        'عدد آخرِ شمارش، جواب توست!';
  }
}

class GuideNotConfiguredException implements Exception {
  const GuideNotConfiguredException();
  @override
  String toString() => 'راهنمای آنلاین پیکربندی نشده است';
}

/// پیام‌های امن استاندارد.
class GuideMessages {
  static const offline = 'راهنمای آنلاین در دسترس نیست؛ اما من همین‌جا هستم و کمک می‌کنم!';
  static const invalidAiOutput = 'جواب راهنمای آنلاین قابل فهم نبود؛ بیا خودمان با هم شمریم!';
}
