import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/brand_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/customer_model.dart';
import '../providers/providers.dart';
import '../providers/customer_providers.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final InvoiceModel? invoice; // الفاتورة للتعديل (اختياري)

  const CreateInvoiceScreen({super.key, this.invoice});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _paidAmountController = TextEditingController(text: '0'); // العربون

  // معرف العميل المختار - يستخدم للتحديث التلقائي
  String? _selectedCustomerId;

  // بيانات العميل المحلية (تستخدم كـ fallback)
  String? _customerName;
  String? _customerPhone;
  String? _customerAddress;

  // طريقة الدفع
  String _paymentMethod = InvoiceModel.paymentCash;

  // سعر الصرف المخصص (للتعديل)
  double? _customExchangeRate;
  bool _useCustomExchangeRate = false;

  List<InvoiceItemModel> _items = [];
  bool _isSaving = false;
  bool _isEditing = false;

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _paidAmount => double.tryParse(_paidAmountController.text) ?? 0;
  double get _totalUSD => _subtotal - _discount;
  double get _amountDue => _totalUSD - _paidAmount; // المبلغ المستحق
  int get _totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  @override
  void initState() {
    super.initState();
    // تحميل بيانات الفاتورة إذا كانت للتعديل
    if (widget.invoice != null) {
      _isEditing = true;
      _loadInvoiceData();
    }
  }

  void _loadInvoiceData() {
    final invoice = widget.invoice!;
    _selectedCustomerId = invoice.customerId;
    _customerName = invoice.customerName;
    _customerPhone = invoice.customerPhone;
    _customerAddress = invoice.customerAddress;
    _items = List.from(invoice.items);
    _discountController.text = invoice.discount.toString();
    _paidAmountController.text = invoice.paidAmount.toString();
    _notesController.text = invoice.notes ?? '';
    _paymentMethod = invoice.paymentMethod;

    // حفظ سعر الصرف الأصلي للفاتورة
    _customExchangeRate = invoice.exchangeRate;
    _useCustomExchangeRate = true;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exchangeRateAsync = ref.watch(exchangeRateNotifierProvider);
    final currentExchangeRate = exchangeRateAsync.valueOrNull ?? 14500.0;

    // استخدام سعر الصرف المخصص عند التعديل أو السعر الحالي للفواتير الجديدة
    final exchangeRate = _useCustomExchangeRate && _customExchangeRate != null
        ? _customExchangeRate!
        : currentExchangeRate;
    final totalSYP = _totalUSD * exchangeRate;

    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'تعديل الفاتورة' : 'فاتورة جديدة',
        subtitle:
            _isEditing ? widget.invoice!.invoiceNumber : 'إنشاء فاتورة مبيعات',
        actions: [
          AppBarTextButton(
            text: _isEditing ? 'تحديث' : 'حفظ',
            icon: Icons.save_outlined,
            isLoading: _isSaving,
            onPressed: () => _saveInvoice(exchangeRate),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            _buildCustomerCard(),
            AppSpacing.gapVerticalMd,
            _buildPaymentMethodCard(), // إضافة كارت طريقة الدفع
            AppSpacing.gapVerticalMd,
            _buildItemsSection(),
            AppSpacing.gapVerticalMd,
            _buildTotalsCard(exchangeRate, totalSYP),
            AppSpacing.gapVerticalMd,
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
    // مراقبة بيانات العميل للتحديث التلقائي
    final customerData = _selectedCustomerId != null
        ? ref.watch(customerDataProvider(_selectedCustomerId!))
        : null;

    // استخدام بيانات العميل المحدثة أو البيانات المحلية كـ fallback
    final displayName = customerData?.name ?? _customerName;
    final displayPhone = customerData?.phone ?? _customerPhone;
    final displayAddress = customerData?.address ?? _customerAddress;

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
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            AppSpacing.gapVerticalMd,
            // حقل اختيار العميل
            InkWell(
              onTap: () => _showCustomerSelector(),
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'اسم العميل *',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (displayName != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() {
                            _selectedCustomerId = null;
                            _customerName = null;
                            _customerPhone = null;
                            _customerAddress = null;
                          }),
                        ),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.blue600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                child: Text(
                  displayName ?? 'اختر العميل...',
                  style: TextStyle(
                    color: displayName != null
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            // عرض رقم الهاتف إذا كان موجوداً - محدث تلقائياً
            if (displayPhone != null && displayPhone.isNotEmpty) ...[
              AppSpacing.gapVerticalSm,
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.teal600.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 18, color: AppColors.teal600),
                    AppSpacing.gapHorizontalSm,
                    Text(
                      displayPhone,
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.teal600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            // عرض العنوان إذا كان موجوداً - محدث تلقائياً
            if (displayAddress != null && displayAddress.isNotEmpty) ...[
              AppSpacing.gapVerticalSm,
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.blue600.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 18, color: AppColors.blue600),
                    AppSpacing.gapHorizontalSm,
                    Expanded(
                      child: Text(
                        displayAddress,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.blue600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// كارت اختيار طريقة الدفع
  Widget _buildPaymentMethodCard() {
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
                // زر نقداً
                Expanded(
                  child: _buildPaymentOption(
                    value: InvoiceModel.paymentCash,
                    label: 'نقداً',
                    icon: Icons.payments_outlined,
                    color: AppColors.success,
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                // زر تحويل
                Expanded(
                  child: _buildPaymentOption(
                    value: InvoiceModel.paymentTransfer,
                    label: 'تحويل',
                    icon: Icons.account_balance_outlined,
                    color: AppColors.blue600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
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

  /// دالة لعرض نافذة إضافة عميل جديد
  void _showAddNewCustomerDialog(BuildContext parentContext, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: AppColors.borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('إلغاء'),
                  ),
                  const Text(
                    'عميل جديد',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('الرجاء إدخال اسم العميل'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      final newCustomer = CustomerModel(
                        id: const Uuid().v4(),
                        name: name,
                        phone: phoneController.text.trim().isNotEmpty
                            ? phoneController.text.trim()
                            : null,
                        address: addressController.text.trim().isNotEmpty
                            ? addressController.text.trim()
                            : null,
                        notes: notesController.text.trim().isNotEmpty
                            ? notesController.text.trim()
                            : null,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      // حفظ العميل في قاعدة البيانات
                      await ref
                          .read(reactiveCustomersProvider.notifier)
                          .addCustomer(newCustomer);

                      // تحديد العميل الجديد باستخدام ID
                      setState(() {
                        _selectedCustomerId = newCustomer.id;
                        _customerName = name;
                        _customerPhone = phoneController.text.trim().isNotEmpty
                            ? phoneController.text.trim()
                            : null;
                        _customerAddress =
                            addressController.text.trim().isNotEmpty
                                ? addressController.text.trim()
                                : null;
                      });

                      // إغلاق نافذة إضافة العميل
                      Navigator.pop(sheetContext);
                      // إغلاق نافذة اختيار العميل
                      Navigator.pop(parentContext);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إضافة العميل واختياره'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    child: const Text('إضافة'),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                padding: AppSpacing.paddingScreen,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم العميل *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                  ),
                  AppSpacing.gapVerticalMd,
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  AppSpacing.gapVerticalMd,
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  AppSpacing.gapVerticalMd,
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات',
                      prefixIcon: Icon(Icons.note_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerSelector() {
    // استخدام Reactive Provider للحصول على قائمة العملاء
    final customersState = ref.read(reactiveCustomersProvider);
    final customers = customersState.customers;
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          // تصفية العملاء حسب البحث
          final filteredCustomers = searchQuery.isEmpty
              ? customers
              : customers.where((c) {
                  final query = searchQuery.toLowerCase();
                  return c.name.toLowerCase().contains(query) ||
                      (c.phone?.contains(query) ?? false);
                }).toList();

          return Container(
            height: MediaQuery.of(sheetContext).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('إلغاء'),
                      ),
                      const Text('اختر العميل',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 60),
                    ],
                  ),
                ),
                // حقل البحث
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) =>
                        setSheetState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'بحث عن عميل...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surfaceBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.borderColor),
                      ),
                    ),
                  ),
                ),
                // زر إضافة عميل جديد
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FilledButton.icon(
                    onPressed: () =>
                        _showAddNewCustomerDialog(sheetContext, ref),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('إضافة عميل جديد'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
                AppSpacing.gapVerticalMd,
                const Divider(height: 1),
                // قائمة العملاء
                Expanded(
                  child: filteredCustomers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 48, color: AppColors.textMuted),
                              AppSpacing.gapVerticalMd,
                              Text(
                                searchQuery.isEmpty
                                    ? 'لا يوجد عملاء'
                                    : 'لا توجد نتائج',
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              if (searchQuery.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'أضف عميل جديد من الأعلى',
                                    style: Theme.of(sheetContext)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = filteredCustomers[index];
                            final isSelected =
                                _selectedCustomerId == customer.id;
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.blue600
                                      : AppColors.teal600.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          color: Colors.white)
                                      : Text(
                                          customer.name.isNotEmpty
                                              ? customer.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.teal600,
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                customer.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                              subtitle: customer.phone != null
                                  ? Row(
                                      children: [
                                        const Icon(Icons.phone_outlined,
                                            size: 14,
                                            color: AppColors.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          customer.phone!,
                                          textDirection: TextDirection.ltr,
                                        ),
                                      ],
                                    )
                                  : null,
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle,
                                      color: AppColors.blue600)
                                  : null,
                              onTap: () {
                                // حفظ معرف العميل للتحديث التلقائي
                                setState(() {
                                  _selectedCustomerId = customer.id;
                                  _customerName = customer.name;
                                  _customerPhone = customer.phone;
                                  _customerAddress = customer.address;
                                });
                                Navigator.pop(sheetContext);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المنتجات',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (_items.isNotEmpty)
                      Text(
                        '$_totalQuantity الكمية',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.teal600),
                      ),
                  ],
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
                    Icon(Icons.inventory_2_outlined,
                        size: 48, color: AppColors.textMuted),
                    AppSpacing.gapVerticalSm,
                    Text('لا توجد منتجات مضافة',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) =>
                    _buildItemTile(_items[index], index),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(InvoiceItemModel item, int index) {
    return InkWell(
      onTap: () => _showEditItemDialog(item, index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info
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
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (item.brand.isNotEmpty)
                        _buildItemChip('الماركة: ${item.brand}'),
                      if (item.category != null && item.category!.isNotEmpty)
                        _buildItemChip(
                          'الفئة: ${item.category}',
                        ),
                      _buildItemChip('المقاس: ${item.size}'),
                      _buildItemChip('${item.packagesCount} طرد'),
                    ],
                  ),
                  AppSpacing.gapVerticalXs,
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.teal600.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.quantity} الكمية',
                          style: AppTypography.labelSmall.copyWith(
                              color: AppColors.teal600,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      AppSpacing.gapHorizontalSm,
                      Text(
                        '× ${CurrencyFormatter.formatUSD(item.unitPrice)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Total & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatUSD(item.total),
                  style: AppTypography.moneyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.blue600, size: 20),
                      onPressed: () => _showEditItemDialog(item, index),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'تعديل',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error, size: 20),
                      onPressed: () => _removeItem(index),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemChip(String label, {Color? color}) {
    final chipColor = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color != null ? color.withOpacity(0.1) : AppColors.screenBg,
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: color?.withOpacity(0.3) ?? AppColors.borderColor),
      ),
      child: Text(label,
          style: AppTypography.labelSmall
              .copyWith(color: chipColor, fontSize: 10)),
    );
  }

  Widget _buildTotalsCard(double exchangeRate, double totalSYP) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          children: [
            _buildTotalRow('عدد الأصناف', '${_items.length}'),
            AppSpacing.gapVerticalXs,
            _buildTotalRow('إجمالي الأزواج', '$_totalQuantity الكمية'),
            const Divider(height: 16),
            _buildTotalRow(
                'المجموع الفرعي', CurrencyFormatter.formatUSD(_subtotal)),
            AppSpacing.gapVerticalSm,
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalSm,
            // حقل العربون
            Row(
              children: [
                const Text('العربون:'),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: TextFormField(
                    controller: _paidAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      suffixIcon: _paidAmount > 0
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _paidAmountController.text = '0';
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildTotalRow(
                'الإجمالي (USD)', CurrencyFormatter.formatUSD(_totalUSD),
                isBold: true),
            if (_paidAmount > 0) ...[
              AppSpacing.gapVerticalXs,
              _buildTotalRow('العربون المدفوع',
                  '- ${CurrencyFormatter.formatUSD(_paidAmount)}',
                  valueColor: AppColors.success),
              AppSpacing.gapVerticalXs,
              _buildTotalRow(
                  'المبلغ المستحق', CurrencyFormatter.formatUSD(_amountDue),
                  isBold: true, valueColor: AppColors.warning),
            ],
            AppSpacing.gapVerticalXs,
            _buildTotalRow(
                'الإجمالي (SYP)', CurrencyFormatter.formatSYP(totalSYP),
                isBold: true, valueColor: AppColors.teal600),
            AppSpacing.gapVerticalSm,
            // سعر الصرف مع زر التعديل
            InkWell(
              onTap: () => _showExchangeRateDialog(exchangeRate),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _useCustomExchangeRate
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.surfaceBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _useCustomExchangeRate
                        ? AppColors.warning.withOpacity(0.3)
                        : AppColors.borderColor,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.currency_exchange,
                          size: 16,
                          color: _useCustomExchangeRate
                              ? AppColors.warning
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'سعر الصرف: ${NumberFormat('#,###').format(exchangeRate)} ل.س/دولار',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _useCustomExchangeRate
                                        ? AppColors.warning
                                        : AppColors.textMuted,
                                    fontWeight: _useCustomExchangeRate
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_useCustomExchangeRate) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'مخصص',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: _useCustomExchangeRate
                              ? AppColors.warning
                              : AppColors.textMuted,
                        ),
                      ],
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
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
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

  /// عرض حوار تعديل سعر الصرف
  void _showExchangeRateDialog(double currentRate) {
    final controller =
        TextEditingController(text: currentRate.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.currency_exchange, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            const Text('تعديل سعر الصرف'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // حقل إدخال السعر
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'سعر الصرف (ل.س/دولار)',
                prefixIcon: const Icon(Icons.monetization_on_outlined),
                suffixText: 'ل.س',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_isEditing && widget.invoice != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.teal600.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history,
                        size: 16, color: AppColors.teal600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سعر البيع الأصلي: ${NumberFormat('#,###').format(widget.invoice!.exchangeRate)} ل.س',
                        style: const TextStyle(
                          color: AppColors.teal600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          // زر تطبيق
          FilledButton(
            onPressed: () {
              final newRate = double.tryParse(controller.text);
              if (newRate != null && newRate > 0) {
                setState(() {
                  _customExchangeRate = newRate;
                  _useCustomExchangeRate = true;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('تطبيق'),
          ),
          // زر إلغاء
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() async {
    // انتظار تحميل المنتجات إذا كانت في حالة تحميل
    final productsAsync = ref.read(productsNotifierProvider);
    if (productsAsync.isLoading) {
      // إظهار مؤشر تحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // انتظار اكتمال التحميل
      await ref.read(productsNotifierProvider.notifier).loadProducts();

      if (mounted) Navigator.pop(context);
    }

    if (!mounted) return;

    final nameController = TextEditingController();
    final sizeController = TextEditingController();
    final packagesController = TextEditingController(text: '1');
    final pairsPerPackageController = TextEditingController(text: '12');
    final priceController = TextEditingController();
    ProductModel? selectedProduct;
    String? selectedBrandName;
    String? selectedCategoryName;

    // متغيرات للتحقق من الأخطاء
    String? nameError;
    String? brandError;
    String? sizeError;
    String? packagesError;
    String? pairsError;
    String? priceError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, ref, _) {
          final products =
              ref.watch(productsNotifierProvider).valueOrNull ?? [];

          return StatefulBuilder(
            builder: (sheetContext, setDialogState) {
              final packages = int.tryParse(packagesController.text) ?? 0;
              final pairsPerPackage =
                  int.tryParse(pairsPerPackageController.text) ?? 0;
              final totalPairs = packages * pairsPerPackage;
              final pricePerPackage =
                  double.tryParse(priceController.text) ?? 0;
              final totalPrice =
                  packages * pricePerPackage; // السعر = عدد الطرود × سعر الطرد
              final pricePerPair = packages > 0 && totalPairs > 0
                  ? totalPrice / totalPairs
                  : 0.0;

              // دالة لعرض منتقي الماركات
              void showBrandSelector() {
                final brandsAsync = ref.read(brandsNotifierProvider);
                final brands = brandsAsync.valueOrNull ?? [];
                final addBrandController = TextEditingController();

                showModalBottomSheet(
                  context: sheetContext,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (brandContext) => StatefulBuilder(
                    builder: (brandContext, setBrandState) => Container(
                      height: MediaQuery.of(brandContext).size.height * 0.6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom:
                                      BorderSide(color: AppColors.borderColor)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(brandContext),
                                  child: const Text('إلغاء'),
                                ),
                                const Text('اختر الماركة',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 60),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: addBrandController,
                                    decoration: const InputDecoration(
                                      hintText: 'أضف ماركة جديدة...',
                                      prefixIcon: Icon(Icons.add),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                AppSpacing.gapHorizontalSm,
                                FilledButton(
                                  onPressed: () async {
                                    final name = addBrandController.text.trim();
                                    if (name.isEmpty) return;

                                    final newBrand = BrandModel(
                                      id: const Uuid().v4(),
                                      name: name,
                                      createdAt: DateTime.now(),
                                    );
                                    await ref
                                        .read(brandsNotifierProvider.notifier)
                                        .addBrand(newBrand);

                                    setDialogState(() {
                                      selectedBrandName = name;
                                      brandError = null;
                                    });
                                    Navigator.pop(brandContext);
                                  },
                                  child: const Text('إضافة'),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: brands.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.branding_watermark_outlined,
                                            size: 48,
                                            color: AppColors.textMuted),
                                        AppSpacing.gapVerticalMd,
                                        const Text('لا توجد ماركات'),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: brands.length,
                                    itemBuilder: (context, index) {
                                      final brand = brands[index];
                                      final isSelected =
                                          selectedBrandName == brand.name;
                                      return ListTile(
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.blue600
                                                : AppColors.teal600
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            isSelected
                                                ? Icons.check
                                                : Icons
                                                    .branding_watermark_outlined,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.teal600,
                                          ),
                                        ),
                                        title: Text(brand.name,
                                            style: TextStyle(
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500)),
                                        trailing: isSelected
                                            ? const Icon(Icons.check_circle,
                                                color: AppColors.blue600)
                                            : null,
                                        onTap: () {
                                          setDialogState(() {
                                            selectedBrandName = brand.name;
                                            brandError = null;
                                          });
                                          Navigator.pop(brandContext);
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // دالة لعرض منتقي الفئات
              void showCategorySelector() {
                final categoriesAsync = ref.read(categoriesNotifierProvider);
                final categories = categoriesAsync.valueOrNull ?? [];
                final addCategoryController = TextEditingController();

                showModalBottomSheet(
                  context: sheetContext,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (catContext) => StatefulBuilder(
                    builder: (catContext, setCatState) => Container(
                      height: MediaQuery.of(catContext).size.height * 0.6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom:
                                      BorderSide(color: AppColors.borderColor)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(catContext),
                                  child: const Text('إلغاء'),
                                ),
                                const Text('اختر الفئة',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 60),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: addCategoryController,
                                    decoration: const InputDecoration(
                                      hintText: 'أضف فئة جديدة...',
                                      prefixIcon: Icon(Icons.add),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                AppSpacing.gapHorizontalSm,
                                FilledButton(
                                  onPressed: () async {
                                    final name =
                                        addCategoryController.text.trim();
                                    if (name.isEmpty) return;

                                    final newCategory = CategoryModel(
                                      id: const Uuid().v4(),
                                      name: name,
                                      createdAt: DateTime.now(),
                                    );
                                    await ref
                                        .read(
                                            categoriesNotifierProvider.notifier)
                                        .addCategory(newCategory);

                                    setDialogState(
                                        () => selectedCategoryName = name);
                                    Navigator.pop(catContext);
                                  },
                                  child: const Text('إضافة'),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: categories.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.category_outlined,
                                            size: 48,
                                            color: AppColors.textMuted),
                                        AppSpacing.gapVerticalMd,
                                        const Text('لا توجد فئات'),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: categories.length,
                                    itemBuilder: (context, index) {
                                      final category = categories[index];
                                      final isSelected =
                                          selectedCategoryName == category.name;
                                      return ListTile(
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.blue600
                                                : AppColors.blue600
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            isSelected
                                                ? Icons.check
                                                : Icons.category_outlined,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.blue600,
                                          ),
                                        ),
                                        title: Text(category.name,
                                            style: TextStyle(
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500)),
                                        trailing: isSelected
                                            ? const Icon(Icons.check_circle,
                                                color: AppColors.blue600)
                                            : null,
                                        onTap: () {
                                          setDialogState(() =>
                                              selectedCategoryName =
                                                  category.name);
                                          Navigator.pop(catContext);
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Container(
                height: MediaQuery.of(sheetContext).size.height * 0.85,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: AppColors.borderColor)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('إلغاء'),
                          ),
                          const Text('إضافة منتج',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          FilledButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              final brand = selectedBrandName ?? '';
                              final size = sizeController.text.trim();

                              // التحقق من الحقول وعرض الأخطاء
                              bool hasError = false;

                              nameError = name.isEmpty ? 'مطلوب' : null;
                              sizeError = size.isEmpty ? 'مطلوب' : null;
                              packagesError = packages <= 0 ? 'مطلوب' : null;
                              pairsError =
                                  pairsPerPackage <= 0 ? 'مطلوب' : null;
                              priceError =
                                  pricePerPackage <= 0 ? 'مطلوب' : null;

                              if (nameError != null ||
                                  sizeError != null ||
                                  packagesError != null ||
                                  pairsError != null ||
                                  priceError != null) {
                                hasError = true;
                              }

                              if (hasError) {
                                setDialogState(() {});
                                return;
                              }

                              // إذا كان المنتج مدخل يدوياً (ليس من القائمة)
                              if (selectedProduct == null) {
                                // السؤال عن حفظ المنتج
                                final shouldSave = await showDialog<bool>(
                                  context: sheetContext,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('حفظ المنتج'),
                                    content: const Text(
                                        'هل تريد حفظ هذا المنتج في قائمة المنتجات لاستخدامه لاحقاً؟'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('لا'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('نعم، احفظ'),
                                      ),
                                    ],
                                  ),
                                );

                                String productId = const Uuid().v4();

                                // حفظ المنتج إذا وافق المستخدم
                                if (shouldSave == true) {
                                  final newProduct = ProductModel(
                                    id: productId,
                                    name: name,
                                    brandName: brand,
                                    sizeRange: size,
                                    wholesalePrice:
                                        pricePerPackage, // سعر الطرد
                                    packagesCount: packages,
                                    pairsPerPackage: pairsPerPackage,
                                    categoryName: selectedCategoryName,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );

                                  await ref
                                      .read(productsNotifierProvider.notifier)
                                      .addProduct(newProduct);

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'تم حفظ المنتج في قائمة المنتجات'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                }

                                setState(() {
                                  _items.add(InvoiceItemModel(
                                    productId: productId,
                                    productName: name,
                                    brand: brand,
                                    size: size,
                                    packagesCount: packages,
                                    pairsPerPackage: pairsPerPackage,
                                    quantity: totalPairs,
                                    unitPrice:
                                        pricePerPair, // سعر الكمية الواحدة
                                    total: totalPrice,
                                    category: selectedCategoryName,
                                  ));
                                });
                              } else {
                                // المنتج مختار من القائمة
                                setState(() {
                                  _items.add(InvoiceItemModel(
                                    productId: selectedProduct!.id,
                                    productName: name,
                                    brand: brand,
                                    size: size,
                                    packagesCount: packages,
                                    pairsPerPackage: pairsPerPackage,
                                    quantity: totalPairs,
                                    unitPrice:
                                        pricePerPair, // سعر الكمية الواحدة
                                    total: totalPrice,
                                    category: selectedCategoryName,
                                  ));
                                });
                              }

                              Navigator.pop(sheetContext);
                            },
                            child: const Text('إضافة'),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: ListView(
                        padding: AppSpacing.paddingScreen,
                        children: [
                          // اختيار من المنتجات
                          if (products.isNotEmpty) ...[
                            Text('اختر من المنتجات',
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: AppColors.textSecondary)),
                            AppSpacing.gapVerticalSm,
                            DropdownButtonFormField<ProductModel>(
                              decoration: const InputDecoration(
                                hintText: 'اختر منتج...',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                              items: products.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                      '${p.name} - ${p.brand} (${p.sizeRange})'),
                                );
                              }).toList(),
                              onChanged: (product) {
                                if (product != null) {
                                  setDialogState(() {
                                    selectedProduct = product;
                                    nameController.text = product.name;
                                    selectedBrandName = product.brand;
                                    sizeController.text = product.sizeRange;
                                    packagesController.text =
                                        product.packagesCount.toString();
                                    pairsPerPackageController.text =
                                        product.pairsPerPackage.toString();
                                    priceController.text =
                                        product.wholesalePrice.toString();
                                    selectedCategoryName = product.category;
                                    // مسح الأخطاء
                                    nameError = null;
                                    brandError = null;
                                    sizeError = null;
                                    packagesError = null;
                                    pairsError = null;
                                    priceError = null;
                                  });
                                }
                              },
                            ),
                            AppSpacing.gapVerticalMd,
                            const Divider(),
                            AppSpacing.gapVerticalMd,
                            Center(
                              child: Text('أو أدخل يدوياً',
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .bodySmall),
                            ),
                            AppSpacing.gapVerticalMd,
                          ],

                          // المعلومات الأساسية
                          Text('المعلومات الأساسية',
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: AppColors.textSecondary)),
                          AppSpacing.gapVerticalSm,
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'اسم المنتج *',
                              prefixIcon:
                                  const Icon(Icons.inventory_2_outlined),
                              errorText: nameError,
                            ),
                            onChanged: (_) => setDialogState(() {
                              nameError = null;
                            }),
                          ),
                          AppSpacing.gapVerticalSm,
                          // حقل الماركة - قابل للضغط
                          InkWell(
                            onTap: () => showBrandSelector(),
                            borderRadius: BorderRadius.circular(8),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'الماركة',
                                prefixIcon: const Icon(
                                    Icons.branding_watermark_outlined),
                                errorText: brandError,
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (selectedBrandName != null)
                                      IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => setDialogState(
                                            () => selectedBrandName = null),
                                      ),
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.blue600,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.add,
                                          color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                              child: Text(
                                selectedBrandName ?? 'اختر الماركة...',
                                style: TextStyle(
                                  color: selectedBrandName != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          AppSpacing.gapVerticalSm,
                          TextField(
                            controller: sizeController,
                            decoration: InputDecoration(
                              labelText: 'نطاق المقاسات *',
                              prefixIcon: const Icon(Icons.straighten),
                              hintText: '24-36',
                              errorText: sizeError,
                            ),
                            onChanged: (_) => setDialogState(() {
                              sizeError = null;
                            }),
                          ),
                          AppSpacing.gapVerticalLg,

                          // الطرود والكميات
                          Text('الطرود والكميات',
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: AppColors.textSecondary)),
                          AppSpacing.gapVerticalSm,
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: packagesController,
                                  decoration: InputDecoration(
                                    labelText: 'عدد الطرود *',
                                    errorText: packagesError,
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setDialogState(() {
                                    packagesError = null;
                                  }),
                                ),
                              ),
                              AppSpacing.gapHorizontalMd,
                              Expanded(
                                child: TextField(
                                  controller: pairsPerPackageController,
                                  decoration: InputDecoration(
                                    labelText: 'الكمية*',
                                    errorText: pairsError,
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setDialogState(() {
                                    pairsError = null;
                                  }),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.gapVerticalMd,
                          Container(
                            padding: AppSpacing.paddingCard,
                            decoration: BoxDecoration(
                              color: AppColors.teal600.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('إجمالي الأزواج'),
                                Text(
                                  '$totalPairs الكمية',
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: AppColors.teal600,
                                          fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.gapVerticalLg,

                          // السعر
                          Text('السعر',
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: AppColors.textSecondary)),
                          AppSpacing.gapVerticalSm,
                          TextField(
                            controller: priceController,
                            decoration: InputDecoration(
                              labelText: 'سعر الطرد (USD) *',
                              prefixIcon: const Icon(Icons.attach_money),
                              prefixText: '\$ ',
                              errorText: priceError,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setDialogState(() {
                              priceError = null;
                            }),
                          ),
                          AppSpacing.gapVerticalLg,

                          // التصنيف
                          Text('التصنيف (اختياري)',
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: AppColors.textSecondary)),
                          AppSpacing.gapVerticalSm,
                          // حقل الفئة - قابل للضغط
                          InkWell(
                            onTap: () => showCategorySelector(),
                            borderRadius: BorderRadius.circular(8),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'الفئة',
                                prefixIcon: const Icon(Icons.category_outlined),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (selectedCategoryName != null)
                                      IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => setDialogState(
                                            () => selectedCategoryName = null),
                                      ),
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.blue600,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.add,
                                          color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                              child: Text(
                                selectedCategoryName ?? 'اختر الفئة...',
                                style: TextStyle(
                                  color: selectedCategoryName != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          AppSpacing.gapVerticalMd,

                          // الإجمالي
                          Container(
                            padding: AppSpacing.paddingCard,
                            decoration: BoxDecoration(
                              color: AppColors.blue600.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.blue600.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('إجمالي السعر'),
                                Text(
                                  CurrencyFormatter.formatUSD(totalPrice),
                                  style: AppTypography.moneyLarge
                                      .copyWith(color: AppColors.blue600),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.gapVerticalXl,
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditItemDialog(InvoiceItemModel item, int index) {
    final nameController = TextEditingController(text: item.productName);
    final sizeController = TextEditingController(text: item.size);
    final packagesController =
        TextEditingController(text: item.packagesCount.toString());
    final pairsPerPackageController =
        TextEditingController(text: item.pairsPerPackage.toString());
    // حساب سعر الطرد من الإجمالي
    final pricePerPackage =
        item.packagesCount > 0 ? item.total / item.packagesCount : 0.0;
    final priceController =
        TextEditingController(text: pricePerPackage.toStringAsFixed(2));

    // تحويل السلسلة الفارغة إلى null
    String? selectedBrandName = item.brand.isNotEmpty ? item.brand : null;
    String? selectedCategoryName = item.category;
    String? nameError;
    String? brandError;
    String? sizeError;
    String? packagesError;
    String? pairsError;
    String? priceError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setDialogState) {
          final packages = int.tryParse(packagesController.text) ?? 0;
          final pairsPerPackage =
              int.tryParse(pairsPerPackageController.text) ?? 0;
          final totalPairs = packages * pairsPerPackage;
          final packagePrice = double.tryParse(priceController.text) ?? 0;
          final totalPrice = packages * packagePrice;
          final pricePerPair =
              packages > 0 && totalPairs > 0 ? totalPrice / totalPairs : 0.0;

          // دالة لعرض منتقي الماركات
          void showBrandSelector() {
            final brandsAsync = ref.read(brandsNotifierProvider);
            final brands = brandsAsync.valueOrNull ?? [];
            final addBrandController = TextEditingController();

            showModalBottomSheet(
              context: sheetContext,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (brandContext) => Container(
                height: MediaQuery.of(brandContext).size.height * 0.6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: AppColors.borderColor)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(brandContext),
                            child: const Text('إلغاء'),
                          ),
                          const Text('اختر الماركة',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 60),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: addBrandController,
                              decoration: const InputDecoration(
                                hintText: 'أضف ماركة جديدة...',
                                prefixIcon: Icon(Icons.add),
                                isDense: true,
                              ),
                            ),
                          ),
                          AppSpacing.gapHorizontalSm,
                          FilledButton(
                            onPressed: () async {
                              final name = addBrandController.text.trim();
                              if (name.isEmpty) return;

                              final newBrand = BrandModel(
                                id: const Uuid().v4(),
                                name: name,
                                createdAt: DateTime.now(),
                              );
                              await ref
                                  .read(brandsNotifierProvider.notifier)
                                  .addBrand(newBrand);

                              setDialogState(() {
                                selectedBrandName = name;
                                brandError = null;
                              });
                              Navigator.pop(brandContext);
                            },
                            child: const Text('إضافة'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: brands.isEmpty
                          ? const Center(child: Text('لا توجد ماركات'))
                          : ListView.builder(
                              itemCount: brands.length,
                              itemBuilder: (context, idx) {
                                final brand = brands[idx];
                                final isSelected =
                                    selectedBrandName == brand.name;
                                return ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.blue600
                                          : AppColors.teal600.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isSelected
                                          ? Icons.check
                                          : Icons.branding_watermark_outlined,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.teal600,
                                    ),
                                  ),
                                  title: Text(brand.name),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle,
                                          color: AppColors.blue600)
                                      : null,
                                  onTap: () {
                                    setDialogState(() {
                                      selectedBrandName = brand.name;
                                      brandError = null;
                                    });
                                    Navigator.pop(brandContext);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            height: MediaQuery.of(sheetContext).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('إلغاء'),
                      ),
                      const Text('تعديل المنتج',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      FilledButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          final brand = selectedBrandName ?? '';
                          final size = sizeController.text.trim();

                          bool hasError = false;
                          nameError = name.isEmpty ? 'مطلوب' : null;
                          sizeError = size.isEmpty ? 'مطلوب' : null;
                          packagesError = packages <= 0 ? 'مطلوب' : null;
                          pairsError = pairsPerPackage <= 0 ? 'مطلوب' : null;
                          priceError = packagePrice <= 0 ? 'مطلوب' : null;

                          if (nameError != null ||
                              sizeError != null ||
                              packagesError != null ||
                              pairsError != null ||
                              priceError != null) {
                            hasError = true;
                          }

                          if (hasError) {
                            setDialogState(() {});
                            return;
                          }

                          setState(() {
                            _items[index] = InvoiceItemModel(
                              productId: item.productId,
                              productName: name,
                              brand: brand,
                              size: size,
                              packagesCount: packages,
                              pairsPerPackage: pairsPerPackage,
                              quantity: totalPairs,
                              unitPrice: pricePerPair,
                              total: totalPrice,
                              category: selectedCategoryName,
                            );
                          });

                          Navigator.pop(sheetContext);
                        },
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: ListView(
                    padding: AppSpacing.paddingScreen,
                    children: [
                      Text('المعلومات الأساسية',
                          style: Theme.of(sheetContext)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: AppColors.textSecondary)),
                      AppSpacing.gapVerticalSm,
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'اسم المنتج *',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                          errorText: nameError,
                        ),
                        onChanged: (_) => setDialogState(() {
                          nameError = null;
                        }),
                      ),
                      AppSpacing.gapVerticalSm,
                      // حقل الماركة
                      InkWell(
                        onTap: () => showBrandSelector(),
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'الماركة',
                            prefixIcon:
                                const Icon(Icons.branding_watermark_outlined),
                            errorText: brandError,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selectedBrandName != null &&
                                    selectedBrandName!.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setDialogState(
                                        () => selectedBrandName = null),
                                  ),
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue600,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                          child: Text(
                            (selectedBrandName != null &&
                                    selectedBrandName!.isNotEmpty)
                                ? selectedBrandName!
                                : 'اختر الماركة...',
                            style: TextStyle(
                              color: (selectedBrandName != null &&
                                      selectedBrandName!.isNotEmpty)
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapVerticalSm,
                      TextField(
                        controller: sizeController,
                        decoration: InputDecoration(
                          labelText: 'نطاق المقاسات *',
                          prefixIcon: const Icon(Icons.straighten),
                          hintText: '24-36',
                          errorText: sizeError,
                        ),
                        onChanged: (_) => setDialogState(() {
                          sizeError = null;
                        }),
                      ),
                      AppSpacing.gapVerticalLg,

                      Text('الطرود والكميات',
                          style: Theme.of(sheetContext)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: AppColors.textSecondary)),
                      AppSpacing.gapVerticalSm,
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: packagesController,
                              decoration: InputDecoration(
                                labelText: 'عدد الطرود *',
                                errorText: packagesError,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDialogState(() {
                                packagesError = null;
                              }),
                            ),
                          ),
                          AppSpacing.gapHorizontalMd,
                          Expanded(
                            child: TextField(
                              controller: pairsPerPackageController,
                              decoration: InputDecoration(
                                labelText: 'الكمية*',
                                errorText: pairsError,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDialogState(() {
                                pairsError = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapVerticalMd,
                      Container(
                        padding: AppSpacing.paddingCard,
                        decoration: BoxDecoration(
                          color: AppColors.teal600.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('إجمالي الأزواج'),
                            Text(
                              '$totalPairs الكمية',
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: AppColors.teal600,
                                      fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapVerticalLg,

                      Text('السعر',
                          style: Theme.of(sheetContext)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: AppColors.textSecondary)),
                      AppSpacing.gapVerticalSm,
                      TextField(
                        controller: priceController,
                        decoration: InputDecoration(
                          labelText: 'سعر الطرد (USD) *',
                          prefixIcon: const Icon(Icons.attach_money),
                          prefixText: '\$ ',
                          errorText: priceError,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setDialogState(() {
                          priceError = null;
                        }),
                      ),
                      AppSpacing.gapVerticalLg,

                      // التصنيف
                      Text('التصنيف (اختياري)',
                          style: Theme.of(sheetContext)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: AppColors.textSecondary)),
                      AppSpacing.gapVerticalSm,
                      InkWell(
                        onTap: () {
                          final categoriesAsync =
                              ref.read(categoriesNotifierProvider);
                          final categories = categoriesAsync.valueOrNull ?? [];
                          final addCatController = TextEditingController();

                          showModalBottomSheet(
                            context: sheetContext,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (catContext) => Container(
                              height:
                                  MediaQuery.of(catContext).size.height * 0.6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: AppColors.borderColor)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(catContext),
                                          child: const Text('إلغاء'),
                                        ),
                                        const Text('اختر الفئة',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 60),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: addCatController,
                                            decoration: const InputDecoration(
                                              hintText: 'أضف فئة جديدة...',
                                              prefixIcon: Icon(Icons.add),
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        AppSpacing.gapHorizontalSm,
                                        FilledButton(
                                          onPressed: () async {
                                            final name =
                                                addCatController.text.trim();
                                            if (name.isEmpty) return;

                                            final newCat = CategoryModel(
                                              id: const Uuid().v4(),
                                              name: name,
                                              createdAt: DateTime.now(),
                                            );
                                            await ref
                                                .read(categoriesNotifierProvider
                                                    .notifier)
                                                .addCategory(newCat);

                                            setDialogState(() =>
                                                selectedCategoryName = name);
                                            Navigator.pop(catContext);
                                          },
                                          child: const Text('إضافة'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  Expanded(
                                    child: categories.isEmpty
                                        ? const Center(
                                            child: Text('لا توجد فئات'))
                                        : ListView.builder(
                                            itemCount: categories.length,
                                            itemBuilder: (context, idx) {
                                              final cat = categories[idx];
                                              final isSelected =
                                                  selectedCategoryName ==
                                                      cat.name;
                                              return ListTile(
                                                leading: Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? AppColors.blue600
                                                        : AppColors.blue600
                                                            .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    isSelected
                                                        ? Icons.check
                                                        : Icons
                                                            .category_outlined,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : AppColors.blue600,
                                                  ),
                                                ),
                                                title: Text(cat.name),
                                                trailing: isSelected
                                                    ? const Icon(
                                                        Icons.check_circle,
                                                        color:
                                                            AppColors.blue600)
                                                    : null,
                                                onTap: () {
                                                  setDialogState(() =>
                                                      selectedCategoryName =
                                                          cat.name);
                                                  Navigator.pop(catContext);
                                                },
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'الفئة',
                            prefixIcon: const Icon(Icons.category_outlined),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selectedCategoryName != null &&
                                    selectedCategoryName!.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setDialogState(
                                        () => selectedCategoryName = null),
                                  ),
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue600,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                          child: Text(
                            (selectedCategoryName != null &&
                                    selectedCategoryName!.isNotEmpty)
                                ? selectedCategoryName!
                                : 'اختر الفئة...',
                            style: TextStyle(
                              color: (selectedCategoryName != null &&
                                      selectedCategoryName!.isNotEmpty)
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapVerticalMd,

                      Container(
                        padding: AppSpacing.paddingCard,
                        decoration: BoxDecoration(
                          color: AppColors.blue600.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.blue600.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('إجمالي السعر'),
                            Text(
                              CurrencyFormatter.formatUSD(totalPrice),
                              style: AppTypography.moneyLarge
                                  .copyWith(color: AppColors.blue600),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapVerticalXl,
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _saveInvoice(double exchangeRate) async {
    // التحقق من اختيار العميل
    if (_customerName == null || _customerName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار العميل'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('الرجاء إضافة منتج واحد على الأقل'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final totalSYP = _totalUSD * exchangeRate;

      if (_isEditing) {
        // تحديث الفاتورة الموجودة - مع الحفاظ على الباركود الأصلي
        final updatedInvoice = InvoiceModel(
          id: widget.invoice!.id,
          invoiceNumber: widget.invoice!.invoiceNumber,
          customerId: _selectedCustomerId ??
              widget.invoice!.customerId, // حفظ معرف العميل
          customerName: _customerName!,
          customerPhone: _customerPhone,
          customerAddress: _customerAddress,
          date: widget.invoice!.date,
          items: _items,
          subtotal: _subtotal,
          discount: _discount,
          totalUSD: _totalUSD,
          exchangeRate: exchangeRate,
          totalIQD: totalSYP,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          createdAt: widget.invoice!.createdAt,
          barcodeValue:
              widget.invoice!.barcodeValue, // الحفاظ على الباركود الأصلي
          paymentMethod: _paymentMethod, // طريقة الدفع
          paidAmount: _paidAmount, // العربون
        );

        await ref
            .read(invoicesNotifierProvider.notifier)
            .updateInvoice(updatedInvoice);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('تم تحديث الفاتورة بنجاح'),
                backgroundColor: AppColors.success),
          );
          Navigator.pop(context, updatedInvoice);
        }
      } else {
        // إنشاء فاتورة جديدة
        final invoiceNumber = await ref
            .read(invoicesNotifierProvider.notifier)
            .generateInvoiceNumber();

        // توليد الباركود من رقم الفاتورة
        final barcodeValue = InvoiceModel.generateBarcode(invoiceNumber);

        final invoice = InvoiceModel(
          id: const Uuid().v4(),
          invoiceNumber: invoiceNumber,
          customerId: _selectedCustomerId, // حفظ معرف العميل للتحديث التلقائي
          customerName: _customerName!,
          customerPhone: _customerPhone,
          customerAddress: _customerAddress,
          date: DateTime.now(),
          items: _items,
          subtotal: _subtotal,
          discount: _discount,
          totalUSD: _totalUSD,
          exchangeRate: exchangeRate,
          totalIQD: totalSYP,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          createdAt: DateTime.now(),
          barcodeValue: barcodeValue, // الباركود الفريد للفاتورة
          paymentMethod: _paymentMethod, // طريقة الدفع
          paidAmount: _paidAmount, // العربون
        );

        await ref.read(invoicesNotifierProvider.notifier).addInvoice(invoice);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('تم حفظ الفاتورة بنجاح'),
                backgroundColor: AppColors.success),
          );
          Navigator.pop(context, invoice);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ في حفظ الفاتورة: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
