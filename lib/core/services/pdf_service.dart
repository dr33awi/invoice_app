import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../data/models/invoice_model.dart';

/// PDF Invoice Service with Arabic RTL Support
class PdfService {
  /// تحميل بيانات الخط بشكل آمن - إنشاء نسخة جديدة كل مرة
  static Future<pw.Font> _loadFont(String path, pw.Font fallback) async {
    try {
      final data = await rootBundle.load(path);
      // إنشاء نسخة جديدة تماماً من البيانات
      final bytes = Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      return pw.Font.ttf(ByteData.view(bytes.buffer));
    } catch (e) {
      print('❌ Failed to load font $path: $e');
      return fallback;
    }
  }

  /// إنشاء فاتورة PDF - تصميم محاسبي احترافي
  static Future<Uint8List> generateInvoice(InvoiceModel invoice) async {
    print('🔵 Loading fonts...');

    // استخدام PdfGoogleFonts لتحميل خطوط عربية متوافقة
    pw.Font arabicFont;
    pw.Font arabicFontBold;

    try {
      arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
      print('✅ Arabic Regular loaded from Google Fonts');
    } catch (e) {
      print('⚠️ Google Fonts failed, using fallback: $e');
      arabicFont = pw.Font.helvetica();
    }

    try {
      arabicFontBold = await PdfGoogleFonts.notoSansArabicBold();
      print('✅ Arabic Bold loaded from Google Fonts');
    } catch (e) {
      print('⚠️ Google Fonts Bold failed, using fallback: $e');
      arabicFontBold = pw.Font.helveticaBold();
    }

    final monoFont = pw.Font.courier();
    print('✅ Fonts loading completed');

    final pdf = pw.Document();

    // الألوان حسب المواصفات
    final slate800 = PdfColor.fromHex('#1E293B'); // Header background
    final slate100 = PdfColor.fromHex('#F1F5F9'); // Table header
    final borderColor = PdfColor.fromHex('#E2E8F0'); // Borders
    final greenColor = PdfColor.fromHex('#15803D'); // Total highlight
    final darkText = PdfColor.fromHex('#1E293B');
    final grayText = PdfColor.fromHex('#64748B');

    // قائمة الخطوط البديلة
    final fallback = <pw.Font>[arabicFont, arabicFontBold, monoFont];

    // تنسيق بالأرقام الإنجليزية
    final dateFmt = DateFormat('yyyy-MM-dd', 'en');
    final numFmt = NumberFormat('#,###', 'en');
    final decimalFmt = NumberFormat('#,##0.00', 'en');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(24), // 24px margins
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ═══════════════════════════════════════════════════════════════
              // HEADER - Slate 800 Background, White Text, No Shadows
              // ═══════════════════════════════════════════════════════════════
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: pw.BoxDecoration(
                  color: slate800,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // معلومات الشركة - يمين (RTL)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'شركة المعيار',
                          style: pw.TextStyle(
                            font: arabicFontBold,
                            fontFallback: fallback,
                            fontSize: 18,
                            color: PdfColors.white,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'بيع الأحذية بالجملة',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontFallback: fallback,
                            fontSize: 10,
                            color: PdfColor.fromHex('#94A3B8'),
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'هاتف: 09xxxxxxxx',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontFallback: fallback,
                            fontSize: 10,
                            color: PdfColor.fromHex('#CBD5E1'),
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          'العنوان: سوريا',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontFallback: fallback,
                            fontSize: 10,
                            color: PdfColor.fromHex('#CBD5E1'),
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                    // INVOICE + معلومات الفاتورة - يسار (RTL)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            font: arabicFontBold,
                            fontFallback: fallback,
                            fontSize: 18,
                            color: PdfColors.white,
                            letterSpacing: 2,
                          ),
                          textDirection: pw.TextDirection.ltr,
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          '${invoice.invoiceNumber} :رقم الفاتورة',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontFallback: fallback,
                            fontSize: 10,
                            color: PdfColor.fromHex('#CBD5E1'),
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          '${dateFmt.format(invoice.date)} :تاريخ الفاتورة',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontFallback: fallback,
                            fontSize: 10,
                            color: PdfColor.fromHex('#CBD5E1'),
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.Text(
                          'USD :العملة الأساسية',
                          style: pw.TextStyle(
                            font: arabicFont,
                            fontFallback: fallback,
                            fontSize: 10,
                            color: PdfColor.fromHex('#CBD5E1'),
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════════
              // 👤 معلومات العميل - فواصل خفيفة بدون صناديق
              // ═══════════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'معلومات العميل',
                      style: pw.TextStyle(
                        font: arabicFontBold,
                        fontFallback: fallback,
                        fontSize: 12,
                        color: darkText,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 12),
                    // صف البيانات
                    pw.Table(
                      border: pw.TableBorder(
                        horizontalInside:
                            pw.BorderSide(color: borderColor, width: 0.5),
                      ),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1),
                        1: const pw.FlexColumnWidth(2),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding:
                                  const pw.EdgeInsets.symmetric(vertical: 8),
                              child: pw.Text(
                                'اسم العميل',
                                style: pw.TextStyle(
                                  font: arabicFont,
                                  fontFallback: fallback,
                                  fontSize: 10,
                                  color: grayText,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding:
                                  const pw.EdgeInsets.symmetric(vertical: 8),
                              child: pw.Text(
                                invoice.customerName,
                                style: pw.TextStyle(
                                  font: arabicFontBold,
                                  fontFallback: fallback,
                                  fontSize: 11,
                                  color: darkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding:
                                  const pw.EdgeInsets.symmetric(vertical: 8),
                              child: pw.Text(
                                'تاريخ الفاتورة',
                                style: pw.TextStyle(
                                  font: arabicFont,
                                  fontFallback: fallback,
                                  fontSize: 10,
                                  color: grayText,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding:
                                  const pw.EdgeInsets.symmetric(vertical: 8),
                              child: pw.Text(
                                dateFmt.format(invoice.date),
                                style: pw.TextStyle(
                                  font: monoFont,
                                  fontFallback: fallback,
                                  fontSize: 11,
                                  color: darkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding:
                                  const pw.EdgeInsets.symmetric(vertical: 8),
                              child: pw.Text(
                                'سعر الصرف',
                                style: pw.TextStyle(
                                  font: arabicFont,
                                  fontFallback: fallback,
                                  fontSize: 10,
                                  color: grayText,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding:
                                  const pw.EdgeInsets.symmetric(vertical: 8),
                              child: pw.Text(
                                '1 USD = ${numFmt.format(invoice.exchangeRate)} SYP',
                                style: pw.TextStyle(
                                  font: monoFont,
                                  fontFallback: fallback,
                                  fontSize: 11,
                                  color: darkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════════
              // 📦 تفاصيل المنتجات - جدول محاسبي كثيف
              // ═══════════════════════════════════════════════════════════════
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'تفاصيل المنتجات',
                  style: pw.TextStyle(
                    font: arabicFontBold,
                    fontFallback: fallback,
                    fontSize: 12,
                    color: darkText,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
              pw.SizedBox(height: 8),

              // جدول المنتجات
              pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 1),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30), // #
                  1: const pw.FlexColumnWidth(3), // اسم المنتج
                  2: const pw.FixedColumnWidth(50), // المقاس
                  3: const pw.FixedColumnWidth(50), // الكمية
                  4: const pw.FixedColumnWidth(80), // سعر الوحدة
                  5: const pw.FixedColumnWidth(80), // الإجمالي
                },
                children: [
                  // Header Row - Slate 100
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: slate100),
                    children: [
                      _buildTableHeader(
                          '#', arabicFontBold, fallback, pw.TextAlign.center),
                      _buildTableHeader('اسم المنتج', arabicFontBold, fallback,
                          pw.TextAlign.right),
                      _buildTableHeader('المقاس', arabicFontBold, fallback,
                          pw.TextAlign.center),
                      _buildTableHeader('الكمية', arabicFontBold, fallback,
                          pw.TextAlign.center),
                      _buildTableHeader('سعر الوحدة (USD)', arabicFontBold,
                          fallback, pw.TextAlign.left),
                      _buildTableHeader('الإجمالي (USD)', arabicFontBold,
                          fallback, pw.TextAlign.left),
                    ],
                  ),
                  // Data Rows
                  ...invoice.items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        _buildTableCell('${i + 1}', monoFont, fallback,
                            pw.TextAlign.center),
                        _buildTableCellArabic(
                            item.productName, arabicFont, fallback),
                        _buildTableCell('${item.size}', monoFont, fallback,
                            pw.TextAlign.center),
                        _buildTableCell('${item.quantity}', monoFont, fallback,
                            pw.TextAlign.center),
                        _buildTableCell(decimalFmt.format(item.unitPrice),
                            monoFont, fallback, pw.TextAlign.left),
                        _buildTableCell(decimalFmt.format(item.total), monoFont,
                            fallback, pw.TextAlign.left),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════════
              // 💰 الملخص المالي
              // ═══════════════════════════════════════════════════════════════
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // الملخص المالي على اليمين (RTL)
                  pw.Container(
                    width: 250,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'الملخص المالي',
                          style: pw.TextStyle(
                            font: arabicFontBold,
                            fontFallback: fallback,
                            fontSize: 12,
                            color: darkText,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.SizedBox(height: 8),
                        pw.Table(
                          border:
                              pw.TableBorder.all(color: borderColor, width: 1),
                          columnWidths: {
                            0: const pw.FlexColumnWidth(1),
                            1: const pw.FlexColumnWidth(1),
                          },
                          children: [
                            // المجموع الفرعي
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(10),
                                  child: pw.Text(
                                    'المجموع الفرعي (USD)',
                                    style: pw.TextStyle(
                                      font: arabicFont,
                                      fontFallback: fallback,
                                      fontSize: 10,
                                      color: grayText,
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(10),
                                  child: pw.Text(
                                    decimalFmt.format(invoice.subtotal),
                                    style: pw.TextStyle(
                                      font: monoFont,
                                      fontFallback: fallback,
                                      fontSize: 11,
                                      color: darkText,
                                    ),
                                    textAlign: pw.TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                            // سعر الصرف
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(10),
                                  child: pw.Text(
                                    'سعر الصرف',
                                    style: pw.TextStyle(
                                      font: arabicFont,
                                      fontFallback: fallback,
                                      fontSize: 10,
                                      color: grayText,
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(10),
                                  child: pw.Text(
                                    numFmt.format(invoice.exchangeRate),
                                    style: pw.TextStyle(
                                      font: monoFont,
                                      fontFallback: fallback,
                                      fontSize: 11,
                                      color: darkText,
                                    ),
                                    textAlign: pw.TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                            // الإجمالي بالليرة - Green highlight
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(10),
                                  child: pw.Text(
                                    'الإجمالي بالليرة (SYP)',
                                    style: pw.TextStyle(
                                      font: arabicFontBold,
                                      fontFallback: fallback,
                                      fontSize: 11,
                                      color: greenColor,
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(10),
                                  child: pw.Text(
                                    numFmt.format(invoice.totalSYP.round()),
                                    style: pw.TextStyle(
                                      font: monoFont,
                                      fontFallback: fallback,
                                      fontSize: 15,
                                      color: greenColor,
                                    ),
                                    textAlign: pw.TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // مساحة فارغة على اليسار (RTL)
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // ═══════════════════════════════════════════════════════════════
              // ملاحظات
              // ═══════════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                      top: pw.BorderSide(color: borderColor, width: 1)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'ملاحظات',
                      style: pw.TextStyle(
                        font: arabicFontBold,
                        fontFallback: fallback,
                        fontSize: 11,
                        color: darkText,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 10),
                    if (invoice.notes != null && invoice.notes!.isNotEmpty)
                      pw.Text(
                        invoice.notes!,
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontFallback: fallback,
                          fontSize: 10,
                          color: grayText,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    pw.Text(
                      'هذه الفاتورة صادرة عن شركة المعيار',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: fallback,
                        fontSize: 10,
                        color: grayText,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'تم إنشاء الفاتورة عبر نظام محاسبي إلكتروني',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: fallback,
                        fontSize: 10,
                        color: grayText,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 20),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'التوقيع: ______________________',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontFallback: fallback,
                          fontSize: 10,
                          color: darkText,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // ═══════════════════════════════════════════════════════════════
              // FOOTER
              // ═══════════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 10),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                      top: pw.BorderSide(color: borderColor, width: 1)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${dateFmt.format(DateTime.now())} - شركة المعيار',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: fallback,
                        fontSize: 9,
                        color: grayText,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      'شكراً لتعاملكم معنا',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontFallback: fallback,
                        fontSize: 9,
                        color: grayText,
                      ),
                      textDirection: pw.TextDirection.rtl,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Table Helper Widgets
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildTableHeader(
    String text,
    pw.Font font,
    List<pw.Font> fallback,
    pw.TextAlign align,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontFallback: fallback,
          fontSize: 10,
          color: PdfColor.fromHex('#1E293B'),
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font,
    List<pw.Font> fallback,
    pw.TextAlign align,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontFallback: fallback,
          fontSize: 10,
          color: PdfColor.fromHex('#1E293B'),
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTableCellArabic(
    String text,
    pw.Font font,
    List<pw.Font> fallback,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontFallback: fallback,
          fontSize: 10,
          color: PdfColor.fromHex('#1E293B'),
        ),
        textAlign: pw.TextAlign.right,
      ),
    );
  }

  // تقرير الفواتير
  static Future<Uint8List> generateInvoicesReport(
    List<InvoiceModel> invoices, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // تحميل الخطوط باستخدام Google Fonts
    pw.Font arabicFont;
    pw.Font arabicFontBold;

    try {
      arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
    } catch (e) {
      arabicFont = pw.Font.helvetica();
    }

    try {
      arabicFontBold = await PdfGoogleFonts.notoSansArabicBold();
    } catch (e) {
      arabicFontBold = pw.Font.helveticaBold();
    }

    final monoFont = pw.Font.courier();
    final fallback = <pw.Font>[arabicFont, arabicFontBold, monoFont];

    final pdf = pw.Document();
    final primaryColor = PdfColor.fromHex('#2563EB');
    final tealColor = PdfColor.fromHex('#0D9488');
    final darkColor = PdfColor.fromHex('#1E293B');
    final grayColor = PdfColor.fromHex('#64748B');
    final lightGray = PdfColor.fromHex('#F1F5F9');
    final borderColor = PdfColor.fromHex('#E2E8F0');

    final dateFmt = DateFormat('yyyy/MM/dd', 'en');
    final numFmt = NumberFormat('#,###', 'en');

    final totalUSD = invoices.fold<double>(0, (s, i) => s + i.totalUSD);
    final totalSYP = invoices.fold<double>(0, (s, i) => s + i.totalSYP);
    final totalItems = invoices.fold<int>(0, (s, i) => s + i.items.length);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('تقرير الفواتير',
                  style: pw.TextStyle(
                      font: arabicFontBold,
                      fontFallback: fallback,
                      fontSize: 20,
                      color: darkColor)),
              pw.Text('صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
                  style: pw.TextStyle(
                      font: arabicFont,
                      fontFallback: fallback,
                      fontSize: 10,
                      color: grayColor)),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 20),
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderColor))),
          child: pw.Text(
            'تم الإنشاء: ${DateFormat('yyyy/MM/dd HH:mm', 'en').format(DateTime.now())}',
            style: pw.TextStyle(
                font: arabicFont,
                fontFallback: fallback,
                fontSize: 9,
                color: grayColor),
            textAlign: pw.TextAlign.center,
          ),
        ),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
                color: lightGray, borderRadius: pw.BorderRadius.circular(12)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _statCard('عدد الفواتير', '${invoices.length}', primaryColor,
                    fallback, arabicFont, monoFont),
                _statCard('إجمالي USD', '\$${totalUSD.toStringAsFixed(2)}',
                    tealColor, fallback, arabicFont, monoFont),
                _statCard(
                    'إجمالي SYP',
                    '${numFmt.format(totalSYP.round())} ل.س',
                    PdfColor.fromHex('#D97706'),
                    fallback,
                    arabicFont,
                    monoFont),
                _statCard(
                    'عدد الأصناف',
                    '$totalItems',
                    PdfColor.fromHex('#7C3AED'),
                    fallback,
                    arabicFont,
                    monoFont),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
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
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: [
                  _tableHeader('رقم الفاتورة', fallback, arabicFontBold),
                  _tableHeader('العميل', fallback, arabicFontBold),
                  _tableHeader('التاريخ', fallback, arabicFontBold),
                  _tableHeader('الأصناف', fallback, arabicFontBold),
                  _tableHeader('الإجمالي', fallback, arabicFontBold),
                ],
              ),
              ...invoices.map((inv) => pw.TableRow(
                    children: [
                      _tableCell(
                          inv.invoiceNumber, fallback, monoFont, arabicFont,
                          isMono: true),
                      _tableCell(
                          inv.customerName, fallback, monoFont, arabicFont),
                      _tableCell(dateFmt.format(inv.date), fallback, monoFont,
                          arabicFont,
                          isMono: true),
                      _tableCell(
                          '${inv.items.length}', fallback, monoFont, arabicFont,
                          textAlign: pw.TextAlign.center),
                      _tableCell('\$${inv.totalUSD.toStringAsFixed(2)}',
                          fallback, monoFont, arabicFont,
                          isMono: true, color: primaryColor),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _statCard(String label, String value, PdfColor color,
      List<pw.Font> fallback, pw.Font arabicFont, pw.Font monoFont) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                font: arabicFont,
                fontFallback: fallback,
                fontSize: 10,
                color: PdfColor.fromHex('#64748B'))),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(
                font: monoFont,
                fontFallback: fallback,
                fontSize: 14,
                color: color)),
      ],
    );
  }

  static pw.Widget _tableHeader(
      String text, List<pw.Font> fallback, pw.Font arabicFontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(text,
          style: pw.TextStyle(
              font: arabicFontBold,
              fontFallback: fallback,
              fontSize: 11,
              color: PdfColors.white),
          textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _tableCell(
      String text, List<pw.Font> fallback, pw.Font monoFont, pw.Font arabicFont,
      {bool isMono = false,
      PdfColor? color,
      pw.TextAlign textAlign = pw.TextAlign.right}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(text,
          style: pw.TextStyle(
              font: isMono ? monoFont : arabicFont,
              fontFallback: fallback,
              fontSize: 10,
              color: color ?? PdfColor.fromHex('#1E293B')),
          textAlign: textAlign),
    );
  }
}
