import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج المنتج الأكثر مبيعاً
class TopProductStat {
  final String productId;
  final String productName;
  final String? brandName;
  final int quantity;
  final double totalSales;

  TopProductStat({
    required this.productId,
    required this.productName,
    this.brandName,
    required this.quantity,
    required this.totalSales,
  });

  factory TopProductStat.fromJson(Map<String, dynamic> json) {
    return TopProductStat(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      brandName: json['brandName'],
      quantity: json['quantity'] ?? 0,
      totalSales: (json['totalSales'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'brandName': brandName,
        'quantity': quantity,
        'totalSales': totalSales,
      };
}

/// نموذج العميل الأكثر شراءً
class TopCustomerStat {
  final String customerId;
  final String customerName;
  final int invoicesCount;
  final double totalPurchases;

  TopCustomerStat({
    required this.customerId,
    required this.customerName,
    required this.invoicesCount,
    required this.totalPurchases,
  });

  factory TopCustomerStat.fromJson(Map<String, dynamic> json) {
    return TopCustomerStat(
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      invoicesCount: json['invoicesCount'] ?? 0,
      totalPurchases: (json['totalPurchases'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'customerName': customerName,
        'invoicesCount': invoicesCount,
        'totalPurchases': totalPurchases,
      };
}

/// نموذج الإحصائيات اليومية
class DailyStatisticsModel {
  final String id; // daily_YYYY-MM-DD
  final String date; // YYYY-MM-DD
  final int year;
  final int month;
  final int day;

  // إحصائيات الفواتير
  final int invoicesCount;
  final int confirmedInvoicesCount;
  final int cancelledInvoicesCount;

  // إحصائيات المبيعات
  final double totalSalesUSD;
  final double totalSalesIQD;
  final double totalPaid;
  final double totalRemaining;

  // إحصائيات الدفع
  final int paidInvoicesCount;
  final int partialInvoicesCount;
  final int unpaidInvoicesCount;

  // أعلى المنتجات والعملاء
  final List<TopProductStat> topProducts;
  final List<TopCustomerStat> topCustomers;

  // التواريخ
  final DateTime createdAt;
  final DateTime? updatedAt;

  DailyStatisticsModel({
    required this.id,
    required this.date,
    required this.year,
    required this.month,
    required this.day,
    this.invoicesCount = 0,
    this.confirmedInvoicesCount = 0,
    this.cancelledInvoicesCount = 0,
    this.totalSalesUSD = 0,
    this.totalSalesIQD = 0,
    this.totalPaid = 0,
    this.totalRemaining = 0,
    this.paidInvoicesCount = 0,
    this.partialInvoicesCount = 0,
    this.unpaidInvoicesCount = 0,
    List<TopProductStat>? topProducts,
    List<TopCustomerStat>? topCustomers,
    DateTime? createdAt,
    this.updatedAt,
  })  : topProducts = topProducts ?? [],
        topCustomers = topCustomers ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// إنشاء معرف من التاريخ
  static String generateId(DateTime date) {
    return 'daily_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// إنشاء من تاريخ
  factory DailyStatisticsModel.forDate(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return DailyStatisticsModel(
      id: 'daily_$dateStr',
      date: dateStr,
      year: date.year,
      month: date.month,
      day: date.day,
    );
  }

  factory DailyStatisticsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return DailyStatisticsModel(
      id: doc.id,
      date: data['date'] ?? '',
      year: data['year'] ?? 0,
      month: data['month'] ?? 0,
      day: data['day'] ?? 0,
      invoicesCount: data['invoicesCount'] ?? 0,
      confirmedInvoicesCount: data['confirmedInvoicesCount'] ?? 0,
      cancelledInvoicesCount: data['cancelledInvoicesCount'] ?? 0,
      totalSalesUSD: (data['totalSalesUSD'] ?? 0).toDouble(),
      totalSalesIQD: (data['totalSalesIQD'] ?? 0).toDouble(),
      totalPaid: (data['totalPaid'] ?? 0).toDouble(),
      totalRemaining: (data['totalRemaining'] ?? 0).toDouble(),
      paidInvoicesCount: data['paidInvoicesCount'] ?? 0,
      partialInvoicesCount: data['partialInvoicesCount'] ?? 0,
      unpaidInvoicesCount: data['unpaidInvoicesCount'] ?? 0,
      topProducts: (data['topProducts'] as List<dynamic>?)
              ?.map((p) => TopProductStat.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      topCustomers: (data['topCustomers'] as List<dynamic>?)
              ?.map((c) => TopCustomerStat.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory DailyStatisticsModel.fromJson(Map<String, dynamic> json) {
    return DailyStatisticsModel(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      day: json['day'] ?? 0,
      invoicesCount: json['invoicesCount'] ?? 0,
      confirmedInvoicesCount: json['confirmedInvoicesCount'] ?? 0,
      cancelledInvoicesCount: json['cancelledInvoicesCount'] ?? 0,
      totalSalesUSD: (json['totalSalesUSD'] ?? 0).toDouble(),
      totalSalesIQD: (json['totalSalesIQD'] ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      totalRemaining: (json['totalRemaining'] ?? 0).toDouble(),
      paidInvoicesCount: json['paidInvoicesCount'] ?? 0,
      partialInvoicesCount: json['partialInvoicesCount'] ?? 0,
      unpaidInvoicesCount: json['unpaidInvoicesCount'] ?? 0,
      topProducts: (json['topProducts'] as List<dynamic>?)
              ?.map((p) => TopProductStat.fromJson(p))
              .toList() ??
          [],
      topCustomers: (json['topCustomers'] as List<dynamic>?)
              ?.map((c) => TopCustomerStat.fromJson(c))
              .toList() ??
          [],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'date': date,
        'year': year,
        'month': month,
        'day': day,
        'invoicesCount': invoicesCount,
        'confirmedInvoicesCount': confirmedInvoicesCount,
        'cancelledInvoicesCount': cancelledInvoicesCount,
        'totalSalesUSD': totalSalesUSD,
        'totalSalesIQD': totalSalesIQD,
        'totalPaid': totalPaid,
        'totalRemaining': totalRemaining,
        'paidInvoicesCount': paidInvoicesCount,
        'partialInvoicesCount': partialInvoicesCount,
        'unpaidInvoicesCount': unpaidInvoicesCount,
        'topProducts': topProducts.take(5).map((p) => p.toJson()).toList(),
        'topCustomers': topCustomers.take(5).map((c) => c.toJson()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'year': year,
        'month': month,
        'day': day,
        'invoicesCount': invoicesCount,
        'confirmedInvoicesCount': confirmedInvoicesCount,
        'cancelledInvoicesCount': cancelledInvoicesCount,
        'totalSalesUSD': totalSalesUSD,
        'totalSalesIQD': totalSalesIQD,
        'totalPaid': totalPaid,
        'totalRemaining': totalRemaining,
        'paidInvoicesCount': paidInvoicesCount,
        'partialInvoicesCount': partialInvoicesCount,
        'unpaidInvoicesCount': unpaidInvoicesCount,
        'topProducts': topProducts.map((p) => p.toJson()).toList(),
        'topCustomers': topCustomers.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  DailyStatisticsModel copyWith({
    String? id,
    String? date,
    int? year,
    int? month,
    int? day,
    int? invoicesCount,
    int? confirmedInvoicesCount,
    int? cancelledInvoicesCount,
    double? totalSalesUSD,
    double? totalSalesIQD,
    double? totalPaid,
    double? totalRemaining,
    int? paidInvoicesCount,
    int? partialInvoicesCount,
    int? unpaidInvoicesCount,
    List<TopProductStat>? topProducts,
    List<TopCustomerStat>? topCustomers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyStatisticsModel(
      id: id ?? this.id,
      date: date ?? this.date,
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      invoicesCount: invoicesCount ?? this.invoicesCount,
      confirmedInvoicesCount:
          confirmedInvoicesCount ?? this.confirmedInvoicesCount,
      cancelledInvoicesCount:
          cancelledInvoicesCount ?? this.cancelledInvoicesCount,
      totalSalesUSD: totalSalesUSD ?? this.totalSalesUSD,
      totalSalesIQD: totalSalesIQD ?? this.totalSalesIQD,
      totalPaid: totalPaid ?? this.totalPaid,
      totalRemaining: totalRemaining ?? this.totalRemaining,
      paidInvoicesCount: paidInvoicesCount ?? this.paidInvoicesCount,
      partialInvoicesCount: partialInvoicesCount ?? this.partialInvoicesCount,
      unpaidInvoicesCount: unpaidInvoicesCount ?? this.unpaidInvoicesCount,
      topProducts: topProducts ?? this.topProducts,
      topCustomers: topCustomers ?? this.topCustomers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// نسبة التحصيل
  double get collectionRate =>
      totalSalesUSD > 0 ? (totalPaid / totalSalesUSD) * 100 : 0;

  @override
  String toString() =>
      'DailyStatisticsModel(date: $date, invoices: $invoicesCount, sales: \$$totalSalesUSD)';
}

/// نموذج الإحصائيات الشهرية
class MonthlyStatisticsModel {
  final String id; // monthly_YYYY-MM
  final int year;
  final int month;

  final int totalDays;
  final int invoicesCount;
  final double totalSalesUSD;
  final double totalSalesIQD;
  final double totalPaid;
  final double totalRemaining;

  final double averageDailySales;
  final double bestDaySales;
  final String? bestDayDate;

  final DateTime createdAt;
  final DateTime? updatedAt;

  MonthlyStatisticsModel({
    required this.id,
    required this.year,
    required this.month,
    this.totalDays = 0,
    this.invoicesCount = 0,
    this.totalSalesUSD = 0,
    this.totalSalesIQD = 0,
    this.totalPaid = 0,
    this.totalRemaining = 0,
    this.averageDailySales = 0,
    this.bestDaySales = 0,
    this.bestDayDate,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// إنشاء معرف من السنة والشهر
  static String generateId(int year, int month) {
    return 'monthly_$year-${month.toString().padLeft(2, '0')}';
  }

  factory MonthlyStatisticsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return MonthlyStatisticsModel(
      id: doc.id,
      year: data['year'] ?? 0,
      month: data['month'] ?? 0,
      totalDays: data['totalDays'] ?? 0,
      invoicesCount: data['invoicesCount'] ?? 0,
      totalSalesUSD: (data['totalSalesUSD'] ?? 0).toDouble(),
      totalSalesIQD: (data['totalSalesIQD'] ?? 0).toDouble(),
      totalPaid: (data['totalPaid'] ?? 0).toDouble(),
      totalRemaining: (data['totalRemaining'] ?? 0).toDouble(),
      averageDailySales: (data['averageDailySales'] ?? 0).toDouble(),
      bestDaySales: (data['bestDaySales'] ?? 0).toDouble(),
      bestDayDate: data['bestDayDate'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'year': year,
        'month': month,
        'totalDays': totalDays,
        'invoicesCount': invoicesCount,
        'totalSalesUSD': totalSalesUSD,
        'totalSalesIQD': totalSalesIQD,
        'totalPaid': totalPaid,
        'totalRemaining': totalRemaining,
        'averageDailySales': averageDailySales,
        'bestDaySales': bestDaySales,
        'bestDayDate': bestDayDate,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// اسم الشهر بالعربية
  String get monthName {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[month - 1];
  }
}
