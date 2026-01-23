import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'payment_model.dart';

@HiveType(typeId: 1)
class InvoiceModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String invoiceNumber;

  // العميل (Reference + Denormalized)
  @HiveField(2)
  final String customerName;

  @HiveField(3)
  final String? customerPhone;

  @HiveField(29)
  final String? customerAddress;

  @HiveField(19)
  final String? customerId; // reference to customers collection

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final List<InvoiceItemModel> items;

  // المالية
  @HiveField(6)
  final double subtotal;

  @HiveField(7)
  final double discount; // نسبة الخصم

  @HiveField(20)
  final double discountAmount; // قيمة الخصم

  @HiveField(8)
  final double totalUSD;

  @HiveField(9)
  final double exchangeRate;

  @HiveField(10)
  final double totalIQD; // تغيير من SYP إلى IQD

  // الدفع
  @HiveField(18)
  final double paidAmount;

  @HiveField(21)
  final double remainingAmount;

  @HiveField(22)
  final String paymentStatus; // paid | partial | unpaid

  @HiveField(23)
  final List<PaymentModel> payments; // سجل الدفعات

  // الحالة
  @HiveField(11)
  final String status; // draft | confirmed | cancelled

  @HiveField(12)
  final String? notes;

  // التواريخ
  @HiveField(24)
  final DateTime? invoiceDate;

  @HiveField(25)
  final DateTime? dueDate;

  @HiveField(13)
  final DateTime? createdAt;

  @HiveField(14)
  final DateTime? updatedAt;

  @HiveField(15)
  final String? createdBy;

  @HiveField(16)
  final String barcodeValue;

  @HiveField(17)
  final String paymentMethod; // طريقة الدفع الأساسية

  // للإحصائيات (denormalized للاستعلامات السريعة)
  @HiveField(26)
  final int year;

  @HiveField(27)
  final int month;

  @HiveField(28)
  final int day;

  /// المبلغ المستحق
  double get amountDue => totalUSD - paidAmount;

  /// حالات الدفع
  static const String statusPaid = 'paid';
  static const String statusPartial = 'partial';
  static const String statusUnpaid = 'unpaid';

  /// حالات الفاتورة
  static const String invoiceDraft = 'draft';
  static const String invoiceConfirmed = 'confirmed';
  static const String invoiceCancelled = 'cancelled';

  /// طرق الدفع
  static const String paymentCash = 'cash';
  static const String paymentTransfer = 'transfer';

  /// الحصول على اسم طريقة الدفع بالعربية
  String get paymentMethodName {
    switch (paymentMethod) {
      case paymentTransfer:
        return 'تحويل';
      case paymentCash:
      default:
        return 'نقداً';
    }
  }

  /// الحصول على اسم حالة الدفع بالعربية
  String get paymentStatusName {
    switch (paymentStatus) {
      case statusPaid:
        return 'مدفوع';
      case statusPartial:
        return 'دفع جزئي';
      case statusUnpaid:
      default:
        return 'غير مدفوع';
    }
  }

  /// الحصول على اسم حالة الفاتورة بالعربية
  String get statusName {
    switch (status) {
      case invoiceDraft:
        return 'مسودة';
      case invoiceConfirmed:
        return 'مؤكدة';
      case invoiceCancelled:
        return 'ملغاة';
      default:
        return 'مكتملة';
    }
  }

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerId,
    required this.date,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.discountAmount = 0,
    required this.totalUSD,
    required this.exchangeRate,
    required double totalIQD,
    this.paidAmount = 0,
    double? remainingAmount,
    String? paymentStatus,
    List<PaymentModel>? payments,
    this.status = 'confirmed',
    this.notes,
    this.invoiceDate,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    String? barcodeValue,
    this.paymentMethod = 'cash',
    int? year,
    int? month,
    int? day,
  })  : totalIQD = totalIQD,
        remainingAmount = remainingAmount ?? (totalUSD - paidAmount),
        paymentStatus =
            paymentStatus ?? _calculatePaymentStatus(totalUSD, paidAmount),
        payments = payments ?? [],
        year = year ?? date.year,
        month = month ?? date.month,
        day = day ?? date.day,
        barcodeValue = barcodeValue ?? generateBarcode(invoiceNumber);

  /// حساب حالة الدفع تلقائياً
  static String _calculatePaymentStatus(double total, double paid) {
    if (paid >= total) return statusPaid;
    if (paid > 0) return statusPartial;
    return statusUnpaid;
  }

  /// توليد قيمة الباركود من رقم الفاتورة
  /// الصيغة: رقم الفاتورة مباشرة (مثل INF-0001)
  static String generateBarcode(String invoiceNumber) {
    if (invoiceNumber.isNotEmpty) {
      // إزالة أي أحرف غير مسموحة في Code128
      final cleanNumber = invoiceNumber.replaceAll(RegExp(r'[^\w\-]'), '');
      return cleanNumber;
    }
    return 'INV-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Create from Firestore document
  factory InvoiceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final invoiceNumber = data['invoiceNumber'] ?? '';
    final dateValue = data['date'] ?? data['invoiceDate'];
    final date = dateValue is Timestamp
        ? dateValue.toDate()
        : (dateValue is String ? DateTime.parse(dateValue) : DateTime.now());

    return InvoiceModel(
      id: doc.id,
      invoiceNumber: invoiceNumber,
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'],
      customerAddress: data['customerAddress'],
      customerId: data['customerId'],
      date: date,
      items: (data['items'] as List<dynamic>?)
              ?.map((item) =>
                  InvoiceItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discount: (data['discount'] ?? data['discountPercent'] ?? 0).toDouble(),
      discountAmount: (data['discountAmount'] ?? 0).toDouble(),
      totalUSD: (data['totalUSD'] ?? 0).toDouble(),
      exchangeRate: (data['exchangeRate'] ?? 0).toDouble(),
      totalIQD: (data['totalIQD'] ?? data['totalSYP'] ?? 0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (data['remainingAmount'] ?? 0).toDouble(),
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      payments: (data['payments'] as List<dynamic>?)
              ?.map((p) => PaymentModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      status: data['status'] ?? 'confirmed',
      notes: data['notes'],
      invoiceDate: (data['invoiceDate'] as Timestamp?)?.toDate(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'],
      barcodeValue: data['barcodeValue'] ?? generateBarcode(invoiceNumber),
      paymentMethod: data['paymentMethod'] ?? 'cash',
      year: data['year'],
      month: data['month'],
      day: data['day'],
    );
  }

  /// Create from JSON map
  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final invoiceNumber = json['invoiceNumber'] ?? '';
    final dateValue = json['date'] ?? json['invoiceDate'];
    final date = dateValue is String
        ? DateTime.parse(dateValue)
        : (dateValue is DateTime ? dateValue : DateTime.now());

    return InvoiceModel(
      id: json['id'] ?? '',
      invoiceNumber: invoiceNumber,
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'],
      customerAddress: json['customerAddress'],
      customerId: json['customerId'],
      date: date,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItemModel.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? json['discountPercent'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalUSD: (json['totalUSD'] ?? 0).toDouble(),
      exchangeRate: (json['exchangeRate'] ?? 0).toDouble(),
      totalIQD: (json['totalIQD'] ?? json['totalSYP'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (json['remainingAmount'] ?? 0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      payments: (json['payments'] as List<dynamic>?)
              ?.map((p) => PaymentModel.fromJson(p))
              .toList() ??
          [],
      status: json['status'] ?? 'confirmed',
      notes: json['notes'],
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'])
          : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdBy: json['createdBy'],
      barcodeValue: json['barcodeValue'] ?? generateBarcode(invoiceNumber),
      paymentMethod: json['paymentMethod'] ?? 'cash',
      year: json['year'],
      month: json['month'],
      day: json['day'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
        'invoiceNumber': invoiceNumber,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerAddress': customerAddress,
        'customerId': customerId,
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'discountPercent': discount,
        'discountAmount': discountAmount,
        'totalUSD': totalUSD,
        'exchangeRate': exchangeRate,
        'totalIQD': totalIQD,
        'paidAmount': paidAmount,
        'remainingAmount': remainingAmount,
        'paymentStatus': paymentStatus,
        'payments': payments.map((p) => p.toFirestore()).toList(),
        'status': status,
        'isActive': status != invoiceCancelled, // للمزامنة مع الأجهزة الأخرى
        'notes': notes,
        'invoiceDate': invoiceDate != null
            ? Timestamp.fromDate(invoiceDate!)
            : Timestamp.fromDate(date),
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
        'barcodeValue': barcodeValue,
        'paymentMethod': paymentMethod,
        'year': year,
        'month': month,
        'day': day,
      };

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerAddress': customerAddress,
        'customerId': customerId,
        'date': date.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'discountAmount': discountAmount,
        'totalUSD': totalUSD,
        'exchangeRate': exchangeRate,
        'totalIQD': totalIQD,
        'paidAmount': paidAmount,
        'remainingAmount': remainingAmount,
        'paymentStatus': paymentStatus,
        'payments': payments.map((p) => p.toJson()).toList(),
        'status': status,
        'notes': notes,
        'invoiceDate': invoiceDate?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'createdBy': createdBy,
        'barcodeValue': barcodeValue,
        'paymentMethod': paymentMethod,
        'year': year,
        'month': month,
        'day': day,
      };

  /// Create a copy with updated fields
  /// ملاحظة: الباركود لا يتغير عند التعديل للحفاظ على التتبع
  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? customerId,
    DateTime? date,
    List<InvoiceItemModel>? items,
    double? subtotal,
    double? discount,
    double? discountAmount,
    double? totalUSD,
    double? exchangeRate,
    double? totalIQD,
    double? paidAmount,
    double? remainingAmount,
    String? paymentStatus,
    List<PaymentModel>? payments,
    String? status,
    String? notes,
    DateTime? invoiceDate,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? barcodeValue,
    String? paymentMethod,
    int? year,
    int? month,
    int? day,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalUSD: totalUSD ?? this.totalUSD,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      totalIQD: totalIQD ?? this.totalIQD,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      payments: payments ?? this.payments,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
    );
  }

  /// إضافة دفعة جديدة
  InvoiceModel addPayment(PaymentModel payment) {
    final newPayments = [...payments, payment];
    final newPaidAmount = paidAmount + payment.amount;
    final newRemainingAmount = totalUSD - newPaidAmount;
    final newPaymentStatus = _calculatePaymentStatus(totalUSD, newPaidAmount);

    return copyWith(
      payments: newPayments,
      paidAmount: newPaidAmount,
      remainingAmount: newRemainingAmount,
      paymentStatus: newPaymentStatus,
    );
  }

  /// Get total item count
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// للتوافق مع الكود القديم
  double get totalSYP => totalIQD;

  @override
  String toString() =>
      'InvoiceModel(id: $id, number: $invoiceNumber, customer: $customerName, total: \$$totalUSD, status: $paymentStatus)';
}

@HiveType(typeId: 2)
class InvoiceItemModel extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final String size; // نطاق المقاسات

  @HiveField(3)
  final int quantity; // إجمالي الأزواج

  @HiveField(4)
  final double unitPrice;

  @HiveField(5)
  final double total;

  @HiveField(6)
  final String brand; // الماركة

  @HiveField(7)
  final int packagesCount; // عدد الطرود

  @HiveField(8)
  final int pairsPerPackage; // الكمية/طرد

  @HiveField(9)
  final String? category; // الفئة

  InvoiceItemModel({
    required this.productId,
    required this.productName,
    required this.size,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.brand = '',
    this.packagesCount = 1,
    this.pairsPerPackage = 12,
    this.category,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      size: json['size'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      brand: json['brand'] ?? '',
      packagesCount: json['packagesCount'] ?? 1,
      pairsPerPackage: json['pairsPerPackage'] ?? 12,
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'size': size,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': total,
        'brand': brand,
        'packagesCount': packagesCount,
        'pairsPerPackage': pairsPerPackage,
        'category': category,
      };

  InvoiceItemModel copyWith({
    String? productId,
    String? productName,
    String? size,
    int? quantity,
    double? unitPrice,
    double? total,
    String? brand,
    int? packagesCount,
    int? pairsPerPackage,
    String? category,
  }) {
    return InvoiceItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      brand: brand ?? this.brand,
      packagesCount: packagesCount ?? this.packagesCount,
      pairsPerPackage: pairsPerPackage ?? this.pairsPerPackage,
      category: category ?? this.category,
    );
  }
}
