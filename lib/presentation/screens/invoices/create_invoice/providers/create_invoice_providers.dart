import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CREATE INVOICE STATE
// ═══════════════════════════════════════════════════════════════════════════

/// حالة شاشة إنشاء الفاتورة
class CreateInvoiceState {
  final String? selectedCustomerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String paymentMethod;
  final double? customExchangeRate;
  final bool useCustomExchangeRate;
  final List<InvoiceItemModel> items;
  final double discount;
  final double paidAmount;
  final String? notes;
  final bool isSaving;
  final bool isEditing;
  final InvoiceModel? originalInvoice;

  const CreateInvoiceState({
    this.selectedCustomerId,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.paymentMethod = InvoiceModel.paymentCash,
    this.customExchangeRate,
    this.useCustomExchangeRate = false,
    this.items = const [],
    this.discount = 0,
    this.paidAmount = 0,
    this.notes,
    this.isSaving = false,
    this.isEditing = false,
    this.originalInvoice,
  });

  CreateInvoiceState copyWith({
    String? selectedCustomerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? paymentMethod,
    double? customExchangeRate,
    bool? useCustomExchangeRate,
    List<InvoiceItemModel>? items,
    double? discount,
    double? paidAmount,
    String? notes,
    bool? isSaving,
    bool? isEditing,
    InvoiceModel? originalInvoice,
    bool clearCustomerId = false,
    bool clearCustomerName = false,
    bool clearCustomerPhone = false,
    bool clearCustomerAddress = false,
    bool clearNotes = false,
  }) {
    return CreateInvoiceState(
      selectedCustomerId: clearCustomerId
          ? null
          : (selectedCustomerId ?? this.selectedCustomerId),
      customerName:
          clearCustomerName ? null : (customerName ?? this.customerName),
      customerPhone:
          clearCustomerPhone ? null : (customerPhone ?? this.customerPhone),
      customerAddress: clearCustomerAddress
          ? null
          : (customerAddress ?? this.customerAddress),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customExchangeRate: customExchangeRate ?? this.customExchangeRate,
      useCustomExchangeRate:
          useCustomExchangeRate ?? this.useCustomExchangeRate,
      items: items ?? this.items,
      discount: discount ?? this.discount,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: clearNotes ? null : (notes ?? this.notes),
      isSaving: isSaving ?? this.isSaving,
      isEditing: isEditing ?? this.isEditing,
      originalInvoice: originalInvoice ?? this.originalInvoice,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CREATE INVOICE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class CreateInvoiceNotifier extends StateNotifier<CreateInvoiceState> {
  final Ref _ref;

  CreateInvoiceNotifier(this._ref, {InvoiceModel? invoice})
      : super(const CreateInvoiceState()) {
    if (invoice != null) {
      _loadInvoiceData(invoice);
    }
  }

  void _loadInvoiceData(InvoiceModel invoice) {
    state = CreateInvoiceState(
      selectedCustomerId: invoice.customerId,
      customerName: invoice.customerName,
      customerPhone: invoice.customerPhone,
      customerAddress: invoice.customerAddress,
      items: List.from(invoice.items),
      discount: invoice.discount,
      paidAmount: invoice.paidAmount,
      notes: invoice.notes,
      paymentMethod: invoice.paymentMethod,
      customExchangeRate: invoice.exchangeRate,
      useCustomExchangeRate: true,
      isEditing: true,
      originalInvoice: invoice,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOMER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void selectCustomer(CustomerModel customer) {
    state = state.copyWith(
      selectedCustomerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      customerAddress: customer.address,
    );
  }

  void clearCustomer() {
    state = state.copyWith(
      clearCustomerId: true,
      clearCustomerName: true,
      clearCustomerPhone: true,
      clearCustomerAddress: true,
    );
  }

  void setCustomerData({
    required String? customerId,
    required String name,
    String? phone,
    String? address,
  }) {
    state = state.copyWith(
      selectedCustomerId: customerId,
      customerName: name,
      customerPhone: phone,
      customerAddress: address,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAYMENT METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount);
  }

  void setPaidAmount(double amount) {
    state = state.copyWith(paidAmount: amount);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ITEMS METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void addItem(InvoiceItemModel item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void updateItem(int index, InvoiceItemModel item) {
    final newItems = List<InvoiceItemModel>.from(state.items);
    newItems[index] = item;
    state = state.copyWith(items: newItems);
  }

  void removeItem(int index) {
    final newItems = List<InvoiceItemModel>.from(state.items);
    newItems.removeAt(index);
    state = state.copyWith(items: newItems);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXCHANGE RATE METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void setCustomExchangeRate(double rate) {
    state = state.copyWith(
      customExchangeRate: rate,
      useCustomExchangeRate: true,
    );
  }

  void clearCustomExchangeRate() {
    state = CreateInvoiceState(
      selectedCustomerId: state.selectedCustomerId,
      customerName: state.customerName,
      customerPhone: state.customerPhone,
      customerAddress: state.customerAddress,
      paymentMethod: state.paymentMethod,
      customExchangeRate: null,
      useCustomExchangeRate: false,
      items: state.items,
      discount: state.discount,
      paidAmount: state.paidAmount,
      notes: state.notes,
      isSaving: state.isSaving,
      isEditing: state.isEditing,
      originalInvoice: state.originalInvoice,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void setNotes(String? notes) {
    if (notes == null || notes.isEmpty) {
      state = state.copyWith(clearNotes: true);
    } else {
      state = state.copyWith(notes: notes);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVING STATE
  // ═══════════════════════════════════════════════════════════════════════════

  void setSaving(bool isSaving) {
    state = state.copyWith(isSaving: isSaving);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider لحالة شاشة إنشاء الفاتورة
final createInvoiceNotifierProvider = StateNotifierProvider.autoDispose
    .family<CreateInvoiceNotifier, CreateInvoiceState, InvoiceModel?>(
  (ref, invoice) => CreateInvoiceNotifier(ref, invoice: invoice),
);

// ═══════════════════════════════════════════════════════════════════════════
// COMPUTED VALUES
// ═══════════════════════════════════════════════════════════════════════════

/// المجموع الفرعي للفاتورة
double computeSubtotal(List<InvoiceItemModel> items) {
  return items.fold(0.0, (sum, item) => sum + item.total);
}

/// إجمالي الفاتورة بالدولار (الإجمالي الفرعي - الخصم)
double computeTotalUSD(double subtotal, double discount) {
  return subtotal - discount;
}

/// المبلغ المستحق
double computeAmountDue(double totalUSD, double paidAmount) {
  return totalUSD - paidAmount;
}

/// إجمالي الكمية
int computeTotalQuantity(List<InvoiceItemModel> items) {
  return items.fold(0, (sum, item) => sum + item.quantity);
}

/// إجمالي الفاتورة بالليرة
double computeTotalSYP(double totalUSD, double exchangeRate) {
  return totalUSD * exchangeRate;
}

/// الحصول على سعر الصرف الفعال
double getEffectiveExchangeRate(
  double? customExchangeRate,
  bool useCustomExchangeRate,
  double currentExchangeRate,
) {
  return useCustomExchangeRate && customExchangeRate != null
      ? customExchangeRate
      : currentExchangeRate;
}

// ═══════════════════════════════════════════════════════════════════════════
// ADD ITEM DIALOG STATE
// ═══════════════════════════════════════════════════════════════════════════

/// حالة حوار إضافة عنصر
class AddItemDialogState {
  final String name;
  final String? brandName;
  final String? categoryName;
  final String size;
  final int packagesCount;
  final int pairsPerPackage;
  final double pricePerPackage;
  final ProductModel? selectedProduct;
  final String? nameError;
  final String? sizeError;
  final String? packagesError;
  final String? pairsError;
  final String? priceError;

  const AddItemDialogState({
    this.name = '',
    this.brandName,
    this.categoryName,
    this.size = '',
    this.packagesCount = 1,
    this.pairsPerPackage = 12,
    this.pricePerPackage = 0,
    this.selectedProduct,
    this.nameError,
    this.sizeError,
    this.packagesError,
    this.pairsError,
    this.priceError,
  });

  int get totalPairs => packagesCount * pairsPerPackage;
  double get totalPrice => packagesCount * pricePerPackage;
  double get pricePerPair =>
      packagesCount > 0 && totalPairs > 0 ? totalPrice / totalPairs : 0.0;

  AddItemDialogState copyWith({
    String? name,
    String? brandName,
    String? categoryName,
    String? size,
    int? packagesCount,
    int? pairsPerPackage,
    double? pricePerPackage,
    ProductModel? selectedProduct,
    String? nameError,
    String? sizeError,
    String? packagesError,
    String? pairsError,
    String? priceError,
    bool clearBrandName = false,
    bool clearCategoryName = false,
    bool clearSelectedProduct = false,
    bool clearNameError = false,
    bool clearSizeError = false,
    bool clearPackagesError = false,
    bool clearPairsError = false,
    bool clearPriceError = false,
  }) {
    return AddItemDialogState(
      name: name ?? this.name,
      brandName: clearBrandName ? null : (brandName ?? this.brandName),
      categoryName:
          clearCategoryName ? null : (categoryName ?? this.categoryName),
      size: size ?? this.size,
      packagesCount: packagesCount ?? this.packagesCount,
      pairsPerPackage: pairsPerPackage ?? this.pairsPerPackage,
      pricePerPackage: pricePerPackage ?? this.pricePerPackage,
      selectedProduct: clearSelectedProduct
          ? null
          : (selectedProduct ?? this.selectedProduct),
      nameError: clearNameError ? null : (nameError ?? this.nameError),
      sizeError: clearSizeError ? null : (sizeError ?? this.sizeError),
      packagesError:
          clearPackagesError ? null : (packagesError ?? this.packagesError),
      pairsError: clearPairsError ? null : (pairsError ?? this.pairsError),
      priceError: clearPriceError ? null : (priceError ?? this.priceError),
    );
  }

  /// التحقق من صحة البيانات
  AddItemDialogState validate() {
    return copyWith(
      nameError: name.isEmpty ? 'مطلوب' : null,
      sizeError: size.isEmpty ? 'مطلوب' : null,
      packagesError: packagesCount <= 0 ? 'مطلوب' : null,
      pairsError: pairsPerPackage <= 0 ? 'مطلوب' : null,
      priceError: pricePerPackage <= 0 ? 'مطلوب' : null,
      clearNameError: name.isNotEmpty,
      clearSizeError: size.isNotEmpty,
      clearPackagesError: packagesCount > 0,
      clearPairsError: pairsPerPackage > 0,
      clearPriceError: pricePerPackage > 0,
    );
  }

  bool get hasErrors =>
      nameError != null ||
      sizeError != null ||
      packagesError != null ||
      pairsError != null ||
      priceError != null;

  /// تحميل بيانات من منتج
  AddItemDialogState loadFromProduct(ProductModel product) {
    return AddItemDialogState(
      name: product.name,
      brandName: product.brand,
      categoryName: product.category,
      size: product.sizeRange,
      packagesCount: product.packagesCount,
      pairsPerPackage: product.pairsPerPackage,
      pricePerPackage: product.wholesalePrice,
      selectedProduct: product,
    );
  }

  /// تحميل بيانات من عنصر فاتورة للتعديل
  static AddItemDialogState fromInvoiceItem(InvoiceItemModel item) {
    final pricePerPackage =
        item.packagesCount > 0 ? item.total / item.packagesCount : 0.0;
    return AddItemDialogState(
      name: item.productName,
      brandName: item.brand.isNotEmpty ? item.brand : null,
      categoryName: item.category,
      size: item.size,
      packagesCount: item.packagesCount,
      pairsPerPackage: item.pairsPerPackage,
      pricePerPackage: pricePerPackage,
    );
  }

  /// تحويل إلى عنصر فاتورة
  InvoiceItemModel toInvoiceItem(String productId) {
    return InvoiceItemModel(
      productId: productId,
      productName: name,
      brand: brandName ?? '',
      size: size,
      packagesCount: packagesCount,
      pairsPerPackage: pairsPerPackage,
      quantity: totalPairs,
      unitPrice: pricePerPair,
      total: totalPrice,
      category: categoryName,
    );
  }
}
