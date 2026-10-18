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
/// ممیزی ۱.۰.۳ (دستورکار P1-۶ — DNS rebinding): اعتبارسنجی «نام» کافی
/// نیست؛ اگر نامی عمومی به آدرس ممنوع resolve شود، اتصال باید رد شود.
/// اکنون:
///  • بازه‌های IPv4 بیشتر مسدود شدند: shared/CGNAT (100.64.0.0/10)،
///    IETF protocol assignments (192.0.0.0/24)، TEST-NET-1/2/3
///    (192.0.2.0/24، 198.51.100.0/24، 203.0.113.0/24)، benchmarking
///    (198.18.0.0/15)، multicast/reserved/broadcast (224/4 و بالاتر)
///  • بازه‌های IPv6 بیشتر: documentation (2001:db8::/32) و discard-only
///    (100::/64)
///  • پیش از اتصال، نام سرور resolve و «همه» آدرس‌های حاصل با همان
///    قواعد بررسی می‌شوند؛ حتی یک آدرس ممنوع → رد کل درخواست
///  • اتصال فقط به همان آدرسِ تأییدشده «پین» می‌شود (connectionFactory
///    سفارشی) — هیچ resolve مجددی هنگام اتصال رخ نمی‌دهد و حمله
///    TOCTOU/DNS-rebinding بسته است
///  • redirect دنبال نمی‌شود (followRedirects=false) تا مقصد جدید بدون
///    اعتبارسنجی باز resolve نشود؛ هر پاسخ 3xx رد می‌شود
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
  // ممیزی ۱.۰.۳: پورت صریح باید معتبر باشد (پیش‌فرض HTTPS یعنی ۴۴۳)
  if (endpoint.hasPort && endpoint.port <= 0) {
    throw const GuideFormatException('پورت آدرس سرور معتبر نیست');
  }
  if (_isLocalOrPrivateHost(host)) {
    throw const GuideFormatException(
        'آدرس‌های محلی/خصوصی برای راهنمای آنلاین مجاز نیستند');
  }
  return endpoint;
}

/// آیا این آدرسِ مشخص (نتیجه resolve یا IP literal) ممنوع است؟
///
/// ممیزی ۱.۰.۳: این تابع هم برای IP literal در URL و هم برای «نتیجه
/// resolve نام سرور» پیش از اتصال به‌کار می‌رود تا DNS rebinding رد شود.
/// IP عمومی (مثلاً 93.184.216.34) مجاز است — فقط مقصدهای محلی/رزرو/اشتراکی
/// ممنوع‌اند.
bool isForbiddenAddress(InternetAddress addr) {
  if (addr.type == InternetAddressType.IPv4) {
    return _isPrivateIPv4Bytes(addr.rawAddress);
  }
  if (addr.type == InternetAddressType.IPv6) {
    return _isPrivateIPv6Bytes(addr.rawAddress);
  }
  return true; // نوع ناشناخته → احتیاط: رد
}

