import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class ProductModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String brand; // ماركة الحذاء

  @HiveField(3)
  final String sizeRange; // نطاق المقاسات مثل 24-36

  @HiveField(4)
  final double wholesalePrice;

  @HiveField(5)
  final String currency;

  @HiveField(6)
  final String? category;

  @HiveField(7)
  final bool isActive;

  @HiveField(8)
  final DateTime? createdAt;

  @HiveField(9)
  final DateTime? updatedAt;

  @HiveField(10)
  final String? createdBy;

  @HiveField(11)
  final int packagesCount; // كمية الطرود

  @HiveField(12)
  final int pairsPerPackage; // كم جوز يسع الطرد

  ProductModel({
    required this.id,
    required this.name,
    this.brand = '',
    required this.sizeRange,
    required this.wholesalePrice,
    this.currency = 'USD',
    this.category,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.packagesCount = 1,
    this.pairsPerPackage = 12,
  });

  /// إجمالي الأزواج
  int get totalPairs => packagesCount * pairsPerPackage;

  /// للتوافق مع الكود القديم
  String get size => sizeRange;

  /// Create from Firestore document
  factory ProductModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      sizeRange: data['sizeRange'] ?? data['size'] ?? '',
      wholesalePrice: (data['wholesalePrice'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      category: data['category'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'],
      packagesCount: data['packagesCount'] ?? 1,
      pairsPerPackage: data['pairsPerPackage'] ?? 12,
    );
  }

  /// Create from JSON map
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      sizeRange: json['sizeRange'] ?? json['size'] ?? '',
      wholesalePrice: (json['wholesalePrice'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      category: json['category'],
      isActive: json['isActive'] ?? true,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdBy: json['createdBy'],
      packagesCount: json['packagesCount'] ?? 1,
      pairsPerPackage: json['pairsPerPackage'] ?? 12,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'brand': brand,
        'sizeRange': sizeRange,
        'wholesalePrice': wholesalePrice,
        'currency': currency,
        'category': category,
        'isActive': isActive,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
        'packagesCount': packagesCount,
        'pairsPerPackage': pairsPerPackage,
      };

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'sizeRange': sizeRange,
        'wholesalePrice': wholesalePrice,
        'currency': currency,
        'category': category,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'createdBy': createdBy,
        'packagesCount': packagesCount,
        'pairsPerPackage': pairsPerPackage,
      };

  /// Create a copy with updated fields
  ProductModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? sizeRange,
    double? wholesalePrice,
    String? currency,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? packagesCount,
    int? pairsPerPackage,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      sizeRange: sizeRange ?? this.sizeRange,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      packagesCount: packagesCount ?? this.packagesCount,
      pairsPerPackage: pairsPerPackage ?? this.pairsPerPackage,
    );
  }

  @override
  String toString() =>
      'ProductModel(id: $id, name: $name, brand: $brand, sizeRange: $sizeRange, price: $wholesalePrice)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
