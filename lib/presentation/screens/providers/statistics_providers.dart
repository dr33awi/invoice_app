import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/data/models/statistics_model.dart';
import 'core_providers.dart';

// ═══════════════════════════════════════════════════════════
// STATISTICS PROVIDERS
// ═══════════════════════════════════════════════════════════

final todayStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.getTodayStats();
});

final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.getDashboardStats();
});

final todayStatisticsProvider = StreamProvider<DailyStatisticsModel?>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.watchTodayStatistics();
});

final currentMonthStatisticsProvider =
    StreamProvider<MonthlyStatisticsModel?>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.watchCurrentMonthStatistics();
});
