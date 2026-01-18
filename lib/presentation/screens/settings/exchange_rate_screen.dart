import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/settings_model.dart';
import '../providers/providers.dart';

class ExchangeRateScreen extends ConsumerStatefulWidget {
  const ExchangeRateScreen({super.key});

  @override
  ConsumerState<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends ConsumerState<ExchangeRateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();
  bool _isSaving = false;
  double _currentRate = SettingsModel.defaultRate;

  @override
  void initState() {
    super.initState();
    _loadCurrentRate();
  }

  void _loadCurrentRate() {
    final rateAsync = ref.read(exchangeRateNotifierProvider);
    rateAsync.whenData((rate) {
      setState(() {
        _currentRate = rate;
        _rateController.text = rate.toStringAsFixed(0);
      });
    });
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exchangeRateAsync = ref.watch(exchangeRateNotifierProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'سعر الصرف',
        subtitle: 'تعديل سعر صرف الدولار',
        actions: [
          AppBarTextButton(
            text: 'حفظ',
            icon: Icons.save_outlined,
            isLoading: _isSaving,
            onPressed: _saveRate,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
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
                          borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.currency_exchange,
                          size: 32, color: AppColors.teal600),
                    ),
                    AppSpacing.gapVerticalMd,
                    Text('سعر صرف الدولار الأمريكي',
                        style: Theme.of(context).textTheme.titleMedium),
                    AppSpacing.gapVerticalSm,
                    exchangeRateAsync.when(
                      data: (rate) => Text(
                          '1 USD = ${NumberFormat('#,###').format(rate)} SYP',
                          style: AppTypography.moneyLarge
                              .copyWith(color: AppColors.blue600)),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => Text(
                          '1 USD = ${NumberFormat('#,###').format(_currentRate)} SYP',
                          style: AppTypography.moneyLarge
                              .copyWith(color: AppColors.blue600)),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalLg,
            Card(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تعديل السعر',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    AppSpacing.gapVerticalMd,
                    TextFormField(
                      controller: _rateController,
                      decoration: const InputDecoration(
                          labelText: 'السعر الجديد',
                          prefixText: '1 USD = ',
                          suffixText: 'SYP',
                          prefixIcon: Icon(Icons.edit_outlined)),
                      keyboardType: TextInputType.number,
                      style: AppTypography.moneyMedium,
                      textAlign: TextAlign.center,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'الرجاء إدخال سعر الصرف';
                        final rate = double.tryParse(v);
                        if (rate == null || rate <= 0)
                          return 'الرجاء إدخال قيمة صحيحة';
                        return null;
                      },
                      onChanged: (v) {
                        final rate = double.tryParse(v);
                        if (rate != null && rate > 0)
                          setState(() => _currentRate = rate);
                      },
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalMd,
            Card(
              color: AppColors.info.withOpacity(0.1),
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.info, size: 20),
                    AppSpacing.gapHorizontalSm,
                    Expanded(
                        child: Text(
                            'سيتم استخدام هذا السعر في جميع الفواتير الجديدة',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.info))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final newRate = double.parse(_rateController.text);
      await ref.read(exchangeRateNotifierProvider.notifier).setRate(newRate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم حفظ سعر الصرف بنجاح'),
            backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
