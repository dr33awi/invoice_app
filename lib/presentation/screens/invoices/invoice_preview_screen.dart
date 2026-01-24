import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/widgets/custom_app_bar.dart';
import '../../../core/services/pdf_service.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/company_model.dart';
import '../providers/company_provider.dart';
import '../providers/customer_providers.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة معاينة الفاتورة بصيغة PDF
/// ═══════════════════════════════════════════════════════════════════════════
///
/// تعرض معاينة مطابقة 100% لملف PDF النهائي باستخدام نفس PdfService
/// المستخدم عند الحفظ والطباعة.
///
/// الميزات:
/// - معاينة قراءة فقط (بدون طباعة أو مشاركة)
/// - حجم ورق ثابت A4
/// - تحديث تلقائي عند تغيير بيانات الشركة
/// - دعم كامل للغة العربية (RTL)
/// ═══════════════════════════════════════════════════════════════════════════

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  final InvoiceModel invoice;

  const InvoicePreviewScreen({
    super.key,
    required this.invoice,
  });

  @override
  ConsumerState<InvoicePreviewScreen> createState() =>
      _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    // مراقبة بيانات الشركة للتحديث التلقائي
    final companyAsync = ref.watch(companyNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: CustomAppBar(
        title: 'معاينة الفاتورة',
        subtitle: widget.invoice.invoiceNumber,
        actions: [
          // مؤشر التحميل
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
                ),
              ),
            ),
        ],
      ),
      body: companyAsync.when(
        data: (company) => _buildPreview(company),
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  /// بناء معاينة PDF
  Widget _buildPreview(CompanyModel company) {
    return Column(
      children: [
        // شريط معلومات
        _buildInfoBar(),
        // معاينة PDF
        Expanded(
          child: PdfPreview(
            // إنشاء PDF باستخدام نفس الخدمة المستخدمة للطباعة والحفظ
            build: (format) => _generatePdf(company),
            // إعدادات المعاينة - قراءة فقط
            allowPrinting: false,
            allowSharing: false,
            canChangeOrientation: false,
            canChangePageFormat: false,
            // حجم الورق الثابت A4
            initialPageFormat: PdfPageFormat.a4,
            // تخصيص المظهر
            pdfFileName: '${widget.invoice.invoiceNumber}.pdf',
            // إعدادات إضافية
            useActions: false, // إخفاء أزرار الإجراءات
            scrollViewDecoration: const BoxDecoration(
              color: AppColors.screenBg,
            ),
            pdfPreviewPageDecoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // مراقبة حالة التحميل
            onPrinted: (_) {},
            onShared: (_) {},
            onError: (context, error) {
              return _buildPdfErrorWidget(error.toString());
            },
            loadingWidget: _buildPdfLoadingWidget(),
            // عند اكتمال التحميل
            previewPageMargin: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  /// إنشاء ملف PDF
  Future<Uint8List> _generatePdf(CompanyModel company) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // الحصول على بيانات العميل المحدثة للتحديث التلقائي
      final customerId = widget.invoice.customerId;
      final customerData = customerId != null
          ? ref.read(customerDataProvider(customerId))
          : null;

      // إنشاء فاتورة محدثة ببيانات العميل الجديدة
      final updatedInvoice = customerData != null
          ? InvoiceModel(
              id: widget.invoice.id,
              invoiceNumber: widget.invoice.invoiceNumber,
              customerId: widget.invoice.customerId,
              customerName: customerData.name,
              customerPhone: customerData.phone,
              customerAddress: customerData.address,
              date: widget.invoice.date,
              items: widget.invoice.items,
              subtotal: widget.invoice.subtotal,
              discount: widget.invoice.discount,
              totalUSD: widget.invoice.totalUSD,
              exchangeRate: widget.invoice.exchangeRate,
              totalIQD: widget.invoice.totalIQD,
              notes: widget.invoice.notes,
              createdAt: widget.invoice.createdAt,
              barcodeValue: widget.invoice.barcodeValue,
              paymentMethod: widget.invoice.paymentMethod,
              paidAmount: widget.invoice.paidAmount,
            )
          : widget.invoice;

      final pdfBytes = await PdfService.generateInvoice(
        updatedInvoice,
        company: company,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      return pdfBytes;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      rethrow;
    }
  }

  /// شريط المعلومات العلوي
  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.warning.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 18,
            color: AppColors.warning.withValues(alpha: 0.8),
          ),
          AppSpacing.gapHorizontalXs,
          Text(
            'معاينة فقط',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.warning.withValues(alpha: 0.8),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                const Text(
                  'A4',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// حالة التحميل
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
          ),
          SizedBox(height: 16),
          Text(
            'جاري تحميل المعاينة...',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// حالة الخطأ
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'خطأ في تحميل المعاينة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ويدجت تحميل PDF
  Widget _buildPdfLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
          ),
          SizedBox(height: 16),
          Text(
            'جاري إنشاء المعاينة...',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// ويدجت خطأ PDF
  Widget _buildPdfErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.picture_as_pdf_outlined,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'خطأ في إنشاء PDF',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة معاينة الفاتورة في الإعدادات (مع بيانات تجريبية)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// تُستخدم في شاشة إعدادات الشركة لمعاينة شكل الفاتورة
/// مع إمكانية التحديث المباشر عند تغيير الإعدادات.
/// ═══════════════════════════════════════════════════════════════════════════

class InvoicePreviewSettingsScreen extends ConsumerStatefulWidget {
  /// بيانات الشركة المخصصة (اختياري - للمعاينة المباشرة)
  final String? companyName;
  final String? companySubtitle;
  final String? companyPhone;
  final String? companyAddress;
  final String? logoPath;

  const InvoicePreviewSettingsScreen({
    super.key,
    this.companyName,
    this.companySubtitle,
    this.companyPhone,
    this.companyAddress,
    this.logoPath,
  });

  @override
  ConsumerState<InvoicePreviewSettingsScreen> createState() =>
      _InvoicePreviewSettingsScreenState();
}

class _InvoicePreviewSettingsScreenState
    extends ConsumerState<InvoicePreviewSettingsScreen> {
  bool _isLoading = true;

  /// إنشاء فاتورة تجريبية للمعاينة
  InvoiceModel get _sampleInvoice => InvoiceModel(
        id: 'preview-sample',
        invoiceNumber: 'INV-2024-001',
        customerName: 'العميل التجريبي',
        customerPhone: '0912345678',
        date: DateTime.now(),
        items: [
          InvoiceItemModel(
            productId: '1',
            productName: 'حذاء رياضي - أبيض',
            size: '40-45',
            quantity: 12,
            unitPrice: 25.00,
            total: 300.00,
            brand: 'Nike',
          ),
          InvoiceItemModel(
            productId: '2',
            productName: 'حذاء كلاسيكي - أسود',
            size: '39-44',
            quantity: 6,
            unitPrice: 35.00,
            total: 210.00,
            brand: 'Adidas',
          ),
          InvoiceItemModel(
            productId: '3',
            productName: 'صندل صيفي - بني',
            size: '38-43',
            quantity: 24,
            unitPrice: 15.00,
            total: 360.00,
            brand: 'Puma',
          ),
        ],
        subtotal: 870.00,
        discount: 20.00,
        totalUSD: 850.00,
        exchangeRate: 1480,
        totalIQD: 1258000,
        status: 'completed',
        notes: 'هذه فاتورة تجريبية للمعاينة',
        paymentMethod: InvoiceModel.paymentCash,
        paidAmount: 200.00,
      );

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: CustomAppBar(
        title: 'معاينة الفاتورة',
        subtitle: 'شكل الفاتورة النهائي',
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
                ),
              ),
            ),
        ],
      ),
      body: companyAsync.when(
        data: (company) => _buildPreview(company),
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildPreview(CompanyModel company) {
    // استخدام البيانات الممررة أو بيانات الشركة المحفوظة
    final effectiveCompanyName = widget.companyName ?? company.name;
    final effectiveSubtitle = widget.companySubtitle ?? company.subtitle;
    final effectivePhone = widget.companyPhone ?? company.phone;
    final effectiveAddress = widget.companyAddress ?? company.address;
    final effectiveLogoPath = widget.logoPath ?? company.logoPath;

    return Column(
      children: [
        _buildInfoBar(),
        Expanded(
          child: PdfPreview(
            build: (format) => _generatePdf(
              companyName: effectiveCompanyName,
              companySubtitle: effectiveSubtitle,
              companyPhone: effectivePhone,
              companyAddress: effectiveAddress,
              logoPath: effectiveLogoPath,
            ),
            allowPrinting: false,
            allowSharing: false,
            canChangeOrientation: false,
            canChangePageFormat: false,
            initialPageFormat: PdfPageFormat.a4,
            pdfFileName: 'invoice_preview.pdf',
            useActions: false,
            scrollViewDecoration: const BoxDecoration(
              color: AppColors.screenBg,
            ),
            pdfPreviewPageDecoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            loadingWidget: _buildPdfLoadingWidget(),
            previewPageMargin: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Future<Uint8List> _generatePdf({
    required String companyName,
    String? companySubtitle,
    String? companyPhone,
    String? companyAddress,
    String? logoPath,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pdfBytes = await PdfService.generateInvoice(
        _sampleInvoice,
        companyName: companyName,
        companySubtitle: companySubtitle,
        companyPhone: companyPhone,
        companyAddress: companyAddress,
        logoPath: logoPath,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      return pdfBytes;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      rethrow;
    }
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.blue600.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.blue600.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.blue600.withValues(alpha: 0.8),
          ),
          AppSpacing.gapHorizontalXs,
          Expanded(
            child: Text(
              'معاينة تجريبية - ستظهر الفاتورة الفعلية بنفس الشكل',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.blue600.withValues(alpha: 0.8),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.blue600.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 4),
                Text(
                  'A4',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
          ),
          SizedBox(height: 16),
          Text(
            'جاري تحميل المعاينة...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'خطأ في تحميل المعاينة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
          ),
          SizedBox(height: 16),
          Text(
            'جاري إنشاء المعاينة...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
