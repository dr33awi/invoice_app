import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_colors.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_spacing.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/providers/customer_providers.dart';
import '../controller/create_invoice_controller.dart';
import '../providers/create_invoice_providers.dart';

/// قسم اختيار العميل - UI فقط
class CustomerSelectionSection extends ConsumerWidget {
  final InvoiceModel? originalInvoice;
  final CreateInvoiceController controller;

  const CustomerSelectionSection({
    super.key,
    required this.originalInvoice,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createInvoiceNotifierProvider(originalInvoice));

    // مراقبة بيانات العميل للتحديث التلقائي
    final customerData = state.selectedCustomerId != null
        ? ref.watch(customerDataProvider(state.selectedCustomerId!))
        : null;

    // استخدام بيانات العميل المحدثة أو البيانات المحلية كـ fallback
    final displayName = customerData?.name ?? state.customerName;
    final displayPhone = customerData?.phone ?? state.customerPhone;
    final displayAddress = customerData?.address ?? state.customerAddress;

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
              onTap: () => _showCustomerSelector(context, ref),
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
                          onPressed: () => controller.clearCustomer(),
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
            // عرض رقم الهاتف إذا كان موجوداً
            if (displayPhone != null && displayPhone.isNotEmpty) ...[
              AppSpacing.gapVerticalSm,
              _buildInfoChip(
                context,
                icon: Icons.phone_outlined,
                text: displayPhone,
                color: AppColors.teal600,
                textDirection: TextDirection.ltr,
              ),
            ],
            // عرض العنوان إذا كان موجوداً
            if (displayAddress != null && displayAddress.isNotEmpty) ...[
              AppSpacing.gapVerticalSm,
              _buildInfoChip(
                context,
                icon: Icons.location_on_outlined,
                text: displayAddress,
                color: AppColors.blue600,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    TextDirection? textDirection,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          AppSpacing.gapHorizontalSm,
          Expanded(
            child: Text(
              text,
              textDirection: textDirection,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerSelector(BuildContext context, WidgetRef ref) {
    final customersState = ref.read(reactiveCustomersProvider);
    final customers = customersState.customers;
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
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
                _buildSheetHeader(sheetContext),
                _buildSearchField(
                    setSheetState, (value) => searchQuery = value),
                _buildAddNewCustomerButton(context, sheetContext, ref),
                AppSpacing.gapVerticalMd,
                const Divider(height: 1),
                Expanded(
                  child: filteredCustomers.isEmpty
                      ? _buildEmptyState(sheetContext, searchQuery)
                      : _buildCustomersList(
                          sheetContext,
                          filteredCustomers,
                          ref
                              .read(createInvoiceNotifierProvider(
                                  originalInvoice))
                              .selectedCustomerId,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetHeader(BuildContext sheetContext) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('إلغاء'),
          ),
          const Text('اختر العميل',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildSearchField(
    StateSetter setSheetState,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          onChanged(value);
          setSheetState(() {});
        },
        decoration: InputDecoration(
          hintText: 'بحث عن عميل...',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          filled: true,
          fillColor: AppColors.surfaceBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
        ),
      ),
    );
  }

  Widget _buildAddNewCustomerButton(
    BuildContext parentContext,
    BuildContext sheetContext,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FilledButton.icon(
        onPressed: () =>
            _showAddNewCustomerDialog(parentContext, sheetContext, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('إضافة عميل جديد'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String searchQuery) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
          AppSpacing.gapVerticalMd,
          Text(
            searchQuery.isEmpty ? 'لا يوجد عملاء' : 'لا توجد نتائج',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          if (searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'أضف عميل جديد من الأعلى',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomersList(
    BuildContext sheetContext,
    List<CustomerModel> customers,
    String? selectedCustomerId,
  ) {
    return ListView.builder(
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        final isSelected = selectedCustomerId == customer.id;
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
                  ? const Icon(Icons.check, color: Colors.white)
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
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          subtitle: customer.phone != null
              ? Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      customer.phone!,
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                )
              : null,
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: AppColors.blue600)
              : null,
          onTap: () {
            controller.selectCustomer(customer);
            Navigator.pop(sheetContext);
          },
        );
      },
    );
  }

  void _showAddNewCustomerDialog(
    BuildContext parentContext,
    BuildContext sheetContext,
    WidgetRef ref,
  ) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: sheetContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => Container(
        height: MediaQuery.of(dialogContext).size.height * 0.75,
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
                    onPressed: () => Navigator.pop(dialogContext),
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
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('الرجاء إدخال اسم العميل'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      await controller.addAndSelectCustomer(
                        name: name,
                        phone: phoneController.text.trim(),
                        address: addressController.text.trim(),
                        notes: notesController.text.trim(),
                      );

                      Navigator.pop(dialogContext);
                      Navigator.pop(sheetContext);

                      if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
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
}
