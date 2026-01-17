import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام فواتير الأحذية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stats Cards Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'فواتير اليوم',
                    value: '5',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.blue600,
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: _StatCard(
                    title: 'إجمالي اليوم',
                    value: '\$2,450',
                    icon: Icons.attach_money,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalLg,

            // Quick Actions
            Text(
              'الإجراءات السريعة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            AppSpacing.gapVerticalMd,

            // Action Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.2,
                children: [
                  _ActionCard(
                    title: 'فاتورة جديدة',
                    subtitle: 'إنشاء فاتورة بيع',
                    icon: Icons.add_circle_outline,
                    color: AppColors.blue600,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.createInvoice),
                  ),
                  _ActionCard(
                    title: 'الفواتير',
                    subtitle: 'عرض جميع الفواتير',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.teal600,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.invoices),
                  ),
                  _ActionCard(
                    title: 'المنتجات',
                    subtitle: 'إدارة المنتجات',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.warning,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.products),
                  ),
                  _ActionCard(
                    title: 'سعر الصرف',
                    subtitle: 'تعديل سعر الدولار',
                    icon: Icons.currency_exchange,
                    color: AppColors.success,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.exchangeRate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createInvoice),
        icon: const Icon(Icons.add),
        label: const Text('فاتورة جديدة'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            AppSpacing.gapVerticalSm,
            Text(
              value,
              style: AppTypography.moneyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Padding(
          padding: AppSpacing.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              AppSpacing.gapVerticalSm,
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
