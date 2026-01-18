import 'dart:typed_data';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../data/models/invoice_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// خدمة إنشاء فواتير PDF - مطابق لتصميم Canva بالضبط
/// ═══════════════════════════════════════════════════════════════════════════

class PdfService {
  // الألوان
  static final PdfColor _black = PdfColor.fromHex('#1A1A1A');
  static final PdfColor _yellow = PdfColor.fromHex('#F4C430');
  static final PdfColor _white = PdfColors.white;
  static final PdfColor _lightGray = PdfColor.fromHex('#F5F5F5');
  static final PdfColor _mediumGray = PdfColor.fromHex('#666666');
  static final PdfColor _borderGray = PdfColor.fromHex('#E0E0E0');
  static final PdfColor _yellowLight = PdfColor.fromHex('#FEF9E7');

  // الخطوط
  static pw.Font? _arabicRegular;
  static pw.Font? _arabicBold;
  static pw.Font? _mono;

  static Future<void> _loadFonts() async {
    if (_arabicRegular != null && _arabicBold != null && _mono != null) return;

    try {
      _arabicRegular = await PdfGoogleFonts.cairoRegular();
    } catch (e) {
      try {
        _arabicRegular = await PdfGoogleFonts.notoSansArabicRegular();
      } catch (e2) {
        _arabicRegular = pw.Font.helvetica();
      }
    }

    try {
      _arabicBold = await PdfGoogleFonts.cairoBold();
    } catch (e) {
      try {
        _arabicBold = await PdfGoogleFonts.notoSansArabicBold();
      } catch (e2) {
        _arabicBold = pw.Font.helveticaBold();
      }
    }

    _mono = pw.Font.courier();
  }

  static List<pw.Font> get _fontFallback =>
      [_arabicRegular!, _arabicBold!, _mono!];

