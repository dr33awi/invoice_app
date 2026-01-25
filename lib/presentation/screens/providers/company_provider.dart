import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../data/models/company_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/unified_sync_service.dart';
import 'core_providers.dart';

/// Provider لبيانات الشركة مع دعم Firestore
final companyNotifierProvider =
    AsyncNotifierProvider<CompanyNotifier, CompanyModel>(
  () => CompanyNotifier(),
);

class CompanyNotifier extends AsyncNotifier<CompanyModel> {
  static const String _boxName = 'company_settings';
  static const String _key = 'company_info';
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<RealtimeSyncEvent>? _syncSubscription;

  @override
  Future<CompanyModel> build() async {
    _listenToRealtimeSync();
    ref.onDispose(() {
      _syncSubscription?.cancel();
    });
    return await _loadCompanyInfo();
  }

  void _listenToRealtimeSync() {
    final enableFirestore = ref.read(enableFirestoreProvider);
    if (!enableFirestore) return;

    _syncSubscription =
        ref.read(unifiedSyncServiceProvider).syncEvents.listen((event) {
      if (event.type == SyncEventType.companyInfoUpdated) {
        // تحديث البيانات عند استلام تحديث من Firestore
        _loadCompanyInfo().then((company) {
          state = AsyncData(company);
        });
      }
    });
  }

  Future<CompanyModel> _loadCompanyInfo() async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get(_key);

      if (data != null && data is Map) {
        return CompanyModel.fromJson(Map<String, dynamic>.from(data));
      }

      // إرجاع القيم الافتراضية
      return CompanyModel.defaults();
    } catch (e) {
      print('خطأ في تحميل بيانات الشركة: $e');
      return CompanyModel.defaults();
    }
  }

  Future<void> updateCompanyInfo(CompanyModel company) async {
    try {
      // حفظ محلياً
      final box = await Hive.openBox(_boxName);
      await box.put(_key, company.toJson());
      state = AsyncData(company);

      // رفع إلى Firestore
      try {
        await _firestoreService.settingsCollection
            .doc('company_info')
            .set(company.toFirestore());
        print('✅ تم رفع معلومات الشركة إلى Firestore');
      } catch (e) {
        print('⚠️ خطأ في رفع معلومات الشركة إلى Firestore: $e');
      }
    } catch (e) {
      print('خطأ في حفظ بيانات الشركة: $e');
      rethrow;
    }
  }

  Future<void> resetToDefaults() async {
    final defaults = CompanyModel.defaults();
    await updateCompanyInfo(defaults);
  }

  /// جلب معلومات الشركة من Firestore
  Future<void> syncFromFirestore() async {
    try {
      final doc =
          await _firestoreService.settingsCollection.doc('company_info').get();

      if (doc.exists && doc.data() != null) {
        final company = CompanyModel.fromFirestore(doc);

        // حفظ محلياً
        final box = await Hive.openBox(_boxName);
        await box.put(_key, company.toJson());
        state = AsyncData(company);

        print('✅ تم جلب معلومات الشركة من Firestore');
      }
    } catch (e) {
      print('⚠️ خطأ في جلب معلومات الشركة من Firestore: $e');
    }
  }
}
