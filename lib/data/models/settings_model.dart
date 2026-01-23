import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج سجل تغيير سعر الصرف
class ExchangeRateHistory {
  final double rate;
  final DateTime date;

  ExchangeRateHistory({
    required this.rate,
    required this.date,
  });

  factory ExchangeRateHistory.fromJson(Map<String, dynamic> json) {
    return ExchangeRateHistory(
      rate: (json['rate'] ?? 0).toDouble(),
      date: json['date'] is String
          ? DateTime.parse(json['date'])
          : (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'rate': rate,
        'date': date.toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'rate': rate,
        'date': Timestamp.fromDate(date),
      };
}

/// نموذج إعدادات سعر الصرف
class SettingsModel {
  final String id;
  final double usdToIqd; // سعر الصرف: دولار إلى دينار عراقي
  final DateTime? lastUpdated;
  final String? updatedBy;
  final List<ExchangeRateHistory> history; // آخر 10 تغييرات

  /// Default exchange rate for offline fallback
  static const double defaultRate = 1480.0;

  SettingsModel({
    this.id = 'exchange_rate',
    required this.usdToIqd,
    this.lastUpdated,
    this.updatedBy,
    List<ExchangeRateHistory>? history,
  }) : history = history ?? [];

  /// للتوافق مع الكود القديم
  double get usdToSyp => usdToIqd;

  /// Create from Firestore document
  factory SettingsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return SettingsModel(
      id: doc.id,
      usdToIqd:
          (data['usdToIqd'] ?? data['usdToSyp'] ?? defaultRate).toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
      history: (data['history'] as List<dynamic>?)
              ?.map((h) =>
                  ExchangeRateHistory.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Create from JSON map
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['id'] ?? 'exchange_rate',
      usdToIqd:
          (json['usdToIqd'] ?? json['usdToSyp'] ?? defaultRate).toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
      updatedBy: json['updatedBy'],
      history: (json['history'] as List<dynamic>?)
              ?.map((h) => ExchangeRateHistory.fromJson(h))
              .toList() ??
          [],
    );
  }

  /// Create default settings
  factory SettingsModel.defaults() {
    return SettingsModel(
      id: 'exchange_rate',
      usdToIqd: defaultRate,
      lastUpdated: DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
        'usdToIqd': usdToIqd,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy,
        'history': history.take(10).map((h) => h.toFirestore()).toList(),
      };

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'usdToIqd': usdToIqd,
        'lastUpdated': lastUpdated?.toIso8601String(),
        'updatedBy': updatedBy,
        'history': history.map((h) => h.toJson()).toList(),
      };

  /// Create a copy with updated fields
  SettingsModel copyWith({
    String? id,
    double? usdToIqd,
    DateTime? lastUpdated,
    String? updatedBy,
    List<ExchangeRateHistory>? history,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      usdToIqd: usdToIqd ?? this.usdToIqd,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
      history: history ?? this.history,
    );
  }

  /// تحديث سعر الصرف مع الاحتفاظ بالتاريخ
  SettingsModel updateRate(double newRate, {String? updatedBy}) {
    final newHistory = [
      ExchangeRateHistory(rate: usdToIqd, date: lastUpdated ?? DateTime.now()),
      ...history,
    ].take(10).toList();

    return copyWith(
      usdToIqd: newRate,
      lastUpdated: DateTime.now(),
      updatedBy: updatedBy,
      history: newHistory,
    );
  }

  @override
  String toString() =>
      'SettingsModel(id: $id, usdToIqd: $usdToIqd, lastUpdated: $lastUpdated)';
}

/// نموذج عدادات النظام
class CountersModel {
  final int invoiceNumber;
  final DateTime? lastResetDate;

  CountersModel({
    this.invoiceNumber = 0,
    this.lastResetDate,
  });

  factory CountersModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CountersModel(
      invoiceNumber: data['invoiceNumber'] ?? 0,
      lastResetDate: (data['lastResetDate'] as Timestamp?)?.toDate(),
    );
  }

  factory CountersModel.fromJson(Map<String, dynamic> json) {
    return CountersModel(
      invoiceNumber: json['invoiceNumber'] ?? 0,
      lastResetDate: json['lastResetDate'] != null
          ? DateTime.parse(json['lastResetDate'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'invoiceNumber': invoiceNumber,
        'lastResetDate':
            lastResetDate != null ? Timestamp.fromDate(lastResetDate!) : null,
      };

  Map<String, dynamic> toJson() => {
        'invoiceNumber': invoiceNumber,
        'lastResetDate': lastResetDate?.toIso8601String(),
      };

  /// إنشاء رقم فاتورة جديد
  String generateInvoiceNumber({String prefix = 'INV'}) {
    final year = DateTime.now().year;
    final newNumber = invoiceNumber + 1;
    return '$prefix-$year-${newNumber.toString().padLeft(4, '0')}';
  }

  CountersModel increment() {
    return CountersModel(
      invoiceNumber: invoiceNumber + 1,
      lastResetDate: lastResetDate,
    );
  }

  /// إعادة تعيين العداد (سنوياً)
  CountersModel reset() {
    return CountersModel(
      invoiceNumber: 0,
      lastResetDate: DateTime.now(),
    );
  }
}
