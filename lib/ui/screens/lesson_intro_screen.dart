import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/utils/persian.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// صفحه معرفی درس — توضیح کوتاه برای کودک پیش از شروع.
class LessonIntroScreen extends StatelessWidget {
  final Lesson lesson;
  final bool trialMode;
  final VoidCallback onStart;

  const LessonIntroScreen({
    super.key,
    required this.lesson,
    required this.trialMode,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final qCount = lesson.allQuestions.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('این درس چیه؟'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.ink,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Center(child: MascotLogo(size: 120)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  lesson.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  lesson.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.touch_app,
                        text: '۲ بازی کوچک: بشمار و عدد را انتخاب کن، بشمار و دسته درست را پیدا کن',
                      ),
                      const Divider(height: 20),
                      _InfoRow(
                        icon: Icons.help_outline,
                        text: 'اگر راه افتادی، من کمکت می‌کنم؛ نگران اشتباه نباش!',
                      ),
                      const Divider(height: 20),
                      _InfoRow(
                        icon: Icons.quiz_outlined,
                        text: 'همین درس $qCount سؤال دارد؛ حداکثر چند دقیقه طول می‌کشد.',
                      ),
                    ],
                  ),
                ),
              ),
              if (trialMode) ...[
                const SizedBox(height: 12),
                const Center(
                  child: LabelChip(text: 'حالت آزمایشی: نتیجه ذخیره نمی‌شود'),
                ),
              ],
              if (!lesson.teacherReviewed) ...[
                const SizedBox(height: 8),
                const Center(
                  child: LabelChip(text: 'محتوای نمونه — نیازمند بازبینی معلم'),
                ),
              ],
              const Spacer(),
              BigButton(
                label: trialMode ? 'شروع آزمایشی' : 'شروع می‌کنم!',
                icon: Icons.play_arrow,
                onPressed: onStart,
              ),
              const SizedBox(height: 8),
              Text(
                'درس ${faNum(1)} از واحد شمارش اشیا • نسخه محتوا ${lesson.contentVersion}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.teal, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
