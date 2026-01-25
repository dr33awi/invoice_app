import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_colors.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_spacing.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import '../controller/create_invoice_controller.dart';
import '../providers/create_invoice_providers.dart';

/// قسم ملخص الفاتورة - الملاحظات وزر الحفظ
class InvoiceSummarySection extends ConsumerWidget {
  final InvoiceModel? originalInvoice;
  final CreateInvoiceController controller;
  final VoidCallback onSave;

  const InvoiceSummarySection({
    super.key,
    required this.originalInvoice,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createInvoiceNotifierProvider(originalInvoice));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // حقل الملاحظات
        Card(
          child: Padding(
            padding: AppSpacing.paddingCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملاحظات',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                AppSpacing.gapVerticalSm,
                _NotesField(
                  notes: state.notes,
                  onChanged: (value) => controller.updateNotes(value),
                ),
              ],
            ),
          ),
        ),
        AppSpacing.gapVerticalLg,

        // زر الحفظ
        _SaveButton(
          isSaving: state.isSaving,
          isEditing: originalInvoice != null,
          hasItems: state.items.isNotEmpty,
          hasCustomer: state.selectedCustomerId != null,
          onPressed: onSave,
        ),
        AppSpacing.gapVerticalXl,
      ],
    );
  }
}

class _NotesField extends StatefulWidget {
  final String? notes;
  final ValueChanged<String> onChanged;

  const _NotesField({
    required this.notes,
    required this.onChanged,
  });

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.notes ?? '');
  }

  @override
  void didUpdateWidget(covariant _NotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentNotes = widget.notes ?? '';
    if (currentNotes != _controller.text) {
      _controller.text = currentNotes;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        hintText: 'أضف ملاحظات للفاتورة (اختياري)...',
        prefixIcon: Icon(Icons.note_alt_outlined),
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      minLines: 2,
      onChanged: widget.onChanged,
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final bool isEditing;
  final bool hasItems;
  final bool hasCustomer;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isSaving,
    required this.isEditing,
    required this.hasItems,
    required this.hasCustomer,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isSaving && hasItems && hasCustomer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // رسالة تحذيرية إذا لم تكن الفاتورة جاهزة
        if (!hasCustomer || !hasItems)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 20),
                AppSpacing.gapHorizontalSm,
                Expanded(
                  child: Text(
                    _getWarningMessage(),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),

        // زر الحفظ
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: isEnabled ? onPressed : null,
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(isEditing ? Icons.save : Icons.check),
            label: Text(
              isSaving
                  ? 'جاري الحفظ...'
                  : isEditing
                      ? 'تحديث الفاتورة'
                      : 'حفظ الفاتورة',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal600,
              disabledBackgroundColor: AppColors.teal600.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  String _getWarningMessage() {
    if (!hasCustomer && !hasItems) {
      return 'يرجى اختيار عميل وإضافة منتجات قبل حفظ الفاتورة';
    } else if (!hasCustomer) {
      return 'يرجى اختيار عميل قبل حفظ الفاتورة';
    } else if (!hasItems) {
      return 'يرجى إضافة منتجات قبل حفظ الفاتورة';
    }
    return '';
  }
}