/// آیا host یک IP محلی/خصوصی یا hostname محلی است؟
///
/// بررسی صریح IP literal (IPv4 و IPv6) و سپس نام‌های محلی شناخته‌شده.
bool _isLocalOrPrivateHost(String host) {
  // ۱) IP literal — از خودِ رشته شروع می‌کنیم تا حالت IPv4-mapped IPv6
  //    (مثل ::ffff:192.168.1.10) هرگز از فیلتر رد نشود.
  if (host.startsWith('::ffff:')) {
    final v4 = host.substring(7);
    if (InternetAddress.tryParse(v4) != null) return _isPrivateIPv4String(v4);
  }
  final addr = InternetAddress.tryParse(host);
  if (addr != null) {
    return isForbiddenAddress(addr);
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

/// بایت‌های IPv4: loopback، خصوصی، link-local، unspecified،
/// shared/CGNAT، TEST-NET، benchmarking، IETF protocol، multicast/reserved
bool _isPrivateIPv4Bytes(List<int> b) {
  if (b.length != 4) return true;
  final o = b[0], t = b[1], th = b[2];
  if (o == 127) return true; // loopback 127.0.0.0/8
  if (o == 10) return true; // 10/8 خصوصی
  if (o == 172 && t >= 16 && t <= 31) return true; // 172.16/12 خصوصی
  if (o == 192 && t == 168) return true; // 192.168/16 خصوصی
  if (o == 169 && t == 254) return true; // link-local 169.254/16
  if (o == 0) return true; // unspecified 0.0.0.0/8
  // ممیزی ۱.۰.۳ — shared address space (CGNAT) 100.64.0.0/10
  if (o == 100 && t >= 64 && t <= 127) return true;
  // ممیزی ۱.۰.۳ — IETF protocol assignments 192.0.0.0/24 و TEST-NET-1 192.0.2.0/24
  if (o == 192 && t == 0 && (th == 0 || th == 2)) return true;
  // ممیزی ۱.۰.۳ — TEST-NET-2 198.51.100.0/24
  if (o == 198 && t == 51 && th == 100) return true;
  // ممیزی ۱.۰.۳ — TEST-NET-3 203.0.113.0/24
  if (o == 203 && t == 0 && th == 113) return true;
  // ممیزی ۱.۰.۳ — benchmarking 198.18.0.0/15
  if (o == 198 && (t == 18 || t == 19)) return true;
  if (o >= 224) return true; // multicast + reserved + broadcast
  return false;
}

/// بایت‌های IPv6: loopback، link-local، ULA، multicast، unspecified،
/// IPv4-mapped (::ffff:0:0/96)، NAT64 (64:ff9b::/96)، documentation
/// (2001:db8::/32) و discard-only (100::/64) — با بررسی IPv4 داخلیِ
/// mapped/NAT64 توسط قواعد IPv4 (شامل CGNAT)
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

  // ممیزی ۱.۰.۳ — documentation 2001:db8::/32
  if (b[0] == 0x20 && b[1] == 0x01 && b[2] == 0x0D && b[3] == 0xB8) return true;

  // ممیزی ۱.۰.۳ — discard-only 100::/64
  if (b[0] == 0x01 && b[1] == 0x00 && b.sublist(2, 8).every((x) => x == 0)) {
    return true;
  }

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
///  • ممیزی ۱.۰.۳ (P1-۶): قبل از اتصال، نام سرور resolve و همه آدرس‌های
///    حاصل با isForbiddenAddress بررسی می‌شوند؛ اتصال فقط به همان
///    آدرس تأییدشده پین می‌شود (بدون resolve مجدد هنگام اتصال)؛ redirect
///    دنبال نمی‌شود؛ گواهی نامعتبر در هر حالت رد می‌شود.
///  • خواندن جریانی با سقف ۸۱۹۲ بایت (readCappedUtf8) — بدون انباشت کامل.
///  • محدودیت اندازه ورودی (۱۲۰ نویسه) و خروجی (۳۰۰ نویسه پس از تجزیه).
///  • timeout قابل تنظیم (پیش‌فرض ۸ ثانیه).
///  • ممیزی ۱.۰.۲ (یافته timeout): یک deadline واحد برای «کل درخواست»
///    وجود دارد که همه مراحل را پوشش می‌دهد: اتصال (connectionTimeout)،
///    resolve نام، headersProvider، دریافت پاسخ (close) و خواندن کامل
///    بدنه. اگر سرور در هر مرحله‌ای (از جمله وسط بدنه) متوقف شود،
///    عملیات در زمان محدود خاتمه می‌یابد، سوکت‌ها با client.close(force:true)
///    بسته می‌شوند و استثنای کنترل‌شده به UI می‌رسد تا fallback محلی
///    اجرا شود.
///  • خروجی باید JSON ساختاریافته {"message": "...", "action": "..."} باشد؛
///    در غیر این صورت GuideFormatException پرتاب می‌شود و UI به راهنمای
///    محلی fallback می‌کند.
///
/// قرارداد سرور واسط (مستند کامل در docs/AI_STT_TTS.md):
///   POST {endpoint}
///   body: {"utterance": "...", "prompt": "...", "hints": [...],
///          "wrongStreak": 0, "activityType": "...", "lessonId": "..."}
///   200 : {"message": "پیام کوتاه فارسی", "action": "showHint"}
///   خطا : هر کد غیر ۲۰۰ (شامل 3xx — redirect دنبال نمی‌شود)
class HttpAiGuideClient implements GuideEngine {
  /// آدرس سرور واسط — از بیرون تزریق می‌شود؛ null یعنی غیرفعال.
  final Uri? Function() endpointProvider;

  final Duration timeout;

  /// هدرهای اختیاری (مثلاً توکن موقت سرور واسط) — از بیرون تزریق می‌شود.
  final Future<Map<String, String>> Function()? headersProvider;

  /// تزریق resolve برای تست (ممیزی ۱.۰.۳) — پیش‌فرض: InternetAddress.lookup.
  /// در محصول استفاده نمی‌شود؛ فقط تست‌های سوکت محلی.
  final Future<List<InternetAddress>> Function(String host)? resolver;

  /// تزریق کارخانه اتصال برای تست (ممیزی ۱.۰.۳) — پیش‌فرض: کارخانه
  /// پین‌شده که «فقط» به آدرس تأییدشده وصل می‌شود و هرگز دوباره resolve
  /// نمی‌کند. در محصول استفاده نمی‌شود.
  final Future<ConnectionTask<Socket>> Function(Uri uri, String? proxyHost,
      int? proxyPort)? connectionFactory;

  /// تزریق رفتار گواهی برای تست (ممیزی ۱.۰.۳) — پیش‌فرض null یعنی
  /// رفتار سخت‌گیرانه (false): هر گواهی نامعتبر/خودامضا رد می‌شود.
  final bool Function(X509Certificate cert, String host, int port)?
      badCertificateCallback;

  HttpAiGuideClient({
    required this.endpointProvider,
    this.timeout = const Duration(seconds: 8),
    this.headersProvider,
    this.resolver,
    this.connectionFactory,
    this.badCertificateCallback,
  });

  /// پیکربندی‌شده = آدرس ارائه‌شده و معتبر از نظر قواعد امنیتی نام
  /// (بررسی DNS فقط هنگام درخواست واقعی انجام می‌شود).
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

  /// ممیزی ۱.۰.۳ (P1-۶): resolve نام و اعتبارسنجی «همه» آدرس‌های حاصل؛
  /// خروجی: آدرس پین‌شده برای اتصال. اگر حتی یک آدرس ممنوع باشد، کل
  /// درخواست رد می‌شود (محافظه‌کارانه و ساده).
  Future<InternetAddress> _resolveAndPin(Uri endpoint, DateTime deadline) async {
    final literal = InternetAddress.tryParse(endpoint.host);
    if (literal != null) {
      // IP literal — در validateGuideEndpoint با همان قواعد رد/قبول شده است
      return literal;
    }
    final lookup = resolver ?? _defaultResolver;
    List<InternetAddress> addresses;
    try {
      addresses = await lookup(endpoint.host).timeout(
            _remaining(deadline),
            onTimeout: () => throw TimeoutException('حل نام سرور راهنما طول کشید'),
          );
    } on GuideFormatException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on Object {
      throw const GuideFormatException('حل نام سرور راهنما ممکن نشد (خطای DNS)');
    }
    if (addresses.isEmpty) {
      throw const GuideFormatException('نام سرور راهنما به هیچ آدرسی حل نشد');
    }
    for (final a in addresses) {
      if (isForbiddenAddress(a)) {
        throw GuideFormatException(
            'مقصد راهنمای آنلاین به آدرس ممنوع حل شد (${a.address})');
      }
    }
    return addresses.first;
  }

  static Future<List<InternetAddress>> _defaultResolver(String host) =>
      InternetAddress.lookup(host);

  /// کارخانه اتصال پیش‌فرض: پین‌شده به آدرس تأییدشده — بدون resolve مجدد.
  ///
  /// در dart:io هنگام کارخانه سفارشی، TLS خودکار اعمال نمی‌شود؛ بنابراین
  /// کارخانه خودش: (۱) TCP خام به آدرسِ پین‌شده، (۲) SecureSocket.secure
  /// با «نام اصلی» (SNI + اعتبارسنجی نام گواهی) و همان رفتار سخت‌گیرانه
  /// گواهی. در نتیجه مقصد واقعی همان آدرس تأییدشده است و نام برای
  /// اعتبارسنجی TLS دست‌نخورده می‌ماند (ممیزی ۱.۰.۳).
  Future<ConnectionTask<Socket>> Function(Uri uri, String? proxyHost,
      int? proxyPort) _factoryFor(InternetAddress pinned, Uri endpoint) {
    final injected = connectionFactory;
    if (injected != null) return injected;
    final strict = badCertificateCallback ??
        ((X509Certificate cert, String host, int port) => false);
    return (Uri uri, String? proxyHost, int? proxyPort) {
      if (proxyHost != null || proxyPort != null) {
        throw const GuideFormatException('اتصال از طریق پروکسی پشتیبانی نمی‌شود');
      }
      if (uri.scheme.toLowerCase() != 'https') {
        throw const GuideFormatException('فقط HTTPS پشتیبانی می‌شود');
      }
      final port = uri.port > 0
          ? uri.port
          : 443; // پیش‌فرض HTTPS
      // TCP خام به آدرس پین‌شده، سپس TLS با نام اصلی endpoint
      ConnectionTask<Socket>? active;
      final Future<Socket> tls = Socket.startConnect(pinned, port).then((task) {
        active = task;
        return task.socket;
      }).then((raw) => SecureSocket.secure(
            raw,
            host: endpoint.host,
            onBadCertificate: (cert) => strict(cert, endpoint.host, port),
          ));
      return Future<ConnectionTask<Socket>>.value(
          ConnectionTask.fromSocket(tls, () {
        try {
          active?.cancel();
        } on Object {
          // لغو در هر مرحله — بدون اثر جانبی
        }
      }));
    };
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

    // ممیزی ۱.۰.۳ (P1-۶): resolve + بررسی همه آدرس‌ها + پین‌کردن مقصد
    final pinned = await _resolveAndPin(endpoint, deadline);

    final client = HttpClient()
      // ممیزی ۱.۰.۳ (P1-۶): اتصال فقط به آدرسِ تأییدشده پین می‌شود؛
      // هیچ resolve مجددی هنگام اتصال رخ نمی‌دهد (ضد DNS rebinding).
      ..connectionFactory = _factoryFor(pinned, endpoint)
      ..findProxy = ((Uri uri) => 'DIRECT')
      ..connectionTimeout = _remaining(deadline)
      // پیش‌فرض سخت‌گیرانه: گواهی نامعتبر/خودامضا رد می‌شود (ممیزی ۱.۰.۱)
      ..badCertificateCallback = badCertificateCallback ??
          ((cert, host, port) => false); // صریحاً غیرفعال

    try {
      final req = await client
          .postUrl(endpoint)
          .timeout(_remaining(deadline),
              onTimeout: () => throw TimeoutException('اتصال به راهنمای آنلاین طول کشید'));
      // ممیزی ۱.۰.۳: redirect دنبال نمی‌شود — هر 3xx مثل خطا رد می‌شود تا
      // مقصد جدید هرگز بدون اعتبارسنجی باز بازresolve نشود.
      req.followRedirects = false;
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
