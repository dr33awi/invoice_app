import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 5)
class CustomerModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? phone;

  @HiveField(8)
  final String? secondaryPhone;

  @HiveField(3)
  final String? address;

  @HiveField(9)
  final String? city;

  // المالية
  @HiveField(10)
  final double totalPurchases; // إجمالي المشتريات

  @HiveField(11)
  final double totalPaid; // إجمالي المدفوع

  @HiveField(12)
  final double balance; // الرصيد المتبقي (ديون)

  // التصنيف
  @HiveField(13)
  final String type; // wholesale | retail

  @HiveField(14)
  final int rating; // 1-5

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final bool isActive;

  // التواريخ
  @HiveField(15)
  final DateTime? lastPurchaseDate;

  @HiveField(6)
  final DateTime? createdAt;

  @HiveField(7)
  final DateTime? updatedAt;

  /// أنواع العملاء
  static const String typeWholesale = 'wholesale';
  static const String typeRetail = 'retail';

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.secondaryPhone,
    this.address,
    this.city,
    this.totalPurchases = 0,
    this.totalPaid = 0,
    this.balance = 0,
    this.type = typeWholesale,
    this.rating = 0,
    this.notes,
    this.isActive = true,
    this.lastPurchaseDate,
    this.createdAt,
    this.updatedAt,
  });

  /// الحصول على اسم نوع العميل بالعربية
  String get typeName {
    switch (type) {
      case typeRetail:
        return 'مفرد';
      case typeWholesale:
      default:
        return 'جملة';
    }
  }

  /// هل العميل مدين؟
  bool get hasDebt => balance > 0;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      secondaryPhone: json['secondaryPhone'],
      address: json['address'],
      city: json['city'],
      totalPurchases: (json['totalPurchases'] ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      type: json['type'] ?? typeWholesale,
      rating: json['rating'] ?? 0,
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
      lastPurchaseDate: json['lastPurchaseDate'] != null
          ? DateTime.parse(json['lastPurchaseDate'])
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  factory CustomerModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CustomerModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'],
      secondaryPhone: data['secondaryPhone'],
      address: data['address'],
      city: data['city'],
      totalPurchases: (data['totalPurchases'] ?? 0).toDouble(),
      totalPaid: (data['totalPaid'] ?? 0).toDouble(),
      balance: (data['balance'] ?? 0).toDouble(),
      type: data['type'] ?? typeWholesale,
      rating: data['rating'] ?? 0,
      notes: data['notes'],
      isActive: data['isActive'] ?? true,
      lastPurchaseDate: (data['lastPurchaseDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'secondaryPhone': secondaryPhone,
        'address': address,
        'city': city,
        'totalPurchases': totalPurchases,
        'totalPaid': totalPaid,
        'balance': balance,
        'type': type,
        'rating': rating,
        'notes': notes,
        'isActive': isActive,
        'lastPurchaseDate': lastPurchaseDate?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'secondaryPhone': secondaryPhone,
        'address': address,
        'city': city,
        'totalPurchases': totalPurchases,
        'totalPaid': totalPaid,
        'balance': balance,
        'type': type,
        'rating': rating,
        'notes': notes,
        'isActive': isActive,
        'lastPurchaseDate': lastPurchaseDate != null
            ? Timestamp.fromDate(lastPurchaseDate!)
            : null,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? secondaryPhone,
    String? address,
    String? city,
    double? totalPurchases,
    double? totalPaid,
    double? balance,
    String? type,
    int? rating,
    String? notes,
    bool? isActive,
    DateTime? lastPurchaseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      address: address ?? this.address,
      city: city ?? this.city,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalPaid: totalPaid ?? this.totalPaid,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// تحديث الإحصائيات المالية بعد فاتورة جديدة
  CustomerModel updateFinancials({
    required double invoiceTotal,
    required double paidAmount,
  }) {
    return copyWith(
      totalPurchases: totalPurchases + invoiceTotal,
      totalPaid: totalPaid + paidAmount,
      balance: balance + (invoiceTotal - paidAmount),
      lastPurchaseDate: DateTime.now(),
    );
  }

  /// تسجيل دفعة
  CustomerModel recordPayment(double amount) {
    return copyWith(
      totalPaid: totalPaid + amount,
      balance: balance - amount,
    );
  }

  @override
  String toString() =>
      'CustomerModel(id: $id, name: $name, phone: $phone, balance: $balance)';
}
