import 'dart:math';

import 'package:flutter/material.dart';

import '../colors.dart';

/// نقاش گرافیک برداری اشیا — بدون هیچ فایل تصویری.
/// اشیا ساده و قابل شمارش برای کودک: سیب، ستاره، توپ، گل، ماهی، پرنده.
class ObjectPainter extends CustomPainter {
  final String shape;
  final Color color;

  ObjectPainter({required this.shape, this.color = Colors.red});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = min(size.width, size.height) / 2;
    switch (shape) {
      case 'apple':
        _apple(canvas, c, r);
      case 'star':
        _star(canvas, c, r, color == Colors.red ? const Color(0xFFFFC93C) : color);
      case 'ball':
        _ball(canvas, c, r);
      case 'flower':
        _flower(canvas, c, r);
      case 'fish':
        _fish(canvas, c, r);
      case 'bird':
        _bird(canvas, c, r);
      default:
        _ball(canvas, c, r);
    }
  }

  void _apple(Canvas canvas, Offset c, double r) {
    // بدنه
    canvas.drawCircle(c + Offset(-r * 0.22, r * 0.15), r * 0.68, Paint()..color = const Color(0xFFEF5350));
    canvas.drawCircle(c + Offset(r * 0.22, r * 0.15), r * 0.68, Paint()..color = const Color(0xFFEF5350));
    // برگ
    final leaf = Paint()..color = const Color(0xFF66BB6A);
    final path = Path()
      ..moveTo(c.dx, c.dy - r * 0.55)
      ..quadraticBezierTo(c.dx + r * 0.5, c.dy - r * 1.0, c.dx + r * 0.65, c.dy - r * 0.5)
      ..quadraticBezierTo(c.dx + r * 0.3, c.dy - r * 0.35, c.dx, c.dy - r * 0.55);
    canvas.drawPath(path, leaf);
    // ساقه
    canvas.drawRect(
      Rect.fromCenter(center: c + Offset(0, -r * 0.5), width: r * 0.12, height: r * 0.45),
      Paint()..color = const Color(0xFF8D6E63),
    );
  }

  void _star(Canvas canvas, Offset c, double r, Color col) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final outer = pi / 2 + i * 2 * pi / 5;
      final inner = outer + pi / 5;
      final p1 = c + Offset(cos(outer) * r, -sin(outer) * r);
      final p2 = c + Offset(cos(inner) * r * 0.45, -sin(inner) * r * 0.45);
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.lineTo(p2.dx, p2.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = col);
  }

  void _ball(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r * 0.85, Paint()..color = const Color(0xFF42A5F5));
    // نوار رنگی توپ
    final stripe = Paint()
      ..color = Colors.white
      ..strokeWidth = r * 0.18
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.85),
      pi + 0.4,
      pi - 0.8,
      false,
      stripe,
    );
  }

  void _flower(Canvas canvas, Offset c, double r) {
    final petals = Paint()..color = const Color(0xFFEC6BAE);
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5 - pi / 2;
      canvas.drawCircle(
        c + Offset(cos(a) * r * 0.5, sin(a) * r * 0.5),
        r * 0.38,
        petals,
      );
    }
    canvas.drawCircle(c, r * 0.35, Paint()..color = const Color(0xFFFFD54F));
  }

  void _fish(Canvas canvas, Offset c, double r) {
    final body = Paint()..color = const Color(0xFF29B6F6);
    // بدنه بیضی
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * 1.7, height: r * 1.0),
      body,
    );
    // دم
    final tail = Path()
      ..moveTo(c.dx + r * 0.8, c.dy)
      ..lineTo(c.dx + r * 1.35, c.dy - r * 0.5)
      ..lineTo(c.dx + r * 1.35, c.dy + r * 0.5)
      ..close();
    canvas.drawPath(tail, body);
    // چشم
    canvas.drawCircle(c - Offset(r * 0.5, r * 0.15), r * 0.12, Paint()..color = Colors.white);
    canvas.drawCircle(c - Offset(r * 0.5, r * 0.15), r * 0.06, Paint()..color = Colors.black87);
  }

  void _bird(Canvas canvas, Offset c, double r) {
    final body = Paint()..color = const Color(0xFFFFCA28);
    // بدنه
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * 1.5, height: r * 1.1),
      body,
    );
    // سر
    canvas.drawCircle(c - Offset(r * 0.5, r * 0.45), r * 0.4, body);
    // منقار
    final beak = Path()
      ..moveTo(c.dx - r * 0.88, c.dy - r * 0.5)
      ..lineTo(c.dx - r * 1.25, c.dy - r * 0.38)
      ..lineTo(c.dx - r * 0.88, c.dy - r * 0.28)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFB8C00));
    // چشم
    canvas.drawCircle(c - Offset(r * 0.58, r * 0.55), r * 0.09, Paint()..color = Colors.black87);
    // بال
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(r * 0.1, r * 0.05), width: r * 0.8, height: r * 0.45),
      Paint()..color = const Color(0xFFF9A825),
    );
  }

  @override
  bool shouldRepaint(covariant ObjectPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}

/// ویجت آماده شیء قابل شمارش.
class CountableObject extends StatelessWidget {
  final String shape;
  final double size;

  const CountableObject({super.key, required this.shape, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ObjectPainter(shape: shape),
      size: Size.square(size),
    );
  }
}

/// رندر یک «دسته اشیا» برای فعالیت matchCount — چیدمان شبکه‌ای منظم
/// تا شمارش برای کودک ساده و دقیق باشد.
class ObjectGroup extends StatelessWidget {
  final String shape;
  final int count;
  final double itemSize;
  final bool selected;
  final VoidCallback? onTap;

  const ObjectGroup({
    super.key,
    required this.shape,
    required this.count,
    this.itemSize = 40,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < count; i++)
              CustomPaint(
                painter: ObjectPainter(shape: shape),
                size: Size.square(itemSize),
              ),
          ],
        ),
      ),
    );
  }
}

/// رنگ‌های تم از colors.dart استفاده می‌شوند.
