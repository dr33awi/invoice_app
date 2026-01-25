import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/core/theme/widgets/custom_app_bar.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_spacing.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_colors.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'controller/create_invoice_controller.dart';
import 'providers/create_invoice_providers.dart';
import 'sections/customer_selection_section.dart';
import 'sections/payment_section.dart';
import 'sections/product_selection_section.dart';
import 'sections/invoice_calculation_section.dart';
import 'sections/invoice_summary_section.dart';

/// شاشة إنشاء/تعديل الفاتورة - الموجه الرئيسي
///
/// هذه الشاشة تعمل كمنسق بين الأقسام المختلفة:
/// - CustomerSelectionSection: اختيار العميل
/// - PaymentSection: طريقة الدفع
/// - ProductSelectionSection: المنتجات
/// - InvoiceCalculationSection: الحسابات
/// - InvoiceSummarySection: الملاحظات والحفظ
class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final InvoiceModel? invoice;

  const CreateInvoiceScreen({super.key, this.invoice});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  late final CreateInvoiceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreateInvoiceController(ref, originalInvoice: widget.invoice);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createInvoiceNotifierProvider(widget.invoice));
    final isEditing = widget.invoice != null;

    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing ? 'تعديل الفاتورة' : 'فاتورة جديدة',
        subtitle:
            isEditing ? widget.invoice!.invoiceNumber : 'إنشاء فاتورة مبيعات',
        actions: [
          AppBarTextButton(
            text: isEditing ? 'تحديث' : 'حفظ',
            icon: Icons.save_outlined,
            isLoading: state.isSaving,
            onPressed: () => _handleSave(context),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          // قسم اختيار العميل
          CustomerSelectionSection(
            originalInvoice: widget.invoice,
            controller: _controller,
          ),
          AppSpacing.gapVerticalMd,

          // قسم طريقة الدفع
          PaymentSection(
            originalInvoice: widget.invoice,
            controller: _controller,
          ),
          AppSpacing.gapVerticalMd,

          // قسم المنتجات
          ProductSelectionSection(
            originalInvoice: widget.invoice,
            controller: _controller,
          ),
          AppSpacing.gapVerticalMd,

          // قسم الحسابات
          InvoiceCalculationSection(
            originalInvoice: widget.invoice,
            controller: _controller,
          ),
          AppSpacing.gapVerticalMd,

          // قسم الملخص والحفظ
          InvoiceSummarySection(
            originalInvoice: widget.invoice,
            controller: _controller,
            onSave: () => _handleSave(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    // التحقق من صحة البيانات
    final validationError = _controller.validateInvoice();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // حفظ الفاتورة
    final result = await _controller.saveInvoice(context);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.invoice != null
                ? 'تم تحديث الفاتورة بنجاح'
                : 'تم حفظ الفاتورة بنجاح',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }
}
