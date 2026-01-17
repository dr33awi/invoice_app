import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/invoice_model.dart';

class InvoiceDetailsScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailsScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: invoice.invoiceNumber,
        subtitle: 'تفاصيل الفاتورة',
        actions: [
          AppBarIconButton(
              icon: Icons.picture_as_pdf_outlined, onPressed: () {}),
          AppBarIconButton(icon: Icons.share_outlined, onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          _buildHeaderCard(context),
          AppSpacing.gapVerticalMd,
          _buildCustomerCard(context),
          AppSpacing.gapVerticalMd,
          _buildItemsCard(context),
          AppSpacing.gapVerticalMd,
          _buildTotalsCard(context),
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            AppSpacing.gapVerticalMd,
            _buildNotesCard(context),
          ],
          AppSpacing.gapVerticalXl,
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.blue600.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long,
                  color: AppColors.blue600, size: 24),
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
                  Text(
                    invoice.invoiceNumber,
                    style: AppTypography.codeSmall
                        .copyWith(color: AppColors.blue600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'التاريخ',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
                Text(
                  DateFormatter.formatDateAr(invoice.date),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
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
            Text(
              'معلومات العميل',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.gapVerticalSm,
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 20, color: AppColors.textSecondary),
                AppSpacing.gapHorizontalSm,
                Expanded(
                  child: Text(
                    invoice.customerName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (invoice.customerPhone != null) ...[
              AppSpacing.gapVerticalXs,
              Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 20, color: AppColors.textSecondary),
                  AppSpacing.gapHorizontalSm,
                  Text(invoice.customerPhone!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ],
        ),
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
                Text(
                  'المنتجات',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.blue600.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${invoice.totalItemCount} قطعة',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.blue600),
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalSm,
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.screenBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('المنتج',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: Text('المقاس',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    child: Text('الكمية',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('المجموع',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.end),
                  ),
                ],
              ),
            ),
            // Items
            ...invoice.items.map((item) => Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.borderColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(item.productName,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      Expanded(
                        child: Text(item.size,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center),
                      ),
                      Expanded(
                        child: Text(item.quantity.toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          CurrencyFormatter.formatUSD(item.total),
                          style: AppTypography.moneySmall
                              .copyWith(color: AppColors.textPrimary),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          children: [
            _buildTotalRow(context, 'المجموع الفرعي',
                CurrencyFormatter.formatUSD(invoice.subtotal)),
            if (invoice.discount > 0) ...[
              AppSpacing.gapVerticalXs,
              _buildTotalRow(context, 'الخصم',
                  '- ${CurrencyFormatter.formatUSD(invoice.discount)}',
                  valueColor: AppColors.error),
            ],
            const Divider(height: 24),
            _buildTotalRow(context, 'الإجمالي (USD)',
                CurrencyFormatter.formatUSD(invoice.totalUSD),
                isBold: true),
            AppSpacing.gapVerticalSm,
            _buildTotalRow(context, 'الإجمالي (SYP)',
                CurrencyFormatter.formatSYP(invoice.totalSYP),
                isBold: true, valueColor: AppColors.teal600),
            AppSpacing.gapVerticalSm,
            Text(
              'سعر الصرف: ${NumberFormat('#,###').format(invoice.exchangeRate)} ل.س/دولار',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? Theme.of(context).textTheme.titleSmall
              : Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: (isBold ? AppTypography.moneyMedium : AppTypography.moneySmall)
              .copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
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
            Text(
              'ملاحظات',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.gapVerticalSm,
            Text(invoice.notes!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
