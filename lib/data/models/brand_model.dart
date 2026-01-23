import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 4)
class BrandModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? nameEn;

  @HiveField(3)
  final String? logo;

  @HiveField(7)
  final String? logoUrl;

  @HiveField(4)
  final String? country;

  @HiveField(8)
  final int order; // للترتيب في العرض

  @HiveField(5)
  final bool isActive;

  @HiveField(9)
  final int productsCount; // عدد المنتجات (denormalized)

  @HiveField(6)
  final DateTime? createdAt;

  @HiveField(10)
  final DateTime? updatedAt;

  BrandModel({
    required this.id,
    required this.name,
    this.nameEn,
    this.logo,
    this.logoUrl,
    this.country,
    this.order = 0,
    this.isActive = true,
    this.productsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// الحصول على رابط الشعار (للتوافق)
  String? get logoImage => logoUrl ?? logo;

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['nameEn'],
      logo: json['logo'],
      logoUrl: json['logoUrl'],
      country: json['country'],
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
      productsCount: json['productsCount'] ?? 0,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  factory BrandModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BrandModel(
      id: doc.id,
      name: data['name'] ?? '',
      nameEn: data['nameEn'],
      logo: data['logo'],
      logoUrl: data['logoUrl'],
      country: data['country'],
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      productsCount: data['productsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameEn': nameEn,
        'logo': logo,
        'logoUrl': logoUrl,
        'country': country,
        'order': order,
        'isActive': isActive,
        'productsCount': productsCount,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'nameEn': nameEn,
        'logo': logo,
        'logoUrl': logoUrl,
        'country': country,
        'order': order,
        'isActive': isActive,
        'productsCount': productsCount,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  BrandModel copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? logo,
    String? logoUrl,
    String? country,
    int? order,
    bool? isActive,
    int? productsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      logo: logo ?? this.logo,
      logoUrl: logoUrl ?? this.logoUrl,
      country: country ?? this.country,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      productsCount: productsCount ?? this.productsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'BrandModel(id: $id, name: $name, order: $order)';
}
