import 'package:flutter/material.dart';

import '../colors.dart';
import '../privacy_texts.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// صفحه تنظیمات — صدا و اطلاعات اپلیکیشن (قابل دسترس از خانه).
class SettingsScreen extends StatefulWidget {
  final bool voiceEnabled;
  final ValueChanged<bool> onToggleVoice;
  final String contentVersionNote;

  const SettingsScreen({
    super.key,
    required this.voiceEnabled,
    required this.onToggleVoice,
    this.contentVersionNote =
        'محتوای درس‌ها: نسخه ۱.۰.۰ — محتوای نمونه، نیازمند بازبینی معلم',
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.volume_up, color: AppColors.teal),
              title: const Text('راهنمای صوتی'),
              subtitle: const Text('خواندن دستورها و بازخوردها با صدای دستگاه'),
              value: widget.voiceEnabled,
              onChanged: widget.onToggleVoice,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'درباره ریاضی‌یار',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اپلیکیشن آموزش تعاملی ریاضی برای کلاس اول ابتدایی.\n'
                    // ممیزی ۱.۰.۲ (یافته حریم خصوصی): تمایز روشن بین حالت
                    // محلی پیش‌فرض و ارسال داده در حالت آنلاین — بدون
                    // ادعای بدون‌شرط «همه داده‌ها همیشه محلی است».
                    'واحد فعلی: شمارش اشیا (۱ تا ۹).\n\n'
                    '${PrivacyTexts.aboutPrivacyBlock}',
                    style: TextStyle(fontSize: 13, height: 1.8, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  const LabelChip(text: 'نسخه ۱.۰.۲ (رفع یافته‌های ممیزی)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.contentVersionNote,
                style: const TextStyle(fontSize: 12, height: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
