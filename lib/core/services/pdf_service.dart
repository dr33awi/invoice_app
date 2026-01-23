import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:barcode/barcode.dart';

import '../../data/models/invoice_model.dart';
import '../../data/models/company_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// خدمة إنشاء فواتير PDF - مع دعم صورة الشعار (Enterprise Pagination)
/// ═══════════════════════════════════════════════════════════════════════════

class PdfService {
  // ═══════════════════════════════════════════════════════════════════════════
  // الثوابت
  // ═══════════════════════════════════════════════════════════════════════════
  static const String _companyLinkUrl = 'https://wonderl.ink/@almiyar_company';
  static const String _companyLinkButtonText = 'تصفح منتجاتنا';

  // عدد المنتجات في كل صفحة
  static const int _itemsPerFirstPage =
      11; // الصفحة الأولى (مع الهيدر ومعلومات العميل)
  static const int _itemsPerMiddlePage = 20; // الصفحات الوسطى

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
  static pw.Font? _latinRegular;

  static Future<void> _loadFonts() async {
    if (_arabicRegular != null) return;

    _latinRegular = await PdfGoogleFonts.robotoRegular();
    _arabicRegular = await PdfGoogleFonts.cairoRegular();
    _arabicBold = await PdfGoogleFonts.cairoBold();
    _mono = _latinRegular;
  }

  static List<pw.Font> get _fontFallback =>
      [_latinRegular!, _arabicRegular!, _arabicBold!, _mono!];

  // ═══════════════════════════════════════════════════════════════════════════
  // أدوات مساعدة للفواتير الكبيرة
  // ═══════════════════════════════════════════════════════════════════════════

  /// تقسيم المنتجات إلى مجموعات حسب الصفحة
  static List<List<InvoiceItemModel>> _splitItemsForPages(
    List<InvoiceItemModel> items,
  ) {
    final chunks = <List<InvoiceItemModel>>[];

    if (items.isEmpty) {
      chunks.add([]);
      return chunks;
    }

    int currentIndex = 0;

    // الصفحة الأولى
    final firstPageCount =
        items.length < _itemsPerFirstPage ? items.length : _itemsPerFirstPage;
    chunks.add(items.sublist(0, firstPageCount));
    currentIndex = firstPageCount;

    // الصفحات الوسطى والأخيرة
    while (currentIndex < items.length) {
      final remaining = items.length - currentIndex;

      // إذا كان المتبقي يمكن أن يملأ صفحة وسطى + صفحة أخيرة
      if (remaining > _itemsPerMiddlePage) {
        // صفحة وسطى كاملة
        chunks.add(
            items.sublist(currentIndex, currentIndex + _itemsPerMiddlePage));
        currentIndex += _itemsPerMiddlePage;
      } else {
        // الصفحة الأخيرة - كل ما تبقى
        chunks.add(items.sublist(currentIndex));
        currentIndex = items.length;
      }
    }

    return chunks;
  }

