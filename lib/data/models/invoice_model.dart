import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class InvoiceModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String invoiceNumber;

  @HiveField(2)
  final String customerName;

  @HiveField(3)
  final String? customerPhone;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final List<InvoiceItemModel> items;

  @HiveField(6)
  final double subtotal;

  @HiveField(7)
  final double discount;

  @HiveField(8)
  final double totalUSD;

  @HiveField(9)
  final double exchangeRate;

  @HiveField(10)
  final double totalSYP;

  @HiveField(11)
  final String status;

  @HiveField(12)
  final String? notes;

  @HiveField(13)
  final DateTime? createdAt;

  @HiveField(14)
  final DateTime? updatedAt;

  @HiveField(15)
  final String? createdBy;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    this.customerPhone,
    required this.date,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.totalUSD,
    required this.exchangeRate,
    required this.totalSYP,
    this.status = 'completed',
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// Create from JSON map
  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'],
      date: json['date'] is String
          ? DateTime.parse(json['date'])
          : json['date'] as DateTime,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItemModel.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalUSD: (json['totalUSD'] ?? 0).toDouble(),
      exchangeRate: (json['exchangeRate'] ?? 0).toDouble(),
      totalSYP: (json['totalSYP'] ?? 0).toDouble(),
      status: json['status'] ?? 'completed',
      notes: json['notes'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdBy: json['createdBy'],
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'date': date.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'totalUSD': totalUSD,
        'exchangeRate': exchangeRate,
        'totalSYP': totalSYP,
        'status': status,
        'notes': notes,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'createdBy': createdBy,
      };

  /// Create a copy with updated fields
  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    String? customerName,
    String? customerPhone,
    DateTime? date,
    List<InvoiceItemModel>? items,
    double? subtotal,
    double? discount,
    double? totalUSD,
    double? exchangeRate,
    double? totalSYP,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      date: date ?? this.date,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      totalUSD: totalUSD ?? this.totalUSD,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      totalSYP: totalSYP ?? this.totalSYP,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Get total item count
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  String toString() =>
      'InvoiceModel(id: $id, number: $invoiceNumber, customer: $customerName, total: \$$totalUSD)';
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
  final int pairsPerPackage; // جوز/طرد

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