  // ═══════════════════════════════════════════════════════════════════════════
  // إنشاء الفاتورة
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> generateInvoice(
    InvoiceModel invoice, {
    String companyName = 'شركة المعيار',
    String companySubtitle = 'للأحذية بالجملة',
    String? companyPhone,
    String companyAddress = 'سوريا',
    String returnPolicy =
        'الإستبدال والإسترجاع خلال فترة الـ 14 يوم من تاريخ أستلام السلعة .',
    double paidAmount = 0,
  }) async {
    await _loadFonts();

    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy/MM/dd', 'en');
    final decimalFormat = NumberFormat('#,##0.00', 'en');

    final totalAfterPaid = invoice.totalUSD - paidAmount + invoice.discount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Container(
            color: _white,
            child: pw.Column(
              children: [
                // ═══════════════════════════════════════════════════════════
                // الهيدر
                // ═══════════════════════════════════════════════════════════
                _buildHeader(
                  companyName: companyName,
                  companySubtitle: companySubtitle,
                  invoiceNumber: invoice.invoiceNumber,
                  invoiceDate: dateFormat.format(invoice.date),
                ),

                // ═══════════════════════════════════════════════════════════
                // معلومات العميل
                // ═══════════════════════════════════════════════════════════
                pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(40, 30, 40, 20),
                  child: _buildCustomerInfo(
                    customerName: invoice.customerName,
                    customerPhone: invoice.customerPhone,
                    customerAddress: companyAddress,
                    companyPhone: companyPhone,
                  ),
                ),

                // ═══════════════════════════════════════════════════════════
                // جدول المنتجات
                // ═══════════════════════════════════════════════════════════
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                  child: _buildItemsTable(
                    items: invoice.items,
                    decimalFormat: decimalFormat,
                  ),
                ),

                pw.SizedBox(height: 20),

                // ═══════════════════════════════════════════════════════════
                // الملخص والملاحظات
                // ═══════════════════════════════════════════════════════════
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                  child: _buildSummarySection(
                    subtotal: invoice.subtotal,
                    paidAmount: paidAmount,
                    discount: invoice.discount,
                    total: totalAfterPaid,
                    returnPolicy: returnPolicy,
                    notes: invoice.notes,
                    decimalFormat: decimalFormat,
                  ),
                ),

                pw.Spacer(),

                // ═══════════════════════════════════════════════════════════
                // الباركود
                // ═══════════════════════════════════════════════════════════
                _buildBarcode(invoice.invoiceNumber),

                pw.SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الهيدر - خلفية سوداء للشعار يسار + شريط ذهبي سفلي
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildHeader({
    required String companyName,
    required String companySubtitle,
    required String invoiceNumber,
    required String invoiceDate,
  }) {
    return pw.Container(
      height: 180,
      child: pw.Stack(
        children: [
          // خلفية بيضاء
          pw.Positioned.fill(child: pw.Container(color: _white)),

          // الخلفية السوداء للشعار - يسار (أكبر)
          pw.Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: pw.CustomPaint(
              size: const PdfPoint(320, 180),
              painter: (canvas, size) {
                // المستطيل الأسود القطري
                canvas
                  ..setFillColor(_black)
                  ..moveTo(0, 0)
                  ..lineTo(290, 0)
                  ..lineTo(230, size.y)
                  ..lineTo(0, size.y)
                  ..closePath()
                  ..fillPath();
              },
            ),
          ),

          // الشعار واسم الشركة - على الخلفية السوداء
          pw.Positioned(
            left: 25,
            top: 35,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // أيقونة الحذاء
                pw.Container(
                  width: 55,
                  height: 50,
                  child: pw.CustomPaint(
                    size: const PdfPoint(55, 50),
                    painter: (canvas, size) {
                      // رسم حذاء بلون أصفر
                      canvas
                        ..setStrokeColor(_yellow)
                        ..setLineWidth(2.5)
                        ..moveTo(5, 32)
                        ..lineTo(10, 15)
                        ..lineTo(28, 8)
                        ..lineTo(50, 15)
                        ..lineTo(50, 32)
                        ..lineTo(45, 38)
                        ..lineTo(5, 38)
                        ..closePath()
                        ..strokePath();
                    },
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        font: _arabicBold,
                        fontFallback: _fontFallback,
                        fontSize: 22,
                        color: _yellow,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      companySubtitle,
                      style: pw.TextStyle(
                        font: _arabicRegular,
                        fontFallback: _fontFallback,
                        fontSize: 11,
                        color: _white,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // عنوان الفاتورة - يمين
          pw.Positioned(
            right: 40,
            top: 30,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'فاتورة مبيعات',
                  style: pw.TextStyle(
                    font: _arabicBold,
                    fontFallback: _fontFallback,
                    fontSize: 28,
                    color: _black,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 12),
                _buildHeaderInfoRow('رقم الفاتورة', invoiceNumber),
                pw.SizedBox(height: 4),
                _buildHeaderInfoRow('تاريخ الفاتورة', invoiceDate),
                pw.SizedBox(height: 4),
                _buildHeaderInfoRow('العملة الأساسية', 'USD'),
              ],
            ),
          ),

          // الخط الأصفر السفلي
          pw.Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: pw.Container(height: 4, color: _yellow),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderInfoRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            font: _mono,
            fontFallback: _fontFallback,
            fontSize: 10,
            color: _mediumGray,
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          '$label :',
          style: pw.TextStyle(
            font: _arabicRegular,
            fontFallback: _fontFallback,
            fontSize: 10,
            color: _black,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // معلومات العميل - عمودين: يمين (معلومات العميل) ويسار (معلومات الشركة)
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildCustomerInfo({
    required String customerName,
    String? customerPhone,
    required String customerAddress,
    String? companyPhone,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // العمود الأيسر - معلومات الشركة
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRowLTR('رقم الهاتف', companyPhone ?? ''),
              pw.SizedBox(height: 6),
              _buildInfoRowLTR('العنوان', customerAddress),
            ],
          ),
        ),

        pw.SizedBox(width: 60),

        // العمود الأيمن - معلومات العميل
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildInfoRowRTL('اسم العميل', customerName),
              pw.SizedBox(height: 6),
              _buildInfoRowRTL('العنوان', ''),
              pw.SizedBox(height: 6),
              _buildInfoRowRTL('رقم الهاتف', customerPhone ?? ''),
            ],
          ),
        ),
      ],
    );
  }

