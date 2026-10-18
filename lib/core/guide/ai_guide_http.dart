import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'guide_engine.dart';

/// اعتبارسنجی endpoint راهنمای آنلاین — «پیش از هرگونه اتصال».
///
/// ممیزی ۱.۰.۱: فقط URI مطلق HTTPS با host معتبر پذیرفته می‌شود.
/// HTTP، آدرس‌های نسبی/نامعتبر و آدرس‌های دارای اطلاعات کاربر (user:pass)
/// پیش از ساخت کلاینت رد می‌شوند تا هیچ اتصالی شروع نشود.
///
/// ممیزی ۱.۰.۲ (یافته اعتبارسنجی endpoint): رفتار کد باید با ادعای
/// مستندات هماهنگ باشد — «آدرس‌های محلی ممنوع‌اند». بنابراین صریحاً
/// رد می‌شوند:
///  • loopback (IPv4 127.0.0.0/8 و IPv6 ::1)
///  • IPv4 خصوصی (10/8، 172.16/12، 192.168/16) و link-local (169.254/16)
///  • IPv6 مربوطه: link-local (fe80::/10)، ULA (fc00::/7)، multicast
///    (ff00::/8)، آدرس نامشخص (::)، و IPv4-mapped مانند ::ffff:192.168.1.10
///  • hostname های محلی: localhost و دامنه‌های mDNS/داخلی شناخته‌شده
///    (.local، .lan، .localdomain، .internal، .home.arpa)
/// سرور واسط این اپ سرویس بیرونی است، نه سرویس روی خود دستگاه؛ این
/// قاعده سطح حمله (SSRF/اتصال به سرویس‌های داخلی دستگاه) را کمینه می‌کند.
///
/// محدودیت شناخته‌شده (مستند در SECURITY_PRIVACY): این اعتبارسنجی «نام»
/// را بررسی می‌کند؛ اگر یک نام عمومی (DNS) به IP خصوصی resolve شود،
/// جلوگیری از اتصال نیازمند resolve و پین کردن IP در لایه سوکت است که
/// خارج از دامنه این نسخه است.
Uri validateGuideEndpoint(Uri? endpoint) {
  if (endpoint == null) throw const GuideNotConfiguredException();
  if (endpoint.scheme.toLowerCase() != 'https') {
    throw const GuideFormatException('فقط آدرس HTTPS برای راهنمای آنلاین مجاز است');
  }
  var host = endpoint.host.trim().toLowerCase();
  // حالت FQDN با نقطه انتهایی: نقطه آخر حذف می‌شود تا قواعد یکسان اعمال شود
  if (host.endsWith('.')) host = host.substring(0, host.length - 1);
  if (host.isEmpty || host.length > 253 || !host.contains('.')) {
    throw const GuideFormatException('آدرس سرور راهنما معتبر نیست');
  }
  if (endpoint.userInfo.isNotEmpty) {
    throw const GuideFormatException('آدرس سرور نباید نام کاربری/رمز داشته باشد');
  }
  if (endpoint.hasFragment) {
    throw const GuideFormatException('آدرس سرور نباید بخش # داشته باشد');
  }
  if (_isLocalOrPrivateHost(host)) {
    throw const GuideFormatException(
        'آدرس‌های محلی/خصوصی برای راهنمای آنلاین مجاز نیستند');
  }
  return endpoint;
}

/// آیا host یک IP محلی/خصوصی یا hostname محلی است؟
///
/// بررسی صریح IP literal (IPv4 و IPv6) و سپس نام‌های محلی شناخته‌شده.
/// IP عمومی (مثلاً 93.184.216.34) مجاز است — فقط آدرس‌های محلی ممنوع‌اند.
bool _isLocalOrPrivateHost(String host) {
  // ۱) IP literal — از خودِ رشته شروع می‌کنیم تا حالت IPv4-mapped IPv6
  //    (مثل ::ffff:192.168.1.10) هرگز از فیلتر رد نشود.
  if (host.startsWith('::ffff:')) {
    final v4 = host.substring(7);
    if (InternetAddress.tryParse(v4) != null) return _isPrivateIPv4String(v4);
  }
  final addr = InternetAddress.tryParse(host);
  if (addr != null) {
    if (addr.type == InternetAddressType.IPv4) return _isPrivateIPv4Bytes(addr.rawAddress);
    if (addr.type == InternetAddressType.IPv6) return _isPrivateIPv6Bytes(addr.rawAddress);
    return true; // نوع ناشناخته → احتیاط: رد
  }

  // ۲) hostname محلی شناخته‌شده
  if (host == 'localhost' || host.endsWith('.localhost')) return true;
  const localSuffixes = ['.local', '.lan', '.localdomain', '.internal', '.home.arpa'];
  for (final s in localSuffixes) {
    if (host.endsWith(s)) return true;
  }
  return false;
}

