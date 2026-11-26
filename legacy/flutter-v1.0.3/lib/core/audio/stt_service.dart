/// وضعیت موتور STT.
enum SttStatus { notInitialized, ready, permissionDenied, unavailable, listening, error }

/// کلید ساخت‌سطحی: ورودی گفتار در این بیلد ارائه نمی‌شود.
///
/// چرا؟ (ممیزی ۱.۰.۱ — حریم خصوصی کودک)
/// موتور تشخیص گفتار اندروید (SpeechRecognizer) «قرارداد سیستمی» است و
/// نحوه پردازش صدا (کاملاً روی دستگاه یا ارسال به سرویس ابری سازنده)
/// به دستگاه/موتور نصب‌شده بستگی دارد و در این پروژه قابل راستی‌آزمایی
/// نیست. تا زمان تأیید پردازش آفلاین و سیاست داده صریح، این قابلیت
/// به‌صورت امن غیرفعال است:
///   ۱) مجوز RECORD_AUDIO از Manifest حذف شده است.
///   ۲) پکیج speech_to_text از وابستگی‌ها حذف شده است.
///   ۳) سرویس تزریق‌شده DisabledSttService است (همیشه «در دسترس نیست»).
///   ۴) دکمه‌های میکروفون در UI با این ثابت پنهان می‌شوند.
/// مسیر اصلی پاسخ‌دهی کودک (دکمه‌های لمسی) کامل و آفلاین باقی مانده است.
/// چک‌لیست فعال‌سازی دوباره: docs/AI_STT_TTS.md §۴.
const bool kSpeechInputAvailable = false;

/// قرارداد مستقل تبدیل گفتار فارسی به متن.
///
/// طراحی بر اساس مأموریت ۵.۷ و ممیزی ۱.۰.۱:
///  - فعال‌سازی میکروفون فقط با اقدام آگاهانه کاربر (start از روی دکمه)
///  - مدیریت رد مجوز، عدم دسترسی سرویس و خطا با وضعیت صریح
///  - نتیجه از طریق callback برگردانده می‌شود
abstract class SttService {
  SttStatus get status;
  Future<bool> init();
  Future<bool> start({required void Function(String text) onResult});
  Future<void> stop();
}

/// سرویس «صریحاً غیرفعال» — پیاده‌سازی پیش‌فرض نسخه ۱.۰.۱.
///
/// هیچ سخت‌افزار یا سرویسی را صدا نمی‌زند؛ فقط وضعیت صادقانه
/// «در دسترس نیست» برمی‌گرداند تا UI پیام کنترل‌شده نشان دهد.
class DisabledSttService implements SttService {
  const DisabledSttService();

  @override
  SttStatus get status => SttStatus.unavailable;

  @override
  Future<bool> init() async => false;

  @override
  Future<bool> start({required void Function(String text) onResult}) async => false;

  @override
  Future<void> stop() async {}
}

/// پیاده‌سازی آزمایشی برای تست و دستگاه‌های بدون موتور گفتار.
class StubSttService implements SttService {
  StubSttService({bool available = true, this.cannedText})
      : _available = available,
        _status = available ? SttStatus.ready : SttStatus.unavailable;

  final bool _available;
  String? cannedText;

  SttStatus _status;

  @override
  SttStatus get status => _status;

  @override
  Future<bool> init() async {
    _status = _available ? SttStatus.ready : SttStatus.unavailable;
    return _available;
  }

  @override
  Future<bool> start({required void Function(String text) onResult}) async {
    if (!_available) {
      _status = SttStatus.unavailable;
      return false;
    }
    if (cannedText != null) {
      onResult(cannedText!);
      return true;
    }
    _status = SttStatus.unavailable;
    return false;
  }

  @override
  Future<void> stop() async {}
}
