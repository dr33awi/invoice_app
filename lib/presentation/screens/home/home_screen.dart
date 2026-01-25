import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(todayStatsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'شركة المعيار',
        subtitle: 'إدارة المبيعات والمنتجات',
        showBackButton: false,
        showMenuButton: false,
        actions: [
          AppBarIconButton(
            icon: Icons.settings_outlined,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayStatsProvider);
          ref.invalidate(invoicesNotifierProvider);
          ref.invalidate(productsNotifierProvider);
        },
        child: Padding(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              statsAsync.when(
                data: (stats) => Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'فواتير اليوم',
                        value: '${stats['count']}',
                        icon: Icons.receipt_long_outlined,
                        color: AppColors.blue600,
                      ),
                    ),
                    AppSpacing.gapHorizontalMd,
                    Expanded(
                      child: _StatCard(
                        title: 'إجمالي اليوم',
                        value: CurrencyFormatter.formatUSD(stats['totalUSD']),
                        icon: Icons.attach_money,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                loading: () => Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'فواتير اليوم',
                        value: '...',
                        icon: Icons.receipt_long_outlined,
                        color: AppColors.blue600,
                      ),
                    ),
                    AppSpacing.gapHorizontalMd,
                    Expanded(
                      child: _StatCard(
                        title: 'إجمالي اليوم',
                        value: '...',
                        icon: Icons.attach_money,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                error: (e, _) => Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'فواتير اليوم',
                        value: '0',
                        icon: Icons.receipt_long_outlined,
                        color: AppColors.blue600,
                      ),
                    ),
                    AppSpacing.gapHorizontalMd,
                    Expanded(
                      child: _StatCard(
                        title: 'إجمالي اليوم',
                        value: '\$0.00',
                        icon: Icons.attach_money,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapVerticalLg,
              Text(
                'الإجراءات السريعة',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              AppSpacing.gapVerticalMd,
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.5,
                  children: [
                    _ActionCard(
                      title: 'فاتورة جديدة',
                      subtitle: 'إنشاء فاتورة بيع',
                      icon: Icons.add_circle_outline,
                      color: AppColors.blue600,
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          AppRoutes.createInvoice,
                        );
                        if (result != null) {
                          ref.invalidate(todayStatsProvider);
                        }
                      },
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
                      title: 'العملاء',
                      subtitle: 'إدارة قائمة العملاء',
                      icon: Icons.people_outline,
                      color: const Color(0xFF8B5CF6),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.customers),
                    ),
                    _ActionCard(
                      title: 'الماركات',
                      subtitle: 'إدارة ماركات الأحذية',
                      icon: Icons.branding_watermark_outlined,
                      color: const Color(0xFFEC4899),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.brands),
                    ),
                    _ActionCard(
                      title: 'الفئات',
                      subtitle: 'إدارة فئات المنتجات',
                      icon: Icons.category_outlined,
                      color: AppColors.success,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.categories),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.createInvoice,
          );
          if (result != null) {
            ref.invalidate(todayStatsProvider);
          }
        },
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
                _StatIconContainer(icon: icon, color: color),
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

/// Extracted static icon container for const optimization
class _StatIconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _StatIconContainer({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionIconContainer(icon: icon, color: color),
              const SizedBox(height: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extracted static icon container for const optimization
class _ActionIconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _ActionIconContainer({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
