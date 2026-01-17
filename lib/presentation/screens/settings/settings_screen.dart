import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          // Exchange Rate Section
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

          // Data Section
          _buildSection(
            context,
            title: 'البيانات',
            children: [
              _SettingsTile(
                icon: Icons.cloud_sync_outlined,
                iconColor: AppColors.blue600,
                title: 'المزامنة',
                subtitle: 'مزامنة البيانات مع السحابة',
                onTap: () {
                  // TODO: Trigger sync
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('جاري المزامنة...')),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.backup_outlined,
                iconColor: AppColors.warning,
                title: 'النسخ الاحتياطي',
                subtitle: 'تصدير البيانات',
                onTap: () {
                  // TODO: Export backup
                },
              ),
              _SettingsTile(
                icon: Icons.restore_outlined,
                iconColor: AppColors.success,
                title: 'استعادة البيانات',
                subtitle: 'استيراد نسخة احتياطية',
                onTap: () {
                  // TODO: Import backup
                },
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,

          // App Info Section
          _buildSection(
            context,
            title: 'حول التطبيق',
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                iconColor: AppColors.textSecondary,
                title: 'الإصدار',
                subtitle: '1.0.0',
                onTap: null,
              ),
              _SettingsTile(
                icon: Icons.code,
                iconColor: AppColors.textSecondary,
                title: 'المطور',
                subtitle: 'نظام فواتير الأحذية',
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
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

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? const Icon(
              Icons.chevron_left,
              color: AppColors.textMuted,
            )
          : null,
      onTap: onTap,
    );
  }
}
