import 'guide_engine.dart';

/// انتخاب و اجرای موتور راهنما با fallback صادقانه — منطق مستقل از UI.
///
/// ممیزی ۱.۰.۱: این منطق قبلاً درون activity_screen (UI) بود؛ برای
/// تست‌پذیریِ مستقیم «رفتار fallback» به هسته منتقل شد. رفتار عیناً حفظ
/// شده است:
///  • راهنمای آنلاین فقط وقتی استفاده می‌شود که در تنظیمات والدین فعال،
///    پیکربندی‌شده و آدرسش معتبر باشد (onlineConfigured).
///  • خروجی نامعتبر سرور (GuideFormatException) → پیام «غیرقابل فهم بود»
///    با منبع محلی.
///  • هر خطای دیگر (نبود سرور/شبکه/timeout) → پیام «در دسترس نیست» با
///    منبع محلی.
///  • در غیر این صورت (غیرفعال/پیکربندی نشده) مستقیم موتور محلی.
///
/// پارامترها عمومی GuideEngine هستند تا با فیک هم قابل تست باشند؛
/// در اپ واقعی: onlineGuide = HttpAiGuideClient و
/// onlineConfigured = onlineGuide.isConfigured (اعتبارسنجی HTTPS داخل آن).
Future<GuideReply> resolveGuideReply({
  required GuideEngine localGuide,
  required GuideEngine? onlineGuide,
  required bool onlineEnabled,
  required bool onlineConfigured,
  required GuideQuery query,
}) async {
  final online = onlineGuide;
  if (onlineEnabled && onlineConfigured && online != null) {
    try {
      return await online.respond(query);
    } on GuideFormatException {
      return const GuideReply(
        message: GuideMessages.invalidAiOutput,
        action: GuideAction.showHint,
        source: 'local',
      );
    } catch (_) {
      return const GuideReply(
        message: GuideMessages.offline,
        action: GuideAction.showHint,
        source: 'local',
      );
    }
  }
  return localGuide.respond(query);
}
