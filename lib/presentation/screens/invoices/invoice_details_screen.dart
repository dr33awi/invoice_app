import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wholesale_shoes_invoice/core/services/pdf_service.dart';
import 'dart:io';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/widgets/custom_app_bar.dart';
import '../../../data/models/invoice_model.dart';
import '../providers/providers.dart';
import '../providers/company_provider.dart';
import 'create_invoice_screen.dart';
import 'invoice_preview_screen.dart';

class InvoiceDetailsScreen extends ConsumerStatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailsScreen({super.key, required this.invoice});

  @override
  ConsumerState<InvoiceDetailsScreen> createState() =>
      _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends ConsumerState<InvoiceDetailsScreen> {
  // ignore: unused_field
  bool _isGeneratingPdf = false; // للتحكم بحالة إنشاء PDF

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'preview':
                  _previewPdf(context);
                  break;
                case 'print':
                  _printPdf(context);
                  break;
                case 'share':
                  _shareInvoice(context);
                  break;
                case 'save':
                  _savePdf(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              _buildPopupMenuItem(
                value: 'preview',
                icon: Icons.visibility_outlined,
                label: 'معاينة',
                color: AppColors.blue600,
              ),
              _buildPopupMenuItem(
                value: 'print',
                icon: Icons.print_outlined,
                label: 'طباعة',
                color: AppColors.teal600,
              ),
              _buildPopupMenuItem(
                value: 'share',
                icon: Icons.share_outlined,
                label: 'مشاركة',
                color: AppColors.success,
              ),
              _buildPopupMenuItem(
                value: 'save',
                icon: Icons.save_alt_outlined,
                label: 'حفظ PDF',
                color: AppColors.warning,
              ),
            ],
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
          AppSpacing.gapVerticalXl,
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF & Share Actions
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _previewPdf(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicePreviewScreen(invoice: widget.invoice),
      ),
    );
  }

  Future<void> _printPdf(BuildContext context) async {
    setState(() => _isGeneratingPdf = true);

    try {
      final companyAsync = ref.read(companyNotifierProvider);
      final company = companyAsync.valueOrNull;

      final pdfData = await PdfService.generateInvoice(
        widget.invoice,
        company: company,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: widget.invoice.invoiceNumber,
      );
    } catch (e) {
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
      final companyAsync = ref.read(companyNotifierProvider);
      final company = companyAsync.valueOrNull;

      final pdfData = await PdfService.generateInvoice(
        widget.invoice,
        company: company,
      );

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${widget.invoice.invoiceNumber}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('تم حفظ الفاتورة بنجاح')),
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
    } catch (e) {
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
      final companyAsync = ref.read(companyNotifierProvider);
      final company = companyAsync.valueOrNull;

      final pdfData = await PdfService.generateInvoice(
        widget.invoice,
        company: company,
      );

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
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
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
    final isPaid = widget.invoice.paidAmount >= widget.invoice.totalUSD;
    final hasDeposit = widget.invoice.paidAmount > 0 && !isPaid;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isPaid) {
      statusColor = AppColors.success;
      statusText = 'مدفوعة';
      statusIcon = Icons.check_circle;
    } else if (hasDeposit) {
      statusColor = AppColors.warning;
      statusText = 'عربون';
      statusIcon = Icons.hourglass_bottom;
    } else {
      statusColor = AppColors.blue600;
      statusText = 'مكتملة';
      statusIcon = Icons.receipt_long;
    }

    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 28),
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
                    borderRadius: BorderRadius.circular(4),
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
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: AppTypography.labelSmall.copyWith(
                      color: statusColor,
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
            _buildSectionHeader(
              context,
              icon: Icons.person,
              title: 'معلومات العميل',
              color: AppColors.teal600,
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
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_outlined,
                                  size: 14, color: AppColors.textSecondary),
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
                      // عرض العنوان إذا كان موجوداً
                      if (widget.invoice.customerAddress != null &&
                          widget.invoice.customerAddress!.isNotEmpty) ...[
                        AppSpacing.gapVerticalXs,
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.textSecondary),
                            AppSpacing.gapHorizontalXs,
                            Expanded(
                              child: Text(
                                widget.invoice.customerAddress!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
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
    final totalPairs = widget.invoice.totalItemCount;

    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              icon: Icons.info_outline,
              title: 'ملخص الفاتورة',
              color: AppColors.blue600,
            ),
            AppSpacing.gapVerticalMd,
            // التاريخ والوقت
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'التاريخ',
                    value: _dateFormat.format(widget.invoice.date),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    icon: Icons.access_time,
                    label: 'الوقت',
                    value: _timeFormat.format(widget.invoice.date),
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalSm,
            // الكميات
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    label: 'الأصناف',
                    value: '${widget.invoice.items.length}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    icon: Icons.all_inbox_outlined,
                    label: 'الطرود',
                    value: '$totalPackages',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    icon: Icons.shopping_bag_outlined,
                    label: 'القطع',
                    value: '$totalPairs',
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalSm,
            // طريقة الدفع
            _buildPaymentMethodRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.screenBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          AppSpacing.gapVerticalXs,
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(BuildContext context) {
    final isTransfer =
        widget.invoice.paymentMethod == InvoiceModel.paymentTransfer;
    final color = isTransfer ? AppColors.blue600 : AppColors.success;
    final icon =
        isTransfer ? Icons.account_balance_outlined : Icons.payments_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          AppSpacing.gapHorizontalSm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'طريقة الدفع',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
              ),
              Text(
                widget.invoice.paymentMethodName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
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
                _buildSectionHeader(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  title: 'المنتجات',
                  color: AppColors.warning,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue600.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.invoice.totalItemCount} قطعة',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.blue600,
                      fontWeight: FontWeight.w600,
                    ),
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
                    bottom: index < widget.invoice.items.length - 1 ? 10 : 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.screenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.blue600.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppColors.blue600,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapHorizontalSm,
                        Expanded(
                          child: Text(
                            item.productName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatUSD(item.total),
                          style: AppTypography.moneySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalSm,
                    // Tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (item.brand.isNotEmpty)
                          _buildTag(item.brand, AppColors.teal600),
                        if (item.category != null && item.category!.isNotEmpty)
                          _buildTag(item.category!, AppColors.statusOnHold),
                        _buildTag('مقاس: ${item.size}', AppColors.warning),
                      ],
                    ),
                    AppSpacing.gapVerticalSm,
                    // Details
                    Row(
                      children: [
                        _buildItemDetail('الطرود', '${item.packagesCount}'),
                        _buildItemDetail('الكمية', '${item.pairsPerPackage}'),
                        _buildItemDetail('سعر الوحدة',
                            CurrencyFormatter.formatUSD(item.unitPrice)),
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

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildItemDetail(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          children: [
            _buildSectionHeader(
              context,
              icon: Icons.calculate_outlined,
              title: 'ملخص المبالغ',
              color: AppColors.success,
            ),
            AppSpacing.gapVerticalMd,
            // المجموع والخصم
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.screenBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildTotalRow(context, 'المجموع الفرعي',
                      CurrencyFormatter.formatUSD(widget.invoice.subtotal)),
                  if (widget.invoice.discount > 0) ...[
                    const SizedBox(height: 8),
                    _buildTotalRow(
                      context,
                      'الخصم',
                      '- ${CurrencyFormatter.formatUSD(widget.invoice.discount)}',
                      valueColor: AppColors.error,
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.gapVerticalSm,
            // الإجمالي بالدولار
            _buildTotalCard(
              context,
              label: 'الإجمالي (USD)',
              value: CurrencyFormatter.formatUSD(widget.invoice.totalUSD),
              icon: Icons.attach_money,
              color: AppColors.blue600,
            ),
            AppSpacing.gapVerticalSm,
            // الإجمالي بالليرة
            _buildTotalCard(
              context,
              label: 'الإجمالي (SYP)',
              value: CurrencyFormatter.formatSYP(widget.invoice.totalSYP),
              iconText: 'ل.س',
              color: AppColors.teal600,
            ),
            // العربون والمبلغ المستحق
            if (widget.invoice.paidAmount > 0) ...[
              AppSpacing.gapVerticalSm,
              Row(
                children: [
                  Expanded(
                    child: _buildSmallTotalCard(
                      context,
                      label: 'العربون',
                      value: CurrencyFormatter.formatUSD(
                          widget.invoice.paidAmount),
                      icon: Icons.payments_outlined,
                      color: AppColors.success,
                    ),
                  ),
                  AppSpacing.gapHorizontalSm,
                  Expanded(
                    child: _buildSmallTotalCard(
                      context,
                      label: 'المستحق',
                      value:
                          CurrencyFormatter.formatUSD(widget.invoice.amountDue),
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
            AppSpacing.gapVerticalMd,
            // سعر الصرف
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.screenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.currency_exchange,
                      size: 14, color: AppColors.textMuted),
                  AppSpacing.gapHorizontalSm,
                  Text(
                    'سعر الصرف: ',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                  Text(
                    '${_numberFormat.format(widget.invoice.exchangeRate)} ل.س/دولار',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Widget _buildTotalCard(
    BuildContext context, {
    required String label,
    required String value,
    IconData? icon,
    String? iconText,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: icon != null
                ? Icon(icon, size: 20, color: color)
                : Text(
                    iconText!,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          AppSpacing.gapHorizontalMd,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
              ),
              Text(
                value,
                style: AppTypography.moneyLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTotalCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
          ),
          Text(
            value,
            style: AppTypography.moneyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: AppTypography.moneySmall.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w500,
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
            _buildSectionHeader(
              context,
              icon: Icons.note_outlined,
              title: 'ملاحظات',
              color: AppColors.statusOnHold,
            ),
            AppSpacing.gapVerticalSm,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.screenBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.invoice.notes!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        AppSpacing.gapHorizontalXs,
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
