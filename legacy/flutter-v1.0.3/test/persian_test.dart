import 'package:flutter_test/flutter_test.dart';
import 'package:riazi_yar/core/utils/persian.dart';

void main() {
  group('تبدیل ارقام فارسی', () {
    test('toFa برای اعداد ۰ تا ۹', () {
      expect(toFa(0), '۰');
      expect(toFa(4), '۴');
      expect(toFa(9), '۹');
    });

    test('toFa برای اعداد چندرقمی', () {
      expect(toFa(15), '۱۵');
      expect(toFa(100), '۱۰۰');
    });

    test('faNum همان toFa است', () {
      expect(faNum(7), toFa(7));
    });

    test('faDigitsIn لاتین را فارسی می‌کند', () {
      expect(faDigitsIn('12 34'), '۱۲ ۳۴');
      expect(faDigitsIn('نسخه 1.0.0'), 'نسخه ۱.۰.۰');
    });
  });

  group('استخراج عدد از گفتار کودک', () {
    test('ارقام لاتین در جمله', () {
      expect(extractNumberFromSpeech('جواب 4 است'), 4);
    });

    test('ارقام فارسی', () {
      expect(extractNumberFromSpeech('«۵»'), 5);
    });

    test('نام عدد فارسی', () {
      expect(extractNumberFromSpeech('فکر کنم سه تا'), 3);
      expect(extractNumberFromSpeech('هفت'), 7);
    });

    test('بدون عدد → null', () {
      expect(extractNumberFromSpeech('نمی‌دانم'), isNull);
      expect(extractNumberFromSpeech(''), isNull);
    });
  });
}
