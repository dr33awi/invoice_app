import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_colors.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_spacing.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import '../controller/create_invoice_controller.dart';
import '../providers/create_invoice_providers.dart';

/// قسم طريقة الدفع - UI فقط
class PaymentSection extends ConsumerWidget {
  final InvoiceModel? originalInvoice;
  final CreateInvoiceController controller;

  const PaymentSection({
    super.key,
    required this.originalInvoice,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createInvoiceNotifierProvider(originalInvoice));

    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'طريقة الدفع',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            AppSpacing.gapVerticalMd,
            Row(
              children: [
                Expanded(
                  child: _PaymentOptionButton(
                    value: InvoiceModel.paymentCash,
                    label: 'نقداً',
                    icon: Icons.payments_outlined,
                    color: AppColors.success,
                    isSelected: state.paymentMethod == InvoiceModel.paymentCash,
                    onTap: () =>
                        controller.setPaymentMethod(InvoiceModel.paymentCash),
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: _PaymentOptionButton(
                    value: InvoiceModel.paymentTransfer,
                    label: 'تحويل',
                    icon: Icons.account_balance_outlined,
                    color: AppColors.blue600,
                    isSelected:
                        state.paymentMethod == InvoiceModel.paymentTransfer,
                    onTap: () => controller
                        .setPaymentMethod(InvoiceModel.paymentTransfer),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionButton extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionButton({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 24,
            ),
            AppSpacing.gapHorizontalSm,
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isSelected ? color : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
            if (isSelected) ...[
              AppSpacing.gapHorizontalSm,
              Icon(Icons.check_circle, color: color, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
