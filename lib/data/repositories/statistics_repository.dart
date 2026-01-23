import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wholesale_shoes_invoice/data/models/statistics_model.dart';
import 'package:wholesale_shoes_invoice/core/services/firestore_service.dart';
import 'package:wholesale_shoes_invoice/core/services/logger_service.dart';

/// Repository للإحصائيات اليومية والشهرية
class StatisticsRepository {
  final FirestoreService _firestoreService;

  StatisticsRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  // ═══════════════════════════════════════════════════════════
  // DAILY STATISTICS
  // ═══════════════════════════════════════════════════════════

  /// الحصول على إحصائيات يوم معين
  Future<DailyStatisticsModel?> getDailyStatistics(DateTime date) async {
    try {
      final doc = await _firestoreService.getDailyStatDoc(date).get();
      if (doc.exists) {
        return DailyStatisticsModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logger.error('Error getting daily statistics', error: e);
      return null;
    }
  }

  /// الحصول على إحصائيات اليوم
  Future<DailyStatisticsModel?> getTodayStatistics() async {
    return getDailyStatistics(DateTime.now());
  }

  /// الحصول على إحصائيات الأسبوع الحالي
  Future<List<DailyStatisticsModel>> getWeekStatistics() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return getStatisticsRange(
      startOfWeek,
      now,
    );
  }

