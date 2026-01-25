import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_colors.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_spacing.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_typography.dart';
import 'package:wholesale_shoes_invoice/core/utils/currency_formatter.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/providers/providers.dart';
import '../controller/create_invoice_controller.dart';
import '../providers/create_invoice_providers.dart';

/// قسم حسابات الفاتورة - الإجماليات والخصومات
class InvoiceCalculationSection extends ConsumerWidget {
  final InvoiceModel? originalInvoice;
  final CreateInvoiceController controller;

  const InvoiceCalculationSection({
    super.key,
    required this.originalInvoice,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createInvoiceNotifierProvider(originalInvoice));
    final exchangeRateAsync = ref.watch(exchangeRateNotifierProvider);
    final exchangeRate = exchangeRateAsync.valueOrNull ?? 12500.0;

    final effectiveRate = getEffectiveExchangeRate(
      state.customExchangeRate,
      state.useCustomExchangeRate,
      exchangeRate,
    );

    final subtotal = computeSubtotal(state.items);
    final totalUSD = computeTotalUSD(subtotal, state.discount);
    final totalSYP = computeTotalSYP(totalUSD, effectiveRate);
    final amountDue = computeAmountDue(totalUSD, state.paidAmount);
    final totalQuantity = computeTotalQuantity(state.items);

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
                  'الحسابات',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                _ExchangeRateButton(
                  effectiveRate: effectiveRate,
                  useCustom: state.useCustomExchangeRate,
                  customRate: state.customExchangeRate,
                  controller: controller,
                ),
              ],
            ),
            AppSpacing.gapVerticalMd,

            // الإجماليات
            _TotalRow(
              label: 'إجمالي الكمية',
              value: '$totalQuantity',
            ),
            AppSpacing.gapVerticalSm,
            _TotalRow(
              label: 'المجموع الفرعي',
              value: CurrencyFormatter.formatUSD(subtotal),
              valueColor: AppColors.textPrimary,
            ),
            AppSpacing.gapVerticalMd,

            // حقل الخصم
            _DiscountField(
              discount: state.discount,
              onChanged: (value) => controller.updateDiscount(value),
            ),
            AppSpacing.gapVerticalMd,

            // الإجمالي بالدولار
            Container(
              padding: AppSpacing.paddingCard,
              decoration: BoxDecoration(
                color: AppColors.teal600.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الإجمالي (USD)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    CurrencyFormatter.formatUSD(totalUSD),
                    style: AppTypography.moneyLarge
                        .copyWith(color: AppColors.teal600),
                  ),
                ],
              ),
            ),
            AppSpacing.gapVerticalSm,

            // الإجمالي بالليرة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.screenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الإجمالي (SYP)'),
                  Text(
                    CurrencyFormatter.formatSYP(totalSYP),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            AppSpacing.gapVerticalLg,

            // المبلغ المدفوع
            _PaidAmountField(
              paidAmount: state.paidAmount,
              totalUSD: totalUSD,
              onChanged: (value) => controller.updatePaidAmount(value),
            ),
            AppSpacing.gapVerticalMd,

            // المبلغ المتبقي
            Container(
              padding: AppSpacing.paddingCard,
              decoration: BoxDecoration(
                color: amountDue > 0
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: amountDue > 0
                      ? AppColors.error.withOpacity(0.3)
                      : AppColors.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    amountDue > 0 ? 'المبلغ المتبقي' : 'تم الدفع بالكامل',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          amountDue > 0 ? AppColors.error : AppColors.success,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatUSD(amountDue),
                    style: AppTypography.moneyLarge.copyWith(
                      color:
                          amountDue > 0 ? AppColors.error : AppColors.success,
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
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ExchangeRateButton extends StatelessWidget {
  final double effectiveRate;
  final bool useCustom;
  final double? customRate;
  final CreateInvoiceController controller;

  const _ExchangeRateButton({
    required this.effectiveRate,
    required this.useCustom,
    this.customRate,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showExchangeRateDialog(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: useCustom
              ? AppColors.blue600.withOpacity(0.1)
              : AppColors.screenBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: useCustom ? AppColors.blue600 : AppColors.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.currency_exchange,
              size: 16,
              color: useCustom ? AppColors.blue600 : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              CurrencyFormatter.formatNumber(effectiveRate),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: useCustom ? AppColors.blue600 : AppColors.textSecondary,
              ),
            ),
            if (useCustom) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.blue600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'مخصص',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.edit_outlined,
              size: 14,
              color: useCustom ? AppColors.blue600 : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showExchangeRateDialog(BuildContext context) {
    final textController = TextEditingController(
      text: customRate?.toStringAsFixed(0) ?? '',
    );
    bool useCustomTemp = useCustom;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('سعر الصرف'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text('استخدام سعر مخصص'),
                value: useCustomTemp,
                onChanged: (val) {
                  setDialogState(() => useCustomTemp = val);
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (useCustomTemp) ...[
                AppSpacing.gapVerticalSm,
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'السعر المخصص',
                    prefixText: 'SYP ',
                    hintText: 'مثال: 14500',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              AppSpacing.gapVerticalMd,
              Text(
                'السعر الحالي: ${CurrencyFormatter.formatNumber(effectiveRate)} SYP',
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final customValue = double.tryParse(textController.text);
                if (useCustomTemp && customValue != null && customValue > 0) {
                  controller.setCustomExchangeRate(customValue, true);
                } else if (!useCustomTemp) {
                  controller.setCustomExchangeRate(null, false);
                }
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountField extends StatefulWidget {
  final double discount;
  final ValueChanged<double> onChanged;

  const _DiscountField({
    required this.discount,
    required this.onChanged,
  });

  @override
  State<_DiscountField> createState() => _DiscountFieldState();
}

class _DiscountFieldState extends State<_DiscountField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.discount > 0 ? widget.discount.toStringAsFixed(2) : '',
    );
  }

  @override
  void didUpdateWidget(covariant _DiscountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // تحديث النص فقط إذا تغيرت القيمة من الخارج
    final currentText = _controller.text;
    final currentValue = double.tryParse(currentText) ?? 0;
    if ((widget.discount - currentValue).abs() > 0.01) {
      _controller.text =
          widget.discount > 0 ? widget.discount.toStringAsFixed(2) : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'الخصم (USD)',
        prefixIcon: const Icon(Icons.discount_outlined),
        prefixText: '\$ ',
        hintText: '0.00',
        suffixIcon: widget.discount > 0
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged(0);
                },
              )
            : null,
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final parsed = double.tryParse(value) ?? 0;
        widget.onChanged(parsed);
      },
    );
  }
}

class _PaidAmountField extends StatefulWidget {
  final double paidAmount;
  final double totalUSD;
  final ValueChanged<double> onChanged;

  const _PaidAmountField({
    required this.paidAmount,
    required this.totalUSD,
    required this.onChanged,
  });

  @override
  State<_PaidAmountField> createState() => _PaidAmountFieldState();
}

class _PaidAmountFieldState extends State<_PaidAmountField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.paidAmount > 0 ? widget.paidAmount.toStringAsFixed(2) : '',
    );
  }

  @override
  void didUpdateWidget(covariant _PaidAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentText = _controller.text;
    final currentValue = double.tryParse(currentText) ?? 0;
    if ((widget.paidAmount - currentValue).abs() > 0.01) {
      _controller.text =
          widget.paidAmount > 0 ? widget.paidAmount.toStringAsFixed(2) : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع (USD)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  prefixText: '\$ ',
                  hintText: '0.00',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final parsed = double.tryParse(value) ?? 0;
                  widget.onChanged(parsed);
                },
              ),
            ),
            AppSpacing.gapHorizontalSm,
            OutlinedButton(
              onPressed: () {
                _controller.text = widget.totalUSD.toStringAsFixed(2);
                widget.onChanged(widget.totalUSD);
              },
              child: const Text('كامل'),
            ),
          ],
        ),
      ],
    );
  }
}
