import 'package:flutter_tts/flutter_tts.dart';

/// وضعیت موتور TTS.
enum TtsStatus { notInitialized, ready, unavailable, error }

/// قرارداد مستقل تبدیل متن به گفتار فارسی.
///
/// طراحی بر اساس مأموریت ۵.۷:
///  - امکان توقف و تکرار
///  - کنترل فعال/غیرفعال از تنظیمات
///  - خطاها به‌صورت وضعیت برگردانده می‌شوند، نه کرش
abstract class TtsService {
  TtsStatus get status;
  Future<bool> init();
  Future<void> speak(String text);
  Future<void> stop();
  void dispose();
}

/// پیاده‌سازی واقعی با flutter_tts (موتور TTS خود اندروید).
///
/// صداقت: پشتیبانی زبان فارسی به موتور TTS نصب‌شده روی دستگاه (مثلاً
/// Google TTS) بستگی دارد. اگر فارسی موجود نباشد، status=unavailable
/// می‌شود و UI پیام کنترل‌شده نشان می‌دهد. هیچ ادعای کارکرد بدون تست
/// دستگاه واقعی نمی‌کنیم.
class FlutterTtsService implements TtsService {
  final FlutterTts _tts = FlutterTts();
  TtsStatus _status = TtsStatus.notInitialized;
  bool _enabled = true;

  @override
  TtsStatus get status => _status;

  @override
  Future<bool> init() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      final langs = await _tts.getLanguages;
      final hasFa = (langs as List?)?.any(
        (l) => l.toString().startsWith('fa'),
      );
      if (hasFa == true) {
        await _tts.setLanguage('fa-IR');
      } else {
        _status = TtsStatus.unavailable;
        return false;
      }
      await _tts.setSpeechRate(0.4); // سرعت آرام مناسب کودک
      await _tts.setPitch(1.2);
      _status = TtsStatus.ready;
      return true;
    } catch (_) {
      _status = TtsStatus.error;
      return false;
    }
  }

  void setEnabled(bool enabled) => _enabled = enabled;

  @override
  Future<void> speak(String text) async {
    if (!_enabled || _status != TtsStatus.ready) return;
    try {
      await _tts.speak(text);
    } catch (_) {
      _status = TtsStatus.error;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    stop();
  }
}

/// پیاده‌سازی بی‌صدا (برای تست و حالت «صدا خاموش» / عدم پشتیبانی).
/// رفتار مشابه را با همان قرارداد تقلید می‌کند.
class StubTtsService implements TtsService {
  final List<String> spoken = [];
  TtsStatus _status = TtsStatus.ready;
  bool enabled = true;

  @override
  TtsStatus get status => _status;

  @override
  Future<bool> init() async {
    _status = TtsStatus.ready;
    return true;
  }

  @override
  Future<void> speak(String text) async {
    if (enabled) spoken.add(text);
  }

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}
