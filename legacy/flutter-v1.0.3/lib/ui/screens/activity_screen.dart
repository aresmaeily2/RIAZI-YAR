import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/engine/lesson_session.dart';
import '../../core/audio/stt_service.dart';
import '../../core/engine/evaluator.dart';
import '../../core/guide/guide_engine.dart';
import '../../core/guide/guide_resolver.dart';
import '../../core/models/models.dart';
import '../../core/utils/persian.dart';
import '../theme.dart';
import '../colors.dart';
import '../widgets/common.dart';
import '../widgets/object_painter.dart';
import 'guide_sheet.dart';

/// صفحه فعالیت آموزشی — اجرای یک جلسه درس.
///
/// ویژگی‌های کلیدی:
///  • قفل پاسخ پس از هر submit تا جلوگیری از ثبت چندباره (مأموریت ۵.۹)
///  • بازخورد فوری محترمانه با امکان تکرار
///  • دکمه راهنما → موتور راهنمای محلی (یا آنلاین در صورت پیکربندی)
///  • دکمه میکروفون → STT فقط با اقدام آگاهانه کاربر
///  • حالت آزمایشی: تلاش‌ها ذخیره نمی‌شوند
class ActivityScreen extends StatefulWidget {
  final Lesson lesson;
  final AppServices services;
  final bool trialMode;

  /// فراخوانی برای ثبت تلاش (در حالت آزمایشی صدا زده نمی‌شود).
  final Future<void> Function(Attempt attempt)? onAttempt;

  /// پایان جلسه با نتیجه.
  final void Function(LessonSession session) onFinish;

  const ActivityScreen({
    super.key,
    required this.lesson,
    required this.services,
    required this.trialMode,
    this.onAttempt,
    required this.onFinish,
  });

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late LessonSession _session;
  late LocalGuideEngine _guide;
  bool _saving = false;
  bool _micBusy = false;

  /// ممیزی ۱.۰.۲ (یافته خطای ذخیره تلاش): اگر ثبت تلاش در پایگاه داده
  /// شکست بخورد، این پرچم بالا می‌آید؛ UI پیام شفاف نشان می‌دهد و
  /// «ثبت موفق پیشرفت» القا نمی‌شود. جلسه برای کودک ادامه می‌یابد
  /// (کودک مجازات نمی‌شود) ولی والد با نشانگر پایدار از وضعیت باخبر است.
  bool _saveFailed = false;
  String? _guideMessage;
  final List<bool> _solvedFlags = [];

