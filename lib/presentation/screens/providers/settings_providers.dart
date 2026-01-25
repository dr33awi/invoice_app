import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/data/repositories/settings_repository_new.dart';
import 'core_providers.dart';

// ═══════════════════════════════════════════════════════════
// EXCHANGE RATE NOTIFIER
// ═══════════════════════════════════════════════════════════

class ExchangeRateNotifier extends StateNotifier<AsyncValue<double>> {
  final SettingsRepository _repository;

  ExchangeRateNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRate();
  }

  Future<void> loadRate({bool showLoading = true}) async {
    if (showLoading && state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }
    try {
      final rate = await _repository.getExchangeRate();
      state = AsyncValue.data(rate);
    } catch (e, st) {
      if (state.hasValue) {
        state = AsyncValue.data(state.value!);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> setRate(double rate) async {
    try {
      await _repository.setExchangeRate(rate);
      state = AsyncValue.data(rate);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final exchangeRateNotifierProvider =
    StateNotifierProvider<ExchangeRateNotifier, AsyncValue<double>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return ExchangeRateNotifier(repository);
});

// ═══════════════════════════════════════════════════════════
// ADDITIONAL SETTINGS PROVIDERS
// ═══════════════════════════════════════════════════════════

final exchangeRateProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getExchangeRate();
});

final exchangeRateStreamProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchExchangeRate();
});
