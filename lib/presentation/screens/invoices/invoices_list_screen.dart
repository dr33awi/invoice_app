import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/invoice_model.dart';

class InvoicesListScreen extends ConsumerWidget {
  const InvoicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Replace with actual provider
    final invoices = <InvoiceModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter
            },
          ),
        ],
      ),
      body: invoices.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: AppSpacing.paddingScreen,
              itemCount: invoices.length,
              separatorBuilder: (_, __) => AppSpacing.gapVerticalSm,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return _InvoiceCard(invoice: invoice);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createInvoice),
        icon: const Icon(Icons.add),
        label: const Text('فاتورة جديدة'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textMuted,
          ),
          AppSpacing.gapVerticalLg,
          Text(
            'لا توجد فواتير',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          AppSpacing.gapVerticalSm,
          Text(
            'اضغط على الزر لإنشاء فاتورة جديدة',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.invoiceDetails,
          arguments: invoice,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blue600.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      invoice.invoiceNumber,
                      style: AppTypography.codeSmall.copyWith(
                        color: AppColors.blue600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormatter.formatDateAr(invoice.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              AppSpacing.gapVerticalSm,

              // Customer Name
              Text(
                invoice.customerName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              if (invoice.customerPhone != null) ...[
                AppSpacing.gapVerticalXs,
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    AppSpacing.gapHorizontalXs,
                    Text(
                      invoice.customerPhone!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],

              const Divider(height: 24),

              // Footer Row
              Row(
                children: [
                  // Items count
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      AppSpacing.gapHorizontalXs,
                      Text(
                        '${invoice.totalItemCount} قطعة',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatUSD(invoice.totalUSD),
                        style: AppTypography.moneyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatSYP(invoice.totalSYP),
                        style: AppTypography.moneySmall.copyWith(
                          color: AppColors.teal600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
