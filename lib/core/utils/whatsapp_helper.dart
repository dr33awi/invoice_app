import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

/// مساعد لفتح محادثات الواتساب
class WhatsAppHelper {
  /// تنظيف رقم الهاتف من الرموز والمسافات
  static String _cleanPhoneNumber(String phoneNumber) {
    String cleanPhone = phoneNumber
        .replaceAll('+', '')
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .replaceAll('(', '')
        .replaceAll(')', '');

    // التأكد من وجود كود الدولة
    if (!cleanPhone.startsWith('963') && !cleanPhone.startsWith('00963')) {
      cleanPhone = '963$cleanPhone';
    }

    // إزالة 00 في البداية
    if (cleanPhone.startsWith('00')) {
      cleanPhone = cleanPhone.substring(2);
    }

    return cleanPhone;
  }

  /// فتح محادثة واتساب مع رقم معين
  ///
  /// [phoneNumber] - رقم الهاتف مع كود الدولة (مثال: +963912345678 أو 963912345678)
  /// [message] - رسالة اختيارية مُعدة مسبقاً
  static Future<bool> openChat({
    required String phoneNumber,
    String? message,
  }) async {
    // تنظيف رقم الهاتف
    final cleanPhone = _cleanPhoneNumber(phoneNumber);

    // بناء رابط الواتساب
    String whatsappUrl = 'https://wa.me/$cleanPhone';

    // إضافة الرسالة إذا كانت موجودة
    if (message != null && message.isNotEmpty) {
      final encodedMessage = Uri.encodeComponent(message);
      whatsappUrl += '?text=$encodedMessage';
    }

    final uri = Uri.parse(whatsappUrl);

    // محاولة فتح الرابط
    try {
      // محاولة الفتح مباشرة
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        return true;
      }

      // محاولة بديلة: فتح في المتصفح
      return await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
    } catch (e) {
      // محاولة أخيرة: استخدام URI مباشر للواتساب
      try {
        final whatsappUri = Uri.parse(
            'whatsapp://send?phone=$cleanPhone${message != null && message.isNotEmpty ? '&text=${Uri.encodeComponent(message)}' : ''}');
        return await launchUrl(whatsappUri,
            mode: LaunchMode.externalApplication);
      } catch (e) {
        return false;
      }
    }
  }

  /// إنشاء رسالة فاتورة جاهزة
  static String createInvoiceMessage({
    required String invoiceNumber,
    required String customerName,
    required double totalAmount,
    required String currency,
    double? totalSYP,
    List<Map<String, dynamic>>? items,
    String? invoiceDate,
    double? paidAmount,
    double? dueAmount,
    String? companyPhone,
    String? websiteLink,
  }) {
    final syp = totalSYP != null
        ? '\n• الإجمالي بالسورية: ${totalSYP.toStringAsFixed(0)} ل.س'
        : '';

    final dateStr = invoiceDate != null ? '\n• التاريخ: $invoiceDate' : '';

    final paidStr = paidAmount != null && paidAmount > 0
        ? '\n• العربون المدفوع: \$${paidAmount.toStringAsFixed(2)}'
        : '';

    final dueStr = dueAmount != null && dueAmount > 0
        ? '\n• المستحق: \$${dueAmount.toStringAsFixed(2)}'
        : '';

    final itemsCount = items?.length ?? 0;
    final itemsCountStr = itemsCount > 0 ? '\n• عدد الأصناف: $itemsCount' : '';

    // إنشاء قائمة المنتجات
    String itemsList = '';
    if (items != null && items.isNotEmpty) {
      itemsList = '\n\nالمنتجات:📦\n━━━━━━━━━━━━━━━━\n';
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final name = item['name'] ?? '';
        final size = item['size'] ?? '';
        final packagesCount = item['packagesCount'] ?? 0;
        final quantity = item['quantity'] ?? 0;
        final price = item['price'] ?? 0.0;

        // اسم المنتج
        itemsList += '🔹 $name\n';

        // المقاس
        if (size.isNotEmpty) {
          itemsList += '   • المقاس: $size\n';
        }

        // الطرود
        itemsList += '   • الطرود: $packagesCount\n';

        // الكمية
        itemsList += '   • الكمية: $quantity\n';

        // السعر
        itemsList += '   • السعر: \$${price.toStringAsFixed(2)}\n';

        // فاصل بين المنتجات
        if (i < items.length - 1) {
          itemsList += '\n';
        }
      }
    }

    // إضافة رابط الموقع إذا كان موجوداً
    String contactInfo = '';
    if (websiteLink != null && websiteLink.isNotEmpty) {
      contactInfo = '\n\n🌐 تصفح منتجاتنا:\n$websiteLink';
    }

    return '''
مرحباً $customerName،

تفاصيل الفاتورة:
• رقم الفاتورة: $invoiceNumber$dateStr$itemsCountStr
• الإجمالي: \$$totalAmount $currency$syp$paidStr$dueStr$itemsList

للاستفسارات، نحن في خدمتك دائماً.$contactInfo
نشكرك على تعاملك معنا
مع تحياتنا
''';
  }
}
