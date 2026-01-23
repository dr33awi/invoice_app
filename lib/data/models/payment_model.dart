import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

/// نموذج الدفعة
/// يُستخدم لتسجيل دفعات العملاء على الفواتير
@HiveType(typeId: 6)
class PaymentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String method; // cash | transfer

  @HiveField(4)
  final String? note;

  @HiveField(5)
  final String? receivedBy;

  /// طرق الدفع المتاحة
  static const String methodCash = 'cash';
  static const String methodTransfer = 'transfer';

  PaymentModel({
    required this.id,
    required this.amount,
    required this.date,
    this.method = methodCash,
    this.note,
    this.receivedBy,
  });

  /// الحصول على اسم طريقة الدفع بالعربية
  String get methodName {
    switch (method) {
      case methodTransfer:
        return 'تحويل';
      case methodCash:
      default:
        return 'نقداً';
    }
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date: json['date'] is String
          ? DateTime.parse(json['date'])
          : (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      method: json['method'] ?? methodCash,
      note: json['note'],
      receivedBy: json['receivedBy'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'method': method,
        'note': note,
        'receivedBy': receivedBy,
      };

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'method': method,
        'note': note,
        'receivedBy': receivedBy,
      };

  PaymentModel copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? method,
    String? note,
    String? receivedBy,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: method ?? this.method,
      note: note ?? this.note,
      receivedBy: receivedBy ?? this.receivedBy,
    );
  }

  @override
  String toString() =>
      'PaymentModel(id: $id, amount: $amount, date: $date, method: $method)';
}
