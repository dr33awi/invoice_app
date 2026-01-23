import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product_model.dart';
import '../providers/providers.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsNotifierProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'المنتجات',
        subtitle: 'إدارة قائمة المنتجات',
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'بحث عن منتج...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surfaceBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusField),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusField),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
              ),
            ),
          ),
          // Products List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(productsNotifierProvider.notifier)
                    .loadProducts();
              },
              child: productsAsync.when(
                data: (products) {
                  final filteredProducts = _filterProducts(products);
                  if (filteredProducts.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.separated(
                    padding: AppSpacing.paddingScreen,
                    itemCount: filteredProducts.length,
                    separatorBuilder: (_, __) => AppSpacing.gapVerticalSm,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _ProductCard(
                        product: product,
                        onEdit: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            AppRoutes.editProduct,
                            arguments: product.id,
                          );
                          if (result != null) {
                            ref
                                .read(productsNotifierProvider.notifier)
                                .loadProducts();
                          }
                        },
                        onDelete: () => _confirmDelete(product),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: AppColors.error),
                      AppSpacing.gapVerticalMd,
                      const Text('حدث خطأ في تحميل المنتجات'),
                      AppSpacing.gapVerticalSm,
                      ElevatedButton(
                        onPressed: () => ref
                            .read(productsNotifierProvider.notifier)
                            .loadProducts(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, AppRoutes.addProduct);
          if (result != null) {
            ref.read(productsNotifierProvider.notifier).loadProducts();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('منتج جديد'),
      ),
    );
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    if (_searchQuery.isEmpty) return products;
    final query = _searchQuery.toLowerCase();
    return products.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.brand.toLowerCase().contains(query) ||
          p.sizeRange.contains(query) ||
          p.category.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80, color: AppColors.textMuted),
          AppSpacing.gapVerticalLg,
          Text(
            _searchQuery.isEmpty ? 'لا توجد منتجات' : 'لا توجد نتائج',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.gapVerticalSm,
          Text(
            _searchQuery.isEmpty
                ? 'اضغط على الزر لإضافة منتج جديد'
                : 'جرب كلمات بحث مختلفة',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل أنت متأكد من حذف "${product.name}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(productsNotifierProvider.notifier)
                  .deleteProduct(product.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('تم حذف المنتج'),
                      backgroundColor: AppColors.success),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard(
      {required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.blue600.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: AppColors.blue600),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (product.brand.isNotEmpty)
                        Text(
                          product.brand,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatUSD(product.wholesalePrice),
                      style: AppTypography.moneyMedium
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: onEdit,
                            visualDensity: VisualDensity.compact),
                        IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20, color: AppColors.error),
                            onPressed: onDelete,
                            visualDensity: VisualDensity.compact),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.gapVerticalSm,
            // Tags row - إزالة إجمالي الأزواج
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildChip('المقاس: ${product.sizeRange}'),
                _buildChip('${product.packagesCount} طرد'),
                _buildChip('${product.pairsPerPackage} الكمية'),
                if (product.category.isNotEmpty) _buildChip(product.category),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.teal600.withOpacity(0.1)
            : AppColors.screenBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: isHighlight ? AppColors.teal600 : AppColors.borderColor),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: isHighlight ? AppColors.teal600 : AppColors.textSecondary,
          fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
