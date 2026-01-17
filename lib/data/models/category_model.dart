import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? icon;

  @HiveField(3)
  final int? colorValue;

  @HiveField(4)
  final bool isActive;

  @HiveField(5)
  final DateTime? createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.colorValue,
    this.isActive = true,
    this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      colorValue: json['colorValue'],
      isActive: json['isActive'] ?? true,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  factory CategoryModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'],
      colorValue: data['colorValue'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'colorValue': colorValue,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'icon': icon,
        'colorValue': colorValue,
        'isActive': isActive,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    int? colorValue,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'CategoryModel(id: $id, name: $name)';
}