  @override
  void initState() {
    super.initState();
    _session = LessonSession(lesson: widget.lesson);
    _guide = LocalGuideEngine();
    _solvedFlags.addAll(List.filled(_session.totalQuestions, false));
    // خواندن دستور با صدا (فقط اگر فعال باشد)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.services.speakInstruction(_session.currentItem.activity.instruction);
    });
  }

  Question get _q => _session.currentItem.question;
  Activity get _a => _session.currentItem.activity;

  Future<void> _submit(int value) async {
    if (_session.isLocked || _saving) return; // ضد دابل‌کلیک
    final result = _session.submitAnswer(value);
    if (result == null) return;
    setState(() {});

    // ثبت تلاش (نه در حالت آزمایشی)
    if (!widget.trialMode && widget.onAttempt != null) {
      _saving = true;
      try {
        await widget.onAttempt!(
          Attempt(
            lessonId: widget.lesson.id,
            activityId: _a.id,
            questionId: _q.id,
            isCorrect: result.isCorrect,
            chosenValue: value,
            hintUsed: _guideMessage != null,
            createdAt: DateTime.now(),
            // ممیزی ۱.۰.۲: شناسه یکتای اجرا برای امتیاز آخرین آزمون
            runId: _session.runId,
          ),
        );
        if (_saveFailed && mounted) {
          setState(() => _saveFailed = false);
        }
      } catch (e) {
        // ممیزی ۱.۰.۲ (یافته خطای ذخیره تلاش): خطای SQLite هرگز نباید
        // UI را بی‌توضیح متوقف کند یا «ثبت موفق» القا شود.
        //  • خطا ثبت می‌شود (debugPrint) نه بی‌صدا.
        //  • یک تلاش مجدد بلافاصله (خطاهای گذرا مثل قفل کوتاه DB) —
        //    فقط یک بار؛ شکست مجدد → وضعیت خطا به والد نمایش داده می‌شود.
        //  • جریان کودک ادامه می‌یابد (بازخورد و پیشروی) — کودک نه
        //    می‌ایستد نه پیام «ذخیره شد» می‌بیند.
        debugPrint('Attempt save failed: $e');
        try {
          await widget.onAttempt!(Attempt(
            lessonId: widget.lesson.id,
            activityId: _a.id,
            questionId: _q.id,
            isCorrect: result.isCorrect,
            chosenValue: value,
            hintUsed: _guideMessage != null,
            createdAt: DateTime.now(),
            runId: _session.runId,
          ));
          if (_saveFailed && mounted) {
            setState(() => _saveFailed = false);
          }
        } catch (e2) {
          debugPrint('Attempt save retry failed: $e2');
          if (mounted) {
            setState(() => _saveFailed = true);
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(const SnackBar(
                duration: Duration(seconds: 5),
                content: Text(
                    'ثبت این تلاش در حافظه دستگاه ممکن نشد؛ ادامه می‌دهیم ولی این تلاش در گزارش ثبت نمی‌شود.'),
              ));
          }
        }
      } finally {
        _saving = false;
      }
    }

    if (result.isCorrect) _solvedFlags[_session.currentIndex] = true;
    widget.services.tts.speak(result.message);
    _showFeedback(result);
  }

  void _showFeedback(EvaluationResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FeedbackDialog(
        isCorrect: result.isCorrect,
        message: result.message,
        triesLeft: 3 - _session.wrongStreakCurrent,
        onContinue: () {
          Navigator.of(ctx).pop();
          final advancedToEnd = _session.advance();
          if (_session.isFinished) {
            widget.onFinish(_session);
          } else if (advancedToEnd) {
            setState(() {
              _guideMessage = null;
            });
            widget.services.speakInstruction(_a.instruction);
          }
        },
      ),
    );
  }

  Future<void> _askGuide({String? utterance}) async {
    final s = widget.services;
    final query = GuideQuery(
      question: _q,
      activity: _a,
      wrongStreak: _session.wrongStreakCurrent,
      utterance: utterance,
    );

    // منطق انتخاب موتور + fallback در هسته منتقل شد (ممیزی ۱.۰.۱)
    // تا مستقل از UI تست شود؛ رفتار عیناً حفظ شده است.
    final reply = await resolveGuideReply(
      localGuide: _guide,
      onlineGuide: s.onlineGuide,
      onlineEnabled: s.settings.onlineGuideEnabled,
      onlineConfigured: s.onlineGuide.isConfigured,
      query: query,
    );

    setState(() => _guideMessage = reply.message);
    widget.services.tts.speak(reply.message);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => GuideSheet(
        message: reply.message,
        source: reply.source,
        // ورودی گفتار فقط اگر در سطح بیلد مجاز و در تنظیمات والدین فعال باشد
        // (ممیزی ۱.۰.۱: kSpeechInputAvailable = false ⇒ دکمه پنهان است)
        onVoiceInput: kSpeechInputAvailable &&
                widget.services.settings.speechInputEnabled
            ? _listenForGuide
            : null,
      ),
    );
  }

  Future<void> _listenForGuide() async {
    if (_micBusy) return;
    setState(() => _micBusy = true);
    final stt = widget.services.stt;
    final ok = await stt.init();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sttErrorMessage(stt.status))),
        );
      }
      setState(() => _micBusy = false);
      return;
    }
    final got = await stt.start(
      onResult: (text) {
        Navigator.of(context, rootNavigator: true).pop(); // بستن راهنما
        _askGuide(utterance: text);
      },
    );
    if (!got && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sttErrorMessage(stt.status))),
      );
      setState(() => _micBusy = false);
    }
  }

  String _sttErrorMessage(SttStatus s) => switch (s) {
        SttStatus.permissionDenied =>
          'برای گفتن جواب، اجازه میکروفون لازم است؛ از والدین بخواه آن را فعال کنند.',
        SttStatus.unavailable =>
          'گفتار به متن روی این گوشی در دسترس نیست؛ ولی با دکمه‌ها می‌توانی جواب بدهی!',
        _ => 'الان نمی‌توانم صدایت را بشنوم؛ دوباره امتحان کن.',
      };

  Future<bool> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خروج از درس؟'),
        content: const Text('اگر خارج شوی، این تمرین نیمه‌کاره می‌ماند؛ ولی پیشرفتت حفظ می‌شود.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ادامه تمرین'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmExit() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.lesson.title, style: const TextStyle(fontSize: 18)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.ink,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'خروج',
              icon: const Icon(Icons.close),
              onPressed: () async {
                if (await _confirmExit() && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ProgressDots(
                  total: _session.totalQuestions,
                  current: _session.currentIndex,
                  solvedFlags: _solvedFlags,
                ),
              ),
              if (widget.trialMode)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: LabelChip(text: 'حالت آزمایشی — نتیجه ذخیره نمی‌شود'),
                ),
              // ممیزی ۱.۰.۲: نشانگر پایدار خطای ذخیره‌سازی برای والد —
              // پیشرفت این جلسه در پایگاه داده ثبت نمی‌شود و UI صادقانه
              // می‌گوید؛ بدون توقف مسیر کودک.
              if (_saveFailed)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: LabelChip(
                    text: 'خطای ذخیره‌سازی — ثبت پیشرفت موقتاً قطع است',
                    color: Colors.red,
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildQuestion(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final item = _session.currentItem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // دستور فعالیت
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            _a.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),

        // پرسش
        Text(
          _q.prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),

        // بدنه: اشیا یا دسته‌ها
        if (item.activity.type == ActivityType.countAndChoose)
          _CountDisplay(shape: _q.itemShape, count: _q.itemCount)
        else
          _NumberGroupMatch(
            target: _q.itemCount,
            shape: _q.itemShape,
            options: _q.options,
            locked: _session.isLocked,
            onPick: (v) => _submit(v),
          ),

        // پیام راهنمای قبلی (در صورت وجود)
        if (_guideMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.softYellow.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'راهنما: $_guideMessage',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
        const SizedBox(height: 20),

        // گزینه‌های عددی برای countAndChoose
        if (item.activity.type == ActivityType.countAndChoose)
          _NumberOptions(
            options: _q.options,
            locked: _session.isLocked,
            onPick: (v) => _submit(v),
          ),

        const SizedBox(height: 16),

        // نوار ابزار: راهنما + میکروفون (گفتن عدد)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ToolButton(
              icon: Icons.lightbulb,
              tooltip: 'کمک می‌خوام',
              color: AppColors.softYellow,
              onTap: _session.isLocked ? null : () => _askGuide(),
            ),
            const SizedBox(width: 16),
            if (kSpeechInputAvailable &&
                widget.services.settings.speechInputEnabled)
              ToolButton(
                icon: _micBusy ? Icons.mic : Icons.mic_none,
                tooltip: 'جواب را بگو',
                color: AppColors.teal,
                active: !_session.isLocked,
                onTap: _session.isLocked ? null : _submitByVoice,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (kSpeechInputAvailable &&
            widget.services.settings.speechInputEnabled)
          Text(
            'می‌توانی جواب را بلند بگویی! روی میکروفون بزن و عدد را بگو.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
      ],
    );
  }

  Future<void> _submitByVoice() async {
    if (_micBusy || _session.isLocked) return;
    setState(() => _micBusy = true);
    final stt = widget.services.stt;
    final ok = await stt.init();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sttErrorMessage(stt.status))),
        );
      }
      setState(() => _micBusy = false);
      return;
    }
    final started = await stt.start(
      onResult: (text) {
        final n = extractNumberFromSpeech(text);
        if (!mounted) return;
        setState(() => _micBusy = false);
        if (n == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('نتوانستم عدد را بشنوم؛ دوباره بگو یا با دکمه‌ها انتخاب کن.'),
            ),
          );
        } else {
          _submit(n);
        }
      },
    );
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sttErrorMessage(stt.status))),
      );
      setState(() => _micBusy = false);
    }
  }
}

