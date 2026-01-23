import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/core/services/firestore_service.dart';
import 'package:wholesale_shoes_invoice/core/services/logger_service.dart';

/// Repository للعملاء يدعم العمل Online/Offline
/// يستخدم Hive للتخزين المحلي و Firestore للسحابة
abstract class CustomerRepository {
  // القراءة
  List<CustomerModel> getAllCustomers();
  CustomerModel? getCustomerById(String id);
  List<CustomerModel> searchCustomers(String query);
  List<CustomerModel> getCustomersByType(String type);
  List<CustomerModel> getCustomersWithDebt();
  Stream<List<CustomerModel>> watchCustomers();

  // الكتابة
  Future<void> addCustomer(CustomerModel customer);
  Future<void> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
  Future<void> hardDeleteCustomer(String id);

  // العمليات المالية
  Future<void> updateCustomerFinancials(
    String customerId, {
    required double purchaseAmount,
    required double paidAmount,
  });
  Future<void> recordPayment(String customerId, double amount);

  // التحقق
  bool customerExists(String name, {String? excludeId});

  // المزامنة
  Future<void> syncToCloud();
  Future<void> syncFromCloud();
}

class CustomerRepositoryImpl implements CustomerRepository {
  final Box<CustomerModel> _localBox;
  final FirestoreService _firestoreService;
  final bool _enableFirestore;

  CustomerRepositoryImpl({
    required Box<CustomerModel> localBox,
    required FirestoreService firestoreService,
    bool enableFirestore = true,
  })  : _localBox = localBox,
        _firestoreService = firestoreService,
        _enableFirestore = enableFirestore;

  // ═══════════════════════════════════════════════════════════
  // READ OPERATIONS
  // ═══════════════════════════════════════════════════════════

