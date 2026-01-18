import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/settings_model.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

abstract class SettingsRepository {
  Future<double> getExchangeRate();
  Future<void> setExchangeRate(double rate);
  Stream<double> watchExchangeRate();
}

class SettingsRepositoryImpl implements SettingsRepository {
  final Box _localBox;
  // final FirebaseFirestore _firestore;  // معلق حالياً

  static const String _exchangeRateKey = 'exchange_rate';

  SettingsRepositoryImpl({
    required Box localBox,
    // required FirebaseFirestore firestore,
  }) : _localBox = localBox;
  // _firestore = firestore;

  // ═══════════════════════════════════════════════════════════
  // LOCAL STORAGE (HIVE)
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
    await _localBox.put(_exchangeRateKey, rate);
    await _localBox.put(
        '${_exchangeRateKey}_updated', DateTime.now().toIso8601String());

    // TODO: Sync to Firestore when enabled
    // await _syncToCloud(rate);
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

  Future<DateTime?> getLastUpdated() async {
    final updated = _localBox.get('${_exchangeRateKey}_updated');
    if (updated != null && updated is String) {
      return DateTime.tryParse(updated);
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  // FIRESTORE (معلق حالياً)
  // ═══════════════════════════════════════════════════════════

  /*
  Future<void> _syncToCloud(double rate) async {
    try {
      await _firestore.collection('settings').doc('exchange_rate').set({
        'usdToSyp': rate,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error syncing exchange rate to cloud: $e');
    }
  }

  Future<void> syncFromCloud() async {
    try {
      final doc = await _firestore
          .collection('settings')
          .doc('exchange_rate')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final rate = (data['usdToSyp'] ?? SettingsModel.defaultRate).toDouble();
        await _localBox.put(_exchangeRateKey, rate);
      }
    } catch (e) {
      print('Error syncing exchange rate from cloud: $e');
    }
  }

  Stream<double> watchExchangeRateFromCloud() {
    return _firestore
        .collection('settings')
        .doc('exchange_rate')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return (snapshot.data()?['usdToSyp'] ?? SettingsModel.defaultRate)
            .toDouble();
      }
      return SettingsModel.defaultRate;
    });
  }
  */
}