  // صف معلومات - محاذاة يمين: التسمية ثم القيمة (للعميل)
  static pw.Widget _buildInfoRowRTL(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (value.isNotEmpty)
          pw.Text(
            value,
            style: pw.TextStyle(
              font: _arabicRegular,
              fontFallback: _fontFallback,
              fontSize: 11,
              color: _black,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        pw.SizedBox(width: 5),
        pw.Text(
          '$label :',
          style: pw.TextStyle(
            font: _arabicBold,
            fontFallback: _fontFallback,
            fontSize: 11,
            color: _black,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  // صف معلومات - محاذاة يسار: القيمة ثم التسمية (للشركة)
  static pw.Widget _buildInfoRowLTR(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (value.isNotEmpty)
          pw.Text(
            value,
            style: pw.TextStyle(
              font: _mono,
              fontFallback: _fontFallback,
              fontSize: 11,
              color: _black,
            ),
          ),
        pw.SizedBox(width: 5),
        pw.Text(
          '$label :',
          style: pw.TextStyle(
            font: _arabicBold,
            fontFallback: _fontFallback,
            fontSize: 11,
            color: _black,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // جدول المنتجات - RTL: الرقم يمين، الإجمالي يسار
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildItemsTable({
    required List<InvoiceItemModel> items,
    required NumberFormat decimalFormat,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      // ترتيب الأعمدة من اليمين لليسار
      columnWidths: {
        0: const pw.FixedColumnWidth(50), // اجمالي
        1: const pw.FixedColumnWidth(45), // الكمية
        2: const pw.FixedColumnWidth(60), // سعر الوحدة
        3: const pw.FixedColumnWidth(55), // المقاس
        4: const pw.FlexColumnWidth(2.5), // أسم المنتج
        5: const pw.FixedColumnWidth(40), // الرقم
      },
      children: [
        // رأس الجدول - أسود
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _black),
          children: [
            _tableHeader('اجمالي'),
            _tableHeader('الكمية'),
            _tableHeader('سعر الوحدة'),
            _tableHeader('المقاس'),
            _tableHeader('أسم المنتج'),
            _tableHeader('الرقم'),
          ],
        ),
        // صفوف البيانات
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? _white : _lightGray),
            children: [
              _tableCell('\$${decimalFormat.format(item.total)}'),
              _tableCell('${item.quantity}'),
              _tableCell('\$${decimalFormat.format(item.unitPrice)}'),
              _tableCell(item.size),
              _tableCell(item.productName, isArabic: true),
              _tableCell('${index + 1}'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: _arabicBold,
          fontFallback: _fontFallback,
          fontSize: 10,
          color: _white,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool isArabic = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isArabic ? _arabicRegular : _mono,
          fontFallback: _fontFallback,
          fontSize: 10,
          color: _black,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // قسم الملخص - الأرقام يسار، الملاحظات يمين
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildSummarySection({
    required double subtotal,
    required double paidAmount,
    required double discount,
    required double total,
    required String returnPolicy,
    String? notes,
    required NumberFormat decimalFormat,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // الملخص المالي - يسار
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // العربون المقبوض
              _buildSummaryRow(
                  'العربون المقبوض', '\$${decimalFormat.format(paidAmount)}'),
              pw.SizedBox(height: 12),

              // مربع الإجمالي الأصفر
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: _yellow,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      '\$${decimalFormat.format(total)}',
                      style: pw.TextStyle(
                        font: _arabicBold,
                        fontFallback: _fontFallback,
                        fontSize: 14,
                        color: _black,
                      ),
                    ),
                    pw.SizedBox(width: 30),
                    pw.Text(
                      'الاجمالي',
                      style: pw.TextStyle(
                        font: _arabicBold,
                        fontFallback: _fontFallback,
                        fontSize: 12,
                        color: _black,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(width: 40),

        // الملاحظات - يمين
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'ملاحظة:',
                style: pw.TextStyle(
                  font: _arabicBold,
                  fontFallback: _fontFallback,
                  fontSize: 11,
                  color: _black,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                returnPolicy,
                style: pw.TextStyle(
                  font: _arabicRegular,
                  fontFallback: _fontFallback,
                  fontSize: 10,
                  color: _mediumGray,
                ),
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.right,
              ),
              if (notes != null && notes.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  notes,
                  style: pw.TextStyle(
                    font: _arabicRegular,
                    fontFallback: _fontFallback,
                    fontSize: 10,
                    color: _mediumGray,
                  ),
                  textDirection: pw.TextDirection.rtl,
                  textAlign: pw.TextAlign.right,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            font: _mono,
            fontFallback: _fontFallback,
            fontSize: 11,
            color: _black,
          ),
        ),
        pw.SizedBox(width: 30),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: _arabicBold,
            fontFallback: _fontFallback,
            fontSize: 11,
            color: _black,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الباركود
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildBarcode(String invoiceNumber) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Container(
            width: 180,
            height: 50,
            child: pw.CustomPaint(
              size: const PdfPoint(180, 50),
              painter: (canvas, size) {
                final random = math.Random(invoiceNumber.hashCode);
                double x = 0;
                const barWidth = 2.0;
                const gap = 1.0;

                while (x < size.x) {
                  final width = (random.nextInt(3) + 1) * barWidth;
                  if (random.nextBool()) {
                    canvas
                      ..setFillColor(_black)
                      ..drawRect(x, 0, width, size.y)
                      ..fillPath();
                  }
                  x += width + gap;
                }
              },
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '4444444444444',
            style: pw.TextStyle(
              font: _mono,
              fontSize: 9,
              color: _mediumGray,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تقرير الفواتير
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> generateInvoicesReport(
    List<InvoiceModel> invoices, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _loadFonts();

    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy/MM/dd', 'en');
    final decimalFormat = NumberFormat('#,##0.00', 'en');

    final totalUSD = invoices.fold<double>(0, (s, i) => s + i.totalUSD);
    final totalItems = invoices.fold<int>(0, (s, i) => s + i.items.length);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(30),
        header: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _yellow, width: 4)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'صفحة ${ctx.pageNumber}/${ctx.pagesCount}',
                style: pw.TextStyle(
                    font: _arabicRegular,
                    fontFallback: _fontFallback,
                    fontSize: 10,
                    color: _mediumGray),
              ),
              pw.Text(
                'تقرير الفواتير',
                style: pw.TextStyle(
                    font: _arabicBold,
                    fontFallback: _fontFallback,
                    fontSize: 22,
                    color: _black),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _yellowLight,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _yellow),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _statCard('عدد الفواتير', '${invoices.length}'),
                _statCard(
                    'إجمالي المبيعات', '\$${decimalFormat.format(totalUSD)}'),
                _statCard('عدد الأصناف', '$totalItems'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Table(
            border: pw.TableBorder.all(color: _borderGray, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(2.5),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _black),
                children: [
                  _tableHeader('الإجمالي'),
                  _tableHeader('الأصناف'),
                  _tableHeader('التاريخ'),
                  _tableHeader('العميل'),
                  _tableHeader('رقم الفاتورة'),
                ],
              ),
              ...invoices.asMap().entries.map((entry) {
                final index = entry.key;
                final inv = entry.value;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: index % 2 == 1 ? _lightGray : _white),
                  children: [
                    _tableCell('\$${decimalFormat.format(inv.totalUSD)}'),
                    _tableCell('${inv.items.length}'),
                    _tableCell(dateFormat.format(inv.date)),
                    _tableCell(inv.customerName, isArabic: true),
                    _tableCell(inv.invoiceNumber),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _statCard(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                font: _arabicRegular,
                fontFallback: _fontFallback,
                fontSize: 10,
                color: _mediumGray),
            textDirection: pw.TextDirection.rtl),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(
                font: _arabicBold,
                fontFallback: _fontFallback,
                fontSize: 16,
                color: _black)),
      ],
    );
  }
}