bool _isPrivateIPv4String(String s) {
  final a = InternetAddress.tryParse(s);
  if (a == null || a.type != InternetAddressType.IPv4) return true;
  return _isPrivateIPv4Bytes(a.rawAddress);
}

/// بایت‌های IPv4: loopback، خصوصی، link-local، unspecified، multicast/reserved
bool _isPrivateIPv4Bytes(List<int> b) {
  if (b.length != 4) return true;
  final o = b[0], t = b[1];
  if (o == 127) return true; // loopback
  if (o == 10) return true; // 10/8
  if (o == 172 && t >= 16 && t <= 31) return true; // 172.16/12
  if (o == 192 && t == 168) return true; // 192.168/16
  if (o == 169 && t == 254) return true; // link-local
  if (o == 0) return true; // unspecified (0.0.0.0/8)
  if (o >= 224) return true; // multicast + reserved + broadcast
  return false;
}

/// بایت‌های IPv6: loopback، link-local، ULA، multicast، unspecified،
/// IPv4-mapped (::ffff:0:0/96) و NAT64 (64:ff9b::/96) با IPv4 محلی داخلشان
bool _isPrivateIPv6Bytes(List<int> b) {
  if (b.length != 16) return true;

  bool allZero = b.every((x) => x == 0);
  if (allZero) return true; // :: (unspecified)

  // loopback ::1
  final isLoopback = b[15] == 1 && b.take(15).every((x) => x == 0);
  if (isLoopback) return true;

  // link-local fe80::/10
  if ((b[0] & 0xFF) == 0xFE && (b[1] & 0xC0) == 0x80) return true;
  // ULA fc00::/7
  if ((b[0] & 0xFE) == 0xFC) return true;
  // multicast ff00::/8
  if (b[0] == 0xFF) return true;

  // IPv4-mapped: ::ffff:a.b.c.d
  final mapped = b[0] == 0 && b[1] == 0 && b[2] == 0 && b[3] == 0 &&
      b[4] == 0 && b[5] == 0 && b[6] == 0 && b[7] == 0 &&
      b[8] == 0 && b[9] == 0 && b[10] == 0xFF && b[11] == 0xFF;
  if (mapped) return _isPrivateIPv4Bytes(b.sublist(12));

  // NAT64 well-known prefix 64:ff9b::/96
  final nat64 = b[0] == 0x00 && b[1] == 0x64 && b[2] == 0xFF && b[3] == 0x9B &&
      b.sublist(4, 12).every((x) => x == 0);
  if (nat64) return _isPrivateIPv4Bytes(b.sublist(12));

  return false;
}

