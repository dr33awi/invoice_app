import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/providers/providers.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/brand_model.dart';

class BrandsScreen extends ConsumerWidget {
  const BrandsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsNotifierProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'الماركات',
        subtitle: 'إدارة ماركات الأحذية',
      ),
      body: brandsAsync.when(
        data: (brands) {
          if (brands.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            padding: AppSpacing.paddingScreen,
            itemCount: brands.length,
            separatorBuilder: (_, __) => AppSpacing.gapVerticalSm,
            itemBuilder: (context, index) {
              final brand = brands[index];
              return _BrandCard(
                brand: brand,
                onEdit: () => _showAddEditDialog(context, ref, brand: brand),
                onDelete: () => _confirmDelete(context, ref, brand),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('ماركة جديدة'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.branding_watermark_outlined,
              size: 80, color: AppColors.textMuted),
          AppSpacing.gapVerticalLg,
          Text('لا توجد ماركات',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.textSecondary)),
          AppSpacing.gapVerticalSm,
          Text('اضغط على الزر لإضافة ماركة جديدة',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref,
      {BrandModel? brand}) {
    final isEditing = brand != null;
    final nameController = TextEditingController(text: brand?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'تعديل الماركة' : 'ماركة جديدة'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'اسم الماركة *',
            prefixIcon: Icon(Icons.branding_watermark_outlined),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء إدخال اسم الماركة')),
                );
                return;
              }

              final newBrand = BrandModel(
                id: brand?.id ?? const Uuid().v4(),
                name: name,
                createdAt: brand?.createdAt ?? DateTime.now(),
              );

              if (isEditing) {
                await ref
                    .read(brandsNotifierProvider.notifier)
                    .updateBrand(newBrand);
              } else {
                await ref
                    .read(brandsNotifierProvider.notifier)
                    .addBrand(newBrand);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(isEditing ? 'تم تحديث الماركة' : 'تم إضافة الماركة'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(isEditing ? 'تحديث' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, BrandModel brand) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الماركة'),
        content: Text('هل أنت متأكد من حذف "${brand.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(brandsNotifierProvider.notifier)
                  .deleteBrand(brand.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('تم حذف الماركة'),
                    backgroundColor: AppColors.success),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  final BrandModel brand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BrandCard({
    required this.brand,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.teal600.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.branding_watermark_outlined,
              color: AppColors.teal600),
        ),
        title: Text(brand.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit),
            IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.error),
                onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