  /// الحصول على إحصائيات فترة معينة
  Future<List<DailyStatisticsModel>> getStatisticsRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _firestoreService.statisticsCollection
          .doc('daily')
          .collection('days')
          .where('date',
              isGreaterThanOrEqualTo: start.toIso8601String().split('T')[0])
          .where('date',
              isLessThanOrEqualTo: end.toIso8601String().split('T')[0])
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DailyStatisticsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      logger.error('Error getting statistics range', error: e);
      return [];
    }
  }

  /// مراقبة إحصائيات اليوم
  Stream<DailyStatisticsModel?> watchTodayStatistics() {
    return _firestoreService.getDailyStatDoc(DateTime.now()).snapshots().map(
      (snapshot) {
        if (snapshot.exists) {
          return DailyStatisticsModel.fromFirestore(snapshot);
        }
        return null;
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MONTHLY STATISTICS
  // ═══════════════════════════════════════════════════════════

  /// الحصول على إحصائيات شهر معين
  Future<MonthlyStatisticsModel?> getMonthlyStatistics(
      int year, int month) async {
    try {
      final doc = await _firestoreService.getMonthlyStatDoc(year, month).get();
      if (doc.exists) {
        return MonthlyStatisticsModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logger.error('Error getting monthly statistics', error: e);
      return null;
    }
  }

  /// الحصول على إحصائيات الشهر الحالي
  Future<MonthlyStatisticsModel?> getCurrentMonthStatistics() async {
    final now = DateTime.now();
    return getMonthlyStatistics(now.year, now.month);
  }

  /// الحصول على إحصائيات السنة
  Future<List<MonthlyStatisticsModel>> getYearStatistics(int year) async {
    try {
      final snapshot = await _firestoreService.statisticsCollection
          .doc('monthly')
          .collection('months')
          .where('year', isEqualTo: year)
          .orderBy('month')
          .get();

      return snapshot.docs
          .map((doc) => MonthlyStatisticsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      logger.error('Error getting year statistics', error: e);
      return [];
    }
  }

  /// مراقبة إحصائيات الشهر الحالي
  Stream<MonthlyStatisticsModel?> watchCurrentMonthStatistics() {
    final now = DateTime.now();
    return _firestoreService
        .getMonthlyStatDoc(now.year, now.month)
        .snapshots()
        .map(
      (snapshot) {
        if (snapshot.exists) {
          return MonthlyStatisticsModel.fromFirestore(snapshot);
        }
        return null;
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TOP PRODUCTS & CUSTOMERS
  // ═══════════════════════════════════════════════════════════

  /// تحديث قائمة المنتجات الأكثر مبيعاً (لليوم)
  Future<void> updateTopProduct({
    required DateTime date,
    required String productId,
    required String productName,
    required int quantitySold,
    required double totalSales,
  }) async {
    try {
      final statDoc = _firestoreService.getDailyStatDoc(date);

      await _firestoreService.firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(statDoc);

        List<Map<String, dynamic>> topProducts = [];
        if (snapshot.exists && snapshot.data()?['topProducts'] != null) {
          topProducts =
              List<Map<String, dynamic>>.from(snapshot.data()!['topProducts']);
        }

        // تحديث أو إضافة المنتج
        final existingIndex =
            topProducts.indexWhere((p) => p['productId'] == productId);

        if (existingIndex >= 0) {
          topProducts[existingIndex]['quantitySold'] += quantitySold;
          topProducts[existingIndex]['totalSales'] += totalSales;
        } else {
          topProducts.add({
            'productId': productId,
            'productName': productName,
            'quantitySold': quantitySold,
            'totalSales': totalSales,
          });
        }

        // ترتيب والاحتفاظ بأفضل 10
        topProducts.sort((a, b) =>
            (b['quantitySold'] as int).compareTo(a['quantitySold'] as int));
        topProducts = topProducts.take(10).toList();

        transaction.set(
          statDoc,
          {
            'topProducts': topProducts,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      logger.error('Error updating top product', error: e);
    }
  }

  /// تحديث قائمة العملاء الأكثر شراءً (لليوم)
  Future<void> updateTopCustomer({
    required DateTime date,
    required String customerId,
    required String customerName,
    required int invoicesCount,
    required double totalPurchases,
  }) async {
    try {
      final statDoc = _firestoreService.getDailyStatDoc(date);

      await _firestoreService.firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(statDoc);

        List<Map<String, dynamic>> topCustomers = [];
        if (snapshot.exists && snapshot.data()?['topCustomers'] != null) {
          topCustomers =
              List<Map<String, dynamic>>.from(snapshot.data()!['topCustomers']);
        }

        final existingIndex =
            topCustomers.indexWhere((c) => c['customerId'] == customerId);

        if (existingIndex >= 0) {
          topCustomers[existingIndex]['invoicesCount'] += invoicesCount;
          topCustomers[existingIndex]['totalPurchases'] += totalPurchases;
        } else {
          topCustomers.add({
            'customerId': customerId,
            'customerName': customerName,
            'invoicesCount': invoicesCount,
            'totalPurchases': totalPurchases,
          });
        }

        topCustomers.sort((a, b) => (b['totalPurchases'] as double)
            .compareTo(a['totalPurchases'] as double));
        topCustomers = topCustomers.take(10).toList();

        transaction.set(
          statDoc,
          {
            'topCustomers': topCustomers,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      logger.error('Error updating top customer', error: e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // AGGREGATED STATISTICS
  // ═══════════════════════════════════════════════════════════

  /// إحصائيات ملخصة للوحة التحكم
  Future<Map<String, dynamic>> getDashboardStats() async {
    final today = await getTodayStatistics();
    final thisMonth = await getCurrentMonthStatistics();

    // إحصائيات الأسبوع
    final weekStats = await getWeekStatistics();
    final weekTotal = weekStats.fold<double>(
      0,
      (sum, stat) => sum + stat.totalSalesUSD,
    );

    return {
      'today': {
        'invoices': today?.invoicesCount ?? 0,
        'salesUSD': today?.totalSalesUSD ?? 0,
        'salesIQD': today?.totalSalesIQD ?? 0,
        'paid': today?.totalPaid ?? 0,
        'remaining': today?.totalRemaining ?? 0,
      },
      'week': {
        'invoices': weekStats.fold<int>(0, (sum, s) => sum + s.invoicesCount),
        'salesUSD': weekTotal,
      },
      'month': {
        'invoices': thisMonth?.invoicesCount ?? 0,
        'salesUSD': thisMonth?.totalSalesUSD ?? 0,
        'salesIQD': thisMonth?.totalSalesIQD ?? 0,
      },
      'topProducts': today?.topProducts ?? [],
      'topCustomers': today?.topCustomers ?? [],
    };
  }

  /// مقارنة مع الفترة السابقة
  Future<Map<String, dynamic>> getComparisonStats() async {
    final now = DateTime.now();
    final today = await getTodayStatistics();
    final yesterday = await getDailyStatistics(
      now.subtract(const Duration(days: 1)),
    );

    final thisMonth = await getCurrentMonthStatistics();
    final lastMonth = await getMonthlyStatistics(
      now.month == 1 ? now.year - 1 : now.year,
      now.month == 1 ? 12 : now.month - 1,
    );

    return {
      'daily': {
        'current': today?.totalSalesUSD ?? 0,
        'previous': yesterday?.totalSalesUSD ?? 0,
        'change': _calculateChange(
          today?.totalSalesUSD ?? 0,
          yesterday?.totalSalesUSD ?? 0,
        ),
      },
      'monthly': {
        'current': thisMonth?.totalSalesUSD ?? 0,
        'previous': lastMonth?.totalSalesUSD ?? 0,
        'change': _calculateChange(
          thisMonth?.totalSalesUSD ?? 0,
          lastMonth?.totalSalesUSD ?? 0,
        ),
      },
    };
  }

  double _calculateChange(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  // ═══════════════════════════════════════════════════════════
  // INITIALIZE STATISTICS
  // ═══════════════════════════════════════════════════════════

  /// تهيئة إحصائيات يوم جديد
  Future<void> initializeDailyStats(DateTime date) async {
    final statDoc = _firestoreService.getDailyStatDoc(date);

    await statDoc.set({
      'date': date.toIso8601String().split('T')[0],
      'year': date.year,
      'month': date.month,
      'day': date.day,
      'invoicesCount': 0,
      'totalSalesUSD': 0.0,
      'totalSalesIQD': 0.0,
      'totalPaid': 0.0,
      'totalRemaining': 0.0,
      'topProducts': [],
      'topCustomers': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// تهيئة إحصائيات شهر جديد
  Future<void> initializeMonthlyStats(int year, int month) async {
    final statDoc = _firestoreService.getMonthlyStatDoc(year, month);

    await statDoc.set({
      'year': year,
      'month': month,
      'invoicesCount': 0,
      'totalSalesUSD': 0.0,
      'totalSalesIQD': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