  @override
  List<CustomerModel> getAllCustomers() {
    return _localBox.values.where((c) => c.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  CustomerModel? getCustomerById(String id) {
    try {
      return _localBox.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<CustomerModel> searchCustomers(String query) {
    final lowerQuery = query.toLowerCase();
    return _localBox.values
        .where((c) =>
            c.isActive &&
            (c.name.toLowerCase().contains(lowerQuery) ||
                (c.phone?.contains(query) ?? false) ||
                (c.secondaryPhone?.contains(query) ?? false) ||
                (c.city?.toLowerCase().contains(lowerQuery) ?? false)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  List<CustomerModel> getCustomersByType(String type) {
    return _localBox.values.where((c) => c.isActive && c.type == type).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  List<CustomerModel> getCustomersWithDebt() {
    return _localBox.values.where((c) => c.isActive && c.balance > 0).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance)); // الأعلى ديناً أولاً
  }

  @override
  Stream<List<CustomerModel>> watchCustomers() {
    return _localBox.watch().map((_) => getAllCustomers());
  }

  // ═══════════════════════════════════════════════════════════
  // WRITE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> addCustomer(CustomerModel customer) async {
    // إنشاء كلمات البحث للعميل
    final customerWithSearch = customer.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // حفظ محلياً
    await _localBox.put(customer.id, customerWithSearch);

    // مزامنة مع Firestore
    if (_enableFirestore) {
      await _syncCustomerToCloud(customerWithSearch);
    }
  }

  @override
  Future<void> updateCustomer(CustomerModel customer) async {
    final updatedCustomer = customer.copyWith(
      updatedAt: DateTime.now(),
    );

    await _localBox.put(customer.id, updatedCustomer);

    if (_enableFirestore) {
      await _syncCustomerToCloud(updatedCustomer);
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    // حذف نهائي من Hive
    await _localBox.delete(id);

    // حذف نهائي من Firestore
    if (_enableFirestore) {
      try {
        await _firestoreService.customersCollection.doc(id).delete();
      } catch (e) {
        logger.error('Error deleting customer from Firestore', error: e);
      }
    }
  }

  @override
  Future<void> hardDeleteCustomer(String id) async {
    await _localBox.delete(id);

    if (_enableFirestore) {
      await _firestoreService.hardDeleteDocument(
        collection: _firestoreService.customersCollection,
        docId: id,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FINANCIAL OPERATIONS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> updateCustomerFinancials(
    String customerId, {
    required double purchaseAmount,
    required double paidAmount,
  }) async {
    final customer = getCustomerById(customerId);
    if (customer == null) return;

    final updatedCustomer = customer.updateFinancials(
      invoiceTotal: purchaseAmount,
      paidAmount: paidAmount,
    );

    await _localBox.put(customerId, updatedCustomer);

    if (_enableFirestore) {
      // استخدام Transaction لضمان تحديث صحيح
      try {
        await _firestoreService.firestore.runTransaction((transaction) async {
          final docRef = _firestoreService.customersCollection.doc(customerId);
          final snapshot = await transaction.get(docRef);

          if (snapshot.exists) {
            transaction.update(docRef, {
              'totalPurchases': FieldValue.increment(purchaseAmount),
              'totalPaid': FieldValue.increment(paidAmount),
              'balance': FieldValue.increment(purchaseAmount - paidAmount),
              'lastPurchaseDate': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        });
      } catch (e) {
        // Sync later
        logger.error('Error updating customer financials', error: e);
      }
    }
  }

  @override
  Future<void> recordPayment(String customerId, double amount) async {
    final customer = getCustomerById(customerId);
    if (customer == null) return;

    final updatedCustomer = customer.recordPayment(amount);
    await _localBox.put(customerId, updatedCustomer);

    if (_enableFirestore) {
      try {
        await _firestoreService.customersCollection.doc(customerId).update({
          'totalPaid': FieldValue.increment(amount),
          'balance': FieldValue.increment(-amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        logger.error('Error recording payment', error: e);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // VALIDATION
  // ═══════════════════════════════════════════════════════════

  @override
  bool customerExists(String name, {String? excludeId}) {
    return _localBox.values.any((c) =>
        c.name.toLowerCase() == name.toLowerCase() &&
        c.id != excludeId &&
        c.isActive);
  }

  // ═══════════════════════════════════════════════════════════
  // SYNC OPERATIONS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> syncToCloud() async {
    if (!_enableFirestore) return;

    final customers = _localBox.values.toList();
    final batch = _firestoreService.firestore.batch();

    for (final customer in customers) {
      final docRef = _firestoreService.customersCollection.doc(customer.id);
      final data = customer.toFirestore();

      // إضافة كلمات البحث
      data['nameSearch'] = _generateSearchTerms(customer.name);

      batch.set(docRef, data, SetOptions(merge: true));
    }

    await batch.commit();
  }

  @override
  Future<void> syncFromCloud() async {
    if (!_enableFirestore) return;

    try {
      final snapshot = await _firestoreService.getActiveDocuments(
        collection: _firestoreService.customersCollection,
        orderBy: 'name',
      );

      for (final doc in snapshot.docs) {
        final customer = CustomerModel.fromFirestore(doc);
        await _localBox.put(customer.id, customer);
      }
    } catch (e) {
      logger.error('Error syncing customers from cloud', error: e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════

  Future<void> _syncCustomerToCloud(CustomerModel customer) async {
    try {
      final data = customer.toFirestore();
      data['nameSearch'] = _generateSearchTerms(customer.name);

      await _firestoreService.customersCollection
          .doc(customer.id)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      logger.error('Error syncing customer to cloud', error: e);
    }
  }

  /// توليد كلمات البحث للعميل
  List<String> _generateSearchTerms(String name) {
    final terms = <String>[];
    final lowerName = name.toLowerCase();

    // إضافة كل بداية ممكنة
    for (int i = 1; i <= lowerName.length; i++) {
      terms.add(lowerName.substring(0, i));
    }

    // إضافة كل كلمة
    final words = lowerName.split(' ');
    for (final word in words) {
      if (word.isNotEmpty) {
        for (int i = 1; i <= word.length; i++) {
          terms.add(word.substring(0, i));
        }
      }
    }

    return terms.toSet().toList(); // إزالة التكرارات
  }
}
