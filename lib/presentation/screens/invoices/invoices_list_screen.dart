import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/providers/company_provider.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../data/models/invoice_model.dart';
import '../providers/providers.dart';
import '../providers/customer_providers.dart';

class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  String _searchQuery = '';
  String _sortOption = 'date'; // date, amount, customer

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesNotifierProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'الفواتير',
        subtitle: 'جميع فواتير المبيعات',
        actions: [
          AppBarIconButton(
            icon: Icons.filter_list,
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث والإحصائيات
          _buildSearchAndStats(invoicesAsync),
          // قائمة الفواتير
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(invoicesNotifierProvider.notifier)
                    .loadInvoices();
              },
              child: invoicesAsync.when(
                data: (invoices) {
                  final filteredInvoices = _filterInvoices(invoices);
                  if (filteredInvoices.isEmpty) {
                    return _buildEmptyState(context, invoices.isEmpty);
                  }
                  return ListView.separated(
                    padding: AppSpacing.paddingScreen,
                    itemCount: filteredInvoices.length,
                    separatorBuilder: (_, __) => AppSpacing.gapVerticalSm,
                    itemBuilder: (context, index) {
                      final invoice = filteredInvoices[index];
                      return _InvoiceCard(invoice: invoice);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      AppSpacing.gapVerticalMd,
                      Text(
                        'حدث خطأ في تحميل الفواتير',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      AppSpacing.gapVerticalSm,
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(invoicesNotifierProvider.notifier)
                              .loadInvoices();
                        },
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
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.createInvoice,
          );
          if (result != null) {
            ref.read(invoicesNotifierProvider.notifier).loadInvoices();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('فاتورة جديدة'),
      ),
    );
  }

  Widget _buildSearchAndStats(AsyncValue<List<InvoiceModel>> invoicesAsync) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'بحث بالرقم أو اسم العميل...',
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
        ],
      ),
    );
  }

  List<InvoiceModel> _filterInvoices(List<InvoiceModel> invoices) {
    var filtered = invoices.toList();

    // تصفية حسب البحث
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((inv) {
        return inv.invoiceNumber.toLowerCase().contains(query) ||
            inv.customerName.toLowerCase().contains(query) ||
            (inv.customerPhone?.contains(query) ?? false);
      }).toList();
    }

    // ترتيب حسب الخيار المحدد
    switch (_sortOption) {
      case 'date':
        filtered.sort((a, b) => b.date.compareTo(a.date)); // الأحدث أولاً
        break;
      case 'amount':
        filtered
            .sort((a, b) => b.totalUSD.compareTo(a.totalUSD)); // الأعلى أولاً
        break;
      case 'customer':
        filtered.sort(
            (a, b) => a.customerName.compareTo(b.customerName)); // أبجدياً
        break;
    }

    return filtered;
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.gapVerticalMd,
            Text(
              'خيارات الترتيب',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            AppSpacing.gapVerticalMd,
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('ترتيب حسب التاريخ'),
              subtitle: const Text('الأحدث أولاً'),
              trailing: _sortOption == 'date'
                  ? const Icon(Icons.check, color: AppColors.blue600)
                  : null,
              onTap: () {
                setState(() => _sortOption = 'date');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('ترتيب حسب المبلغ'),
              subtitle: const Text('الأعلى أولاً'),
              trailing: _sortOption == 'amount'
                  ? const Icon(Icons.check, color: AppColors.blue600)
                  : null,
              onTap: () {
                setState(() => _sortOption = 'amount');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('ترتيب حسب العميل'),
              subtitle: const Text('أبجدياً'),
              trailing: _sortOption == 'customer'
                  ? const Icon(Icons.check, color: AppColors.blue600)
                  : null,
              onTap: () {
                setState(() => _sortOption = 'customer');
                Navigator.pop(context);
              },
            ),
            AppSpacing.gapVerticalMd,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool noInvoices) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            noInvoices ? Icons.receipt_long_outlined : Icons.search_off,
            size: 80,
            color: AppColors.textMuted,
          ),
          AppSpacing.gapVerticalLg,
          Text(
            noInvoices ? 'لا توجد فواتير' : 'لا توجد نتائج',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          AppSpacing.gapVerticalSm,
          Text(
            noInvoices
                ? 'اضغط على الزر لإنشاء فاتورة جديدة'
                : 'جرب كلمات بحث مختلفة',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends ConsumerWidget {
  final InvoiceModel invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // مراقبة بيانات العميل للتحديث التلقائي
    final customerId = invoice.customerId;
    final customerData =
        customerId != null ? ref.watch(customerDataProvider(customerId)) : null;

    // استخدام البيانات المحدثة أو البيانات المحفوظة في الفاتورة كـ fallback
    final displayName = customerData?.name ?? invoice.customerName;
    final displayPhone = customerData?.phone ?? invoice.customerPhone;
    final displayAddress = customerData?.address ?? invoice.customerAddress;

    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.invoiceDetails,
          arguments: invoice,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.blue600,
                          AppColors.blue600.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      invoice.invoiceNumber,
                      style: AppTypography.codeSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AppSpacing.gapHorizontalSm,
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 12, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'مكتملة',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormatter.formatDateAr(invoice.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        DateFormat('hh:mm a', 'ar').format(invoice.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),

              // Customer Info Row - محدث تلقائياً
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.teal600.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal600,
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
                          displayName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (displayPhone != null &&
                            displayPhone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              AppSpacing.gapHorizontalXs,
                              Text(
                                displayPhone,
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
                                      ClipboardData(text: displayPhone));
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
                              // زر الواتساب صغير
                              InkWell(
                                onTap: () async {
                                  // الحصول على معلومات الشركة
                                  final companyAsync =
                                      ref.read(companyNotifierProvider);
                                  final company = companyAsync.value;

                                  final items = invoice.items
                                      .map((item) => {
                                            'name': item.productName,
                                            'size': item.size,
                                            'packagesCount': item.packagesCount,
                                            'quantity': item.quantity,
                                            'price': item.total,
                                          })
                                      .toList();

                                  // حساب المبلغ المستحق
                                  final dueAmount =
                                      invoice.totalUSD - invoice.paidAmount;

                                  final message =
                                      WhatsAppHelper.createInvoiceMessage(
                                    invoiceNumber: invoice.invoiceNumber,
                                    customerName: displayName,
                                    totalAmount: invoice.totalUSD,
                                    currency: 'USD',
                                    totalSYP: invoice.totalSYP,
                                    items: items,
                                    invoiceDate: invoice.date != null
                                        ? '${invoice.date!.day}/${invoice.date!.month}/${invoice.date!.year}'
                                        : null,
                                    paidAmount: invoice.paidAmount,
                                    dueAmount: dueAmount,
                                    companyPhone: company?.phone,
                                    websiteLink: company?.websiteLink,
                                  );

                                  final success = await WhatsAppHelper.openChat(
                                    phoneNumber: displayPhone,
                                    message: message,
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
                        // عرض العنوان
                        if (displayAddress != null &&
                            displayAddress.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              AppSpacing.gapHorizontalXs,
                              Expanded(
                                child: Text(
                                  displayAddress,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AppColors.textSecondary),
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
                ],
              ),

              AppSpacing.gapVerticalSm,

              // Footer Row - Totals
              Row(
                children: [
                  // USD Total
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.blue600.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_money,
                              size: 18, color: AppColors.blue600),
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.formatUSD(invoice.totalUSD),
                                style: AppTypography.moneyMedium.copyWith(
                                  color: AppColors.blue600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // SYP Total
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.teal600.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ل.س',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.teal600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.formatSYP(invoice.totalSYP),
                                style: AppTypography.moneySmall.copyWith(
                                  color: AppColors.teal600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
