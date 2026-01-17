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
        title: 'فواتير الأحذية',
        subtitle: 'إدارة المبيعات والمنتجات',
        showBackButton: false,
        showMenuButton: true,
        actions: [
          AppBarIconButton(
            icon: Icons.sync,
            onPressed: () {
              ref.invalidate(todayStatsProvider);
              ref.invalidate(invoicesNotifierProvider);
              ref.invalidate(productsNotifierProvider);
            },
          ),
          AppBarIconButton(
            icon: Icons.notifications_outlined,
            showBadge: true,
            onPressed: () {},
          ),
          AppBarIconButton(
            icon: Icons.settings_outlined,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
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
              // Stats Cards Row
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

              // Quick Actions
              Text(
                'الإجراءات السريعة',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                      title: 'الماركات',
                      subtitle: 'إدارة ماركات الأحذية',
                      icon: Icons.branding_watermark_outlined,
                      color: const Color(0xFF8B5CF6),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.brands),
                    ),
                    _ActionCard(
                      title: 'الفئات',
                      subtitle: 'إدارة فئات المنتجات',
                      icon: Icons.category_outlined,
                      color: const Color(0xFFEC4899),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.categories),
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            color: AppColors.slate800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store,
                    size: 32,
                    color: AppColors.slate800,
                  ),
                ),
                AppSpacing.gapVerticalMd,
                const Text(
                  'فواتير الأحذية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'نظام إدارة المبيعات',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.home_outlined,
                  title: 'الرئيسية',
                  isSelected: true,
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'الفواتير',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.invoices);
                  },
                ),
                _DrawerItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'المنتجات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.products);
                  },
                ),
                const Divider(),
                _DrawerItem(
                  icon: Icons.branding_watermark_outlined,
                  title: 'الماركات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.brands);
                  },
                ),
                _DrawerItem(
                  icon: Icons.category_outlined,
                  title: 'الفئات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.categories);
                  },
                ),
                const Divider(),
                _DrawerItem(
                  icon: Icons.currency_exchange,
                  title: 'سعر الصرف',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.exchangeRate);
                  },
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'الإعدادات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.blue600 : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.blue600 : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.blue600.withOpacity(0.1),
      onTap: onTap,
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
