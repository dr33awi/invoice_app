import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

import '../../data/models/invoice_model.dart';

/// PDF Invoice Service with Arabic RTL Support
/// خدمة إنشاء فواتير PDF مع دعم اللغة العربية و RTL
class PdfService {
  static pw.Font? _arabicFont;
  static pw.Font? _arabicFontBold;
  static pw.Font? _monoFont;

  /// تحميل الخطوط العربية
  static Future<void> _loadFonts() async {
    if (_arabicFont != null) return;

    try {
      // تحميل خط Cairo للعربية
      final arabicFontData =
          await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      _arabicFont = pw.Font.ttf(arabicFontData);

      final arabicBoldData =
          await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      _arabicFontBold = pw.Font.ttf(arabicBoldData);

      final monoData =
          await rootBundle.load('assets/fonts/IBMPlexMono-Medium.ttf');
      _monoFont = pw.Font.ttf(monoData);
    } catch (e) {
      print('Error loading fonts: $e');
      // استخدام خطوط بديلة
      _arabicFont = pw.Font.helvetica();
      _arabicFontBold = pw.Font.helveticaBold();
      _monoFont = pw.Font.courier();
    }
  }

  /// إنشاء فاتورة PDF
  static Future<Uint8List> generateInvoice(InvoiceModel invoice) async {
    await _loadFonts();

    final pdf = pw.Document();

    // الألوان
    final primaryColor = PdfColor.fromHex('#2563EB');
    final tealColor = PdfColor.fromHex('#0D9488');
    final darkColor = PdfColor.fromHex('#1E293B');
    final grayColor = PdfColor.fromHex('#64748B');
    final lightGray = PdfColor.fromHex('#F1F5F9');
    final borderColor = PdfColor.fromHex('#E2E8F0');
    final errorColor = PdfColor.fromHex('#DC2626');
    final warningColor = PdfColor.fromHex('#F59E0B');

    // الأنماط
    final headingStyle = pw.TextStyle(
      font: _arabicFontBold,
      fontSize: 14,
      color: darkColor,
    );

    final bodyStyle = pw.TextStyle(
      font: _arabicFont,
      fontSize: 11,
      color: darkColor,
    );

    final smallStyle = pw.TextStyle(
      font: _arabicFont,
      fontSize: 9,
      color: grayColor,
    );

    final monoStyle = pw.TextStyle(
      font: _monoFont,
      fontSize: 11,
      color: darkColor,
    );

    final monoBoldStyle = pw.TextStyle(
      font: _monoFont,
      fontSize: 14,
      color: primaryColor,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ═══════════════════════════════════════════════════════════
              // HEADER - رأس الفاتورة
              // ═══════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // معلومات الشركة
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'فاتورة مبيعات',
                            style: pw.TextStyle(
                              font: _arabicFontBold,
                              fontSize: 28,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'نظام فواتير الأحذية',
                            style: pw.TextStyle(
                              font: _arabicFont,
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // رقم الفاتورة
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'رقم الفاتورة',
                            style: pw.TextStyle(
                              font: _arabicFont,
                              fontSize: 10,
                              color: grayColor,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            invoice.invoiceNumber,
                            style: pw.TextStyle(
                              font: _monoFont,
                              fontSize: 14,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ═══════════════════════════════════════════════════════════
              // معلومات العميل والتاريخ
              // ═══════════════════════════════════════════════════════════
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // معلومات العميل
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 8,
                                height: 8,
                                decoration: pw.BoxDecoration(
                                  color: tealColor,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Text('معلومات العميل', style: smallStyle),
                            ],
                          ),
                          pw.SizedBox(height: 12),
                          pw.Text(invoice.customerName, style: headingStyle),
                          if (invoice.customerPhone != null) ...[
                            pw.SizedBox(height: 6),
                            pw.Text(
                              invoice.customerPhone!,
                              style: bodyStyle.copyWith(color: grayColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // معلومات الفاتورة
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 8,
                                height: 8,
                                decoration: pw.BoxDecoration(
                                  color: primaryColor,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Text('تفاصيل الفاتورة', style: smallStyle),
                            ],
                          ),
                          pw.SizedBox(height: 12),
                          _buildInfoRow(
                            'التاريخ',
                            DateFormat('yyyy/MM/dd').format(invoice.date),
                            bodyStyle,
                            monoStyle,
                          ),
                          pw.SizedBox(height: 6),
                          _buildInfoRow(
                            'الوقت',
                            DateFormat('hh:mm a', 'ar').format(invoice.date),
                            bodyStyle,
                            monoStyle,
                          ),
                          pw.SizedBox(height: 6),
                          _buildInfoRow(
                            'الحالة',
                            'مكتملة',
                            bodyStyle,
                            bodyStyle.copyWith(color: tealColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // ═══════════════════════════════════════════════════════════
              // جدول المنتجات
              // ═══════════════════════════════════════════════════════════
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    // رأس الجدول
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: pw.BoxDecoration(
                        color: lightGray,
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(8),
                          topRight: pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text('المنتج', style: headingStyle),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              'الكمية',
                              style: headingStyle,
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              'السعر',
                              style: headingStyle,
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              'الإجمالي',
                              style: headingStyle,
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // صفوف المنتجات
                    ...invoice.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isLast = index == invoice.items.length - 1;

                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: pw.BoxDecoration(
                          border: isLast
                              ? null
                              : pw.Border(
                                  bottom: pw.BorderSide(color: borderColor),
                                ),
                        ),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // معلومات المنتج
                            pw.Expanded(
                              flex: 3,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(item.productName, style: bodyStyle),
                                  pw.SizedBox(height: 4),
                                  pw.Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (item.brand.isNotEmpty)
                                        _buildTag(item.brand, tealColor),
                                      _buildTag(
                                          'مقاس: ${item.size}', grayColor),
                                      _buildTag('${item.packagesCount} طرد',
                                          grayColor),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // الكمية
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                '${item.quantity} جوز',
                                style: bodyStyle,
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            // السعر
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                '\$${item.unitPrice.toStringAsFixed(2)}',
                                style: monoStyle,
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            // الإجمالي
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                '\$${item.total.toStringAsFixed(2)}',
                                style: monoStyle.copyWith(
                                  color: primaryColor,
                                ),
                                textAlign: pw.TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ═══════════════════════════════════════════════════════════
              // الإجماليات والملاحظات
              // ═══════════════════════════════════════════════════════════
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ملاحظات
                  pw.Expanded(
                    child: invoice.notes != null && invoice.notes!.isNotEmpty
                        ? pw.Container(
                            padding: const pw.EdgeInsets.all(16),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('#FEF3C7'),
                              borderRadius: pw.BorderRadius.circular(8),
                              border: pw.Border.all(
                                color: warningColor,
                                width: 0.5,
                              ),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'ملاحظات',
                                  style: smallStyle.copyWith(
                                    color: PdfColor.fromHex('#92400E'),
                                  ),
                                ),
                                pw.SizedBox(height: 8),
                                pw.Text(
                                  invoice.notes!,
                                  style: bodyStyle.copyWith(
                                    color: PdfColor.fromHex('#92400E'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : pw.Container(),
                  ),
                  pw.SizedBox(width: 16),
                  // الإجماليات
                  pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderColor),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        _buildTotalRow(
                          'المجموع الفرعي',
                          '\$${invoice.subtotal.toStringAsFixed(2)}',
                          bodyStyle,
                          monoStyle,
                        ),
                        if (invoice.discount > 0) ...[
                          pw.SizedBox(height: 8),
                          _buildTotalRow(
                            'الخصم',
                            '-\$${invoice.discount.toStringAsFixed(2)}',
                            bodyStyle,
                            monoStyle.copyWith(color: errorColor),
                          ),
                        ],
                        pw.SizedBox(height: 8),
                        pw.Divider(color: borderColor),
                        pw.SizedBox(height: 8),
                        // الإجمالي بالدولار
                        pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#EFF6FF'),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('الإجمالي (USD)', style: headingStyle),
                              pw.Text(
                                '\$${invoice.totalUSD.toStringAsFixed(2)}',
                                style: monoBoldStyle,
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        // الإجمالي بالليرة
                        pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F0FDFA'),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('الإجمالي (SYP)', style: headingStyle),
                              pw.Text(
                                _formatSYP(invoice.totalSYP),
                                style: monoBoldStyle.copyWith(color: tealColor),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        // سعر الصرف
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: pw.BoxDecoration(
                            color: lightGray,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'سعر الصرف: ${NumberFormat('#,###').format(invoice.exchangeRate)} ل.س',
                            style: smallStyle,
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // ═══════════════════════════════════════════════════════════
              // FOOTER - تذييل الصفحة
              // ═══════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 16),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: borderColor),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'شكراً لتعاملكم معنا',
                      style: bodyStyle.copyWith(color: grayColor),
                    ),
                    pw.Text(
                      'تم الإنشاء: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
                      style: smallStyle,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// بناء صف معلومات
  static pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: labelStyle),
        pw.Text(value, style: valueStyle),
      ],
    );
  }

  /// بناء صف إجمالي
  static pw.Widget _buildTotalRow(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: labelStyle),
        pw.Text(value, style: valueStyle),
      ],
    );
  }

  /// بناء وسم (Tag)
  static pw.Widget _buildTag(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.5),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: _arabicFont,
          fontSize: 8,
          color: color,
        ),
      ),
    );
  }

  /// تنسيق الليرة السورية
  static String _formatSYP(double amount) {
    final formatter = NumberFormat('#,###', 'ar');
    return '${formatter.format(amount.round())} ل.س';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تقرير فواتير متعددة
  // ═══════════════════════════════════════════════════════════════════════════

  /// إنشاء تقرير فواتير متعددة
  static Future<Uint8List> generateInvoicesReport(
    List<InvoiceModel> invoices, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _loadFonts();

    final pdf = pw.Document();
    final primaryColor = PdfColor.fromHex('#2563EB');
    final tealColor = PdfColor.fromHex('#0D9488');
    final darkColor = PdfColor.fromHex('#1E293B');
    final grayColor = PdfColor.fromHex('#64748B');
    final lightGray = PdfColor.fromHex('#F1F5F9');
    final borderColor = PdfColor.fromHex('#E2E8F0');

    // حساب الإجماليات
    final totalUSD = invoices.fold<double>(0, (sum, inv) => sum + inv.totalUSD);
    final totalSYP = invoices.fold<double>(0, (sum, inv) => sum + inv.totalSYP);
    final totalItems =
        invoices.fold<int>(0, (sum, inv) => sum + inv.items.length);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'تقرير الفواتير',
                style: pw.TextStyle(
                  font: _arabicFontBold,
                  fontSize: 20,
                  color: darkColor,
                ),
              ),
              pw.Text(
                'صفحة ${context.pageNumber} من ${context.pagesCount}',
                style: pw.TextStyle(
                  font: _arabicFont,
                  fontSize: 10,
                  color: grayColor,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 20),
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: borderColor)),
          ),
          child: pw.Text(
            'تم الإنشاء: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
            style:
                pw.TextStyle(font: _arabicFont, fontSize: 9, color: grayColor),
            textAlign: pw.TextAlign.center,
          ),
        ),
        build: (context) => [
          // ملخص التقرير
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: lightGray,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                    'عدد الفواتير', '${invoices.length}', primaryColor),
                _buildStatCard('إجمالي USD', '\$${totalUSD.toStringAsFixed(2)}',
                    tealColor),
                _buildStatCard('إجمالي SYP', _formatSYP(totalSYP),
                    PdfColor.fromHex('#D97706')),
                _buildStatCard(
                    'عدد الأصناف', '$totalItems', PdfColor.fromHex('#7C3AED')),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // جدول الفواتير
          pw.Table(
            border: pw.TableBorder.all(color: borderColor),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              // رأس الجدول
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: [
                  _buildTableHeader('رقم الفاتورة'),
                  _buildTableHeader('العميل'),
                  _buildTableHeader('التاريخ'),
                  _buildTableHeader('الأصناف'),
                  _buildTableHeader('الإجمالي'),
                ],
              ),
              // صفوف البيانات
              ...invoices.map((invoice) => pw.TableRow(
                    children: [
                      _buildTableCell(invoice.invoiceNumber, isMono: true),
                      _buildTableCell(invoice.customerName),
                      _buildTableCell(
                        DateFormat('yyyy/MM/dd').format(invoice.date),
                        isMono: true,
                      ),
                      _buildTableCell(
                        '${invoice.items.length}',
                        textAlign: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        '\$${invoice.totalUSD.toStringAsFixed(2)}',
                        isMono: true,
                        color: primaryColor,
                      ),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// بناء بطاقة إحصائية
  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: _arabicFont,
            fontSize: 10,
            color: PdfColor.fromHex('#64748B'),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: _monoFont,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  /// بناء رأس جدول
  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: _arabicFontBold,
          fontSize: 11,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// بناء خلية جدول
  static pw.Widget _buildTableCell(
    String text, {
    bool isMono = false,
    PdfColor? color,
    pw.TextAlign textAlign = pw.TextAlign.right,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isMono ? _monoFont : _arabicFont,
          fontSize: 10,
          color: color ?? PdfColor.fromHex('#1E293B'),
        ),
        textAlign: textAlign,
      ),
    );
  }
}