  static Future<pw.ImageProvider?> _loadLogoImage(String? logoPath) async {
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (await file.exists()) {
        return pw.MemoryImage(await file.readAsBytes());
      }
    }
    final bytes = await rootBundle.load('assets/images/1.png');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إنشاء الفاتورة (مُعاد هيكلتها باحتراف)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> generateInvoice(
    InvoiceModel invoice, {
    CompanyModel? company,
    String? companyName,
    String? companySubtitle,
    String? companyPhone,
    String? companyAddress,
    String? logoPath,
    double? paidAmount,
  }) async {
    await _loadFonts();

    final pdf = pw.Document();
    final decimalFormat = NumberFormat('#,##0.00', 'en');
    final numberFormat = NumberFormat('#,###', 'en');
    final dateFormat = DateFormat('yyyy/MM/dd', 'en');

    final logoImage = await _loadLogoImage(company?.logoPath ?? logoPath);
    final effectivePaid = paidAmount ?? invoice.paidAmount;
    final amountDue = invoice.totalUSD - effectivePaid;

    // تقسيم المنتجات إلى صفحات
    final itemChunks = _splitItemsForPages(invoice.items);
    final totalPages = itemChunks.length;
    int globalItemIndex = 0; // لتتبع الترقيم العام للمنتجات

    // ═══════════════════════════════════════════════════════════════════════════
    // إنشاء الصفحات
    // ═══════════════════════════════════════════════════════════════════════════

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final isFirstPage = pageIndex == 0;
      final isLastPage = pageIndex == totalPages - 1;
      final currentItems = itemChunks[pageIndex];
      final startIndex = globalItemIndex;
      globalItemIndex += currentItems.length;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: isFirstPage
              ? pw.EdgeInsets.zero
              : const pw.EdgeInsets.fromLTRB(40, 30, 40, 30),
          build: (context) {
            final widgets = <pw.Widget>[];

            // ─────────────── الهيدر (الصفحة الأولى فقط) ───────────────
            if (isFirstPage) {
              widgets.add(
                _buildHeader(
                  companyName: company?.name ?? CompanyModel.defaultName,
                  companySubtitle:
                      company?.subtitle ?? CompanyModel.defaultSubtitle,
                  invoiceNumber: invoice.invoiceNumber,
                  invoiceDate: dateFormat.format(invoice.date),
                  logoImage: logoImage,
                  companyPhone: company?.phone,
                  companyAddress: company?.address,
                ),
              );

              // معلومات العميل مع الباركود
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(40, 25, 40, 15),
                  child: _buildCustomerInfoWithBarcode(
                    customerName: invoice.customerName,
                    customerPhone: invoice.customerPhone,
                    customerAddress: invoice.customerAddress,
                    companyAddress: company?.address ?? '',
                    barcodeValue: invoice.barcodeValue,
                  ),
                ),
              );
            }

            // ─────────────── هيدر مصغر للصفحات التالية ───────────────
            if (!isFirstPage) {
              widgets.add(_buildContinuationHeader(
                invoiceNumber: invoice.invoiceNumber,
                pageNumber: pageIndex + 1,
                totalPages: totalPages,
              ));
              widgets.add(pw.SizedBox(height: 15));
            }

            // ─────────────── جدول المنتجات ───────────────
            if (currentItems.isNotEmpty) {
              widgets.add(
                pw.Padding(
                  padding: isFirstPage
                      ? const pw.EdgeInsets.symmetric(horizontal: 40)
                      : pw.EdgeInsets.zero,
                  child: _buildItemsTableWithIndex(
                    items: currentItems,
                    decimalFormat: decimalFormat,
                    startIndex: startIndex,
                  ),
                ),
              );
            }

            // ─────────────── الملخص (الصفحة الأخيرة فقط) ───────────────
            if (isLastPage) {
              widgets.add(pw.SizedBox(height: 20));
              widgets.add(
                pw.Padding(
                  padding: isFirstPage
                      ? const pw.EdgeInsets.symmetric(horizontal: 40)
                      : pw.EdgeInsets.zero,
                  child: _buildSummarySection(
                    subtotal: invoice.subtotal,
                    paidAmount: effectivePaid,
                    discount: invoice.discount,
                    total: amountDue,
                    totalSYP: invoice.totalSYP,
                    exchangeRate: invoice.exchangeRate,
                    notes: invoice.notes,
                    paymentMethod: invoice.paymentMethodName,
                    decimalFormat: decimalFormat,
                    numberFormat: numberFormat,
                  ),
                ),
              );
            }

