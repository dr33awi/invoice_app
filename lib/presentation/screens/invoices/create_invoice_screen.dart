import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/brand_model.dart';
import '../../../data/models/category_model.dart';
import '../providers/providers.dart';

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
  bool _isSaving = false;

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _totalUSD => _subtotal - _discount;
  int get _totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

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
    final exchangeRateAsync = ref.watch(exchangeRateNotifierProvider);
    final exchangeRate = exchangeRateAsync.valueOrNull ?? 14500.0;
    final totalSYP = _totalUSD * exchangeRate;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'فاتورة جديدة',
        subtitle: 'إنشاء فاتورة مبيعات',
        actions: [
          AppBarTextButton(
            text: 'حفظ',
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
                        '$_totalQuantity جوز',
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
                        _buildItemChip('الفئة: ${item.category}',
                            color: AppColors.blue600),
                      _buildItemChip('المقاس: ${item.size}'),
                      _buildItemChip('${item.packagesCount} طرد'),
                      _buildItemChip('${item.pairsPerPackage} جوز/طرد'),
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
                          '${item.quantity} جوز',
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
            _buildTotalRow('إجمالي الأزواج', '$_totalQuantity جوز'),
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
            const Divider(height: 24),
            _buildTotalRow(
                'الإجمالي (USD)', CurrencyFormatter.formatUSD(_totalUSD),
                isBold: true),
            AppSpacing.gapVerticalXs,
            _buildTotalRow(
                'الإجمالي (SYP)', CurrencyFormatter.formatSYP(totalSYP),
                isBold: true, valueColor: AppColors.teal600),
            AppSpacing.gapVerticalXs,
            Text(
              'سعر الصرف: ${NumberFormat('#,###').format(exchangeRate)} ل.س/دولار',
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
    final productsAsync = ref.read(productsNotifierProvider);
    final products = productsAsync.valueOrNull ?? [];

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
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setDialogState) {
          final packages = int.tryParse(packagesController.text) ?? 0;
          final pairsPerPackage =
              int.tryParse(pairsPerPackageController.text) ?? 0;
          final totalPairs = packages * pairsPerPackage;
          final pricePerPackage = double.tryParse(priceController.text) ?? 0;
          final totalPrice =
              packages * pricePerPackage; // السعر = عدد الطرود × سعر الطرد
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
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.branding_watermark_outlined,
                                        size: 48, color: AppColors.textMuted),
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
                              bottom: BorderSide(color: AppColors.borderColor)),
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
                                final name = addCategoryController.text.trim();
                                if (name.isEmpty) return;

                                final newCategory = CategoryModel(
                                  id: const Uuid().v4(),
                                  name: name,
                                  createdAt: DateTime.now(),
                                );
                                await ref
                                    .read(categoriesNotifierProvider.notifier)
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.category_outlined,
                                        size: 48, color: AppColors.textMuted),
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
                                        borderRadius: BorderRadius.circular(8),
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
                                          selectedCategoryName = category.name);
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
                          brandError = brand.isEmpty ? 'مطلوب' : null;
                          sizeError = size.isEmpty ? 'مطلوب' : null;
                          packagesError = packages <= 0 ? 'مطلوب' : null;
                          pairsError = pairsPerPackage <= 0 ? 'مطلوب' : null;
                          priceError = pricePerPackage <= 0 ? 'مطلوب' : null;

                          if (nameError != null ||
                              brandError != null ||
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
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('لا'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
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
                                brand: brand,
                                sizeRange: size,
                                wholesalePrice: pricePerPackage, // سعر الطرد
                                packagesCount: packages,
                                pairsPerPackage: pairsPerPackage,
                                category: selectedCategoryName,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              );

                              await ref
                                  .read(productsNotifierProvider.notifier)
                                  .addProduct(newProduct);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('تم حفظ المنتج في قائمة المنتجات'),
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
                                unitPrice: pricePerPair, // سعر الجوز الواحد
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
                                unitPrice: pricePerPair, // سعر الجوز الواحد
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
                              style:
                                  Theme.of(sheetContext).textTheme.bodySmall),
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
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
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
                            labelText: 'الماركة *',
                            prefixIcon:
                                const Icon(Icons.branding_watermark_outlined),
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
                                labelText: 'جوز*',
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
                              '$totalPairs جوز',
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
                          brandError = brand.isEmpty ? 'مطلوب' : null;
                          sizeError = size.isEmpty ? 'مطلوب' : null;
                          packagesError = packages <= 0 ? 'مطلوب' : null;
                          pairsError = pairsPerPackage <= 0 ? 'مطلوب' : null;
                          priceError = packagePrice <= 0 ? 'مطلوب' : null;

                          if (nameError != null ||
                              brandError != null ||
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
                            labelText: 'الماركة *',
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
                                labelText: 'جوز*',
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
                              '$totalPairs جوز',
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
    if (!_formKey.currentState!.validate()) return;

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
      final invoiceNumber = await ref
          .read(invoicesNotifierProvider.notifier)
          .generateInvoiceNumber();
      final totalSYP = _totalUSD * exchangeRate;

      final invoice = InvoiceModel(
        id: const Uuid().v4(),
        invoiceNumber: invoiceNumber,
        customerName: _customerController.text.trim(),
        customerPhone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        date: DateTime.now(),
        items: _items,
        subtotal: _subtotal,
        discount: _discount,
        totalUSD: _totalUSD,
        exchangeRate: exchangeRate,
        totalSYP: totalSYP,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: DateTime.now(),
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
