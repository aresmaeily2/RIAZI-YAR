import 'package:flutter/material.dart';

import '../colors.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// صفحه/شیت راهنمای آموزشی — نمایش پیام راهنما با منبع صادقانه
/// (راهنمای محلی یا آنلاین) و امکان ورود گفتاری.
class GuideSheet extends StatelessWidget {
  final String message;
  final String source; // 'local' | 'online'
  final VoidCallback? onVoiceInput;

  const GuideSheet({
    super.key,
    required this.message,
    required this.source,
    this.onVoiceInput,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MascotLogo(size: 64),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'راهنمای من',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  LabelChip(
                    text: source == 'online'
                        ? 'راهنمای آنلاین'
                        : 'راهنمای محلی (روی همین گوشی)',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.sky,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              style: const TextStyle(fontSize: 17, height: 1.7),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          if (onVoiceInput != null)
            TextButton.icon(
              onPressed: onVoiceInput,
              icon: const Icon(Icons.mic),
              label: const Text('چیزی بگو'),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: BigButton(
              label: 'فهمیدم، بریم بشماریم',
              icon: Icons.check,
              color: AppColors.teal,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
