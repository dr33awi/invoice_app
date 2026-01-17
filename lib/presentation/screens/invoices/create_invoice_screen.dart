import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/settings_model.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController(text: '0');

  List<InvoiceItemModel> _items = [];

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _totalUSD => _subtotal - _discount;

  // TODO: Get from provider
  double get _exchangeRate => SettingsModel.defaultRate;
  double get _totalSYP => _totalUSD * _exchangeRate;

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة جديدة'),
        actions: [
          TextButton.icon(
            onPressed: _saveInvoice,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            // Customer Info Card
            _buildCustomerCard(),
            AppSpacing.gapVerticalMd,

            // Items Section
            _buildItemsSection(),
            AppSpacing.gapVerticalMd,

            // Totals Card
            _buildTotalsCard(),
            AppSpacing.gapVerticalMd,

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: Icon(Icons.note_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),

            AppSpacing.gapVerticalXl,
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات العميل',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            AppSpacing.gapVerticalMd,
            TextFormField(
              controller: _customerController,
              decoration: const InputDecoration(
                labelText: 'اسم العميل *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال اسم العميل';
                }
                return null;
              },
            ),
            AppSpacing.gapVerticalSm,
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                FilledButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة'),
                ),
              ],
            ),
            AppSpacing.gapVerticalSm,
            if (_items.isEmpty)
              Container(
                padding: AppSpacing.paddingLg,
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    AppSpacing.gapVerticalSm,
                    Text(
                      'لا توجد منتجات مضافة',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _buildItemTile(item, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(InvoiceItemModel item, int index) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.productName,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        'المقاس: ${item.size} | الكمية: ${item.quantity} | السعر: ${CurrencyFormatter.formatUSD(item.unitPrice)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyFormatter.formatUSD(item.total),
            style: AppTypography.moneySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _removeItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          children: [
            _buildTotalRow(
                'المجموع الفرعي', CurrencyFormatter.formatUSD(_subtotal)),
            AppSpacing.gapVerticalSm,

            // Discount Input
            Row(
              children: [
                const Text('الخصم:'),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: '\$ ',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            _buildTotalRow(
              'الإجمالي (USD)',
              CurrencyFormatter.formatUSD(_totalUSD),
              isBold: true,
            ),
            AppSpacing.gapVerticalXs,
            _buildTotalRow(
              'الإجمالي (SYP)',
              CurrencyFormatter.formatSYP(_totalSYP),
              isBold: true,
              valueColor: AppColors.teal600,
            ),
            AppSpacing.gapVerticalXs,
            Text(
              'سعر الصرف: ${NumberFormat('#,###').format(_exchangeRate)} ل.س/دولار',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value,
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

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final sizeController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة منتج'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم المنتج *'),
              ),
              AppSpacing.gapVerticalSm,
              TextField(
                controller: sizeController,
                decoration: const InputDecoration(labelText: 'المقاس *'),
              ),
              AppSpacing.gapVerticalSm,
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'الكمية *'),
                keyboardType: TextInputType.number,
              ),
              AppSpacing.gapVerticalSm,
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'السعر (USD) *',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final size = sizeController.text.trim();
              final quantity = int.tryParse(quantityController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0;

              if (name.isEmpty || size.isEmpty || quantity <= 0 || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء ملء جميع الحقول')),
                );
                return;
              }

              setState(() {
                _items.add(InvoiceItemModel(
                  productId: const Uuid().v4(),
                  productName: name,
                  size: size,
                  quantity: quantity,
                  unitPrice: price,
                  total: quantity * price,
                ));
              });

              Navigator.pop(context);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إضافة منتج واحد على الأقل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final invoice = InvoiceModel(
      id: const Uuid().v4(),
      invoiceNumber: _generateInvoiceNumber(),
      customerName: _customerController.text.trim(),
      customerPhone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      date: DateTime.now(),
      items: _items,
      subtotal: _subtotal,
      discount: _discount,
      totalUSD: _totalUSD,
      exchangeRate: _exchangeRate,
      totalSYP: _totalSYP,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    // TODO: Save invoice using provider

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الفاتورة بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, invoice);
    }
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(7);
    return 'INV-${now.year}-$timestamp';
  }
}
