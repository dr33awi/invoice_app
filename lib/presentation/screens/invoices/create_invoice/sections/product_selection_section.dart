import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_colors.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_spacing.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_typography.dart';
import 'package:wholesale_shoes_invoice/core/utils/currency_formatter.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/providers/providers.dart';
import '../controller/create_invoice_controller.dart';
import '../providers/create_invoice_providers.dart';

/// قسم اختيار المنتجات - UI فقط
class ProductSelectionSection extends ConsumerWidget {
  final InvoiceModel? originalInvoice;
  final CreateInvoiceController controller;

  const ProductSelectionSection({
    super.key,
    required this.originalInvoice,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createInvoiceNotifierProvider(originalInvoice));
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
                    if (state.items.isNotEmpty)
                      Text(
                        '$totalQuantity الكمية',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.teal600),
                      ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showAddItemDialog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة'),
                ),
              ],
            ),
            AppSpacing.gapVerticalSm,
            if (state.items.isEmpty)
              _buildEmptyState(context)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) => _ItemTile(
                  item: state.items[index],
                  index: index,
                  onEdit: () => _showEditItemDialog(
                      context, ref, state.items[index], index),
                  onDelete: () => controller.removeItem(index),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
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
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) async {
    final productsAsync = ref.read(productsNotifierProvider);
    if (productsAsync.isLoading) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
      await ref.read(productsNotifierProvider.notifier).loadProducts();
      if (context.mounted) Navigator.pop(context);
    }

    if (!context.mounted) return;

    _showItemDialog(
      context: context,
      ref: ref,
      title: 'إضافة منتج',
      isEditing: false,
      onSave: (dialogState, productId) {
        final item = dialogState.toInvoiceItem(productId);
        controller.addItem(item);
      },
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    WidgetRef ref,
    InvoiceItemModel item,
    int index,
  ) {
    final initialState = AddItemDialogState.fromInvoiceItem(item);

    _showItemDialog(
      context: context,
      ref: ref,
      title: 'تعديل المنتج',
      isEditing: true,
      initialState: initialState,
      existingProductId: item.productId,
      onSave: (dialogState, productId) {
        final updatedItem = dialogState.toInvoiceItem(productId);
        controller.updateItem(index, updatedItem);
      },
    );
  }

  void _showItemDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required bool isEditing,
    AddItemDialogState? initialState,
    String? existingProductId,
    required void Function(AddItemDialogState state, String productId) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddEditItemSheet(
        title: title,
        isEditing: isEditing,
        initialState: initialState,
        existingProductId: existingProductId,
        controller: controller,
        onSave: onSave,
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final InvoiceItemModel item;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemTile({
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        _ItemChip(label: 'الماركة: ${item.brand}'),
                      if (item.category != null && item.category!.isNotEmpty)
                        _ItemChip(label: 'الفئة: ${item.category}'),
                      _ItemChip(label: 'المقاس: ${item.size}'),
                      _ItemChip(label: '${item.packagesCount} طرد'),
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
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'تعديل',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error, size: 20),
                      onPressed: onDelete,
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
}

class _ItemChip extends StatelessWidget {
  final String label;
  final Color? color;

  const _ItemChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color != null ? color!.withOpacity(0.1) : AppColors.screenBg,
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: color?.withOpacity(0.3) ?? AppColors.borderColor),
      ),
      child: Text(label,
          style: AppTypography.labelSmall
              .copyWith(color: chipColor, fontSize: 10)),
    );
  }
}

class _AddEditItemSheet extends ConsumerStatefulWidget {
  final String title;
  final bool isEditing;
  final AddItemDialogState? initialState;
  final String? existingProductId;
  final CreateInvoiceController controller;
  final void Function(AddItemDialogState state, String productId) onSave;

  const _AddEditItemSheet({
    required this.title,
    required this.isEditing,
    this.initialState,
    this.existingProductId,
    required this.controller,
    required this.onSave,
  });

  @override
  ConsumerState<_AddEditItemSheet> createState() => _AddEditItemSheetState();
}

class _AddEditItemSheetState extends ConsumerState<_AddEditItemSheet> {
  late TextEditingController _nameController;
  late TextEditingController _sizeController;
  late TextEditingController _packagesController;
  late TextEditingController _pairsController;
  late TextEditingController _priceController;

