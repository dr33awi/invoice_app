import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/widgets/custom_app_bar.dart';
import '../../../data/models/company_model.dart';
import '../providers/company_provider.dart';
import '../invoices/invoice_preview_screen.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() =>
      _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSaving = false;
  bool _isLoaded = false;
  String? _logoPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadData(CompanyModel company) {
    if (!_isLoaded) {
      _nameController.text = company.name;
      _subtitleController.text = company.subtitle ?? '';
      _phoneController.text = company.phone ?? '';
      _addressController.text = company.address ?? '';
      _logoPath = company.logoPath;
      _isLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyNotifierProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'معلومات الشركة',
        subtitle: 'إعدادات الفاتورة',
        actions: [
          AppBarIconButton(
            icon: Icons.restore_outlined,
            onPressed: _resetToDefaults,
          ),
          AppBarTextButton(
            text: 'حفظ',
            icon: Icons.save_outlined,
            isLoading: _isSaving,
            onPressed: _saveCompanyInfo,
          ),
        ],
      ),
      body: companyAsync.when(
        data: (company) {
          _loadData(company);
          return Form(
            key: _formKey,
            child: ListView(
              padding: AppSpacing.paddingScreen,
              children: [
                // بطاقة الشعار
                _buildLogoCard(),
                AppSpacing.gapVerticalMd,

                // بطاقة معلومات الاتصال
                _buildContactCard(),
                AppSpacing.gapVerticalMd,

                // ملاحظة
                _buildInfoNote(),
                AppSpacing.gapVerticalMd,

                // زر معاينة الفاتورة
                _buildPreviewButton(),
                AppSpacing.gapVerticalXl,
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              AppSpacing.gapVerticalMd,
              Text('خطأ في تحميل البيانات: $error'),
              AppSpacing.gapVerticalMd,
              ElevatedButton(
                onPressed: () => ref.refresh(companyNotifierProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildHeaderPreview() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.screenBg,
            child: Row(
              children: [
                const Icon(Icons.preview_outlined,
                    size: 18, color: AppColors.textSecondary),
                AppSpacing.gapHorizontalXs,
                Text(
                  'معاينة الهيدر',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'تحديث مباشر',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // معاينة الهيدر
          _InvoiceHeaderPreview(
            companyName: _nameController.text.isNotEmpty
                ? _nameController.text
                : CompanyModel.defaultName,
            companySubtitle: _subtitleController.text.isNotEmpty
                ? _subtitleController.text
                : CompanyModel.defaultSubtitle,
            logoPath: _logoPath,
            companyPhone:
                _phoneController.text.isNotEmpty ? _phoneController.text : null,
            companyAddress: _addressController.text.isNotEmpty
                ? _addressController.text
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoCard() {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.warning, size: 22),
                ),
                AppSpacing.gapHorizontalMd,
                Text(
                  'شعار الشركة',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            AppSpacing.gapVerticalLg,
            Center(
              child: Column(
                children: [
                  // عرض الشعار الحالي أو placeholder
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.screenBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.borderColor,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _logoPath != null && File(_logoPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_logoPath!),
                                fit: BoxFit.contain,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: AppColors.textMuted,
                                ),
                                AppSpacing.gapVerticalSm,
                                Text(
                                  'اضغط لاختيار شعار',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                    ),
                  ),
                  AppSpacing.gapVerticalMd,
                  // أزرار التحكم
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.upload_outlined, size: 18),
                        label: const Text('اختيار صورة'),
                      ),
                      if (_logoPath != null) ...[
                        AppSpacing.gapHorizontalSm,
                        OutlinedButton.icon(
                          onPressed: _removeLogo,
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          label: const Text('حذف',
                              style: TextStyle(color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ],
                    ],
                  ),
                  AppSpacing.gapVerticalSm,
                  Text(
                    'PNG أو JPG - يفضل خلفية شفافة',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );

      if (image != null) {
        // حفظ الصورة في مجلد التطبيق
        final directory = await getApplicationDocumentsDirectory();
        final logoDir = Directory('${directory.path}/logos');
        if (!await logoDir.exists()) {
          await logoDir.create(recursive: true);
        }

        final extension = path.extension(image.path);
        final newPath = '${logoDir.path}/company_logo$extension';

        // نسخ الصورة
        final File newImage = await File(image.path).copy(newPath);

        setState(() {
          _logoPath = newImage.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الصورة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeLogo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الشعار'),
        content: const Text('هل تريد حذف شعار الشركة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _logoPath = null;
              });
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.blue600.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business,
                      color: AppColors.blue600, size: 22),
                ),
                AppSpacing.gapHorizontalMd,
                Text(
                  'المعلومات الأساسية',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            AppSpacing.gapVerticalLg,
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الشركة *',
                prefixIcon: Icon(Icons.store_outlined),
                hintText: 'مثال: شركة المعيار',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'اسم الشركة مطلوب' : null,
              onChanged: (_) => setState(() {}),
            ),
            AppSpacing.gapVerticalMd,
            TextFormField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: 'الوصف / التخصص',
                prefixIcon: Icon(Icons.description_outlined),
                hintText: 'مثال: للأحذية بالجملة',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.teal600.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.contact_phone_outlined,
                      color: AppColors.teal600, size: 22),
                ),
                AppSpacing.gapHorizontalMd,
                Text(
                  'معلومات الاتصال',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            AppSpacing.gapVerticalLg,
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: 'مثال: 0912345678',
              ),
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
            ),
            AppSpacing.gapVerticalMd,
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                prefixIcon: Icon(Icons.location_on_outlined),
                hintText: 'مثال: دمشق - سوريا',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNote() {
    return Card(
      color: AppColors.info.withOpacity(0.1),
      child: Padding(
        padding: AppSpacing.paddingCard,
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.info, size: 20),
            AppSpacing.gapHorizontalSm,
            Expanded(
              child: Text(
                'ستظهر هذه المعلومات والشعار في جميع الفواتير الجديدة',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewButton() {
    return FilledButton.icon(
      onPressed: _openInvoicePreview,
      icon: const Icon(Icons.picture_as_pdf_outlined),
      label: const Text('معاينة شكل الفاتورة'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  void _openInvoicePreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicePreviewSettingsScreen(
          companyName: _nameController.text.isNotEmpty
              ? _nameController.text
              : CompanyModel.defaultName,
          companySubtitle: _subtitleController.text.isNotEmpty
              ? _subtitleController.text
              : CompanyModel.defaultSubtitle,
          companyPhone:
              _phoneController.text.isNotEmpty ? _phoneController.text : null,
          companyAddress: _addressController.text.isNotEmpty
              ? _addressController.text
              : null,
          logoPath: _logoPath,
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: _resetToDefaults,
      icon: const Icon(Icons.restore_outlined),
      label: const Text('إعادة التعيين للقيم الافتراضية'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.borderColor),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Future<void> _saveCompanyInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final company = CompanyModel(
        name: _nameController.text.trim(),
        subtitle: _subtitleController.text.trim().isNotEmpty
            ? _subtitleController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        updatedAt: DateTime.now(),
        logoPath: _logoPath,
      );

      await ref
          .read(companyNotifierProvider.notifier)
          .updateCompanyInfo(company);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ معلومات الشركة بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة التعيين'),
        content:
            const Text('هل تريد إعادة تعيين معلومات الشركة للقيم الافتراضية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _nameController.text = CompanyModel.defaultName;
                _subtitleController.text = CompanyModel.defaultSubtitle;
                _phoneController.text = CompanyModel.defaultPhone ?? '';
                _addressController.text = CompanyModel.defaultAddress ?? '';
                _logoPath = null;
              });
            },
            child: const Text('إعادة التعيين'),
          ),
        ],
      ),
    );
  }
}

/// ويدجت معاينة هيدر الفاتورة
class _InvoiceHeaderPreview extends StatelessWidget {
  final String companyName;
  final String companySubtitle;
  final String? logoPath;
  final String? companyPhone;
  final String? companyAddress;

  const _InvoiceHeaderPreview({
    required this.companyName,
    required this.companySubtitle,
    this.logoPath,
    this.companyPhone,
    this.companyAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      child: Stack(
        children: [
          // خلفية بيضاء
          Positioned.fill(
            child: Container(color: Colors.white),
          ),

          // الخلفية السوداء المائلة للشعار - يسار
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: CustomPaint(
              size: const Size(180, 140),
              painter: _DiagonalPainter(),
            ),
          ),

          // الشعار - على الخلفية السوداء
          Positioned(
            left: 0,
            top: 0,
            child: logoPath != null && File(logoPath!).existsSync()
                // عرض الشعار المخصص بحجم كامل
                ? Container(
                    width: 170,
                    height: 100,
                    padding: const EdgeInsets.all(5),
                    child: Center(
                      child: Image.file(
                        File(logoPath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                // عرض الشعار الافتراضي من assets
                : Container(
                    width: 170,
                    height: 100,
                    padding: const EdgeInsets.all(5),
                    child: Center(
                      child: Image.asset(
                        'assets/images/1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),

          // رقم الهاتف والعنوان - صف واحد في أسفل الخلفية السوداء
          Positioned(
            left: 8,
            bottom: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // العنوان أولاً (يظهر على اليسار)
                if (companyAddress != null && companyAddress!.isNotEmpty) ...[
                  Text(
                    companyAddress!,
                    style: const TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'العنوان:',
                    style: TextStyle(
                      fontSize: 7,
                      color: Color(0xFFF4C430),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
                // فاصل
                if (companyAddress != null &&
                    companyAddress!.isNotEmpty &&
                    companyPhone != null &&
                    companyPhone!.isNotEmpty)
                  const SizedBox(width: 12),
                // رقم الهاتف ثانياً (يظهر على اليمين)
                if (companyPhone != null && companyPhone!.isNotEmpty) ...[
                  Text(
                    companyPhone!,
                    style: const TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'رقم الهاتف:',
                    style: TextStyle(
                      fontSize: 7,
                      color: Color(0xFFF4C430),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ],
            ),
          ),

          // عنوان الفاتورة - يمين
          Positioned(
            right: 16,
            top: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'فاتورة مبيعات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('رقم الفاتورة', 'INV-2025-001'),
                const SizedBox(height: 2),
                _buildInfoRow('تاريخ الفاتورة', '2025/01/18'),
                const SizedBox(height: 2),
                _buildInfoRow('العملة الأساسية', 'USD'),
              ],
            ),
          ),

          // الخط الأصفر السفلي
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 3,
              color: const Color(0xFFF4C430),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF666666),
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label :',
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF1A1A1A),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}

/// رسام الخلفية المائلة
class _DiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.85, 0)
      ..lineTo(size.width * 0.65, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