/// خواندن جریانی بدنه پاسخ با سقف بایت — انباشت پیش از سقف انجام نمی‌شود.
///
/// ممیزی ۱.۰.۱: در نسخه قبل کل بدنه با decodeStream انباشته و «بعداً»
/// سقف بررسی می‌شد؛ اکنون در حین خواندن جریان، با عبور از سقف، خواندن
/// قطع می‌شود (استریم با خطا بسته می‌شود) و حداکثر [maxBytes] + یک
/// قطعه در حافظه می‌ماند.
///
/// ممیزی ۱.۰.۲ (یافته timeout): اگر [deadline] داده شود، خواندن «کل
/// بدنه» باید پیش از آن تمام شود — اگر سرور پس از فرستادن بخشی از بدنه
/// متوقف شود (بدون close)، انتظار بی‌نهایت رخ نمی‌دهد؛ Timer مستقل
/// مستقل از وضعیت جریان فعال می‌شود، subscription لغو (منابع شبکه
/// آزاد) و TimeoutException پرتاب می‌شود تا فراخواننده fallback محلی
/// اجرا کند. (Stream.timeout برای این کار کافی نیست: هنگام تعلیق
/// subscription منبع، رفتار آن قابل اتکا نیست — Timer صریح تضمین می‌دهد.)
Future<String> readCappedUtf8(
  Stream<List<int>> byteStream, {
  int maxBytes = 8192,
  DateTime? deadline,
}) {
  // deadline گذشته → بدون شروع خواندن، خاتمه فوری
  if (deadline != null && !DateTime.now().isBefore(deadline)) {
    return Future.error(TimeoutException(
        'خواندن پاسخ سرور راهنما در زمان مجاز تمام نشد'));
  }

  final completer = Completer<String>();
  final builder = BytesBuilder(copy: false);
  var total = 0;
  StreamSubscription<List<int>>? sub;
  Timer? timer;

  void fail(Object e, [StackTrace? st]) {
    if (completer.isCompleted) return;
    timer?.cancel();
    sub?.cancel(); // آزادسازی منابع شبکه در هر مسیر خطا
    completer.completeError(e, st);
  }

  if (deadline != null) {
    timer = Timer(deadline.difference(DateTime.now()), () {
      fail(TimeoutException(
          'خواندن پاسخ سرور راهنما در زمان مجاز تمام نشد'));
    });
  }

  sub = byteStream.listen(
    (chunk) {
      if (completer.isCompleted) return;
      total += chunk.length;
      if (total > maxBytes) {
        fail(const GuideFormatException('پاسخ سرور بیش از حد بزرگ است'));
        return;
      }
      builder.add(chunk);
    },
    onError: fail,
    onDone: () {
      if (completer.isCompleted) return;
      timer?.cancel();
      try {
        completer.complete(utf8.decode(builder.takeBytes()));
      } on FormatException {
        fail(const GuideFormatException('پاسخ سرور متن معتبر (UTF-8) نیست'));
      }
    },
    cancelOnError: true,
  );

  return completer.future;
}

/// راهنمای آنلاین — کلاینت واقعی HTTP به «سرور واسط» (proxy).
///
/// الزامات امنیتی مأموریت + ممیزی که این کلاس اجرا می‌کند:
///  • هیچ کلید API در اپ یا APK قرار نمی‌گیرد؛ آدرس سرور واسط از بیرون
///    تزریق می‌شود (env/config یا تنظیمات والدین) و پیش‌فرض null است
///    یعنی قابلیت غیرفعال است و UI صادقانه «راهنمای محلی» را نشان می‌دهد.
///  • فقط HTTPS؛ اعتبارسنجی کامل پیش از اتصال (validateGuideEndpoint) —
///    شامل رد صریح آدرس‌های محلی/خصوصی (ممیزی ۱.۰.۲).
///  • خواندن جریانی با سقف ۸۱۹۲ بایت (readCappedUtf8) — بدون انباشت کامل.
///  • محدودیت اندازه ورودی (۱۲۰ نویسه) و خروجی (۳۰۰ نویسه پس از تجزیه).
///  • timeout قابل تنظیم (پیش‌فرض ۸ ثانیه) و گواهی‌های نامعتبر رد می‌شوند.
///  • ممیزی ۱.۰.۲ (یافته timeout): یک deadline واحد برای «کل درخواست»
///    وجود دارد که همه مراحل را پوشش می‌دهد: اتصال (connectionTimeout)،
///    headersProvider، دریافت پاسخ (close) و خواندن کامل بدنه. اگر سرور
///    در هر مرحله‌ای (از جمله وسط بدنه) متوقف شود، عملیات در زمان محدود
///    خاتمه می‌یابد، سوکت‌ها با client.close(force:true) بسته می‌شوند و
///    استثنای کنترل‌شده به UI می‌رسد تا fallback محلی اجرا شود.
///  • خروجی باید JSON ساختاریافته {"message": "...", "action": "..."} باشد؛
///    در غیر این صورت GuideFormatException پرتاب می‌شود و UI به راهنمای
///    محلی fallback می‌کند.
///
/// قرارداد سرور واسط (مستند کامل در docs/AI_STT_TTS.md):
///   POST {endpoint}
///   body: {"utterance": "...", "prompt": "...", "hints": [...],
///          "wrongStreak": 0, "lessonId": "...", "questionId": "..."}
///   200 : {"message": "پیام کوتاه فارسی", "action": "showHint"}
///   خطا : هر کد غیر ۲۰۰
class HttpAiGuideClient implements GuideEngine {
  /// آدرس سرور واسط — از بیرون تزریق می‌شود؛ null یعنی غیرفعال.
  final Uri? Function() endpointProvider;

