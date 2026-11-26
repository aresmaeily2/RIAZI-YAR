import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riazi_yar/core/guide/ai_guide_http.dart';
import 'package:riazi_yar/core/guide/guide_engine.dart';
import 'package:riazi_yar/core/models/models.dart';

// Helpers — همان الگوی guide_engine_test.dart
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

GuideQuery _query({String? utterance}) => GuideQuery(
      question: _lesson().allQuestions.first,
      activity: _lesson().activities.first,
      wrongStreak: 0,
      utterance: utterance,
    );

void main() {
  group('اعتبارسنجی endpoint — فقط HTTPS مطلق با host معتبر', () {
    test('HTTPS با دامنه معتبر پذیرفته می‌شود', () {
      final u = validateGuideEndpoint(Uri.parse('https://guide.example.com/api'));
      expect(u.host, 'guide.example.com');
    });

    test('HTTP صریحاً رد می‌شود', () {
      expect(
        () => validateGuideEndpoint(Uri.parse('http://guide.example.com/api')),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('host بدون نقطه (localhost) رد می‌شود', () {
      expect(
        () => validateGuideEndpoint(Uri.parse('https://localhost/api')),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('host خالی رد می‌شود', () {
      expect(
        () => validateGuideEndpoint(Uri.parse('https:///api')),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('آدرس دارای user:pass رد می‌شود', () {
      expect(
        () => validateGuideEndpoint(
            Uri.parse('https://user:pass@guide.example.com/api')),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('آدرس دارای fragment (#) رد می‌شود', () {
      expect(
        () => validateGuideEndpoint(Uri.parse('https://guide.example.com/api#x')),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('endpoint تهی → GuideNotConfiguredException', () {
      expect(
        () => validateGuideEndpoint(null),
        throwsA(isA<GuideNotConfiguredException>()),
      );
    });
  });

  group('رد آدرس‌های محلی/خصوصی — ممیزی ۱.۰.۲ (رفتار = ادعای مستندات)', () {
    test('۱۲۷.۰.۰.۱ (loopback IPv4) رد می‌شود', () {
      expect(
        () => validateGuideEndpoint(Uri.parse('https://127.0.0.1:8443/guide')),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('۱۹۲.۱۶۸.۱.۱۰ (IPv4 خصوصی) رد می‌شود', () {
      expect(
        () => validateGuideEndpoint(Uri.parse('https://192.168.1.10/guide')),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('سایر بازه‌های IPv4 خصوصی/link-local رد می‌شوند', () {
      for (final host in [
        '10.0.0.5',
        '172.16.0.9',
        '172.31.255.1',
        '169.254.1.1',
        '0.0.0.0',
      ]) {
        expect(
          () => validateGuideEndpoint(Uri.parse('https://$host/guide')),
          throwsA(isA<GuideFormatException>()),
          reason: '$host باید رد شود',
        );
      }
    });

    test('loopback و link-local و ULA و multicast IPv6 رد می‌شوند', () {
      for (final host in [
        '[::1]', // loopback
        '[fe80::1]', // link-local
        '[fd00::1]', // ULA
        '[fc00::1]', // ULA
        '[ff02::1]', // multicast
        '[::]', // unspecified
      ]) {
        expect(
          () => validateGuideEndpoint(Uri.parse('https://$host/guide')),
          throwsA(isA<GuideFormatException>()),
          reason: '$host باید رد شود',
        );
      }
    });

    test('IPv4-mapped IPv6 (::ffff:192.168.1.10) با قواعد IPv4 رد می‌شود', () {
      expect(
        () => validateGuideEndpoint(Uri.parse('https://[::ffff:192.168.1.10]/guide')),
        throwsA(isA<GuideFormatException>()),
      );
      expect(
        () => validateGuideEndpoint(Uri.parse('https://[::ffff:127.0.0.1]/guide')),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('hostname محلی (myserver.local) رد می‌شود', () {
      expect(
        () => validateGuideEndpoint(Uri.parse('https://myserver.local/guide')),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('سایر نام‌های محلی شناخته‌شده رد می‌شوند', () {
      for (final host in [
        'localhost',
        'sub.localhost',
        'router.lan',
        'printer.localdomain',
        'nas.internal',
        'box.home.arpa',
        'myserver.local',
      ]) {
        expect(
          () => validateGuideEndpoint(Uri.parse('https://$host/guide')),
          throwsA(isA<GuideFormatException>()),
          reason: '$host باید رد شود',
        );
      }
    });

    test('IP عمومی پذیرفته می‌شود (فقط آدرس‌های محلی ممنوع‌اند)', () {
      final u = validateGuideEndpoint(Uri.parse('https://93.184.216.34/guide'));
      expect(u.host, '93.184.216.34');
    });

    test('دامنه معتبر با نقطه انتهایی (FQDN) پذیرفته می‌شود', () {
      final u = validateGuideEndpoint(Uri.parse('https://guide.example.com./api'));
      expect(u.host, contains('example.com'));
    });
  });

  group('سقف بایت پاسخ — خواندن جریانی بدون انباشت کامل', () {
    test('بدنه کوچک‌تر از سقف کامل خوانده و decode می‌شود', () async {
      const body = '{"message":"سلام"}';
      final out = await readCappedUtf8(
        Stream.value(utf8.encode(body)),
        maxBytes: 8192,
      );
      expect(out, body);
    });

    test('بدنه دقیقاً ۸۱۹۲ بایتی مجاز است', () async {
      final bytes = List.filled(8192, 0x61); // 'a'
      final out = await readCappedUtf8(Stream.value(bytes), maxBytes: 8192);
      expect(out.length, 8192);
    });

    test('عبور از سقف → GuideFormatException', () async {
      final bytes = List.filled(8193, 0x61);
      await expectLater(
        readCappedUtf8(Stream.value(bytes), maxBytes: 8192),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('سقف در حین جریان اعمال می‌شود؛ کل بدنه بزرگ انباشته نمی‌شود', () async {
      var pulledChunks = 0;
      Stream<List<int>> bigStream() async* {
        for (var i = 0; i < 100; i++) {
          pulledChunks++;
          yield List.filled(2048, 0x61);
        }
      }

      await expectLater(
        readCappedUtf8(bigStream(), maxBytes: 8192),
        throwsA(isA<GuideFormatException>()),
      );
      expect(pulledChunks, lessThan(10));
    });

    test('UTF-8 نامعتبر → خطای قالب کنترل‌شده', () async {
      await expectLater(
        readCappedUtf8(Stream.value(const [0xC3, 0x28]), maxBytes: 8192),
        throwsA(isA<GuideFormatException>()),
      );
    });
  });

  group('deadline خواندن بدنه — پاسخ معلق/متوقف‌شده (ممیزی ۱.۰.۲)', () {
    test('سرور پس از بخشی از بدنه متوقف می‌شود → TimeoutException در زمان محدود',
        () async {
      // جریان واقعی ناهمگام: یک قطعه می‌فرستد و هرگز نمی‌بندد —
      // همان رفتار «سروری که وسط بدنه گیر می‌کند».
      final controller = StreamController<List<int>>();
      controller.add(utf8.encode('{"message":"سلام'));
      // هیچ close/add دیگری انجام نمی‌شود — جریان معلق است.

      final sw = Stopwatch()..start();
      await expectLater(
        readCappedUtf8(controller.stream, deadline: DateTime.now().add(const Duration(milliseconds: 250))),
        throwsA(isA<TimeoutException>()),
      );
      sw.stop();
      await controller.close();
      // باید به‌موقع خاتمه یافته باشد نه بی‌نهایت منتظر بماند (زیر ۵ ثانیه)
      expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
      expect(sw.elapsedMilliseconds, lessThan(3000),
          reason: 'خاتمه باید نزدیک deadline باشد (۲۵۰ms)، نه بسیار دیرتر');
    });

    test('خواندن کامل بدنه پیش از deadline: بدون خطا', () async {
      const body = '{"message":"ok"}';
      final out = await readCappedUtf8(
        Stream.value(utf8.encode(body)),
        deadline: DateTime.now().add(const Duration(seconds: 2)),
      );
      expect(out, body);
    });

    test('deadline گذشته → TimeoutException فوری', () async {
      await expectLater(
        readCappedUtf8(
          Stream.value(utf8.encode('{}')),
          deadline: DateTime.now().subtract(const Duration(seconds: 1)),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('pause طولانی بین قطعه‌ها زیر deadline → TimeoutException', () async {
      Stream<List<int>> slowStream() async* {
        yield utf8.encode('{"mess');
        await Future<void>.delayed(const Duration(seconds: 10));
        yield utf8.encode('age":"x"}');
      }

      final sw = Stopwatch()..start();
      await expectLater(
        readCappedUtf8(slowStream(), deadline: DateTime.now().add(const Duration(milliseconds: 300))),
        throwsA(isA<TimeoutException>()),
      );
      sw.stop();
      expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
    });
  });

  group('respond() — رد پیش از اتصال، با سوکت واقعی', () {
    test('endpoint صفحه HTTP واقعی → هیچ اتصالی به سرور نمی‌رسد', () async {
      var connections = 0;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((_) {
        connections++;
      });
      addTearDown(server.close);

      final client = HttpAiGuideClient(
        endpointProvider: () => Uri.parse('http://127.0.0.1:${server.port}/guide'),
      );

      await expectLater(
        client.respond(_query()),
        throwsA(isA<GuideFormatException>()),
      );
      expect(connections, 0, reason: 'رد باید پیش از هرگونه اتصال انجام شود');
    });

    test('endpoint نامعتبر (localhost) → رد بدون اتصال', () async {
      final client = HttpAiGuideClient(
        endpointProvider: () => Uri.parse('https://localhost:8443/guide'),
      );
      await expectLater(
        client.respond(_query()),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('endpoint IP محلی (۱۹۲.۱۶۸.۱.۱۰) → رد پیش از اتصال (ممیزی ۱.۰.۲)',
        () async {
      final client = HttpAiGuideClient(
        endpointProvider: () => Uri.parse('https://192.168.1.10/guide'),
      );
      await expectLater(
        client.respond(_query()),
        throwsA(isA<GuideFormatException>()),
      );
      expect(client.isConfigured, false);
    });

    test('isConfigured برای آدرس نامعتبر false است (بدون خطا)', () {
      final client = HttpAiGuideClient(
        endpointProvider: () => Uri.parse('http://not-secure.example.com'),
      );
      expect(client.isConfigured, false);
    });

    test('isConfigured برای endpoint محلی false و برای دامنه معتبر true است', () {
      final local = HttpAiGuideClient(
        endpointProvider: () => Uri.parse('https://127.0.0.1/guide'),
      );
      expect(local.isConfigured, false);

      final ok = HttpAiGuideClient(
        endpointProvider: () => Uri.parse('https://guide.example.com/api'),
      );
      expect(ok.isConfigured, true);
    });
  });

  // ممیزی ۱.۰.۳: دو سناریوی «NOT RUN» قبلی (چرخه کامل HTTPS موفق و سقف ۸KB
  // روی پاسخ HTTPS واقعی) اکنون با سرور HTTPS واقعی محلی (سوکت + TLS واقعی)
  // اجرا می‌شوند — گروه زیر. این شبیه‌سازی «سرور» است، نه سرویس عملیاتی؛
  // تست endpoint عملیاتی هنوز NOT RUN است و جداگانه گزارش می‌شود.

  // ─── ابزار سرور HTTPS محلی (ممیزی ۱.۰.۳) ───────────────────────────────
  //
  // گواهی test/fixtures/tls/server_cert.pem گواهی «آزمونِ دورریز» است
  // (CN=guide.example.test، اعتبار ۱۰ سال) — فیکسچر غیرمحرمانه مخصوص
  // همین تست‌ها؛ هیچ keystore/کلید واقعی در سورس قرار ندارد.
  String fixturePath(String name) =>
      '${Directory.current.path}/test/fixtures/tls/$name';

  Future<int> startTlsServer(
      Future<void> Function(HttpRequest) handler) async {
    final ctx = SecurityContext()
      ..useCertificateChain(fixturePath('server_cert.pem'))
      ..usePrivateKey(fixturePath('server_key.pem'));
    final srv = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      ctx,
    );
    srv.listen((req) async {
      try {
        await handler(req);
      } on Object {
        // خطای handler فقط همان اتصال را می‌بندد
      }
    });
    addTearDown(srv.close);
    return srv.port;
  }

  HttpAiGuideClient seamClient({
    required Uri endpoint,
    required int port,
    bool Function(X509Certificate, String, int)? badCert,
    Duration? timeout,
  }) =>
      HttpAiGuideClient(
        endpointProvider: () => endpoint,
        timeout: timeout ?? const Duration(seconds: 4),
        resolver: (_) async => [InternetAddress('93.184.216.34')],
        // همان قرارداد کارخانه پیش‌فرض: TCP خام به مقصد محلی + TLS با
        // نام اصلی uri (SNI/اعتبارسنجی نام) — چون dart:io با کارخانه
        // سفارشی TLS خودکار اعمال نمی‌کند.
        connectionFactory: (uri, proxyHost, proxyPort) {
          final Future<Socket> tls =
              Socket.startConnect(InternetAddress.loopbackIPv4, port)
              .then((t) => t.socket)
              .then((raw) => SecureSocket.secure(
                    raw,
                    host: uri.host,
                    onBadCertificate: (cert) =>
                        badCert?.call(cert, uri.host, uri.port) ?? false,
                  ));
          return Future<ConnectionTask<Socket>>.value(
              ConnectionTask.fromSocket(tls, () {}));
        },
        badCertificateCallback: badCert,
      );

  group('ماتریس HTTPS واقعی — سوکت و TLS واقعی روی سرور محلی (ممیزی ۱.۰.۳)', () {
    // برچسب صادقانه: این تست‌ها سرور واقعی محلی دارند (TLS + TCP واقعی)،
    // اما «سرویس عملیاتی» نیستند؛ تست endpoint عملیاتی NOT RUN است.

    test('پاسخ موفق: POST + پاسخ JSON معتبر (جایگزین NOT RUN قبلی)', () async {
      var requests = 0;
      final port = await startTlsServer((req) async {
        requests++;
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response
            .write('{"message":"آفرین! سه تا سیب است","action":"showHint"}');
        await req.response.close();
      });
      final client = seamClient(
        endpoint: Uri.parse('https://guide.example.test/guide'),
        port: port,
        badCert: (cert, host, p) => host == 'guide.example.test',
      );
      final reply = await client.respond(_query());
      expect(reply.message, 'آفرین! سه تا سیب است');
      expect(reply.source, 'online');
      expect(requests, 1);
    });

    test('دقیقاً شش فیلد payload اعلام‌شده ارسال می‌شود (P1-۵ — متن رضایت = واقعیت)',
        () async {
      Map<String, dynamic>? captured;
      final port = await startTlsServer((req) async {
        captured =
            jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write('{"message":"ok","action":"showHint"}');
        await req.response.close();
      });
      final client = seamClient(
        endpoint: Uri.parse('https://guide.example.test/guide'),
        port: port,
        badCert: (c, h, p) => true,
      );
      await client.respond(_query());
      expect(captured, isNotNull);
      expect(captured!.keys.toSet(),
          {'utterance', 'prompt', 'hints', 'wrongStreak', 'activityType', 'lessonId'});
      expect(captured!['utterance'], ''); // بدون ورود گفتاری → خالی
      expect(captured!['prompt'], 'چند سیب؟');
      expect(captured!['hints'],
          ['راهنمای اول', 'راهنمای دوم', 'راهنمای سوم']);
      expect(captured!['wrongStreak'], 0);
      expect(captured!['activityType'], 'countAndChoose');
      expect(captured!['lessonId'], 'a1');
    });

    test('redirect 302 دنبال نمی‌شود (followRedirects=false)', () async {
      var requests = 0;
      final port = await startTlsServer((req) async {
        requests++;
        req.response.statusCode = 302;
        req.response.headers
            .set(HttpHeaders.locationHeader, 'https://evil.example.com/x');
        await req.response.close();
      });
      final client = seamClient(
        endpoint: Uri.parse('https://guide.example.test/guide'),
        port: port,
        badCert: (c, h, p) => true,
      );
      await expectLater(
        client.respond(_query()),
        throwsA(isA<GuideFormatException>()),
      );
      expect(requests, 1,
          reason: 'هیچ درخواستی به مقصد redirect نباید ارسال شود');
    });

    test('TLS نامعتبر: گواهی خودامضا با callback سخت‌گیرانه رد می‌شود؛ درخواستی نمی‌رسد',
        () async {
      var requests = 0;
      final port = await startTlsServer((req) async {
        requests++;
      });
      final client = seamClient(
        endpoint: Uri.parse('https://guide.example.test/guide'),
        port: port,
        // badCertificateCallback = null → رفتار سخت‌گیرانه پیش‌فرض (false)
      );
      await expectLater(
        client.respond(_query()),
        throwsA(isA<GuideNotConfiguredException>()),
      );
      expect(requests, 0,
          reason: 'پس از شکست TLS هیچ درخواست HTTP ارسال نمی‌شود');
    });

    test('پاسخ بیش از حد مجاز (۱۰KB > سقف ۸KB) روی HTTPS واقعی (جایگزین NOT RUN قبلی)',
        () async {
      final port = await startTlsServer((req) async {
        req.response.statusCode = 200;
        await req.response
            .addStream(Stream.fromIterable([List.filled(10240, 0x61)]));
        await req.response.close();
      });
      final client = seamClient(
        endpoint: Uri.parse('https://guide.example.test/guide'),
        port: port,
        badCert: (c, h, p) => true,
      );
      await expectLater(
        client.respond(_query()),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('قطع اتصال وسط بدنه → خطای کنترل‌شده (fallback محلی)', () async {
      final port = await startTlsServer((req) async {
        req.response.statusCode = 200;
        req.response.contentLength = 1000;
        req.response.add(List.filled(10, 0x7b));
        await req.response.flush();
        // قطع خشن وسط بدنه — جداکردن سوکت و destroy آن
        final raw = await req.response.detachSocket();
        raw.destroy();
      });
      final client = seamClient(
        endpoint: Uri.parse('https://guide.example.test/guide'),
        port: port,
        badCert: (c, h, p) => true,
      );
      await expectLater(
        client.respond(_query()),
        throwsA(isA<GuideNotConfiguredException>()),
      );
    });

    test('سرور معلق (بدون پاسخ) → خاتمه در deadline واحد، نه انتظار بی‌نهایت',
        () async {
      final port = await startTlsServer((req) async {
        await Future<void>.delayed(const Duration(seconds: 30));
      });
      final client = seamClient(
        endpoint: Uri.parse('https://guide.example.test/guide'),
        port: port,
        badCert: (c, h, p) => true,
        timeout: const Duration(milliseconds: 700),
      );
      final sw = Stopwatch()..start();
      await expectLater(
        client.respond(_query()),
        throwsA(isA<GuideNotConfiguredException>()),
      );
      sw.stop();
      expect(sw.elapsed, lessThan(const Duration(seconds: 3)));
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('خطای DNS → خطای قالب کنترل‌شده (بدون اتصال)', () async {
      final client = HttpAiGuideClient(
        endpointProvider: () => Uri.parse(
            'https://nonexistent.invalid-dns-test.example/guide'),
        resolver: (_) async =>
            throw const SocketException('Failed host lookup'),
      );
      await expectLater(
        client.respond(_query()),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('مقصد ممنوع در نتیجه resolve (100.64.0.1 — CGNAT) → رد پیش از هرگونه اتصال',
        () async {
      var connects = 0;
      final client = HttpAiGuideClient(
        endpointProvider: () =>
            Uri.parse('https://rebind.attacker.example/guide'),
        resolver: (_) async => [InternetAddress('100.64.0.1')],
        connectionFactory: (uri, proxyHost, proxyPort) async {
          connects++;
          return Socket.startConnect(InternetAddress.loopbackIPv4, 1);
        },
      );
      await expectLater(
        client.respond(_query()),
        throwsA(isA<GuideFormatException>()),
      );
      expect(connects, 0, reason: 'اتصال به مقصد ممنوع هرگز نباید شروع شود');
    });

    test('مقصد ممنوع IPv4-mapped در نتیجه resolve (::ffff:192.168.1.10) → رد',
        () async {
      var connects = 0;
      final client = HttpAiGuideClient(
        endpointProvider: () =>
            Uri.parse('https://rebind.attacker.example/guide'),
        resolver: (_) async => [InternetAddress('::ffff:192.168.1.10')],
        connectionFactory: (uri, proxyHost, proxyPort) async {
          connects++;
          return Socket.startConnect(InternetAddress.loopbackIPv4, 1);
        },
      );
      await expectLater(
        client.respond(_query()),
        throwsA(isA<GuideFormatException>()),
      );
      expect(connects, 0);
    });

    test('چند A record که یکی ممنوع است → کل درخواست رد می‌شود', () async {
      var connects = 0;
      final client = HttpAiGuideClient(
        endpointProvider: () =>
            Uri.parse('https://mixed.rebind.attacker.example/guide'),
        resolver: (_) async =>
            [InternetAddress('93.184.216.34'), InternetAddress('10.9.9.9')],
        connectionFactory: (uri, proxyHost, proxyPort) async {
          connects++;
          return Socket.startConnect(InternetAddress.loopbackIPv4, 1);
        },
      );
      await expectLater(
        client.respond(_query()),
        throwsA(isA<GuideFormatException>()),
      );
      expect(connects, 0);
    });

    test('پین‌کردن مقصد: resolve فقط یک‌بار انجام می‌شود (بدون resolve مجدد هنگام اتصال)',
        () async {
      var lookups = 0;
      final client = HttpAiGuideClient(
        endpointProvider: () => Uri.parse('https://guide.example.test/guide'),
        timeout: const Duration(milliseconds: 700),
        resolver: (host) async {
          lookups++;
          return [InternetAddress('93.184.216.34')];
        },
        // کارخانه اتصال پیش‌فرض (پین‌شده): تلاش اتصال به IP عمومی در
        // سندباکس شکست می‌خورد — مهم: resolve دوباره رخ نمی‌دهد.
      );
      await expectLater(
        client.respond(_query()),
        throwsA(isA<GuideNotConfiguredException>()),
      );
      expect(lookups, 1,
          reason: 'تنها یک resolve باید انجام شود؛ اتصال به همان آدرس پین می‌شود');
    });
  });

  group('isForbiddenAddress — بازه‌های ممنوع ممیزی ۱.۰.۳ (CGNAT/TEST-NET/reserved)', () {
    test('IPv4 ممنوع: loopback/خصوصی/link-local/CGNAT/TEST-NET/benchmark/multicast/reserved',
        () {
      for (final ip in [
        '127.0.0.1', '10.1.2.3', '192.168.5.5', '172.16.0.9', '169.254.9.9',
        '0.0.0.0',
        '100.64.0.0', '100.64.0.1', '100.100.10.10', '100.127.255.255',
        '192.0.0.9', '192.0.2.5', '198.51.100.7', '203.0.113.9',
        '198.18.0.1', '198.19.255.254',
        '224.0.0.1', '240.0.0.1', '255.255.255.255',
      ]) {
        expect(isForbiddenAddress(InternetAddress(ip)), isTrue,
            reason: '$ip باید ممنوع باشد');
      }
    });

    test('IPv4 مجاز: IP عمومی و مرزهای بیرونی CGNAT/TEST-NET', () {
      for (final ip in [
        '8.8.8.8', '93.184.216.34',
        '100.63.255.255', // مرز پایین CGNAT — بیرون بازه
        '100.128.0.0', // مرز بالای CGNAT — بیرون بازه
        '198.20.0.1', '192.0.1.1', '203.0.114.1',
      ]) {
        expect(isForbiddenAddress(InternetAddress(ip)), isFalse,
            reason: '$ip باید مجاز باشد');
      }
    });

    test('IPv6 ممنوع: loopback/unspecified/link-local/ULA/multicast/doc/discard/mapped/NAT64',
        () {
      for (final ip in [
        '::1', '::', 'fe80::1', 'fc00::1', 'fd00::1', 'ff02::1',
        '2001:db8::1', '100::1',
        '::ffff:10.0.0.1', '::ffff:100.64.0.1', '::ffff:192.0.2.5',
        '64:ff9b::7f00:1',
      ]) {
        expect(isForbiddenAddress(InternetAddress(ip)), isTrue,
            reason: '$ip باید ممنوع باشد');
      }
    });

    test('IPv6 مجاز: آدرس عمومی واقعی', () {
      for (final ip in ['2606:4700:4700::1111', '2001:4860:4860::8888']) {
        expect(isForbiddenAddress(InternetAddress(ip)), isFalse,
            reason: '$ip باید مجاز باشد');
      }
    });
  });

  group('validateGuideEndpoint — بازه‌های جدید و پورت (ممیزی ۱.۰.۳)', () {
    test('IP literal از بازه‌های ممنوع جدید رد می‌شود', () {
      for (final host in [
        '100.64.0.1', '192.0.2.5', '198.18.0.1', '203.0.113.9',
        '[2001:db8::1]', '[::ffff:100.64.0.1]',
      ]) {
        expect(
          () => validateGuideEndpoint(Uri.parse('https://$host/guide')),
          throwsA(isA<GuideFormatException>()),
          reason: '$host باید رد شود',
        );
      }
    });

    test('پورت صفر رد می‌شود', () {
      expect(
        () => validateGuideEndpoint(
            Uri.parse('https://guide.example.com:0/guide')),
        throwsA(isA<GuideFormatException>()),
      );
    });

    test('پورت ۸۴۴۳ معتبر پذیرفته می‌شود', () {
      final u = validateGuideEndpoint(
          Uri.parse('https://guide.example.com:8443/guide'));
      expect(u.port, 8443);
    });
  });
}
