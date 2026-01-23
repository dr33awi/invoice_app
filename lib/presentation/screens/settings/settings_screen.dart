import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';
import 'package:wholesale_shoes_invoice/core/services/backup_service.dart';
import 'package:wholesale_shoes_invoice/core/services/invoice_migration.dart';
import 'package:wholesale_shoes_invoice/core/services/auth_service.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';
import 'package:wholesale_shoes_invoice/data/models/category_model.dart';
import 'package:wholesale_shoes_invoice/data/models/brand_model.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isSyncing = false;
  bool _isMigrating = false;
  final _authService = AuthService();

  BackupService get _backupService {
    return BackupService(
      invoicesBox: Hive.box<InvoiceModel>('invoices'),
      customersBox: Hive.box<CustomerModel>('customers'),
      productsBox: Hive.box<ProductModel>('products'),
      categoriesBox: Hive.box<CategoryModel>('categories'),
      brandsBox: Hive.box<BrandModel>('brands'),
      settingsBox: Hive.box('settings'),
    );
  }

  Future<void> _performBackup() async {
    setState(() => _isBackingUp = true);

    try {
      final success = await _backupService.shareBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(success
                    ? 'تم إنشاء النسخة الاحتياطية'
                    : 'فشل إنشاء النسخة الاحتياطية'),
              ],
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _performRestore() async {
    // تأكيد الاستعادة
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة البيانات'),
        content: const Text(
          'سيتم دمج البيانات من النسخة الاحتياطية مع البيانات الحالية.\n\nهل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRestoring = true);

    try {
      final result = await _backupService.restoreFromFile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.success
                        ? 'تمت الاستعادة: ${result.totalItems} عنصر'
                        : result.message,
                  ),
                ),
              ],
            ),
            backgroundColor:
                result.success ? AppColors.success : AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );

        // تحديث الـ providers
        if (result.success) {
          ref.invalidate(invoicesNotifierProvider);
          ref.invalidate(customersNotifierProvider);
          ref.invalidate(productsNotifierProvider);
          ref.invalidate(categoriesNotifierProvider);
          ref.invalidate(brandsNotifierProvider);
          ref.invalidate(exchangeRateNotifierProvider);
        }
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _performSync() async {
    setState(() => _isSyncing = true);

    try {
      final syncService = ref.read(initialSyncServiceProvider);
      final result = await syncService.performInitialSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result.success ? Icons.cloud_done : Icons.cloud_off,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.success
                        ? 'تمت المزامنة: ${result.totalSynced} عنصر'
                        : result.message,
                  ),
                ),
              ],
            ),
            backgroundColor:
                result.success ? AppColors.success : AppColors.error,
          ),
        );

        // تحديث الـ providers
        if (result.success) {
          ref.invalidate(invoicesNotifierProvider);
          ref.invalidate(customersNotifierProvider);
          ref.invalidate(productsNotifierProvider);
          ref.invalidate(categoriesNotifierProvider);
          ref.invalidate(brandsNotifierProvider);
          ref.invalidate(exchangeRateNotifierProvider);
        }
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _performMigration() async {
    setState(() => _isMigrating = true);

    try {
      final results = await InvoiceMigration.migrateAll();

      if (mounted) {
        int totalUpdated = 0;
        int totalErrors = 0;

        for (final result in results.values) {
          totalUpdated += result.updated;
          totalErrors += result.errors;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  totalErrors == 0 ? Icons.check_circle : Icons.warning,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    totalErrors == 0
                        ? 'تم تحديث $totalUpdated عنصر بنجاح'
                        : 'تم تحديث $totalUpdated عنصر مع $totalErrors أخطاء',
                  ),
                ),
              ],
            ),
            backgroundColor:
                totalErrors == 0 ? AppColors.success : AppColors.warning,
          ),
        );

        // تحديث الـ providers
        ref.invalidate(invoicesNotifierProvider);
        ref.invalidate(customersNotifierProvider);
        ref.invalidate(productsNotifierProvider);
        ref.invalidate(categoriesNotifierProvider);
        ref.invalidate(brandsNotifierProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحديث: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isMigrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'الإعدادات',
        subtitle: 'إدارة إعدادات التطبيق',
      ),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          // قسم الحساب
          _buildSection(
            context,
            title: 'الحساب',
            children: [
              _SettingsTile(
                icon: Icons.account_circle_outlined,
                iconColor: AppColors.blue600,
                title: 'إعدادات الحساب',
                subtitle: _authService.userEmail ?? 'غير مسجل',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.accountSettings),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          // قسم الشركة
          _buildSection(
            context,
            title: 'الشركة',
            children: [
              _SettingsTile(
                icon: Icons.business_outlined,
                iconColor: AppColors.blue600,
                title: 'معلومات الشركة',
                subtitle: 'اسم الشركة والشعار والعنوان',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.companySettings),
              ),
              _SettingsTile(
                icon: Icons.picture_as_pdf_outlined,
                iconColor: AppColors.warning,
                title: 'معاينة الفاتورة',
                subtitle: 'عرض شكل الفاتورة النهائي',
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.invoicePreviewSettings),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          // قسم العملة
          _buildSection(
            context,
            title: 'العملة',
            children: [
              _SettingsTile(
                icon: Icons.currency_exchange,
                iconColor: AppColors.teal600,
                title: 'سعر الصرف',
                subtitle: 'تعديل سعر صرف الدولار',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.exchangeRate),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          // قسم البيانات
          _buildSection(
            context,
            title: 'البيانات',
            children: [
              _SettingsTile(
                icon: Icons.cloud_sync_outlined,
                iconColor: AppColors.statusOnHold,
                title: 'المزامنة',
                subtitle: 'مزامنة البيانات مع السحابة',
                isLoading: _isSyncing,
                onTap: _isSyncing ? null : _performSync,
              ),
              _SettingsTile(
                icon: Icons.backup_outlined,
                iconColor: AppColors.warning,
                title: 'النسخ الاحتياطي',
                subtitle: 'تصدير البيانات إلى ملف',
                isLoading: _isBackingUp,
                onTap: _isBackingUp ? null : _performBackup,
              ),
              _SettingsTile(
                icon: Icons.restore_outlined,
                iconColor: AppColors.success,
                title: 'استعادة البيانات',
                subtitle: 'استيراد نسخة احتياطية',
                isLoading: _isRestoring,
                onTap: _isRestoring ? null : _performRestore,
              ),
              _SettingsTile(
                icon: Icons.update_outlined,
                iconColor: AppColors.statusOnHold,
                title: 'تحديث البيانات القديمة',
                subtitle: 'إصلاح مشاكل المزامنة',
                isLoading: _isMigrating,
                onTap: _isMigrating ? null : _performMigration,
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          // قسم حول التطبيق
          _buildSection(
            context,
            title: 'حول التطبيق',
            children: [
              const _SettingsTile(
                icon: Icons.info_outline,
                iconColor: AppColors.textSecondary,
                title: 'الإصدار',
                subtitle: '1.0.0',
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            : Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null && !isLoading
          ? const Icon(Icons.chevron_left, color: AppColors.textMuted)
          : null,
      onTap: isLoading ? null : onTap,
    );
  }
}
