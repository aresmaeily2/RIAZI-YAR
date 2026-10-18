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

  // ثبت صادقانه آزمون‌های شبکه واقعی HTTPS که در این محیط اجرا نشدند:
  // sandbox فاقد سرور HTTPS است و چرخه کامل TLS (گواهی معتبر) شبیه‌سازی
  // نمی‌شود؛ کلاینت نیز گواهی نامعتبر را با badCertificateCallback=false
  // رد می‌کند. این دو سناریو به تست میدانی موکول است.
  test('چرخه کامل HTTPS موفق (POST + پاسخ JSON معتبر) — NOT RUN',
      skip: 'نیازمند سرور HTTPS واقعی؛ ثبت‌شده در گزارش ممیزی', () async {
    fail('در محیط اجرا نشده است');
  });

  test('سقف ۸KB روی پاسخ HTTPS واقعی — NOT RUN',
      skip: 'نیازمند سرور HTTPS واقعی؛ ثبت‌شده در گزارش ممیزی', () async {
    fail('در محیط اجرا نشده است');
  });
}
