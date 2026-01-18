import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'dart:typed_data';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/theme/widgets/custom_app_bar.dart';
import '../../../data/models/invoice_model.dart';
import '../providers/providers.dart';
import 'create_invoice_screen.dart';

class InvoiceDetailsScreen extends ConsumerStatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailsScreen({super.key, required this.invoice});

  @override
  ConsumerState<InvoiceDetailsScreen> createState() =>
      _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends ConsumerState<InvoiceDetailsScreen> {
  bool _isGeneratingPdf = false;

  // تنسيقات الأرقام الإنجليزية
  final _dateFormat = DateFormat('yyyy/MM/dd', 'en');
  final _timeFormat = DateFormat('hh:mm a', 'en');
  final _numberFormat = NumberFormat('#,###', 'en');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'تفاصيل الفاتورة',
        subtitle: widget.invoice.invoiceNumber,
        actions: [
          AppBarIconButton(
            icon: Icons.edit_outlined,
            onPressed: () => _editInvoice(context),
          ),
          AppBarIconButton(
            icon: Icons.delete_outline,
            onPressed: () => _confirmDelete(context, ref),
          ),
          AppBarIconButton(
            icon: Icons.picture_as_pdf_outlined,
            onPressed: _isGeneratingPdf ? null : () => _showPdfOptions(context),
          ),
          AppBarIconButton(
            icon: Icons.share_outlined,
            onPressed: _isGeneratingPdf ? null : () => _shareInvoice(context),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          _buildHeaderCard(context),
          AppSpacing.gapVerticalMd,
          _buildCustomerCard(context),
          AppSpacing.gapVerticalMd,
          _buildInvoiceSummaryCard(context),
          AppSpacing.gapVerticalMd,
          _buildItemsCard(context),
          AppSpacing.gapVerticalMd,
          _buildTotalsCard(context),
          if (widget.invoice.notes != null &&
              widget.invoice.notes!.isNotEmpty) ...[
            AppSpacing.gapVerticalMd,
            _buildNotesCard(context),
          ],
          AppSpacing.gapVerticalMd,
          _buildActionButtons(context),
          AppSpacing.gapVerticalXl,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF & Share Actions
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isGeneratingPdf ? null : () => _previewPdf(context),
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.preview_outlined),
            label: const Text('معاينة PDF'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        AppSpacing.gapHorizontalMd,
        Expanded(
          child: FilledButton.icon(
            onPressed: _isGeneratingPdf ? null : () => _shareInvoice(context),
            icon: const Icon(Icons.share_outlined),
            label: const Text('مشاركة'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showPdfOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AppSpacing.gapVerticalMd,
            Text(
              'خيارات PDF',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            AppSpacing.gapVerticalMd,
            _buildPdfOptionTile(
              context,
              icon: Icons.preview_outlined,
              color: AppColors.blue600,
              title: 'معاينة',
              subtitle: 'عرض الفاتورة قبل الطباعة',
              onTap: () {
                Navigator.pop(context);
                _previewPdf(context);
              },
            ),
            _buildPdfOptionTile(
              context,
              icon: Icons.print_outlined,
              color: AppColors.teal600,
              title: 'طباعة',
              subtitle: 'طباعة الفاتورة مباشرة',
              onTap: () {
                Navigator.pop(context);
                _printPdf(context);
              },
            ),
            _buildPdfOptionTile(
              context,
              icon: Icons.save_alt_outlined,
              color: AppColors.warning,
              title: 'حفظ PDF',
              subtitle: 'حفظ الفاتورة كملف PDF',
              onTap: () {
                Navigator.pop(context);
                _savePdf(context);
              },
            ),
            _buildPdfOptionTile(
              context,
              icon: Icons.share_outlined,
              color: AppColors.success,
              title: 'مشاركة',
              subtitle: 'إرسال الفاتورة عبر التطبيقات',
              onTap: () {
                Navigator.pop(context);
                _shareInvoice(context);
              },
            ),
            AppSpacing.gapVerticalMd,
          ],
        ),
      ),
    );
  }

  Widget _buildPdfOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  Future<void> _previewPdf(BuildContext context) async {
    setState(() => _isGeneratingPdf = true);

    try {
      print('🔵 Starting PDF generation for preview...');
      final pdfData = await PdfService.generateInvoice(widget.invoice);
      print('🔵 PDF generated successfully, size: ${pdfData.length} bytes');

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('معاينة - ${widget.invoice.invoiceNumber}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _shareFromPreview(context, pdfData),
                ),
                IconButton(
                  icon: const Icon(Icons.print_outlined),
                  onPressed: () => Printing.layoutPdf(
                    onLayout: (format) async => pdfData,
                  ),
                ),
              ],
            ),
            body: PdfPreview(
              build: (format) async => pdfData,
              initialPageFormat: PdfPageFormat.a4,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName: '${widget.invoice.invoiceNumber}.pdf',
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Error generating PDF: $e');
      print('❌ Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إنشاء PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _printPdf(BuildContext context) async {
    setState(() => _isGeneratingPdf = true);

    try {
      print('🔵 Starting PDF generation for print...');
      final pdfData = await PdfService.generateInvoice(widget.invoice);
      print('🔵 PDF generated successfully');

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: widget.invoice.invoiceNumber,
      );
    } catch (e, stackTrace) {
      print('❌ Error printing PDF: $e');
      print('❌ Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الطباعة: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _savePdf(BuildContext context) async {
    setState(() => _isGeneratingPdf = true);

    try {
      print('🔵 Starting PDF generation for save...');
      final pdfData = await PdfService.generateInvoice(widget.invoice);
      print('🔵 PDF generated successfully');

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${widget.invoice.invoiceNumber}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfData);
      print('🔵 PDF saved to: $filePath');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(child: Text('تم حفظ الفاتورة بنجاح')),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'مشاركة',
            textColor: Colors.white,
            onPressed: () => _shareFile(file),
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Error saving PDF: $e');
      print('❌ Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ الملف: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _shareInvoice(BuildContext context) async {
    setState(() => _isGeneratingPdf = true);

    try {
      print('🔵 Starting PDF generation for share...');
      final pdfData = await PdfService.generateInvoice(widget.invoice);
      print('🔵 PDF generated successfully, size: ${pdfData.length} bytes');

      final directory = await getTemporaryDirectory();
      print('🔵 Temp directory: ${directory.path}');

      final filePath = '${directory.path}/${widget.invoice.invoiceNumber}.pdf';
      final file = File(filePath);

      print('🔵 Writing file...');
      await file.writeAsBytes(pdfData);
      print('🔵 File written successfully');

      print('🔵 Starting share...');
      await Share.shareXFiles(
        [XFile(filePath)],
        text:
            'فاتورة رقم ${widget.invoice.invoiceNumber}\nالعميل: ${widget.invoice.customerName}\nالإجمالي: \$${widget.invoice.totalUSD.toStringAsFixed(2)}',
        subject: 'فاتورة ${widget.invoice.invoiceNumber}',
      );
      print('🔵 Share completed');
    } catch (e, stackTrace) {
      print('❌ Error sharing PDF: $e');
      print('❌ Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في المشاركة: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _shareFromPreview(
      BuildContext context, Uint8List pdfData) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/${widget.invoice.invoiceNumber}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfData);

      await Share.shareXFiles(
        [XFile(filePath)],
        text:
            'فاتورة رقم ${widget.invoice.invoiceNumber}\nالعميل: ${widget.invoice.customerName}\nالإجمالي: \$${widget.invoice.totalUSD.toStringAsFixed(2)}',
        subject: 'فاتورة ${widget.invoice.invoiceNumber}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في المشاركة: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'فاتورة رقم ${widget.invoice.invoiceNumber}\nالعميل: ${widget.invoice.customerName}\nالإجمالي: \$${widget.invoice.totalUSD.toStringAsFixed(2)}',
      subject: 'فاتورة ${widget.invoice.invoiceNumber}',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Edit & Delete Actions
  // ═══════════════════════════════════════════════════════════════════════════

  void _editInvoice(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateInvoiceScreen(invoice: widget.invoice),
      ),
    );

    if (result != null && context.mounted) {
      Navigator.pop(context, result);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفاتورة'),
        content: Text(
            'هل أنت متأكد من حذف الفاتورة "${widget.invoice.invoiceNumber}"؟\nهذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(invoicesNotifierProvider.notifier)
                  .deleteInvoice(widget.invoice.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الفاتورة بنجاح'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI Components
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.blue600,
                    AppColors.blue600.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.receipt_long, color: Colors.white, size: 28),
            ),
            AppSpacing.gapHorizontalMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'فاتورة بيع',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  AppSpacing.gapVerticalXs,
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: widget.invoice.invoiceNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ رقم الفاتورة'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.invoice.invoiceNumber,
                          style: AppTypography.codeSmall
                              .copyWith(color: AppColors.blue600),
                        ),
                        AppSpacing.gapHorizontalXs,
                        Icon(Icons.copy,
                            size: 14,
                            color: AppColors.blue600.withOpacity(0.7)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'مكتملة',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person,
                    size: 18, color: AppColors.textSecondary),
                AppSpacing.gapHorizontalXs,
                Text(
                  'معلومات العميل',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            AppSpacing.gapVerticalMd,
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.teal600.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      widget.invoice.customerName.isNotEmpty
                          ? widget.invoice.customerName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal600,
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.invoice.customerName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (widget.invoice.customerPhone != null) ...[
                        AppSpacing.gapVerticalXs,
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(
                                text: widget.invoice.customerPhone!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ رقم الهاتف'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_outlined,
                                  size: 16, color: AppColors.textSecondary),
                              AppSpacing.gapHorizontalXs,
                              Text(
                                widget.invoice.customerPhone!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              AppSpacing.gapHorizontalXs,
                              Icon(Icons.copy,
                                  size: 12,
                                  color: AppColors.textMuted.withOpacity(0.7)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceSummaryCard(BuildContext context) {
    final totalPackages = widget.invoice.items
        .fold<int>(0, (sum, item) => sum + item.packagesCount);

    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.textSecondary),
                AppSpacing.gapHorizontalXs,
                Text(
                  'ملخص الفاتورة',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            AppSpacing.gapVerticalMd,
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'التاريخ',
                    value: _dateFormat.format(widget.invoice.date),
                    color: AppColors.blue600,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.borderColor),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.access_time,
                    label: 'الوقت',
                    value: _timeFormat.format(widget.invoice.date),
                    color: AppColors.statusOnHold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    label: 'عدد الأصناف',
                    value: '${widget.invoice.items.length}',
                    color: AppColors.warning,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.borderColor),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.all_inbox_outlined,
                    label: 'عدد الطرود',
                    value: '$totalPackages',
                    color: AppColors.teal600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        AppSpacing.gapVerticalXs,
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildItemsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined,
                        size: 18, color: AppColors.textSecondary),
                    AppSpacing.gapHorizontalXs,
                    Text(
                      'المنتجات',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.blue600.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${widget.invoice.totalItemCount} قطعة',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.blue600),
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalMd,
            ...widget.invoice.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: EdgeInsets.only(
                    bottom: index < widget.invoice.items.length - 1 ? 12 : 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.screenBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.blue600.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.blue600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapHorizontalSm,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              AppSpacing.gapVerticalXs,
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (item.brand.isNotEmpty)
                                    _buildDetailChip(
                                      item.brand,
                                      Icons.branding_watermark_outlined,
                                      AppColors.teal600,
                                    ),
                                  if (item.category != null &&
                                      item.category!.isNotEmpty)
                                    _buildDetailChip(
                                      item.category!,
                                      Icons.category_outlined,
                                      AppColors.statusOnHold,
                                    ),
                                  _buildDetailChip(
                                    'مقاس: ${item.size}',
                                    Icons.straighten,
                                    AppColors.warning,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatUSD(item.total),
                          style: AppTypography.moneyMedium.copyWith(
                            color: AppColors.blue600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildItemDetail(
                            context,
                            'الطرود',
                            '${item.packagesCount}',
                            Icons.all_inbox_outlined,
                          ),
                        ),
                        Expanded(
                          child: _buildItemDetail(
                            context,
                            'جوز/طرد',
                            '${item.pairsPerPackage}',
                            Icons.layers_outlined,
                          ),
                        ),
                        Expanded(
                          child: _buildItemDetail(
                            context,
                            'سعر الجوز',
                            CurrencyFormatter.formatUSD(item.unitPrice),
                            Icons.attach_money,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style:
                AppTypography.labelSmall.copyWith(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetail(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildTotalsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.calculate_outlined,
                    size: 18, color: AppColors.textSecondary),
                AppSpacing.gapHorizontalXs,
                Text(
                  'ملخص المبالغ',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            AppSpacing.gapVerticalMd,
            _buildTotalRow(context, 'المجموع الفرعي',
                CurrencyFormatter.formatUSD(widget.invoice.subtotal)),
            if (widget.invoice.discount > 0) ...[
              AppSpacing.gapVerticalSm,
              _buildTotalRow(
                context,
                'الخصم',
                '- ${CurrencyFormatter.formatUSD(widget.invoice.discount)}',
                valueColor: AppColors.error,
                icon: Icons.discount_outlined,
              ),
            ],
            const Divider(height: 24),
            // الإجمالي بالدولار
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blue600.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.blue600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.attach_money,
                        size: 16, color: Colors.white),
                  ),
                  AppSpacing.gapHorizontalSm,
                  Text(
                    'الإجمالي (USD)',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatter.formatUSD(widget.invoice.totalUSD),
                        style: AppTypography.moneyLarge.copyWith(
                          color: AppColors.blue600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapVerticalSm,
            // الإجمالي بالليرة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teal600.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.teal600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ل.س',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AppSpacing.gapHorizontalSm,
                  Text(
                    'الإجمالي (SYP)',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatter.formatSYP(widget.invoice.totalSYP),
                        style: AppTypography.moneyLarge.copyWith(
                          color: AppColors.teal600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapVerticalMd,
            // سعر الصرف
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.screenBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.currency_exchange,
                      size: 16, color: AppColors.textMuted),
                  AppSpacing.gapHorizontalSm,
                  Text(
                    'سعر الصرف: ${_numberFormat.format(widget.invoice.exchangeRate)} ل.س/دولار',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: valueColor ?? AppColors.textSecondary),
          AppSpacing.gapHorizontalXs,
        ],
        Text(
          label,
          style: isBold
              ? Theme.of(context).textTheme.titleSmall
              : Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: (isBold
                      ? AppTypography.moneyMedium
                      : AppTypography.moneySmall)
                  .copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_outlined,
                    size: 18, color: AppColors.textSecondary),
                AppSpacing.gapHorizontalXs,
                Text(
                  'ملاحظات',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            AppSpacing.gapVerticalSm,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Text(
                widget.invoice.notes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