            // ─────────────── رقم الصفحة للصفحات غير الأخيرة ───────────────
            if (!isLastPage) {
              widgets.add(pw.Spacer());
              widgets.add(
                pw.Padding(
                  padding: isFirstPage
                      ? const pw.EdgeInsets.symmetric(horizontal: 40)
                      : pw.EdgeInsets.zero,
                  child: _buildPageNumber(pageIndex + 1, totalPages),
                ),
              );
            }

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: widgets,
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // هيدر مصغر للصفحات التالية
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildContinuationHeader({
    required String invoiceNumber,
    required int pageNumber,
    required int totalPages,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _yellow, width: 3)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'صفحة $pageNumber من $totalPages',
            style: pw.TextStyle(
              font: _arabicRegular,
              fontFallback: _fontFallback,
              fontSize: 10,
              color: _mediumGray,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Row(
            children: [
              pw.Text(
                invoiceNumber,
                style: pw.TextStyle(
                  font: _mono,
                  fontFallback: _fontFallback,
                  fontSize: 11,
                  color: _black,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'تابع فاتورة رقم:',
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
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // رقم الصفحة
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildPageNumber(int current, int total) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Text(
        'صفحة $current من $total',
        style: pw.TextStyle(
          font: _arabicRegular,
          fontFallback: _fontFallback,
          fontSize: 10,
          color: _mediumGray,
        ),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // جدول المنتجات مع ترقيم مخصص
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildItemsTableWithIndex({
    required List<InvoiceItemModel> items,
    required NumberFormat decimalFormat,
    required int startIndex,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(55),
        1: const pw.FixedColumnWidth(35),
        2: const pw.FixedColumnWidth(35),
        3: const pw.FixedColumnWidth(50),
        4: const pw.FixedColumnWidth(45),
        5: const pw.FlexColumnWidth(2),
        6: const pw.FixedColumnWidth(30),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _black),
          children: [
            _tableHeader('اجمالي'),
            _tableHeader('الكمية'),
            _tableHeader('طرد'),
            _tableHeader('سعر الوحدة'),
            _tableHeader('المقاس'),
            _tableHeader('أسم المنتج'),
            _tableHeader('م'),
          ],
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final globalIndex = startIndex + index;
          final isEven = globalIndex % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? _white : _lightGray),
            children: [
              _tableCell('\$${decimalFormat.format(item.total)}'),
              _tableCell('${item.quantity}'),
              _tableCell('${item.packagesCount}'),
              _tableCell('\$${decimalFormat.format(item.unitPrice)}'),
              _tableCell(item.size),
              _tableCell(item.productName, isArabic: true),
              _tableCell('${globalIndex + 1}'),
            ],
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QR Code رابط الشركة - يعمل على جميع الأجهزة (محجوز للاستخدام المستقبلي)
  // ═══════════════════════════════════════════════════════════════════════════

  // ignore: unused_element
  static pw.Widget _buildCompanyLinkQR() {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _black, width: 1),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.BarcodeWidget(
            barcode: Barcode.qrCode(),
            data: _companyLinkUrl,
            width: 70,
            height: 70,
            color: _black,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _companyLinkButtonText,
          style: pw.TextStyle(
            font: _arabicBold,
            fontFallback: _fontFallback,
            fontSize: 9,
            color: _black,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // باركود الفاتورة - Code128
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildBarcode(String barcodeValue) {
    return pw.Column(
      children: [
        pw.BarcodeWidget(
          barcode: Barcode.code128(),
          data: barcodeValue,
          width: 200,
          height: 50,
          drawText: false,
          color: _black,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          barcodeValue,
          style: pw.TextStyle(
            font: _mono,
            fontSize: 9,
            color: _mediumGray,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الهيدر - مع دعم صورة الشعار
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildHeader({
    required String companyName,
    required String companySubtitle,
    required String invoiceNumber,
    required String invoiceDate,
    pw.ImageProvider? logoImage,
    String? companyPhone,
    String? companyAddress,
  }) {
    return pw.Container(
      height: 180,
      child: pw.Stack(
        children: [
          // خلفية بيضاء
          pw.Positioned.fill(child: pw.Container(color: _white)),

          // الخلفية السوداء للشعار - يسار (محسنة)
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

          // الشعار - على الخلفية السوداء
          pw.Positioned(
            left: 0,
            top: 0,
            child: logoImage != null
                ? _buildFullSizeLogo(logoImage)
                : pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 20, top: 20),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // الشعار الافتراضي
                        _buildLogo(null),
                        pw.SizedBox(width: 12),
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
                            if (companySubtitle.isNotEmpty)
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
          ),

          // رقم الهاتف والعنوان - صف واحد في أسفل الخلفية السوداء (أقصى اليمين)
          pw.Positioned(
            left: 15,
            right: 320, // لتكون على أقصى يمين الخلفية السوداء
            bottom: 12,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                // العنوان أولاً (يظهر على اليسار)
                if (companyAddress != null && companyAddress.isNotEmpty) ...[
                  pw.Text(
                    companyAddress,
                    style: pw.TextStyle(
                      font: _arabicRegular,
                      fontFallback: _fontFallback,
                      fontSize: 9,
                      color: _white,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    'العنوان:',
                    style: pw.TextStyle(
                      font: _arabicRegular,
                      fontFallback: _fontFallback,
                      fontSize: 9,
                      color: _yellow,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
                // فاصل
                if (companyAddress != null &&
                    companyAddress.isNotEmpty &&
                    companyPhone != null &&
                    companyPhone.isNotEmpty)
                  pw.SizedBox(width: 25),
                // رقم الهاتف ثانياً (يظهر على اليمين)
                if (companyPhone != null && companyPhone.isNotEmpty) ...[
                  pw.Text(
                    companyPhone,
                    style: pw.TextStyle(
                      font: _mono,
                      fontFallback: _fontFallback,
                      fontSize: 9,
                      color: _white,
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    'رقم الهاتف:',
                    style: pw.TextStyle(
                      font: _arabicRegular,
                      fontFallback: _fontFallback,
                      fontSize: 9,
                      color: _yellow,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
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

  // ═══════════════════════════════════════════════════════════════════════════
  // بناء الشعار بحجم كامل - يملأ المنطقة السوداء
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildFullSizeLogo(pw.ImageProvider logoImage) {
    // الشعار بحجم كامل يملأ المنطقة السوداء (بدون نص الشركة)
    return pw.Container(
      width: 260,
      height: 176, // ارتفاع المنطقة السوداء مع هامش
      padding: const pw.EdgeInsets.all(8),
      child: pw.Center(
        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // بناء الشعار - صورة أو رسم افتراضي
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildLogo(pw.ImageProvider? logoImage) {
    if (logoImage != null) {
      // عرض صورة الشعار المحملة
      return pw.Container(
        width: 60,
        height: 60,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _yellow, width: 2),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.ClipRRect(
          horizontalRadius: 6,
          verticalRadius: 6,
          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
        ),
      );
    } else {
      // عرض الشعار الافتراضي (رسم الحذاء)
      return _buildDefaultShoeLogo();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // لوجو الحذاء الافتراضي
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildDefaultShoeLogo() {
    return pw.Container(
      width: 60,
      height: 60,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _yellow, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.CustomPaint(
          size: const PdfPoint(45, 35),
          painter: (canvas, size) {
            // رسم حذاء أنيق
            final paint = _yellow;

            // قاعدة الحذاء (النعل)
            canvas
              ..setStrokeColor(paint)
              ..setLineWidth(2.5)
              ..moveTo(5, size.y - 5)
              ..lineTo(size.x - 5, size.y - 5)
              ..strokePath();

            // الكعب
            canvas
              ..setFillColor(paint)
              ..drawRect(size.x - 12, size.y - 12, 7, 7)
              ..fillPath();

            // جسم الحذاء
            canvas
              ..setStrokeColor(paint)
              ..setLineWidth(2)
              ..moveTo(5, size.y - 5)
              ..lineTo(5, size.y - 15)
              ..lineTo(15, size.y - 22)
              ..lineTo(30, size.y - 22)
              ..lineTo(40, size.y - 12)
              ..lineTo(size.x - 5, size.y - 5)
              ..strokePath();

            // فتحة الحذاء العلوية
            canvas
              ..setStrokeColor(paint)
              ..setLineWidth(1.5)
              ..moveTo(8, size.y - 18)
              ..curveTo(12, size.y - 28, 25, size.y - 30, 32, size.y - 20)
              ..strokePath();

            // رباط الحذاء
            canvas
              ..setStrokeColor(paint)
              ..setLineWidth(1.5)
              ..moveTo(15, size.y - 18)
              ..lineTo(20, size.y - 25)
              ..strokePath()
              ..moveTo(20, size.y - 18)
              ..lineTo(25, size.y - 24)
              ..strokePath()
              ..moveTo(25, size.y - 18)
              ..lineTo(28, size.y - 22)
              ..strokePath();
          },
        ),
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
  // معلومات العميل
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildCustomerInfoWithBarcode({
    required String customerName,
    String? customerPhone,
    String? customerAddress,
    required String companyAddress,
    required String barcodeValue,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // باركود الفاتورة (على اليسار)
        _buildBarcode(barcodeValue),
        // معلومات العميل (على اليمين)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildInfoRowRTL('اسم العميل', customerName),
            pw.SizedBox(height: 6),
            if (customerPhone != null && customerPhone.isNotEmpty)
              _buildInfoRowRTL('رقم الهاتف', customerPhone),
            if (customerAddress != null && customerAddress.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              _buildInfoRowRTL('العنوان', customerAddress)
            ],
          ],
        ),
      ],
    );
  }

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

  // ignore: unused_element
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

  static pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: _arabicBold,
          fontFallback: _fontFallback,
          fontSize: 9,
          color: _white,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool isArabic = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isArabic ? _arabicRegular : _mono,
          fontFallback: _fontFallback,
          fontSize: 9,
          color: _black,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // قسم الملخص
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildSummarySection({
    required double subtotal,
    required double paidAmount,
    required double discount,
    required double total,
    required double totalSYP,
    required double exchangeRate,
    String? notes,
    String? paymentMethod,
    required NumberFormat decimalFormat,
    required NumberFormat numberFormat,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ─────────────── ملخص الدفع (يسار) ───────────────
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(
                  'الاجمالي', '\$${decimalFormat.format(subtotal)}'),
              pw.SizedBox(height: 8),
              if (discount > 0) ...[
                _buildSummaryRow(
                    'الخصم', '-\$${decimalFormat.format(discount)}'),
                pw.SizedBox(height: 8),
              ],
              _buildSummaryRow(
                  'العربون المقبوض', '\$${decimalFormat.format(paidAmount)}'),
              pw.SizedBox(height: 12),
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
                      'المستحق',
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
              pw.SizedBox(height: 10),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: _lightGray,
                  borderRadius: pw.BorderRadius.circular(3),
                  border: pw.Border.all(color: _borderGray),
                ),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      '${numberFormat.format(totalSYP)} ل.س',
                      style: pw.TextStyle(
                        font: _arabicBold,
                        fontFallback: _fontFallback,
                        fontSize: 12,
                        color: _black,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(width: 20),
                    pw.Text(
                      'بالسورية',
                      style: pw.TextStyle(
                        font: _arabicRegular,
                        fontFallback: _fontFallback,
                        fontSize: 10,
                        color: _mediumGray,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'سعر الصرف: ${numberFormat.format(exchangeRate)} ل.س',
                style: pw.TextStyle(
                  font: _arabicRegular,
                  fontFallback: _fontFallback,
                  fontSize: 8,
                  color: _mediumGray,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              if (paymentMethod != null) ...[
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: _lightGray,
                    borderRadius: pw.BorderRadius.circular(3),
                    border: pw.Border.all(color: _borderGray),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        paymentMethod,
                        style: pw.TextStyle(
                          font: _arabicBold,
                          fontFallback: _fontFallback,
                          fontSize: 10,
                          color: _black,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'طريقة الدفع:',
                        style: pw.TextStyle(
                          font: _arabicRegular,
                          fontFallback: _fontFallback,
                          fontSize: 9,
                          color: _mediumGray,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 30),
        // ─────────────── الملاحظات (يمين) ───────────────
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // الملاحظات
              if (notes != null && notes.isNotEmpty) ...[
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
                pw.SizedBox(height: 6),
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
