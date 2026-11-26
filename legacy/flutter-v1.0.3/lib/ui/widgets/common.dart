import 'package:flutter/material.dart';

import '../colors.dart';

/// نشان «ریاضی‌یار» — روباه شمارنده ساده با اشکال برداری.
class MascotLogo extends StatelessWidget {
  final double size;
  const MascotLogo({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          CustomPaint(painter: _FoxPainter(), size: Size.square(size * 0.72)),
        ],
      ),
    );
  }
}

class _FoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final orange = Paint()..color = const Color(0xFFFF8A3D);
    final white = Paint()..color = Colors.white;
    final ink = Paint()..color = const Color(0xFF2D3142);

    // گوش‌ها
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r * 0.85, c.dy - r * 0.15)
        ..lineTo(c.dx - r * 0.55, c.dy - r * 1.0)
        ..lineTo(c.dx - r * 0.25, c.dy - r * 0.45)
        ..close(),
      orange,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + r * 0.85, c.dy - r * 0.15)
        ..lineTo(c.dx + r * 0.55, c.dy - r * 1.0)
        ..lineTo(c.dx + r * 0.25, c.dy - r * 0.45)
        ..close(),
      orange,
    );
    // صورت
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * 1.5, height: r * 1.3),
      orange,
    );
    // گونه‌ها
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.35),
        width: r * 1.0,
        height: r * 0.7,
      ),
      white,
    );
    // چشم‌ها
    canvas.drawCircle(c - Offset(r * 0.32, r * 0.12), r * 0.1, ink);
    canvas.drawCircle(c + Offset(r * 0.32, r * 0.12), r * 0.1, ink);
    // بینی
    canvas.drawCircle(c + Offset(0, r * 0.22), r * 0.07, ink);
  }

  @override
  bool shouldRepaint(covariant _FoxPainter oldDelegate) => false;
}

/// نوار پیشرفت نقاطی برای نمایش جایگاه کودک در درس.
class ProgressDots extends StatelessWidget {
  final int total;
  final int current;
  final List<bool> solvedFlags;

  const ProgressDots({
    super.key,
    required this.total,
    required this.current,
    required this.solvedFlags,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: solvedFlags.length > i && solvedFlags[i]
                  ? AppColors.success
                  : i == current
                      ? AppColors.primary
                      : Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
          ),
      ],
    );
  }
}

/// دکمه بزرگ لمسی مناسب کودک.
class BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;

  const BigButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_back, size: 28), // RTL: back-arrow = forward
        label: Text(label, textAlign: TextAlign.center),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
        ),
      ),
    );
  }
}

/// دکمه گرد کوچک برای ابزارها (راهنما، میکروفون، صدا).
class ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color color;
  final bool active;

  const ToolButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color = AppColors.teal,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? color : Colors.grey,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

/// نشان برچسب کوچک (مثلاً «محتوای نمونه»).
class LabelChip extends StatelessWidget {
  final String text;
  final Color color;

  const LabelChip({super.key, required this.text, this.color = AppColors.labelBrown});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
