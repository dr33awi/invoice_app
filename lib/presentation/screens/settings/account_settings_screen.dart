import 'package:flutter/material.dart';
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';
import 'package:wholesale_shoes_invoice/core/services/auth_service.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_colors.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_spacing.dart';
import 'package:wholesale_shoes_invoice/app/routes.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final email = _authService.userEmail ?? 'غير متوفر';

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'إعدادات الحساب',
        subtitle: 'إدارة حسابك الشخصي',
      ),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          // معلومات الحساب
          _buildSection(
            context,
            title: 'معلومات الحساب',
            children: [
              _buildInfoTile(
                icon: Icons.email_outlined,
                iconColor: AppColors.blue600,
                title: 'البريد الإلكتروني',
                value: email,
              ),
              _buildInfoTile(
                icon: Icons.fingerprint,
                iconColor: AppColors.teal600,
                title: 'معرف المستخدم',
                value: user?.uid.substring(0, 8) ?? 'غير متوفر',
              ),
              _buildInfoTile(
                icon: Icons.verified_user_outlined,
                iconColor: user?.emailVerified == true
                    ? AppColors.success
                    : AppColors.warning,
                title: 'حالة التحقق',
                value: user?.emailVerified == true ? 'محقق' : 'غير محقق',
              ),
            ],
          ),

          AppSpacing.gapVerticalMd,

          // الأمان
          _buildSection(
            context,
            title: 'الأمان',
            children: [
              _buildActionTile(
                icon: Icons.lock_reset_outlined,
                iconColor: AppColors.warning,
                title: 'تغيير كلمة المرور',
                subtitle: 'إعادة تعيين كلمة المرور',
                onTap: _resetPassword,
              ),
            ],
          ),

          AppSpacing.gapVerticalMd,

          // الإجراءات
          _buildSection(
            context,
            title: 'الإجراءات',
            children: [
              _buildActionTile(
                icon: Icons.logout,
                iconColor: AppColors.error,
                title: 'تسجيل الخروج',
                subtitle: 'الخروج من الحساب الحالي',
                onTap: _showLogoutDialog,
              ),
            ],
          ),

          AppSpacing.gapVerticalXl,

          // تحذير
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'عند تسجيل الخروج، ستحتاج إلى تسجيل الدخول مرة أخرى',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Future<void> _resetPassword() async {
    final email = _authService.userEmail;
    if (email == null) {
      _showMessage('لا يوجد بريد إلكتروني مسجل', isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين كلمة المرور'),
        content: Text(
          'سيتم إرسال رابط إعادة تعيين كلمة المرور إلى:\n$email',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        _showMessage('تم إرسال رابط إعادة تعيين كلمة المرور');
      }
    } catch (e) {
      _showMessage('فشل إرسال الرابط', isError: true);
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
