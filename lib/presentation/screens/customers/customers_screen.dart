import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/providers/customer_providers.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../data/models/customer_model.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // استخدام Reactive Provider للتحديث التلقائي
    final customersState = ref.watch(reactiveCustomersProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'العملاء',
        subtitle: 'إدارة قائمة العملاء',
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'بحث عن عميل...',
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
          // Customers List
          Expanded(
            child: _buildCustomersList(customersState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('عميل جديد'),
      ),
    );
  }

  Widget _buildCustomersList(CustomersState customersState) {
    if (customersState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (customersState.error != null) {
      return Center(child: Text('خطأ: ${customersState.error}'));
    }

    final filteredCustomers = _filterCustomers(customersState.customers);
    if (filteredCustomers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(reactiveCustomersProvider.notifier).refresh(),
      child: ListView.separated(
        padding: AppSpacing.paddingScreen,
        itemCount: filteredCustomers.length,
        separatorBuilder: (_, __) => AppSpacing.gapVerticalSm,
        itemBuilder: (context, index) {
          final customer = filteredCustomers[index];
          return _CustomerCard(
            key: ValueKey(customer.id),
            customer: customer,
            onEdit: () => _showAddEditDialog(context, ref, customer: customer),
            onDelete: () => _confirmDelete(context, ref, customer),
          );
        },
      ),
    );
  }

  List<CustomerModel> _filterCustomers(List<CustomerModel> customers) {
    if (_searchQuery.isEmpty) return customers;
    final query = _searchQuery.toLowerCase();
    return customers.where((c) {
      return c.name.toLowerCase().contains(query) ||
          (c.phone?.contains(query) ?? false) ||
          (c.address?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: AppColors.textMuted),
          AppSpacing.gapVerticalLg,
          Text(
            _searchQuery.isEmpty ? 'لا يوجد عملاء' : 'لا توجد نتائج',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.gapVerticalSm,
          Text(
            _searchQuery.isEmpty
                ? 'اضغط على الزر لإضافة عميل جديد'
                : 'جرب كلمات بحث مختلفة',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref,
      {CustomerModel? customer}) {
    final isEditing = customer != null;
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final addressController =
        TextEditingController(text: customer?.address ?? '');
    final notesController = TextEditingController(text: customer?.notes ?? '');

    showModalBottomSheet(
      context: context,
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
                  Text(
                    isEditing ? 'تعديل العميل' : 'عميل جديد',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('الرجاء إدخال اسم العميل')),
                        );
                        return;
                      }

                      final newCustomer = CustomerModel(
                        id: customer?.id ?? const Uuid().v4(),
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
                        createdAt: customer?.createdAt ?? DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      if (isEditing) {
                        await ref
                            .read(reactiveCustomersProvider.notifier)
                            .updateCustomer(newCustomer);
                      } else {
                        await ref
                            .read(reactiveCustomersProvider.notifier)
                            .addCustomer(newCustomer);
                      }

                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing
                              ? 'تم تحديث العميل'
                              : 'تم إضافة العميل'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: Text(isEditing ? 'تحديث' : 'إضافة'),
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

  void _confirmDelete(
      BuildContext context, WidgetRef ref, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العميل'),
        content: Text('هل أنت متأكد من حذف "${customer.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(reactiveCustomersProvider.notifier)
                  .deleteCustomer(customer.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('تم حذف العميل'),
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

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    super.key,
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.blue600.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue600,
                  ),
                ),
              ),
            ),
            AppSpacing.gapHorizontalMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (customer.phone != null) ...[
                    AppSpacing.gapVerticalXs,
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 14, color: AppColors.textMuted),
                        AppSpacing.gapHorizontalXs,
                        Text(
                          customer.phone!,
                          textDirection: TextDirection.ltr,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        AppSpacing.gapHorizontalXs,
                        // زر النسخ
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: customer.phone!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ رقم الهاتف'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.copy,
                            size: 14,
                            color: AppColors.textMuted.withOpacity(0.7),
                          ),
                        ),
                        AppSpacing.gapHorizontalXs,
                        // زر الواتساب
                        InkWell(
                          onTap: () async {
                            final success = await WhatsAppHelper.openChat(
                              phoneNumber: customer.phone!,
                            );

                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('لا يمكن فتح الواتساب'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: FaIcon(
                            FontAwesomeIcons.whatsapp,
                            size: 16,
                            color: const Color(0xFF25D366),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (customer.address != null) ...[
                    AppSpacing.gapVerticalXs,
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textMuted),
                        AppSpacing.gapHorizontalXs,
                        Expanded(
                          child: Text(
                            customer.address!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.error),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
