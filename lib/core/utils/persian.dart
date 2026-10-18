/// ابزارهای فارسی‌سازی: تبدیل ارقام و متن‌های کمکی.
/// این لایه کاملاً خالص Dart است و هیچ وابستگی به Flutter ندارد
/// تا در تست‌های واحد بدون شبیه‌ساز اجرا شود.
library;

const String _faDigits = '۰۱۲۳۴۵۶۷۸۹';

/// تبدیل عدد به رشته با ارقام فارسی (مثلاً 4 → «۴»).
String toFa(int n) => _toFaImpl(n);

/// نام کوتاه‌تر پرکاربرد برای [toFa].
String faNum(int n) => _toFaImpl(n);

String _toFaImpl(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (final ch in s.codeUnits) {
    if (ch >= 0x30 && ch <= 0x39) {
      buf.write(_faDigits[ch - 0x30]);
    } else {
      buf.writeCharCode(ch);
    }
  }
  return buf.toString();
}

/// تبدیل رشته ارقام لاتین/عربی به فارسی برای نمایش یکدست.
String faDigitsIn(String s) {
  final buf = StringBuffer();
  for (final ch in s.runes) {
    if (ch >= 0x30 && ch <= 0x39) {
      buf.write(_faDigits[ch - 0x30]);
    } else if (ch >= 0x660 && ch <= 0x669) {
      buf.write(_faDigits[ch - 0x660]);
    } else {
      buf.writeCharCode(ch);
    }
  }
  return buf.toString();
}

/// استخراج اولین عدد از گفتار کودک (مثلاً «فکر کنم سه تا» → 3).
/// هم ارقام عددی و هم نام اعداد فارسی را می‌شناسد.
/// اگر عددی پیدا نشود null برمی‌گرداند.
int? extractNumberFromSpeech(String input) {
  final t = input.trim();
  if (t.isEmpty) return null;

  // ۱) ارقام (لاتین یا فارسی یا عربی)
  const digitMap = {
    '0': 0, '1': 1, '2': 2, '3': 3, '4': 4,
    '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
    '۰': 0, '۱': 1, '۲': 2, '۳': 3, '۴': 4,
    '۵': 5, '۶': 6, '۷': 7, '۸': 8, '۹': 9,
    '٠': 0, '١': 1, '٢': 2, '٣': 3, '٤': 4,
    '٥': 5, '٦': 6, '٧': 7, '٨': 8, '٩': 9,
  };
  final buf = <int>[];
  for (final ch in t.runes) {
    final c = String.fromCharCode(ch);
    if (digitMap.containsKey(c)) buf.add(digitMap[c]!);
  }
  if (buf.isNotEmpty) {
    // عدد چندرقمی پشت‌سرهم را یک عدد فرض می‌کنیم (حاصل گفتار STT)
    return int.tryParse(buf.join()) ?? buf.last;
  }

  // ۲) نام اعداد فارسی
  const names = {
    'صفر': 0, 'یک': 1, 'دو': 2, 'سه': 3, 'چهار': 4, 'پنج': 5,
    'شش': 6, 'هفت': 7, 'هشت': 8, 'نه': 9, 'ده': 10,
  };
  final normalized = t
      .replaceAll('‌', ' ') // نیم‌فاصله به فاصله
      .replaceAll(RegExp(r'[،.؟!:\u060C]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  for (final entry in names.entries) {
    if (RegExp('(^| )${entry.key}( |\$)').hasMatch(normalized)) {
      return entry.value;
    }
  }
  return null;
}
