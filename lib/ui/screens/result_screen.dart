import 'package:flutter/material.dart';

import '../../core/engine/evaluator.dart';
import '../../core/engine/lesson_session.dart';
import '../../core/models/models.dart';
import '../../core/utils/persian.dart';
import '../colors.dart';
import '../widgets/common.dart';

/// صفحه نتیجه — بازخورد مثبت بدون سرزنش + گزینه تکرار.
class ResultScreen extends StatelessWidget {
  final Lesson lesson;
  final LessonSession session;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  const ResultScreen({
    super.key,
    required this.lesson,
    required this.session,
    required this.onRetry,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final score = session.score();
    final correct = session.correctCount;
    final total = session.totalQuestions;
    final message = const Evaluator().resultMessage(score);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: MascotLogo(size: 150)),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  lesson.kind == LessonKind.quiz
                      ? 'آزمون تمام شد!'
                      : 'درس تمام شد!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 16),

              // ستاره‌ها بر اساس امتیاز
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Icon(
                      Icons.star,
                      size: 48,
                      color: score >= (i + 1) / 3 - 0.01
                          ? AppColors.softYellow
                          : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '${faNum(correct)} از ${faNum(total)} در نخستین تلاش درست',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ),
              ),
              if (lesson.kind == LessonKind.quiz) ...[
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'نتیجه این آزمون در گزارش والدین ثبت شد.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              BigButton(
                label: 'یک‌بار دیگر تمرین کنم',
                icon: Icons.refresh,
                color: AppColors.teal,
                onPressed: onRetry,
              ),
              const SizedBox(height: 12),
              BigButton(
                label: 'برگشت به خانه',
                icon: Icons.home,
                onPressed: onHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