/// نمایش شبکه‌ای اشیای قابل شمارش (countAndChoose).
class _CountDisplay extends StatelessWidget {
  final String shape;
  final int count;

  const _CountDisplay({required this.shape, required this.count});

  @override
  Widget build(BuildContext context) {
    final cols = count <= 4 ? 2 : 3;
    final rows = (count / cols).ceil();
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows; r++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var c = 0; c < cols; c++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: (r * cols + c) < count
                            ? CustomPaint(
                                painter: ObjectPainter(shape: shape),
                                size: const Size.square(56),
                              )
                            : const SizedBox(width: 56, height: 56),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// تطبیق عدد با دسته‌ها (matchCount) — عدد هدف بزرگ + دسته‌های قابل انتخاب.
class _NumberGroupMatch extends StatelessWidget {
  final int target;
  final String shape;
  final List<AnswerOption> options;
  final bool locked;
  final void Function(int value) onPick;

  const _NumberGroupMatch({
    required this.target,
    required this.shape,
    required this.options,
    required this.locked,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // عدد هدف
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.teal,
            shape: BoxShape.circle,
          ),
          child: Text(
            toFa(target),
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final opt in options)
              ObjectGroup(
                shape: shape,
                count: opt.value,
                selected: false,
                onTap: locked ? null : () => onPick(opt.value),
              ),
          ],
        ),
      ],
    );
  }
}

/// گزینه‌های عددی بزرگ (countAndChoose).
class _NumberOptions extends StatelessWidget {
  final List<AnswerOption> options;
  final bool locked;
  final void Function(int value) onPick;

  const _NumberOptions({
    required this.options,
    required this.locked,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final opt in options)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: locked ? null : () => onPick(opt.value),
              child: Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: Text(
                  opt.label,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// دیالوگ بازخورد فوری.
class _FeedbackDialog extends StatelessWidget {
  final bool isCorrect;
  final String message;
  final int triesLeft;
  final VoidCallback onContinue;

  const _FeedbackDialog({
    required this.isCorrect,
    required this.message,
    required this.triesLeft,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCorrect ? Icons.emoji_events : Icons.sentiment_satisfied_alt,
              color: isCorrect ? AppColors.success : AppColors.primary,
              size: 72,
            ),
            const SizedBox(height: 12),
            Text(
              isCorrect ? 'آفرین!' : 'اشکالی ندارد!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isCorrect ? AppColors.success : AppColors.primaryDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            if (!isCorrect && triesLeft > 0) ...[
              const SizedBox(height: 8),
              Text(
                'تلاش‌های باقی‌مانده: ${faNum(triesLeft)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 20),
            BigButton(
              label: isCorrect ? 'بریم بعدی' : 'دوباره امتحان می‌کنم',
              icon: Icons.arrow_back,
              color: isCorrect ? AppColors.success : AppColors.primary,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
