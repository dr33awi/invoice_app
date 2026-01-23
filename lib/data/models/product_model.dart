import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

/// نموذج المقاس والمخزون
@HiveType(typeId: 7)
class ProductSizeModel extends HiveObject {
  @HiveField(0)
  final String size;

  @HiveField(1)
  final int stock;

  @HiveField(2)
  final int minStock;

  ProductSizeModel({
    required this.size,
    this.stock = 0,
    this.minStock = 0,
  });

  /// هل المخزون منخفض؟
  bool get isLowStock => stock <= minStock && stock > 0;

  /// هل نفد المخزون؟
  bool get isOutOfStock => stock <= 0;

  factory ProductSizeModel.fromJson(Map<String, dynamic> json) {
    return ProductSizeModel(
      size: json['size'] ?? '',
      stock: json['stock'] ?? 0,
      minStock: json['minStock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'size': size,
        'stock': stock,
        'minStock': minStock,
      };

  ProductSizeModel copyWith({
    String? size,
    int? stock,
    int? minStock,
  }) {
    return ProductSizeModel(
      size: size ?? this.size,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
    );
  }
}

@HiveType(typeId: 0)
class ProductModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(13)
  final String? code; // كود المنتج (فريد)

  // التصنيف (Reference + Denormalized)
  @HiveField(6)
  final String? categoryId;

  @HiveField(14)
  final String? categoryName;

  @HiveField(2)
  final String? brandId;

  @HiveField(15)
  final String? brandName;

  // للتوافق مع الكود القديم
  String get brand => brandName ?? '';
  String get category => categoryName ?? '';

  @HiveField(16)
  final String? description;

  @HiveField(17)
  final String? imageUrl;

  // المقاسات والمخزون
  @HiveField(3)
  final String sizeRange; // نطاق المقاسات للعرض مثل 24-36

  @HiveField(18)
  final List<ProductSizeModel> sizes; // تفاصيل المقاسات والمخزون

  // الأسعار
  @HiveField(19)
  final double costPrice; // سعر الشراء

  @HiveField(4)
  final double wholesalePrice; // سعر الجملة

  @HiveField(20)
  final double? retailPrice; // سعر المفرد

  @HiveField(5)
  final String currency;

  // المخزون (للطرود)
  @HiveField(11)
  final int packagesCount; // كمية الطرود

  @HiveField(12)
  final int pairsPerPackage; // كم الكمية يسع الطرد

  @HiveField(21)
  final int totalStock; // إجمالي المخزون (computed)

  // الحالة
  @HiveField(7)
  final bool isActive;

  // التواريخ
  @HiveField(8)
  final DateTime? createdAt;

  @HiveField(9)
  final DateTime? updatedAt;

  @HiveField(10)
  final String? createdBy;

  ProductModel({
    required this.id,
    required this.name,
    this.code,
    this.categoryId,
    this.categoryName,
    this.brandId,
    this.brandName,
    this.description,
    this.imageUrl,
    required this.sizeRange,
    List<ProductSizeModel>? sizes,
    this.costPrice = 0,
    required this.wholesalePrice,
    this.retailPrice,
    this.currency = 'USD',
    this.packagesCount = 1,
    this.pairsPerPackage = 12,
    int? totalStock,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  })  : sizes = sizes ?? [],
        totalStock = totalStock ?? (packagesCount * pairsPerPackage);

  /// إجمالي الأزواج
  int get totalPairs => packagesCount * pairsPerPackage;

  /// للتوافق مع الكود القديم
  String get size => sizeRange;

  /// حساب إجمالي المخزون من المقاسات
  int get calculatedTotalStock {
    if (sizes.isEmpty) return totalStock;
    return sizes.fold(0, (sum, s) => sum + s.stock);
  }

  /// هل المنتج منخفض المخزون؟
  bool get isLowStock => sizes.any((s) => s.isLowStock);

  /// هل نفد المخزون؟
  bool get isOutOfStock =>
      sizes.isNotEmpty ? sizes.every((s) => s.isOutOfStock) : totalStock <= 0;

  /// هامش الربح
  double get profitMargin => wholesalePrice - costPrice;

  /// نسبة الربح
  double get profitPercentage =>
      costPrice > 0 ? ((profitMargin / costPrice) * 100) : 0;

  /// Create from Firestore document
  factory ProductModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'],
      categoryId: data['categoryId'],
      categoryName: data['categoryName'] ?? data['category'],
      brandId: data['brandId'],
      brandName: data['brandName'] ?? data['brand'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      sizeRange: data['sizeRange'] ?? data['size'] ?? '',
      sizes: (data['sizes'] as List<dynamic>?)
              ?.map((s) => ProductSizeModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      costPrice: (data['costPrice'] ?? 0).toDouble(),
      wholesalePrice: (data['wholesalePrice'] ?? 0).toDouble(),
      retailPrice: data['retailPrice']?.toDouble(),
      currency: data['currency'] ?? 'USD',
      packagesCount: data['packagesCount'] ?? 1,
      pairsPerPackage: data['pairsPerPackage'] ?? 12,
      totalStock: data['totalStock'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'],
    );
  }

  /// Create from JSON map
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? json['category'],
      brandId: json['brandId'],
      brandName: json['brandName'] ?? json['brand'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      sizeRange: json['sizeRange'] ?? json['size'] ?? '',
      sizes: (json['sizes'] as List<dynamic>?)
              ?.map((s) => ProductSizeModel.fromJson(s))
              .toList() ??
          [],
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      wholesalePrice: (json['wholesalePrice'] ?? 0).toDouble(),
      retailPrice: json['retailPrice']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      packagesCount: json['packagesCount'] ?? 1,
      pairsPerPackage: json['pairsPerPackage'] ?? 12,
      totalStock: json['totalStock'],
      isActive: json['isActive'] ?? true,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdBy: json['createdBy'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'code': code,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'brandId': brandId,
        'brandName': brandName,
        'description': description,
        'imageUrl': imageUrl,
        'sizeRange': sizeRange,
        'sizes': sizes.map((s) => s.toJson()).toList(),
        'costPrice': costPrice,
        'wholesalePrice': wholesalePrice,
        'retailPrice': retailPrice,
        'currency': currency,
        'packagesCount': packagesCount,
        'pairsPerPackage': pairsPerPackage,
        'totalStock': calculatedTotalStock,
        'isActive': isActive,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      };

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'brandId': brandId,
        'brandName': brandName,
        'description': description,
        'imageUrl': imageUrl,
        'sizeRange': sizeRange,
        'sizes': sizes.map((s) => s.toJson()).toList(),
        'costPrice': costPrice,
        'wholesalePrice': wholesalePrice,
        'retailPrice': retailPrice,
        'currency': currency,
        'packagesCount': packagesCount,
        'pairsPerPackage': pairsPerPackage,
        'totalStock': calculatedTotalStock,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'createdBy': createdBy,
        // للتوافق مع الكود القديم
        'brand': brandName,
        'category': categoryName,
      };

  /// Create a copy with updated fields
  ProductModel copyWith({
    String? id,
    String? name,
    String? code,
    String? categoryId,
    String? categoryName,
    String? brandId,
    String? brandName,
    String? description,
    String? imageUrl,
    String? sizeRange,
    List<ProductSizeModel>? sizes,
    double? costPrice,
    double? wholesalePrice,
    double? retailPrice,
    String? currency,
    int? packagesCount,
    int? pairsPerPackage,
    int? totalStock,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sizeRange: sizeRange ?? this.sizeRange,
      sizes: sizes ?? this.sizes,
      costPrice: costPrice ?? this.costPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      retailPrice: retailPrice ?? this.retailPrice,
      currency: currency ?? this.currency,
      packagesCount: packagesCount ?? this.packagesCount,
      pairsPerPackage: pairsPerPackage ?? this.pairsPerPackage,
      totalStock: totalStock ?? this.totalStock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() =>
      'ProductModel(id: $id, name: $name, code: $code, brand: $brandName, price: $wholesalePrice)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
