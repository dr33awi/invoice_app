import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// أداة لتحديث الفواتير القديمة في Firestore
/// تضيف حقل isActive لكل الفواتير التي لا تحتوي عليه
class InvoiceMigration {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// تشغيل عملية التحديث
  static Future<MigrationResult> migrateInvoices() async {
    int updated = 0;
    int skipped = 0;
    int errors = 0;
    final errorMessages = <String>[];

    try {
      debugPrint('🔄 بدء تحديث الفواتير القديمة...');

      // جلب كل الفواتير
      final snapshot = await _firestore.collection('invoices').get();

      debugPrint('📊 عدد الفواتير الكلي: ${snapshot.docs.length}');

      // استخدام batch للتحديث الجماعي (أسرع وأرخص)
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();

          // تحقق إذا كان isActive غير موجود
          if (!data.containsKey('isActive')) {
            // حدد isActive بناءً على status
            final status = data['status'] as String? ?? 'confirmed';
            final isActive = status != 'cancelled';

            batch.update(doc.reference, {
              'isActive': isActive,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            updated++;
            batchCount++;

            // Firebase batch يدعم حد أقصى 500 عملية
            if (batchCount >= 450) {
              await batch.commit();
              debugPrint('✅ تم تحديث $updated فاتورة...');
              batch = _firestore.batch();
              batchCount = 0;
            }
          } else {
            skipped++;
          }
        } catch (e) {
          errors++;
          errorMessages.add('خطأ في الفاتورة ${doc.id}: $e');
          debugPrint('❌ خطأ في تحديث ${doc.id}: $e');
        }
      }

      // تنفيذ آخر batch
      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('✅ اكتمل التحديث!');
      debugPrint('   - تم تحديث: $updated');
      debugPrint('   - تم تخطي: $skipped');
      debugPrint('   - أخطاء: $errors');

      return MigrationResult(
        success: true,
        updated: updated,
        skipped: skipped,
        errors: errors,
        errorMessages: errorMessages,
      );
    } catch (e) {
      debugPrint('❌ فشل التحديث: $e');
      return MigrationResult(
        success: false,
        updated: updated,
        skipped: skipped,
        errors: errors + 1,
        errorMessages: [...errorMessages, 'خطأ عام: $e'],
      );
    }
  }

  /// تحديث كل البيانات (فواتير، عملاء، منتجات، إلخ)
  static Future<Map<String, MigrationResult>> migrateAll() async {
    final results = <String, MigrationResult>{};

    // تحديث الفواتير
    results['invoices'] = await migrateInvoices();

    // تحديث العملاء
    results['customers'] = await _migrateCollection(
      collection: 'customers',
      checkField: 'isActive',
    );

    // تحديث المنتجات
    results['products'] = await _migrateCollection(
      collection: 'products',
      checkField: 'isActive',
    );

    // تحديث الفئات
    results['categories'] = await _migrateCollection(
      collection: 'categories',
      checkField: 'isActive',
    );

    // تحديث الماركات
    results['brands'] = await _migrateCollection(
      collection: 'brands',
      checkField: 'isActive',
    );

    return results;
  }

  /// تحديث مجموعة عامة
  static Future<MigrationResult> _migrateCollection({
    required String collection,
    required String checkField,
  }) async {
    int updated = 0;
    int skipped = 0;
    int errors = 0;

    try {
      final snapshot = await _firestore.collection(collection).get();
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (!data.containsKey(checkField)) {
          batch.update(doc.reference, {
            checkField: true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          updated++;
          batchCount++;

          if (batchCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        } else {
          skipped++;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('✅ $collection: تم تحديث $updated، تخطي $skipped');

      return MigrationResult(
        success: true,
        updated: updated,
        skipped: skipped,
        errors: errors,
      );
    } catch (e) {
      debugPrint('❌ خطأ في $collection: $e');
      return MigrationResult(
        success: false,
        updated: updated,
        skipped: skipped,
        errors: 1,
        errorMessages: [e.toString()],
      );
    }
  }
}

/// نتيجة عملية التحديث
class MigrationResult {
  final bool success;
  final int updated;
  final int skipped;
  final int errors;
  final List<String> errorMessages;

  MigrationResult({
    required this.success,
    required this.updated,
    required this.skipped,
    required this.errors,
    this.errorMessages = const [],
  });

  int get total => updated + skipped + errors;

  @override
  String toString() {
    return 'MigrationResult(success: $success, updated: $updated, skipped: $skipped, errors: $errors)';
  }
}
