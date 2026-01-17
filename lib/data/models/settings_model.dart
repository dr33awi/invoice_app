import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsModel {
  final String id;
  final double usdToSyp;
  final DateTime? lastUpdated;
  final String? updatedBy;

  /// Default exchange rate for offline fallback
  static const double defaultRate = 14500.0;

  SettingsModel({
    this.id = 'exchange_rate',
    required this.usdToSyp,
    this.lastUpdated,
    this.updatedBy,
  });

  /// Create from Firestore document
  factory SettingsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return SettingsModel(
      id: doc.id,
      usdToSyp: (data['usdToSyp'] ?? defaultRate).toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
    );
  }

  /// Create from JSON map
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['id'] ?? 'exchange_rate',
      usdToSyp: (json['usdToSyp'] ?? defaultRate).toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
      updatedBy: json['updatedBy'],
    );
  }

  /// Create default settings
  factory SettingsModel.defaults() {
    return SettingsModel(
      id: 'exchange_rate',
      usdToSyp: defaultRate,
      lastUpdated: DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
        'usdToSyp': usdToSyp,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy,
      };

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'usdToSyp': usdToSyp,
        'lastUpdated': lastUpdated?.toIso8601String(),
        'updatedBy': updatedBy,
      };

  /// Create a copy with updated fields
  SettingsModel copyWith({
    String? id,
    double? usdToSyp,
    DateTime? lastUpdated,
    String? updatedBy,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      usdToSyp: usdToSyp ?? this.usdToSyp,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  String toString() =>
      'SettingsModel(id: $id, usdToSyp: $usdToSyp, lastUpdated: $lastUpdated)';
}