  late AddItemDialogState _dialogState;

  @override
  void initState() {
    super.initState();
    _dialogState = widget.initialState ?? const AddItemDialogState();

    _nameController = TextEditingController(text: _dialogState.name);
    _sizeController = TextEditingController(text: _dialogState.size);
    _packagesController =
        TextEditingController(text: _dialogState.packagesCount.toString());
    _pairsController =
        TextEditingController(text: _dialogState.pairsPerPackage.toString());
    _priceController =
        TextEditingController(text: _dialogState.pricePerPackage.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _packagesController.dispose();
    _pairsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {
      _dialogState = _dialogState.copyWith(
        name: _nameController.text.trim(),
        size: _sizeController.text.trim(),
        packagesCount: int.tryParse(_packagesController.text) ?? 0,
        pairsPerPackage: int.tryParse(_pairsController.text) ?? 0,
        pricePerPackage: double.tryParse(_priceController.text) ?? 0,
      );
    });
  }

  Future<void> _handleSave() async {
    _updateState();
    final validated = _dialogState.validate();
    setState(() => _dialogState = validated);

    if (validated.hasErrors) return;

    String productId;
    if (widget.existingProductId != null) {
      productId = widget.existingProductId!;
    } else if (_dialogState.selectedProduct != null) {
      productId = _dialogState.selectedProduct!.id;
    } else {
      // منتج جديد مدخل يدوياً
      final shouldSave = await showDialog<bool>(
        context: context,
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

      if (shouldSave == true) {
        final newProduct = await widget.controller.saveNewProduct(_dialogState);
        productId = newProduct.id;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ المنتج في قائمة المنتجات'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        productId = const Uuid().v4();
      }
    }

    widget.onSave(_dialogState, productId);
    if (mounted) Navigator.pop(context);
  }

  void _loadFromProduct(ProductModel product) {
    setState(() {
      _dialogState = _dialogState.loadFromProduct(product);
      _nameController.text = product.name;
      _sizeController.text = product.sizeRange;
      _packagesController.text = product.packagesCount.toString();
      _pairsController.text = product.pairsPerPackage.toString();
      _priceController.text = product.wholesalePrice.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsNotifierProvider).valueOrNull ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: AppSpacing.paddingScreen,
              children: [
                if (products.isNotEmpty && !widget.isEditing) ...[
                  _buildProductSelector(products),
                  AppSpacing.gapVerticalMd,
                  const Divider(),
                  AppSpacing.gapVerticalMd,
                  Center(
                    child: Text('أو أدخل يدوياً',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  AppSpacing.gapVerticalMd,
                ],
                _buildBasicInfoSection(),
                AppSpacing.gapVerticalLg,
                _buildQuantitySection(),
                AppSpacing.gapVerticalLg,
                _buildPriceSection(),
                AppSpacing.gapVerticalLg,
                _buildCategorySection(),
                AppSpacing.gapVerticalMd,
                _buildTotalDisplay(),
                AppSpacing.gapVerticalXl,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          Text(widget.title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          FilledButton(
            onPressed: _handleSave,
            child: Text(widget.isEditing ? 'حفظ' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelector(List<ProductModel> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اختر من المنتجات',
            style: Theme.of(context)
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
              child: Text('${p.name} - ${p.brand} (${p.sizeRange})'),
            );
          }).toList(),
          onChanged: (product) {
            if (product != null) _loadFromProduct(product);
          },
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المعلومات الأساسية',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: AppColors.textSecondary)),
        AppSpacing.gapVerticalSm,
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'اسم المنتج *',
            prefixIcon: const Icon(Icons.inventory_2_outlined),
            errorText: _dialogState.nameError,
          ),
          onChanged: (_) => setState(() {
            _dialogState = _dialogState.copyWith(clearNameError: true);
          }),
        ),
        AppSpacing.gapVerticalSm,
        _BrandSelectorField(
          selectedBrandName: _dialogState.brandName,
          controller: widget.controller,
          onChanged: (brandName) {
            setState(() {
              _dialogState = _dialogState.copyWith(
                brandName: brandName,
                clearBrandName: brandName == null,
              );
            });
          },
        ),
        AppSpacing.gapVerticalSm,
        TextField(
          controller: _sizeController,
          decoration: InputDecoration(
            labelText: 'نطاق المقاسات *',
            prefixIcon: const Icon(Icons.straighten),
            hintText: '24-36',
            errorText: _dialogState.sizeError,
          ),
          onChanged: (_) => setState(() {
            _dialogState = _dialogState.copyWith(clearSizeError: true);
          }),
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الطرود والكميات',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: AppColors.textSecondary)),
        AppSpacing.gapVerticalSm,
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _packagesController,
                decoration: InputDecoration(
                  labelText: 'عدد الطرود *',
                  errorText: _dialogState.packagesError,
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  _updateState();
                  setState(() {
                    _dialogState =
                        _dialogState.copyWith(clearPackagesError: true);
                  });
                },
              ),
            ),
            AppSpacing.gapHorizontalMd,
            Expanded(
              child: TextField(
                controller: _pairsController,
                decoration: InputDecoration(
                  labelText: 'الكمية*',
                  errorText: _dialogState.pairsError,
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  _updateState();
                  setState(() {
                    _dialogState = _dialogState.copyWith(clearPairsError: true);
                  });
                },
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
                '${_dialogState.totalPairs} الكمية',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.teal600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('السعر',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: AppColors.textSecondary)),
        AppSpacing.gapVerticalSm,
        TextField(
          controller: _priceController,
          decoration: InputDecoration(
            labelText: 'سعر الطرد (USD) *',
            prefixIcon: const Icon(Icons.attach_money),
            prefixText: '\$ ',
            errorText: _dialogState.priceError,
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) {
            _updateState();
            setState(() {
              _dialogState = _dialogState.copyWith(clearPriceError: true);
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('التصنيف (اختياري)',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: AppColors.textSecondary)),
        AppSpacing.gapVerticalSm,
        _CategorySelectorField(
          selectedCategoryName: _dialogState.categoryName,
          controller: widget.controller,
          onChanged: (categoryName) {
            setState(() {
              _dialogState = _dialogState.copyWith(
                categoryName: categoryName,
                clearCategoryName: categoryName == null,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildTotalDisplay() {
    return Container(
      padding: AppSpacing.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.blue600.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue600.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('إجمالي السعر'),
          Text(
            CurrencyFormatter.formatUSD(_dialogState.totalPrice),
            style: AppTypography.moneyLarge.copyWith(color: AppColors.blue600),
          ),
        ],
      ),
    );
  }
}

class _BrandSelectorField extends ConsumerWidget {
  final String? selectedBrandName;
  final CreateInvoiceController controller;
  final ValueChanged<String?> onChanged;

  const _BrandSelectorField({
    required this.selectedBrandName,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _showBrandSelector(context, ref),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'الماركة',
          prefixIcon: const Icon(Icons.branding_watermark_outlined),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedBrandName != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.blue600,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
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
    );
  }

  void _showBrandSelector(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.read(brandsNotifierProvider);
    final brands = brandsAsync.valueOrNull ?? [];
    final addBrandController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Container(
          height: MediaQuery.of(sheetContext).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
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
                        await controller.addNewBrand(name);
                        onChanged(name);
                        Navigator.pop(sheetContext);
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
                          final isSelected = selectedBrandName == brand.name;
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
                              onChanged(brand.name);
                              Navigator.pop(sheetContext);
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
}

class _CategorySelectorField extends ConsumerWidget {
  final String? selectedCategoryName;
  final CreateInvoiceController controller;
  final ValueChanged<String?> onChanged;

  const _CategorySelectorField({
    required this.selectedCategoryName,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _showCategorySelector(context, ref),
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
                  onPressed: () => onChanged(null),
                ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.blue600,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
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
    );
  }

  void _showCategorySelector(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.read(categoriesNotifierProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    final addCategoryController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Container(
          height: MediaQuery.of(sheetContext).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
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
                        await controller.addNewCategory(name);
                        onChanged(name);
                        Navigator.pop(sheetContext);
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
                                    : AppColors.blue600.withOpacity(0.1),
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
                              onChanged(category.name);
                              Navigator.pop(sheetContext);
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
}
