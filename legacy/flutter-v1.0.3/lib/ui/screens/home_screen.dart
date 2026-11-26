import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/utils/persian.dart';
import '../colors.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// صفحه اصلی کودک — نمایش درس‌ها، پیشرفت و دکمه بزرگ ادامه یادگیری.
class HomeScreen extends StatelessWidget {
  final String childName;
  final List<Lesson> lessons;
  final Map<String, LearningProgress> progressByActivity;

  /// انتخاب درس → شروع معمولی
  final void Function(Lesson) onStartLesson;

  /// شروع آزمایشی (بدون ذخیره پیشرفت) برای درس اول
  final void Function(Lesson) onTrialLesson;

  final VoidCallback onOpenParents;
  final VoidCallback onOpenSettings;

  const HomeScreen({
    super.key,
    required this.childName,
    required this.lessons,
    required this.progressByActivity,
    required this.onStartLesson,
    required this.onTrialLesson,
    required this.onOpenParents,
    required this.onOpenSettings,
  });

  double _lessonProgress(Lesson l) {
    final acts = l.activities;
    if (acts.isEmpty) return 0;
    final done = acts.where((a) => progressByActivity[a.id]?.mastered ?? false).length;
    return done / acts.length;
  }

  Lesson? get _nextLesson {
    for (final l in lessons.where((l) => l.kind == LessonKind.regular)) {
      final allDone = l.activities.every((a) => progressByActivity[a.id]?.mastered ?? false);
      if (!allDone) return l;
    }
    return lessons.isNotEmpty ? lessons.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextLesson;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // سربرگ سلام و ابزارها
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سلام $childName!',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'امروز چند تا شیء می‌شماریم؟',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  ToolButton(
                    icon: Icons.family_restroom,
                    tooltip: 'بخش والدین',
                    color: AppColors.teal,
                    onTap: onOpenParents,
                  ),
                  const SizedBox(width: 8),
                  ToolButton(
                    icon: Icons.settings,
                    tooltip: 'تنظیمات',
                    color: Colors.blueGrey,
                    onTap: onOpenSettings,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // دکمه بزرگ ادامه یادگیری
              if (next != null) ...[
                _ContinueCard(
                  lesson: next,
                  progress: _lessonProgress(next),
                  onTap: () => onStartLesson(next),
                ),
              ],
              const SizedBox(height: 20),

              // فهرست درس‌ها
              Text(
                'درس‌های من',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              for (final lesson in lessons) ...[
                _LessonCard(
                  lesson: lesson,
                  progress: _lessonProgress(lesson),
                  onTap: () => onStartLesson(lesson),
                  onTrial: lesson.kind == LessonKind.regular
                      ? () => onTrialLesson(lesson)
                      : null,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final Lesson lesson;
  final double progress;
  final VoidCallback onTap;

  const _ContinueCard({
    required this.lesson,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress > 0 ? 'ادامه یادگیری' : 'شروع یادگیری',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.white38,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_back, color: Colors.white, size: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback? onTrial;

  const _LessonCard({
    required this.lesson,
    required this.progress,
    required this.onTap,
    this.onTrial,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const MascotLogo(size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lesson.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                _ProgressRing(progress: progress),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // ممیزی ۱.۰.۲ (کشف در تست ویجت): در صفحه‌های باریک، ترکیب
                // برچسب + دکمه‌ها RenderFlex overflow می‌داد؛ برچسب اکنون
                // انعطاف‌پذیر است و در صورت نیاز می‌شکند.
                if (!lesson.teacherReviewed)
                  Expanded(
                    child: const LabelChip(
                      text: 'محتوای نمونه — نیازمند بازبینی معلم',
                    ),
                  ),
                const Spacer(),
                if (onTrial != null)
                  TextButton(
                    onPressed: onTrial,
                    child: const Text('امتحان آزمایشی'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onTap,
                  child: Text(lesson.kind == LessonKind.quiz ? 'آزمون' : 'شروع'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  const _ProgressRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress == 0 ? null : progress,
            strokeWidth: 5,
            color: progress >= 1 ? AppColors.success : AppColors.teal,
            backgroundColor: Colors.grey.shade200,
          ),
          Text(
            progress >= 1 ? '✓' : '${faNum((progress * 100).round())}٪',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
