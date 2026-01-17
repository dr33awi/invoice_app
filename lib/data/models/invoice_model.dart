import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Create from Firestore document
  factory InvoiceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return InvoiceModel(
      id: doc.id,
      invoiceNumber: data['invoiceNumber'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'],
      date: (data['date'] as Timestamp).toDate(),
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItemModel.fromJson(item))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      totalUSD: (data['totalUSD'] ?? 0).toDouble(),
      exchangeRate: (data['exchangeRate'] ?? 0).toDouble(),
      totalSYP: (data['totalSYP'] ?? 0).toDouble(),
      status: data['status'] ?? 'completed',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'],
    );
  }

  /// Create from JSON map
  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'],
      date: json['date'] is String
          ? DateTime.parse(json['date'])
          : (json['date'] as Timestamp).toDate(),
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

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
        'invoiceNumber': invoiceNumber,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'date': Timestamp.fromDate(date),
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'totalUSD': totalUSD,
        'exchangeRate': exchangeRate,
        'totalSYP': totalSYP,
        'status': status,
        'notes': notes,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      };

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
  final String size;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final double unitPrice;

  @HiveField(5)
  final double total;

  InvoiceItemModel({
    required this.productId,
    required this.productName,
    required this.size,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      size: json['size'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'size': size,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': total,
      };

  InvoiceItemModel copyWith({
    String? productId,
    String? productName,
    String? size,
    int? quantity,
    double? unitPrice,
    double? total,
  }) {
    return InvoiceItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }
}
