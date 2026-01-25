import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';
import 'package:wholesale_shoes_invoice/data/models/brand_model.dart';
import 'package:wholesale_shoes_invoice/data/models/category_model.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_colors.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/providers/providers.dart';
import '../providers/create_invoice_providers.dart';

/// Controller لإدارة منطق شاشة إنشاء الفاتورة
/// يحتوي على orchestration logic فقط - لا يحتوي على أي كود UI
class CreateInvoiceController {
  final WidgetRef _ref;
  final InvoiceModel? _originalInvoice;

  CreateInvoiceController(this._ref, {InvoiceModel? originalInvoice})
      : _originalInvoice = originalInvoice;

  CreateInvoiceNotifier get _notifier =>
      _ref.read(createInvoiceNotifierProvider(_originalInvoice).notifier);

  CreateInvoiceState get state =>
      _ref.read(createInvoiceNotifierProvider(_originalInvoice));

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOMER OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// اختيار عميل من القائمة
  void selectCustomer(CustomerModel customer) {
    _notifier.selectCustomer(customer);
  }

  /// مسح العميل المحدد
  void clearCustomer() {
    _notifier.clearCustomer();
  }

  /// إضافة عميل جديد واختياره
  Future<void> addAndSelectCustomer({
    required String name,
    String? phone,
    String? address,
    String? notes,
  }) async {
    final newCustomer = CustomerModel(
      id: const Uuid().v4(),
      name: name,
      phone: phone?.isNotEmpty == true ? phone : null,
      address: address?.isNotEmpty == true ? address : null,
      notes: notes?.isNotEmpty == true ? notes : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _ref
        .read(reactiveCustomersProvider.notifier)
        .addCustomer(newCustomer);

    _notifier.setCustomerData(
      customerId: newCustomer.id,
      name: name,
      phone: phone?.isNotEmpty == true ? phone : null,
      address: address?.isNotEmpty == true ? address : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAYMENT OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// تغيير طريقة الدفع
  void setPaymentMethod(String method) {
    _notifier.setPaymentMethod(method);
  }

  /// تحديث الخصم
  void updateDiscount(double discount) {
    _notifier.setDiscount(discount);
  }

  /// تحديث العربون
  void updatePaidAmount(double amount) {
    _notifier.setPaidAmount(amount);
  }

  /// مسح العربون
  void clearPaidAmount() {
    _notifier.setPaidAmount(0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ITEMS OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// إضافة عنصر للفاتورة
  void addItem(InvoiceItemModel item) {
    _notifier.addItem(item);
  }

  /// تحديث عنصر في الفاتورة
  void updateItem(int index, InvoiceItemModel item) {
    _notifier.updateItem(index, item);
  }

  /// حذف عنصر من الفاتورة
  void removeItem(int index) {
    _notifier.removeItem(index);
  }

  /// إضافة عنصر من حالة الحوار
  Future<InvoiceItemModel> createItemFromDialogState(
    AddItemDialogState dialogState, {
    String? existingProductId,
  }) async {
    final productId = existingProductId ?? const Uuid().v4();
    return dialogState.toInvoiceItem(productId);
  }

  /// حفظ منتج جديد في قاعدة البيانات
  Future<ProductModel> saveNewProduct(AddItemDialogState dialogState) async {
    final productId = const Uuid().v4();
    final newProduct = ProductModel(
      id: productId,
      name: dialogState.name,
      brandName: dialogState.brandName ?? '',
      sizeRange: dialogState.size,
      wholesalePrice: dialogState.pricePerPackage,
      packagesCount: dialogState.packagesCount,
      pairsPerPackage: dialogState.pairsPerPackage,
      categoryName: dialogState.categoryName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _ref.read(productsNotifierProvider.notifier).addProduct(newProduct);

    return newProduct;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXCHANGE RATE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحديث سعر الصرف المخصص
  void setCustomExchangeRate(double? rate, bool useCustom) {
    if (rate != null && useCustom) {
      _notifier.setCustomExchangeRate(rate);
    } else {
      // إذا لم يكن مخصصاً، نستخدم السعر الافتراضي
      _notifier.clearCustomExchangeRate();
    }
  }

  /// الحصول على سعر الصرف الفعال
  double getEffectiveRate() {
    final exchangeRateAsync = _ref.read(exchangeRateNotifierProvider);
    final currentRate = exchangeRateAsync.valueOrNull ?? 12500.0;
    return getEffectiveExchangeRate(
      state.customExchangeRate,
      state.useCustomExchangeRate,
      currentRate,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحديث الملاحظات
  void updateNotes(String notes) {
    _notifier.setNotes(notes.isEmpty ? null : notes);
  }

  /// تحديث الملاحظات
  void setNotes(String? notes) {
    _notifier.setNotes(notes);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BRAND & CATEGORY OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// إضافة ماركة جديدة
  Future<BrandModel> addNewBrand(String name) async {
    final newBrand = BrandModel(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _ref.read(brandsNotifierProvider.notifier).addBrand(newBrand);
    return newBrand;
  }

  /// إضافة فئة جديدة
  Future<CategoryModel> addNewCategory(String name) async {
    final newCategory = CategoryModel(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _ref
        .read(categoriesNotifierProvider.notifier)
        .addCategory(newCategory);
    return newCategory;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE INVOICE
  // ═══════════════════════════════════════════════════════════════════════════

  /// التحقق من صحة بيانات الفاتورة
  String? validateInvoice() {
    if (state.customerName == null || state.customerName!.isEmpty) {
      return 'الرجاء اختيار العميل';
    }
    if (state.items.isEmpty) {
      return 'الرجاء إضافة منتج واحد على الأقل';
    }
    return null;
  }

  /// حفظ الفاتورة
  Future<InvoiceModel?> saveInvoice(BuildContext context) async {
    final validationError = validateInvoice();
    if (validationError != null) {
      _showError(context, validationError);
      return null;
    }

    _notifier.setSaving(true);

    try {
      final exchangeRate = getEffectiveRate();
      final subtotal = computeSubtotal(state.items);
      final totalUSD = computeTotalUSD(subtotal, state.discount);
      final totalSYP = computeTotalSYP(totalUSD, exchangeRate);

      InvoiceModel resultInvoice;

      if (state.isEditing && _originalInvoice != null) {
        resultInvoice = _createUpdatedInvoice(
          subtotal: subtotal,
          totalUSD: totalUSD,
          totalSYP: totalSYP,
          exchangeRate: exchangeRate,
        );
        await _ref
            .read(invoicesNotifierProvider.notifier)
            .updateInvoice(resultInvoice);
        _showSuccess(context, 'تم تحديث الفاتورة بنجاح');
      } else {
        resultInvoice = await _createNewInvoice(
          subtotal: subtotal,
          totalUSD: totalUSD,
          totalSYP: totalSYP,
          exchangeRate: exchangeRate,
        );
        await _ref
            .read(invoicesNotifierProvider.notifier)
            .addInvoice(resultInvoice);
        _showSuccess(context, 'تم حفظ الفاتورة بنجاح');
      }

      return resultInvoice;
    } catch (e) {
      _showError(context, 'خطأ في حفظ الفاتورة: $e');
      return null;
    } finally {
      _notifier.setSaving(false);
    }
  }

  InvoiceModel _createUpdatedInvoice({
    required double subtotal,
    required double totalUSD,
    required double totalSYP,
    required double exchangeRate,
  }) {
    return InvoiceModel(
      id: _originalInvoice!.id,
      invoiceNumber: _originalInvoice!.invoiceNumber,
      customerId: state.selectedCustomerId ?? _originalInvoice!.customerId,
      customerName: state.customerName!,
      customerPhone: state.customerPhone,
      customerAddress: state.customerAddress,
      date: _originalInvoice!.date,
      items: state.items,
      subtotal: subtotal,
      discount: state.discount,
      totalUSD: totalUSD,
      exchangeRate: exchangeRate,
      totalIQD: totalSYP,
      notes: state.notes?.isNotEmpty == true ? state.notes : null,
      createdAt: _originalInvoice!.createdAt,
      barcodeValue: _originalInvoice!.barcodeValue,
      paymentMethod: state.paymentMethod,
      paidAmount: state.paidAmount,
    );
  }

  Future<InvoiceModel> _createNewInvoice({
    required double subtotal,
    required double totalUSD,
    required double totalSYP,
    required double exchangeRate,
  }) async {
    final invoiceNumber = await _ref
        .read(invoicesNotifierProvider.notifier)
        .generateInvoiceNumber();

    final barcodeValue = InvoiceModel.generateBarcode(invoiceNumber);

    return InvoiceModel(
      id: const Uuid().v4(),
      invoiceNumber: invoiceNumber,
      customerId: state.selectedCustomerId,
      customerName: state.customerName!,
      customerPhone: state.customerPhone,
      customerAddress: state.customerAddress,
      date: DateTime.now(),
      items: state.items,
      subtotal: subtotal,
      discount: state.discount,
      totalUSD: totalUSD,
      exchangeRate: exchangeRate,
      totalIQD: totalSYP,
      notes: state.notes?.isNotEmpty == true ? state.notes : null,
      createdAt: DateTime.now(),
      barcodeValue: barcodeValue,
      paymentMethod: state.paymentMethod,
      paidAmount: state.paidAmount,
    );
  }

  void _showSuccess(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
