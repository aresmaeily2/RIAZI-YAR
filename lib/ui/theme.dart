import 'package:flutter/material.dart';

/// تم بصری کودک‌پسند «ریاضی‌یار»
/// - رنگ‌های شاد و پرکنتراست مناسب کودک ۶-۷ سال
/// - فونت Vazirmatn (بومی فارسی)
/// - اندازه لمس حداقل 48dp برای همه دکمه‌ها
class AppTheme {
  AppTheme._();

  // پالت
  static const Color sky = Color(0xFFE8F4FD);      // پس‌زمینه آسمانی
  static const Color primary = Color(0xFFFF8A3D);  // نارنجی گرم
  static const Color primaryDark = Color(0xFFE06D1B);
  static const Color teal = Color(0xFF2BB3A3);     // فیروزه‌ای
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color ink = Color(0xFF2D3142);      // متن اصلی
  static const Color softYellow = Color(0xFFFFD54F);
  static const Color cardWhite = Colors.white;

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: teal,
        surface: cardWhite,
        error: error,
      ),
      scaffoldBackgroundColor: sky,
      fontFamily: 'Vazirmatn',
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
        fontFamily: 'Vazirmatn',
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
