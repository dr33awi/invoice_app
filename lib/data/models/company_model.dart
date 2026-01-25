import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'company_model.g.dart';

/// نموذج معلومات الشركة
/// يُستخدم في الفاتورة المطبوعة والإعدادات العامة
@HiveType(typeId: 10)
class CompanyModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(6)
  final String? nameEn;

  @HiveField(1)
  final String? subtitle;

  @HiveField(2)
  final String? phone;

  @HiveField(7)
  final String? secondaryPhone;

  @HiveField(3)
  final String? address;

  @HiveField(8)
  final String? city;

  @HiveField(5)
  final String? logoPath;

  @HiveField(9)
  final String? logoUrl;

  // للفاتورة المطبوعة
  @HiveField(10)
  final String? invoiceNotes;

  @HiveField(11)
  final String? termsAndConditions;

  // الإعدادات
  @HiveField(12)
  final String defaultCurrency; // USD | IQD

  @HiveField(13)
  final String invoicePrefix; // INV

  @HiveField(14)
  final String? websiteLink; // رابط موقع الويب

  @HiveField(4)
  final DateTime updatedAt;

  CompanyModel({
    required this.name,
    this.nameEn,
    this.subtitle,
    this.phone,
    this.secondaryPhone,
    this.address,
    this.city,
    this.logoPath,
    this.logoUrl,
    this.invoiceNotes,
    this.termsAndConditions,
    this.defaultCurrency = 'USD',
    this.invoicePrefix = 'INV',
    this.websiteLink,
    required this.updatedAt,
  });

  /// الحصول على رابط الشعار
  String? get logo => logoUrl ?? logoPath;

  // القيم الافتراضية
  static const String defaultName = 'شركة المعيار';
  static const String defaultNameEn = 'Al-Miar Company';
  static const String defaultSubtitle = 'للأحذية بالجملة';
  static const String? defaultPhone = null;
  static const String? defaultAddress = null;
  static const String? defaultLogoPath = null;

  factory CompanyModel.defaults() {
    return CompanyModel(
      name: defaultName,
      nameEn: defaultNameEn,
      subtitle: defaultSubtitle,
      phone: defaultPhone,
      address: defaultAddress,
      updatedAt: DateTime.now(),
      logoPath: defaultLogoPath,
    );
  }

  factory CompanyModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CompanyModel(
      name: data['name'] ?? defaultName,
      nameEn: data['nameEn'],
      subtitle: data['subtitle'] ?? defaultSubtitle,
      phone: data['phone'],
      secondaryPhone: data['secondaryPhone'],
      address: data['address'],
      city: data['city'],
      logoPath: data['logoPath'],
      logoUrl: data['logoUrl'],
      invoiceNotes: data['invoiceNotes'],
      termsAndConditions: data['termsAndConditions'],
      defaultCurrency: data['defaultCurrency'] ?? 'USD',
      invoicePrefix: data['invoicePrefix'] ?? 'INV',
      websiteLink: data['websiteLink'] ?? data['whatsappContactLink'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  CompanyModel copyWith({
    String? name,
    String? nameEn,
    String? subtitle,
    String? phone,
    String? secondaryPhone,
    String? address,
    String? city,
    String? logoPath,
    String? logoUrl,
    String? invoiceNotes,
    String? termsAndConditions,
    String? defaultCurrency,
    String? invoicePrefix,
    String? websiteLink,
    DateTime? updatedAt,
  }) {
    return CompanyModel(
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      subtitle: subtitle ?? this.subtitle,
      phone: phone ?? this.phone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      address: address ?? this.address,
      city: city ?? this.city,
      logoPath: logoPath ?? this.logoPath,
      logoUrl: logoUrl ?? this.logoUrl,
      invoiceNotes: invoiceNotes ?? this.invoiceNotes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      websiteLink: websiteLink ?? this.websiteLink,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameEn': nameEn,
      'subtitle': subtitle,
      'phone': phone,
      'secondaryPhone': secondaryPhone,
      'address': address,
      'city': city,
      'logoPath': logoPath,
      'logoUrl': logoUrl,
      'invoiceNotes': invoiceNotes,
      'termsAndConditions': termsAndConditions,
      'defaultCurrency': defaultCurrency,
      'invoicePrefix': invoicePrefix,
      'websiteLink': websiteLink,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'nameEn': nameEn,
      'subtitle': subtitle,
      'phone': phone,
      'secondaryPhone': secondaryPhone,
      'address': address,
      'city': city,
      'logoPath': logoPath,
      'logoUrl': logoUrl,
      'invoiceNotes': invoiceNotes,
      'termsAndConditions': termsAndConditions,
      'defaultCurrency': defaultCurrency,
      'invoicePrefix': invoicePrefix,
      'websiteLink': websiteLink,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      name: json['name'] ?? defaultName,
      nameEn: json['nameEn'],
      subtitle: json['subtitle'] ?? defaultSubtitle,
      phone: json['phone'],
      secondaryPhone: json['secondaryPhone'],
      address: json['address'] ?? defaultAddress,
      city: json['city'],
      logoPath: json['logoPath'],
      logoUrl: json['logoUrl'],
      invoiceNotes: json['invoiceNotes'],
      termsAndConditions: json['termsAndConditions'],
      defaultCurrency: json['defaultCurrency'] ?? 'USD',
      invoicePrefix: json['invoicePrefix'] ?? 'INV',
      websiteLink: json['websiteLink'] ?? json['whatsappContactLink'],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