  final Duration timeout;

  /// هدرهای اختیاری (مثلاً توکن موقت سرور واسط) — از بیرون تزریق می‌شود.
  final Future<Map<String, String>> Function()? headersProvider;

  HttpAiGuideClient({
    required this.endpointProvider,
    this.timeout = const Duration(seconds: 8),
    this.headersProvider,
  });

  /// پیکربندی‌شده = آدرس ارائه‌شده و معتبر از نظر قواعد امنیتی.
  bool get isConfigured {
    try {
      validateGuideEndpoint(endpointProvider());
      return true;
    } on Object {
      return false;
    }
  }

  Duration _remaining(DateTime deadline) {
    final d = deadline.difference(DateTime.now());
    return d <= Duration.zero ? const Duration(milliseconds: 1) : d;
  }

  @override
  Future<GuideReply> respond(GuideQuery query) async {
    // اعتبارسنجی کامل پیش از ساخت کلاینت/اتصال (ممیزی ۱.۰.۱/۱.۰.۲)
    final endpoint = validateGuideEndpoint(endpointProvider());

    final utter = (query.utterance ?? '').trim();
    if (utter.length > 120) {
      throw const GuideFormatException('ورودی گفتار بیش از حد مجاز است');
    }

    // deadline واحد کل درخواست (ممیزی ۱.۰.۲)
    final deadline = DateTime.now().add(timeout);

    final client = HttpClient()
      ..connectionTimeout = _remaining(deadline)
      ..badCertificateCallback = ((cert, host, port) => false); // صریحاً غیرفعال

    try {
      final req = await client
          .postUrl(endpoint)
          .timeout(_remaining(deadline),
              onTimeout: () => throw TimeoutException('اتصال به راهنمای آنلاین طول کشید'));
      req.headers.contentType = ContentType.json;
      // headersProvider هم زیر همان deadline — ممیزی ۱.۰.۲
      final headers = headersProvider == null
          ? const <String, String>{}
          : await headersProvider!().timeout(_remaining(deadline),
              onTimeout: () => throw TimeoutException('آماده‌سازی هدرها طول کشید'));
      headers.forEach(req.headers.set);

      req.write(jsonEncode({
        'utterance': utter,
        'prompt': query.question.prompt,
        'hints': query.question.hints,
        'wrongStreak': query.wrongStreak,
        'activityType': query.activity.type.name,
        'lessonId': query.activity.id,
      }));

      final res = await req.close().timeout(_remaining(deadline));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw GuideFormatException('پاسخ خطا از سرور راهنما: ${res.statusCode}');
      }
      // خواندن کامل بدنه نیز زیر همان deadline (ممیزی ۱.۰.۲) — اگر سرور
      // پس از ارسال بخشی از بدنه متوقف شود، TimeoutException می‌آید.
      final body = await readCappedUtf8(res, deadline: deadline);
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const GuideFormatException('قالب پاسخ سرور نامعتبر است');
      }
      return GuideReply.fromJson(decoded, source: 'online');
    } on GuideFormatException {
      rethrow;
    } catch (_) {
      // هر خطای شبکه/زمان به یک استثنای کنترل‌شده تبدیل می‌شود تا UI
      // بتواند به راهنمای محلی برگردد (حالت «نبود API Key» هم همین است).
      throw const GuideNotConfiguredException();
    } finally {
      // بستن همه منابع شبکه در هر مسیر خروج (شامل timeout وسط بدنه)
      client.close(force: true);
    }
  }
}
