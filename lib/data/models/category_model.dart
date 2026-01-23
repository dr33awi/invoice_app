import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(6)
  final String? nameEn;

  @HiveField(7)
  final String? description;

  @HiveField(2)
  final String? icon;

  @HiveField(8)
  final String? imageUrl;

  @HiveField(3)
  final int? colorValue;

  @HiveField(9)
  final int order; // للترتيب في العرض

  @HiveField(4)
  final bool isActive;

  @HiveField(10)
  final int productsCount; // عدد المنتجات (denormalized)

  @HiveField(5)
  final DateTime? createdAt;

  @HiveField(11)
  final DateTime? updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.nameEn,
    this.description,
    this.icon,
    this.imageUrl,
    this.colorValue,
    this.order = 0,
    this.isActive = true,
    this.productsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['nameEn'],
      description: json['description'],
      icon: json['icon'],
      imageUrl: json['imageUrl'],
      colorValue: json['colorValue'],
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
      productsCount: json['productsCount'] ?? 0,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  factory CategoryModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      nameEn: data['nameEn'],
      description: data['description'],
      icon: data['icon'],
      imageUrl: data['imageUrl'],
      colorValue: data['colorValue'],
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
        'description': description,
        'icon': icon,
        'imageUrl': imageUrl,
        'colorValue': colorValue,
        'order': order,
        'isActive': isActive,
        'productsCount': productsCount,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'nameEn': nameEn,
        'description': description,
        'icon': icon,
        'imageUrl': imageUrl,
        'colorValue': colorValue,
        'order': order,
        'isActive': isActive,
        'productsCount': productsCount,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  CategoryModel copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? description,
    String? icon,
    String? imageUrl,
    int? colorValue,
    int? order,
    bool? isActive,
    int? productsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      colorValue: colorValue ?? this.colorValue,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      productsCount: productsCount ?? this.productsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'CategoryModel(id: $id, name: $name, order: $order)';
}
