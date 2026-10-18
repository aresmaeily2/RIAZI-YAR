import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/utils/persian.dart';
import '../colors.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// بخش والدین — با گیت ساده محافظتی (سؤال ریاضی دو رقمی).
/// صداقت: این گیت «محافظت ساده» است و امنیت بالا ادعا نمی‌شود.
class ParentGateScreen extends StatefulWidget {
  final Widget child;

  const ParentGateScreen({super.key, required this.child});

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  late int a;
  late int b;
  final controller = TextEditingController();
  bool failed = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    final seed = DateTime.now().millisecondsSinceEpoch;
    a = 12 + (seed % 20);
    b = 12 + ((seed ~/ 7) % 20);
  }

  void _check() {
    final v = int.tryParse(controller.text.trim());
    if (v == a + b) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.child),
      );
    } else {
      setState(() {
        failed = true;
        _newQuestion();
        controller.clear();
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بخش والدین'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.ink,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppColors.teal),
              const SizedBox(height: 16),
              const Text(
                'این بخش برای بزرگ‌ترهاست.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Text(
                '${faNum(a)} + ${faNum(b)} = ؟',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    hintText: 'پاسخ را با عدد انگلیسی وارد کنید',
                  ),
                ),
              ),
              if (failed) ...[
                const SizedBox(height: 8),
                const Text(
                  'پاسخ درست نبود؛ سؤال جدید آماده شد.',
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _check,
                child: const Text('ورود'),
              ),
              const SizedBox(height: 12),
              Text(
                'این محافظت ساده است و جایگزین نظارت والدین نمی‌شود.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صفحه گزارش والدین — فقط داده واقعی ثبت‌شده، بدون تشخیص یا برچسب کودک.
class ParentDashboardScreen extends StatefulWidget {
  final ParentSummary summary;
  final LearnerSettings settings;
  final ValueChanged<bool> onToggleOnlineGuide;
  final ValueChanged<bool> onToggleVoice;
  final VoidCallback onResetProgress;
  final String storageNotice;

  const ParentDashboardScreen({
    super.key,
    required this.summary,
    required this.settings,
    required this.onToggleOnlineGuide,
    required this.onToggleVoice,
    required this.onResetProgress,
    this.storageNotice = 'همه داده‌ها فقط روی همین دستگاه ذخیره می‌شوند.',
  });

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش کودک'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              _StatCard(
                title: 'تعداد فعالیت انجام‌شده',
                value: faNum(s.totalAttempts),
                icon: Icons.touch_app,
              ),
              const SizedBox(width: 12),
              _StatCard(
                title: 'پاسخ‌های درست',
                value: '${faNum(s.totalCorrect)} (${faNum((s.overallAccuracy * 100).round())}٪)',
                icon: Icons.check_circle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                title: 'فعالیت‌های شروع‌شده',
                value: faNum(s.activitiesStarted),
                icon: Icons.flag,
              ),
              const SizedBox(width: 12),
              _StatCard(
                title: 'فعالیت‌های تسلط‌یافته',
                value: faNum(s.activitiesMastered),
                icon: Icons.emoji_events,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.quiz, color: AppColors.teal),
              title: Text(s.lastQuizTitle ?? 'آزمونی ثبت نشده است'),
              subtitle: Text(
                s.lastQuizScore == null
                    ? 'پس از اولین آزمون، نتیجه اینجا نمایش داده می‌شود.'
                    : 'آخرین نتیجه: ${faNum((s.lastQuizScore! * 100).round())}٪',
              ),
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
                    'موضوعات نیازمند تمرین بیشتر',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (s.needsPracticeTitles.isEmpty)
                    Text(
                      'فعلاً چیزی ثبت نشده؛ وقتی دقتی زیر ۷۵٪ باشد اینجا نمایش داده می‌شود.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    )
                  else
                    for (final t in s.needsPracticeTitles)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.repeat, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t)),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'تنظیمات قابلیت‌ها',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('راهنمای صوتی (خواندن دستورها)'),
            subtitle: const Text(
              'با موتور گفتار خود دستگاه؛ فقط خواندن متن است و صدایی ضبط نمی‌شود',
            ),
            value: widget.settings.voiceGuideEnabled,
            onChanged: widget.onToggleVoice,
          ),
          // ممیزی ۱.۰.۱: ورودی گفتار در سطح بیلد غیرفعال است؛ به‌جای سوییچ،
          // توضیح صادقانه برای والد نمایش داده می‌شود.
          ListTile(
            leading: const Icon(Icons.mic_off, color: Colors.grey),
            title: const Text('ورودی گفتار (میکروفون)'),
            subtitle: const Text(
              'در این نسخه غیرفعال است: موتور تشخیص گفتار گوشی ممکن است صدا '
              'را برای پردازش به سرویس‌های خودش بفرستد و این مسیر قابل '
              'راستی‌آزمایی نبود. پاسخ دادن کودک با دکمه‌ها کامل و آفلاین است.',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const LabelChip(text: 'غیرفعال'),
          ),
          SwitchListTile(
            title: const Text('راهنمای آنلاین'),
            // ممیزی ۱.۰.۲ (یافته حریم خصوصی): توضیح شفاف — فعال‌سازی با
            // دیالوگ رضایت آگاهانه همراه است؛ مقصد و نوع داده ارسالی
            // پیش از فعال‌سازی نمایش داده می‌شود.
            subtitle: const Text(
              'پیش‌فرض خاموش. در صورت فعال‌سازی (با تأیید صریح شما)، هنگام '
              'درخواست راهنما، متن پرسش و شناسه پرسش به سرور راهنما '
              'ارسال می‌شود؛ پیشرفت کودک همچنان فقط روی همین دستگاه ذخیره '
              'می‌شود.',
            ),
            value: widget.settings.onlineGuideEnabled,
            onChanged: widget.onToggleOnlineGuide,
          ),
          const SizedBox(height: 16),
          Card(
            color: AppTheme.sky,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                widget.storageNotice,
                style: const TextStyle(fontSize: 12, height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: widget.onResetProgress,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: const Text(
              'پاک کردن همه پیشرفت‌ها',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.teal, size: 26),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
