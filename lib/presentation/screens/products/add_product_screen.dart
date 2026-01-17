import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/product_model.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String? productId;

  const AddProductScreen({
    super.key,
    this.productId,
  });

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _sizeController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadProduct();
    }
  }

  void _loadProduct() {
    // TODO: Load product from provider
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل المنتج' : 'منتج جديد'),
        actions: [
          TextButton.icon(
            onPressed: _saveProduct,
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
            // Basic Info Card
            Card(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المعلومات الأساسية',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,

                    // Arabic Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المنتج (عربي) *',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال اسم المنتج';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.gapVerticalSm,

                    // English Name
                    TextFormField(
                      controller: _nameEnController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المنتج (إنجليزي)',
                        prefixIcon: Icon(Icons.translate),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    AppSpacing.gapVerticalSm,

                    // Size
                    TextFormField(
                      controller: _sizeController,
                      decoration: const InputDecoration(
                        labelText: 'المقاس *',
                        prefixIcon: Icon(Icons.straighten),
                        hintText: 'مثال: 42',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال المقاس';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalMd,

            // Pricing Card
            Card(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التسعير',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,

                    // Price
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'سعر الجملة (USD) *',
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال السعر';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'الرجاء إدخال سعر صحيح';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapVerticalMd,

            // Category Card
            Card(
              child: Padding(
                padding: AppSpacing.paddingCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التصنيف',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    AppSpacing.gapVerticalMd,

                    // Category
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'الفئة',
                        prefixIcon: Icon(Icons.category_outlined),
                        hintText: 'مثال: رجالي، نسائي، أطفال',
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    AppSpacing.gapVerticalSm,

                    // Quick Category Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCategoryChip('رجالي'),
                        _buildCategoryChip('نسائي'),
                        _buildCategoryChip('أطفال'),
                        _buildCategoryChip('رياضي'),
                        _buildCategoryChip('رسمي'),
                      ],
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

  Widget _buildCategoryChip(String label) {
    final isSelected = _categoryController.text == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _categoryController.text = selected ? label : '';
        });
      },
      selectedColor: AppColors.blue600.withOpacity(0.2),
      checkmarkColor: AppColors.blue600,
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = ProductModel(
      id: widget.productId ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      nameEn: _nameEnController.text.trim().isNotEmpty
          ? _nameEnController.text.trim()
          : null,
      size: _sizeController.text.trim(),
      wholesalePrice: double.parse(_priceController.text.trim()),
      category: _categoryController.text.trim().isNotEmpty
          ? _categoryController.text.trim()
          : null,
      createdAt: _isEditing ? null : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // TODO: Save product using provider

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'تم تحديث المنتج' : 'تم إضافة المنتج'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, product);
    }
  }
}
