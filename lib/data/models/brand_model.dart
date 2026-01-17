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

  @HiveField(4)
  final String? country;

  @HiveField(5)
  final bool isActive;

  @HiveField(6)
  final DateTime? createdAt;

  BrandModel({
    required this.id,
    required this.name,
    this.nameEn,
    this.logo,
    this.country,
    this.isActive = true,
    this.createdAt,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['nameEn'],
      logo: json['logo'],
      country: json['country'],
      isActive: json['isActive'] ?? true,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  factory BrandModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BrandModel(
      id: doc.id,
      name: data['name'] ?? '',
      nameEn: data['nameEn'],
      logo: data['logo'],
      country: data['country'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameEn': nameEn,
        'logo': logo,
        'country': country,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'nameEn': nameEn,
        'logo': logo,
        'country': country,
        'isActive': isActive,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  BrandModel copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? logo,
    String? country,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      logo: logo ?? this.logo,
      country: country ?? this.country,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'BrandModel(id: $id, name: $name)';
}
