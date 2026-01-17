import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/settings_model.dart';

class ExchangeRateScreen extends ConsumerStatefulWidget {
  const ExchangeRateScreen({super.key});

  @override
  ConsumerState<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends ConsumerState<ExchangeRateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();

  // TODO: Get from provider
  double _currentRate = SettingsModel.defaultRate;

  @override
  void initState() {
    super.initState();
    _rateController.text = _currentRate.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سعر الصرف'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            // Current Rate Card
            Card(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.teal600.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.currency_exchange,
                        size: 32,
                        color: AppColors.teal600,
                      ),
                    ),
                    AppSpacing.gapVerticalMd,
                    Text(
                      'سعر صرف الدولار الأمريكي',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    AppSpacing.gapVerticalSm,
                    Text(
                      '1 USD = ${NumberFormat('#,###').format(_currentRate)} SYP',
                      style: AppTypography.moneyLarge.copyWith(
                        color: AppColors.blue600,
                      ),
                    ),
                    AppSpacing.gapVerticalXs,
                    Text(
                      'آخر تحديث: الآن',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalLg,

            // Update Rate Card
            Card(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تعديل السعر',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,
                    TextFormField(
                      controller: _rateController,
                      decoration: InputDecoration(
                        labelText: 'السعر الجديد',
                        prefixText: '1 USD = ',
                        suffixText: 'SYP',
                        prefixIcon: const Icon(Icons.edit_outlined),
                        helperText: 'أدخل سعر الصرف بالليرة السورية',
                      ),
                      keyboardType: TextInputType.number,
                      style: AppTypography.moneyMedium,
                      textAlign: TextAlign.center,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال سعر الصرف';
                        }
                        final rate = double.tryParse(value);
                        if (rate == null || rate <= 0) {
                          return 'الرجاء إدخال قيمة صحيحة';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Live preview
                        final rate = double.tryParse(value);
                        if (rate != null && rate > 0) {
                          setState(() {
                            _currentRate = rate;
                          });
                        }
                      },
                    ),
                    AppSpacing.gapVerticalLg,

                    // Quick Values
                    Text(
                      'قيم سريعة',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    AppSpacing.gapVerticalSm,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickValueChip(14000),
                        _buildQuickValueChip(14500),
                        _buildQuickValueChip(15000),
                        _buildQuickValueChip(15500),
                        _buildQuickValueChip(16000),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalLg,

            // Save Button
            FilledButton.icon(
              onPressed: _saveRate,
              icon: const Icon(Icons.save),
              label: const Text('حفظ السعر'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),

            AppSpacing.gapVerticalMd,

            // Info Text
            Card(
              color: AppColors.info.withOpacity(0.1),
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 20,
                    ),
                    AppSpacing.gapHorizontalSm,
                    Expanded(
                      child: Text(
                        'سيتم استخدام هذا السعر في جميع الفواتير الجديدة',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.info,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickValueChip(int value) {
    final isSelected = _rateController.text == value.toString();
    return ActionChip(
      label: Text(NumberFormat('#,###').format(value)),
      onPressed: () {
        setState(() {
          _rateController.text = value.toString();
          _currentRate = value.toDouble();
        });
      },
      backgroundColor: isSelected ? AppColors.blue600.withOpacity(0.2) : null,
      side: BorderSide(
        color: isSelected ? AppColors.blue600 : AppColors.borderColor,
      ),
    );
  }

  Future<void> _saveRate() async {
    if (!_formKey.currentState!.validate()) return;

    final newRate = double.parse(_rateController.text);

    // TODO: Save using provider

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ سعر الصرف بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }
}
