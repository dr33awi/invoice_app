import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/brand_model.dart';
import '../providers/providers.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AddProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sizeFromController = TextEditingController();
  final _sizeToController = TextEditingController();
  final _priceController = TextEditingController();
  final _packagesCountController = TextEditingController(text: '1');
  final _pairsPerPackageController = TextEditingController(text: '12');

  String? _selectedBrandName;
  String? _selectedCategoryName;
  bool _isLoading = false;
  bool _isSaving = false;
  ProductModel? _existingProduct;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final product = await ref
          .read(productRepositoryProvider)
          .getProductById(widget.productId!);
      if (product != null && mounted) {
        final sizeParts = product.sizeRange.split('-');
        setState(() {
          _existingProduct = product;
          _nameController.text = product.name;
          _selectedBrandName = product.brand;
          _selectedCategoryName = product.category;
          if (sizeParts.length == 2) {
            _sizeFromController.text = sizeParts[0].trim();
            _sizeToController.text = sizeParts[1].trim();
          } else {
            _sizeFromController.text = product.sizeRange;
          }
          _priceController.text = product.wholesalePrice.toString();
          _packagesCountController.text = product.packagesCount.toString();
          _pairsPerPackageController.text = product.pairsPerPackage.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeFromController.dispose();
    _sizeToController.dispose();
    _priceController.dispose();
    _packagesCountController.dispose();
    _pairsPerPackageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: _isEditing ? 'تعديل المنتج' : 'منتج جديد'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final packagesCount = int.tryParse(_packagesCountController.text) ?? 1;
    final pairsPerPackage = int.tryParse(_pairsPerPackageController.text) ?? 12;
    final totalPairs = packagesCount * pairsPerPackage;

    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'تعديل المنتج' : 'منتج جديد',
        subtitle: _isEditing ? 'تعديل بيانات المنتج' : 'إضافة منتج جديد',
        actions: [
          AppBarTextButton(
            text: 'حفظ',
            icon: Icons.save_outlined,
            isLoading: _isSaving,
            onPressed: _saveProduct,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            // المعلومات الأساسية
            Card(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المعلومات الأساسية',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    AppSpacing.gapVerticalMd,
                    // اسم المنتج
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المنتج *',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                        hintText: 'مثال: حذاء رياضي',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'الرجاء إدخال اسم المنتج'
                          : null,
                    ),
                    AppSpacing.gapVerticalMd,

                    // الماركة - حقل قابل للضغط (اختياري)
                    _buildSelectableField(
                      label: 'الماركة',
                      value: _selectedBrandName,
                      icon: Icons.branding_watermark_outlined,
                      onTap: () => _showBrandSelector(),
                      isRequired: false,
                    ),
                    AppSpacing.gapVerticalMd,

                    // نطاق المقاسات
                    Text(
                      'نطاق المقاسات *',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    AppSpacing.gapVerticalXs,
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sizeFromController,
                            decoration: const InputDecoration(
                                labelText: 'من', hintText: '24'),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'مطلوب' : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('—',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: AppColors.textMuted)),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _sizeToController,
                            decoration: const InputDecoration(
                                labelText: 'إلى', hintText: '36'),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'مطلوب' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalMd,

            // الطرود والكميات
            Card(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الطرود والكميات',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    AppSpacing.gapVerticalMd,
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _packagesCountController,
                            decoration: const InputDecoration(
                                labelText: 'عدد الطرود *',
                                prefixIcon: Icon(Icons.inventory_outlined)),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'مطلوب';
                              final num = int.tryParse(v);
                              if (num == null || num <= 0)
                                return 'قيمة غير صحيحة';
                              return null;
                            },
                          ),
                        ),
                        AppSpacing.gapHorizontalMd,
                        Expanded(
                          child: TextFormField(
                            controller: _pairsPerPackageController,
                            decoration: const InputDecoration(
                                labelText: 'الكمية*',
                                prefixIcon: Icon(Icons.straighten)),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'مطلوب';
                              final num = int.tryParse(v);
                              if (num == null || num <= 0)
                                return 'قيمة غير صحيحة';
                              return null;
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
                            '$totalPairs الكمية',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: AppColors.teal600,
                                    fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalMd,

            // التسعير
            Card(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التسعير',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    AppSpacing.gapVerticalMd,
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                          labelText: 'سعر(USD) *',
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: '\$ '),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'الرجاء إدخال السعر';
                        final price = double.tryParse(v);
                        if (price == null || price <= 0)
                          return 'الرجاء إدخال سعر صحيح';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalMd,

            // التصنيف
            Card(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التصنيف',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    AppSpacing.gapVerticalMd,
                    // الفئة - حقل قابل للضغط
                    _buildSelectableField(
                      label: 'الفئة',
                      value: _selectedCategoryName,
                      icon: Icons.category_outlined,
                      onTap: () => _showCategorySelector(),
                      isRequired: false,
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalXl,
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableField({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    bool isRequired = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      if (label.contains('الماركة')) {
                        _selectedBrandName = null;
                      } else {
                        _selectedCategoryName = null;
                      }
                    });
                  },
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
          errorText: isRequired && value == null ? null : null,
        ),
        child: Text(
          value ?? 'اختر...',
          style: TextStyle(
            color: value != null ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _showBrandSelector() {
    final brandsAsync = ref.read(brandsNotifierProvider);
    final brands = brandsAsync.valueOrNull ?? [];
    final addBrandController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    const Text('اختر الماركة',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 60),
                  ],
                ),
              ),

              // Add new brand
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

                        setState(() => _selectedBrandName = name);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('تم إضافة الماركة'),
                              backgroundColor: AppColors.success),
                        );
                      },
                      child: const Text('إضافة'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Brands list
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
                            const Text('أضف ماركة جديدة من الأعلى',
                                style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: brands.length,
                        itemBuilder: (context, index) {
                          final brand = brands[index];
                          final isSelected = _selectedBrandName == brand.name;
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
                              setState(() => _selectedBrandName = brand.name);
                              Navigator.pop(context);
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

  void _showCategorySelector() {
    final categoriesAsync = ref.read(categoriesNotifierProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    final addCategoryController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    const Text('اختر الفئة',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 60),
                  ],
                ),
              ),

              // Add new category
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

                        setState(() => _selectedCategoryName = name);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('تم إضافة الفئة'),
                              backgroundColor: AppColors.success),
                        );
                      },
                      child: const Text('إضافة'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Categories list
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
                            const Text('أضف فئة جديدة من الأعلى',
                                style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected =
                              _selectedCategoryName == category.name;
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
                              setState(
                                  () => _selectedCategoryName = category.name);
                              Navigator.pop(context);
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final sizeRange =
          '${_sizeFromController.text.trim()}-${_sizeToController.text.trim()}';

      final product = ProductModel(
        id: widget.productId ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        brandName: _selectedBrandName,
        sizeRange: sizeRange,
        wholesalePrice: double.parse(_priceController.text.trim()),
        categoryName: _selectedCategoryName,
        packagesCount: int.parse(_packagesCountController.text.trim()),
        pairsPerPackage: int.parse(_pairsPerPackageController.text.trim()),
        createdAt: _existingProduct?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await ref
            .read(productsNotifierProvider.notifier)
            .updateProduct(product);
      } else {
        await ref.read(productsNotifierProvider.notifier).addProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isEditing ? 'تم تحديث المنتج' : 'تم إضافة المنتج'),
              backgroundColor: AppColors.success),
        );
        Navigator.pop(context, product);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
