import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/category_model.dart';
import '../providers/providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'الفئات',
        subtitle: 'إدارة فئات المنتجات',
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            padding: AppSpacing.paddingScreen,
            itemCount: categories.length,
            separatorBuilder: (_, __) => AppSpacing.gapVerticalSm,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(
                category: category,
                onEdit: () =>
                    _showAddEditDialog(context, ref, category: category),
                onDelete: () => _confirmDelete(context, ref, category),
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
        label: const Text('فئة جديدة'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: AppColors.textMuted),
          AppSpacing.gapVerticalLg,
          Text('لا توجد فئات',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.textSecondary)),
          AppSpacing.gapVerticalSm,
          Text('اضغط على الزر لإضافة فئة جديدة',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref,
      {CategoryModel? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'تعديل الفئة' : 'فئة جديدة'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'اسم الفئة *',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
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
                  const SnackBar(content: Text('الرجاء إدخال اسم الفئة')),
                );
                return;
              }

              final newCategory = CategoryModel(
                id: category?.id ?? const Uuid().v4(),
                name: name,
                createdAt: category?.createdAt ?? DateTime.now(),
              );

              if (isEditing) {
                await ref
                    .read(categoriesNotifierProvider.notifier)
                    .updateCategory(newCategory);
              } else {
                await ref
                    .read(categoriesNotifierProvider.notifier)
                    .addCategory(newCategory);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(isEditing ? 'تم تحديث الفئة' : 'تم إضافة الفئة'),
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

  void _confirmDelete(
      BuildContext context, WidgetRef ref, CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الفئة'),
        content: Text('هل أنت متأكد من حذف "${category.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(categoriesNotifierProvider.notifier)
                  .deleteCategory(category.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('تم حذف الفئة'),
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

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
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
            color: AppColors.blue600.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.category_outlined, color: AppColors.blue600),
        ),
        title: Text(category.name,
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
