import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/settings_model.dart';
import 'package:wholesale_shoes_invoice/core/services/firestore_service.dart';
import 'package:wholesale_shoes_invoice/core/services/logger_service.dart';

/// Repository للإعدادات يدعم العمل Online/Offline
/// يشمل سعر الصرف والعدادات وإعدادات الشركة
abstract class SettingsRepository {
  // سعر الصرف
  Future<double> getExchangeRate();
  Future<void> setExchangeRate(double rate);
  Stream<double> watchExchangeRate();
  Future<List<ExchangeRateHistory>> getExchangeRateHistory();

  // العدادات
  Future<int> getNextInvoiceNumber();
  Future<CountersModel> getCounters();

  // المزامنة
  Future<void> syncToCloud();
  Future<void> syncFromCloud();
}

class SettingsRepositoryImpl implements SettingsRepository {
  final Box _localBox;
  final FirestoreService _firestoreService;
  final bool _enableFirestore;

  static const String _exchangeRateKey = 'exchange_rate';
  static const String _exchangeRateHistoryKey = 'exchange_rate_history';
  static const String _countersKey = 'counters';

  SettingsRepositoryImpl({
    required Box localBox,
    required FirestoreService firestoreService,
    bool enableFirestore = true,
  })  : _localBox = localBox,
        _firestoreService = firestoreService,
        _enableFirestore = enableFirestore;

  // ═══════════════════════════════════════════════════════════
  // EXCHANGE RATE
  // ═══════════════════════════════════════════════════════════

  @override
  Future<double> getExchangeRate() async {
    final rate = _localBox.get(_exchangeRateKey);
    if (rate != null && rate is double) {
      return rate;
    }
    return SettingsModel.defaultRate;
  }

  @override
  Future<void> setExchangeRate(double rate) async {
    final oldRate = await getExchangeRate();

    // حفظ السعر الجديد
    await _localBox.put(_exchangeRateKey, rate);
    await _localBox.put(
        '${_exchangeRateKey}_updated', DateTime.now().toIso8601String());

    // إضافة للتاريخ
    await _addToRateHistory(oldRate, rate);

    // مزامنة مع Firestore
    if (_enableFirestore) {
      try {
        await _firestoreService.settingsCollection.doc('exchange_rate').set({
          'usdToIqd': rate,
          'previousRate': oldRate,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // إضافة للتاريخ في Firestore
        await _firestoreService.settingsCollection
            .doc('exchange_rate')
            .collection('history')
            .add({
          'rate': rate,
          'previousRate': oldRate,
          'changedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        logger.error('Error syncing exchange rate', error: e);
      }
    }
  }

  @override
  Stream<double> watchExchangeRate() {
    return _localBox.watch(key: _exchangeRateKey).map((_) {
      final rate = _localBox.get(_exchangeRateKey);
      if (rate != null && rate is double) {
        return rate;
      }
      return SettingsModel.defaultRate;
    });
  }

  @override
  Future<List<ExchangeRateHistory>> getExchangeRateHistory() async {
    final historyJson = _localBox.get(_exchangeRateHistoryKey);
    if (historyJson != null && historyJson is List) {
      return historyJson
          .map(
              (e) => ExchangeRateHistory.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<void> _addToRateHistory(double oldRate, double newRate) async {
    final history = await getExchangeRateHistory();

    history.insert(
      0,
      ExchangeRateHistory(
        rate: newRate,
        date: DateTime.now(),
      ),
    );

    // الاحتفاظ بآخر 10 تغييرات فقط
    final trimmedHistory = history.take(10).toList();

    await _localBox.put(
      _exchangeRateHistoryKey,
      trimmedHistory.map((e) => e.toJson()).toList(),
    );
  }

  Future<DateTime?> getLastUpdated() async {
    final updated = _localBox.get('${_exchangeRateKey}_updated');
    if (updated != null && updated is String) {
      return DateTime.tryParse(updated);
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  // COUNTERS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<int> getNextInvoiceNumber() async {
    if (_enableFirestore && _firestoreService.isOnline) {
      try {
        return await _firestoreService.getNextSequence('invoiceNumber');
      } catch (e) {
        // Fallback للتخزين المحلي
      }
    }

    // استخدام العداد المحلي
    final counters = await getCounters();
    final nextNumber = counters.invoiceNumber + 1;

    await _localBox.put(_countersKey, {
      ...counters.toJson(),
      'invoiceNumber': nextNumber,
      'lastUpdated': DateTime.now().toIso8601String(),
    });

    return nextNumber;
  }

  @override
  Future<CountersModel> getCounters() async {
    final data = _localBox.get(_countersKey);
    if (data != null && data is Map) {
      return CountersModel.fromJson(Map<String, dynamic>.from(data));
    }
    return CountersModel();
  }

  // ═══════════════════════════════════════════════════════════
  // SYNC OPERATIONS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> syncToCloud() async {
    if (!_enableFirestore) return;

    try {
      final rate = await getExchangeRate();
      final counters = await getCounters();
      final history = await getExchangeRateHistory();

      // سعر الصرف
      await _firestoreService.settingsCollection.doc('exchange_rate').set({
        'usdToIqd': rate,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // العدادات
      await _firestoreService.settingsCollection.doc('counters').set({
        ...counters.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // التاريخ
      final batch = _firestoreService.firestore.batch();
      for (final item in history) {
        final docRef = _firestoreService.settingsCollection
            .doc('exchange_rate')
            .collection('history')
            .doc();
        batch.set(docRef, {
          ...item.toJson(),
          'changedAt': item.date,
        });
      }
      await batch.commit();
    } catch (e) {
      logger.error('Error syncing settings to cloud', error: e);
    }
  }

  @override
  Future<void> syncFromCloud() async {
    if (!_enableFirestore) return;

    try {
      // سعر الصرف
      final rateDoc =
          await _firestoreService.settingsCollection.doc('exchange_rate').get();

      if (rateDoc.exists) {
        final data = rateDoc.data()!;
        final rate = (data['usdToIqd'] ?? SettingsModel.defaultRate).toDouble();
        await _localBox.put(_exchangeRateKey, rate);
      }

      // العدادات
      final countersDoc =
          await _firestoreService.settingsCollection.doc('counters').get();

      if (countersDoc.exists) {
        await _localBox.put(_countersKey, countersDoc.data());
      }

      // التاريخ
      final historySnapshot = await _firestoreService.settingsCollection
          .doc('exchange_rate')
          .collection('history')
          .orderBy('changedAt', descending: true)
          .limit(10)
          .get();

      final history = historySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'rate': data['rate'],
          'previousRate': data['previousRate'],
          'changedAt':
              (data['changedAt'] as Timestamp?)?.toDate().toIso8601String(),
        };
      }).toList();

      await _localBox.put(_exchangeRateHistoryKey, history);
    } catch (e) {
      logger.error('Error syncing settings from cloud', error: e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FIRESTORE STREAMS
  // ═══════════════════════════════════════════════════════════

  Stream<double> watchExchangeRateFromCloud() {
    return _firestoreService.settingsCollection
        .doc('exchange_rate')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return (snapshot.data()?['usdToIqd'] ?? SettingsModel.defaultRate)
            .toDouble();
      }
      return SettingsModel.defaultRate;
    });
  }
}
