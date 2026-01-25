import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';
import 'package:wholesale_shoes_invoice/data/models/category_model.dart';
import 'package:wholesale_shoes_invoice/data/models/brand_model.dart';
import 'package:wholesale_shoes_invoice/data/models/company_model.dart';
import 'package:wholesale_shoes_invoice/data/repositories/customer_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/invoice_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/product_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/settings_repository_new.dart';
import 'package:wholesale_shoes_invoice/core/services/firestore_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// UNIFIED SYNC SERVICE
// ═══════════════════════════════════════════════════════════════════════════
//
// خدمة مزامنة موحدة تجمع كل منطق المزامنة في مكان واحد:
// - InitialSync: المزامنة الأولية عند فتح التطبيق
// - RealtimeSync: الاستماع للتغييرات في الوقت الحقيقي
// - CustomerSync: أحداث مزامنة العملاء
// - SyncService: المزامنة اليدوية مع السحابة
//
// Architecture:
// - Facade Pattern: واجهة موحدة للخدمات الداخلية
// - Stream-based reactive updates
// - Offline-first behavior
// - Conflict resolution via timestamp comparison
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════
// ENUMS & MODELS
// ═══════════════════════════════════════════════════════════

/// حالة المزامنة
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

/// أنواع أحداث المزامنة في الوقت الحقيقي
enum SyncEventType {
  started,
  stopped,
  invoicesUpdated,
  customersUpdated,
  productsUpdated,
  categoriesUpdated,
  brandsUpdated,
  companyInfoUpdated,
  error,
}

/// أحداث تحديث العملاء
enum CustomerSyncEventType {
  created,
  updated,
  deleted,
  bulkUpdated,
}

/// نتيجة المزامنة
class SyncResult {
  final bool success;
  final String? error;
  final DateTime timestamp;
  final Map<String, int> syncedCounts;

  SyncResult({
    required this.success,
    this.error,
    required this.timestamp,
    this.syncedCounts = const {},
  });
}

/// نتيجة المزامنة الأولية
class InitialSyncResult {
  final bool success;
  final String message;
  final Map<String, int> syncedCounts;
  final List<String> errors;
  final DateTime timestamp;

  InitialSyncResult({
    required this.success,
    required this.message,
    this.syncedCounts = const {},
    this.errors = const [],
  }) : timestamp = DateTime.now();

  int get totalSynced => syncedCounts.values.fold(0, (a, b) => a + b);
}

/// حدث المزامنة في الوقت الحقيقي
class RealtimeSyncEvent {
  final SyncEventType type;
  final String message;
  final String? error;
  final Map<String, dynamic>? details;
  final DateTime timestamp;

  RealtimeSyncEvent({
    required this.type,
    required this.message,
    this.error,
    this.details,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'RealtimeSyncEvent(type: $type, message: $message, details: $details)';
  }
}

/// حدث تحديث عميل
class CustomerSyncEvent {
  final CustomerSyncEventType type;
  final CustomerModel? customer;
  final List<CustomerModel>? customers;
  final DateTime timestamp;

  CustomerSyncEvent({
    required this.type,
    this.customer,
    this.customers,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory CustomerSyncEvent.created(CustomerModel customer) {
    return CustomerSyncEvent(
      type: CustomerSyncEventType.created,
      customer: customer,
    );
  }

  factory CustomerSyncEvent.updated(CustomerModel customer) {
    return CustomerSyncEvent(
      type: CustomerSyncEventType.updated,
      customer: customer,
    );
  }

  factory CustomerSyncEvent.deleted(String customerId) {
    return CustomerSyncEvent(
      type: CustomerSyncEventType.deleted,
      customer: CustomerModel(id: customerId, name: ''),
    );
  }

  factory CustomerSyncEvent.bulkUpdated(List<CustomerModel> customers) {
    return CustomerSyncEvent(
      type: CustomerSyncEventType.bulkUpdated,
      customers: customers,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// INTERNAL: INITIAL SYNC MODULE
// ═══════════════════════════════════════════════════════════

/// وحدة المزامنة الأولية - تجلب كل البيانات من Firestore عند فتح التطبيق
class _InitialSyncModule {
  final FirestoreService _firestoreService;
  final Box<InvoiceModel> _invoicesBox;
  final Box<CustomerModel> _customersBox;
  final Box<ProductModel> _productsBox;
  final Box<CategoryModel> _categoriesBox;
  final Box<BrandModel> _brandsBox;
  final Box _settingsBox;

  bool _isSyncing = false;
  bool _hasCompletedInitialSync = false;

  _InitialSyncModule({
    required FirestoreService firestoreService,
    required Box<InvoiceModel> invoicesBox,
    required Box<CustomerModel> customersBox,
    required Box<ProductModel> productsBox,
    required Box<CategoryModel> categoriesBox,
    required Box<BrandModel> brandsBox,
    required Box settingsBox,
  })  : _firestoreService = firestoreService,
        _invoicesBox = invoicesBox,
        _customersBox = customersBox,
        _productsBox = productsBox,
        _categoriesBox = categoriesBox,
        _brandsBox = brandsBox,
        _settingsBox = settingsBox;

  bool get isSyncing => _isSyncing;
  bool get hasCompletedInitialSync => _hasCompletedInitialSync;

  /// تنفيذ المزامنة الأولية - جلب كل البيانات من Firestore
  Future<InitialSyncResult> performInitialSync() async {
    if (_isSyncing) {
      return InitialSyncResult(
        success: false,
        message: 'المزامنة جارية بالفعل',
      );
    }

    _isSyncing = true;
    debugPrint('🔄 InitialSync: Starting initial sync from Firestore...');

    final counts = <String, int>{};
    final errors = <String>[];

    try {
      // 1. جلب معلومات الشركة
      await _syncCompanyInfo();
      counts['company'] = 1;

      // 2. جلب الفئات
      final categoriesCount = await _syncCategories();
      counts['categories'] = categoriesCount;

      // 3. جلب الماركات
      final brandsCount = await _syncBrands();
      counts['brands'] = brandsCount;

      // 4. جلب العملاء
      final customersCount = await _syncCustomers();
      counts['customers'] = customersCount;

      // 5. جلب المنتجات
      final productsCount = await _syncProducts();
      counts['products'] = productsCount;

      // 6. جلب الفواتير
      final invoicesCount = await _syncInvoices();
      counts['invoices'] = invoicesCount;

      _hasCompletedInitialSync = true;
      _isSyncing = false;

      debugPrint('✅ InitialSync: Completed successfully');
      debugPrint('   - Categories: ${counts['categories']}');
      debugPrint('   - Brands: ${counts['brands']}');
      debugPrint('   - Customers: ${counts['customers']}');
      debugPrint('   - Products: ${counts['products']}');
      debugPrint('   - Invoices: ${counts['invoices']}');

      return InitialSyncResult(
        success: true,
        message: 'تمت المزامنة بنجاح',
        syncedCounts: counts,
      );
    } catch (e) {
      _isSyncing = false;
      debugPrint('❌ InitialSync: Failed - $e');
      errors.add(e.toString());

      return InitialSyncResult(
        success: false,
        message: 'فشلت المزامنة: $e',
        syncedCounts: counts,
        errors: errors,
      );
    }
  }

  /// جلب معلومات الشركة من Firestore
  Future<void> _syncCompanyInfo() async {
    try {
      final doc =
          await _firestoreService.settingsCollection.doc('company_info').get();

      if (doc.exists && doc.data() != null) {
        final company = CompanyModel.fromFirestore(doc);
        await _settingsBox.put('company_info', company.toJson());
        debugPrint('🔄 InitialSync: Company info synced');
      }
    } catch (e) {
      debugPrint('⚠️ InitialSync: Error syncing company info: $e');
    }
  }

  /// جلب الفئات من Firestore
  Future<int> _syncCategories() async {
    try {
      final snapshot = await _firestoreService.categoriesCollection
          .where('isActive', isEqualTo: true)
          .get();

      int count = 0;
      for (final doc in snapshot.docs) {
        try {
          final category = CategoryModel.fromFirestore(doc);

          final localCategory = _categoriesBox.get(category.id);
          if (localCategory == null ||
              _isNewer(category.updatedAt, localCategory.updatedAt)) {
            await _categoriesBox.put(category.id, category);
            count++;
          }
        } catch (e) {
          debugPrint('⚠️ InitialSync: Error parsing category ${doc.id}: $e');
        }
      }

      debugPrint('🔄 InitialSync: Synced $count categories');
      return count;
    } catch (e) {
      debugPrint('⚠️ InitialSync: Error syncing categories: $e');
      return 0;
    }
  }

  /// جلب الماركات من Firestore
  Future<int> _syncBrands() async {
    try {
      final snapshot = await _firestoreService.brandsCollection
          .where('isActive', isEqualTo: true)
          .get();

      int count = 0;
      for (final doc in snapshot.docs) {
        try {
          final brand = BrandModel.fromFirestore(doc);

          final localBrand = _brandsBox.get(brand.id);
          if (localBrand == null ||
              _isNewer(brand.updatedAt, localBrand.updatedAt)) {
            await _brandsBox.put(brand.id, brand);
            count++;
          }
        } catch (e) {
          debugPrint('⚠️ InitialSync: Error parsing brand ${doc.id}: $e');
        }
      }

      debugPrint('🔄 InitialSync: Synced $count brands');
      return count;
    } catch (e) {
      debugPrint('⚠️ InitialSync: Error syncing brands: $e');
      return 0;
    }
  }

  /// جلب العملاء من Firestore
  Future<int> _syncCustomers() async {
    try {
      final snapshot = await _firestoreService.customersCollection
          .where('isActive', isEqualTo: true)
          .get();

      int count = 0;
      for (final doc in snapshot.docs) {
        try {
          final customer = CustomerModel.fromFirestore(doc);

          // التحقق من أن البيانات أحدث
          final localCustomer = _customersBox.get(customer.id);
          if (localCustomer == null ||
              _isNewer(customer.updatedAt, localCustomer.updatedAt)) {
            await _customersBox.put(customer.id, customer);
            count++;
          }
        } catch (e) {
          debugPrint('⚠️ InitialSync: Error parsing customer ${doc.id}: $e');
        }
      }

      debugPrint('🔄 InitialSync: Synced $count customers');
      return count;
    } catch (e) {
      debugPrint('⚠️ InitialSync: Error syncing customers: $e');
      return 0;
    }
  }

  /// جلب المنتجات من Firestore
  Future<int> _syncProducts() async {
    try {
      final snapshot = await _firestoreService.productsCollection
          .where('isActive', isEqualTo: true)
          .get();

      int count = 0;
      for (final doc in snapshot.docs) {
        try {
          final product = ProductModel.fromFirestore(doc);

          final localProduct = _productsBox.get(product.id);
          if (localProduct == null ||
              _isNewer(product.updatedAt, localProduct.updatedAt)) {
            await _productsBox.put(product.id, product);
            count++;
          }
        } catch (e) {
          debugPrint('⚠️ InitialSync: Error parsing product ${doc.id}: $e');
        }
      }

      debugPrint('🔄 InitialSync: Synced $count products');
      return count;
    } catch (e) {
      debugPrint('⚠️ InitialSync: Error syncing products: $e');
      return 0;
    }
  }

  /// جلب الفواتير من Firestore
  Future<int> _syncInvoices() async {
    try {
      // جلب كل الفواتير (بدون فلتر isActive) لضمان جلب الفواتير القديمة
      // التي لم تُحدّث بعد لتحتوي على حقل isActive
      final snapshot = await _firestoreService.invoicesCollection
          .orderBy('createdAt', descending: true)
          .limit(500) // جلب آخر 500 فاتورة
          .get();

      int count = 0;
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          // تجاهل الفواتير الملغاة
          if (data['status'] == 'cancelled') continue;

          final invoice = InvoiceModel.fromFirestore(doc);

          final localInvoice = _invoicesBox.get(invoice.id);
          if (localInvoice == null ||
              _isNewer(invoice.updatedAt, localInvoice.updatedAt)) {
            await _invoicesBox.put(invoice.id, invoice);
            count++;
          }
        } catch (e) {
          debugPrint('⚠️ InitialSync: Error parsing invoice ${doc.id}: $e');
        }
      }

      debugPrint('🔄 InitialSync: Synced $count invoices');
      return count;
    } catch (e) {
      debugPrint('⚠️ InitialSync: Error syncing invoices: $e');
      return 0;
    }
  }

  /// التحقق من أن التاريخ الجديد أحدث
  bool _isNewer(DateTime? newDate, DateTime? oldDate) {
    if (newDate == null) return false;
    if (oldDate == null) return true;
    return newDate.isAfter(oldDate);
  }

  /// جلب كل الفواتير (بدون حد)
  Future<int> syncAllInvoices() async {
    try {
      // جلب كل الفواتير بدون فلتر isActive لضمان التوافقية
      final snapshot = await _firestoreService.invoicesCollection.get();

      int count = 0;
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          // تجاهل الفواتير الملغاة
          if (data['status'] == 'cancelled') continue;

          final invoice = InvoiceModel.fromFirestore(doc);
          await _invoicesBox.put(invoice.id, invoice);
          count++;
        } catch (e) {
          debugPrint('⚠️ Error parsing invoice ${doc.id}: $e');
        }
      }

      return count;
    } catch (e) {
      debugPrint('⚠️ Error syncing all invoices: $e');
      return 0;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// INTERNAL: REALTIME SYNC MODULE
// ═══════════════════════════════════════════════════════════

/// وحدة المزامنة في الوقت الحقيقي
/// تستمع للتغييرات من Firestore وتحدث البيانات المحلية فوراً
class _RealtimeSyncModule {
  final FirestoreService _firestoreService;
  final Box<InvoiceModel> _invoicesBox;
  final Box<CustomerModel> _customersBox;
  final Box<ProductModel> _productsBox;
  final Box<CategoryModel> _categoriesBox;
  final Box<BrandModel> _brandsBox;
  final Box _settingsBox;

  // Subscriptions
  StreamSubscription<QuerySnapshot>? _invoicesSubscription;
  StreamSubscription<QuerySnapshot>? _customersSubscription;
  StreamSubscription<QuerySnapshot>? _productsSubscription;
  StreamSubscription<QuerySnapshot>? _categoriesSubscription;
  StreamSubscription<QuerySnapshot>? _brandsSubscription;
  StreamSubscription<DocumentSnapshot>? _companyInfoSubscription;

  // Controllers for local streams
  final _invoicesController = StreamController<List<InvoiceModel>>.broadcast();
  final _customersController =
      StreamController<List<CustomerModel>>.broadcast();
  final _productsController = StreamController<List<ProductModel>>.broadcast();
  final _categoriesController =
      StreamController<List<CategoryModel>>.broadcast();
  final _brandsController = StreamController<List<BrandModel>>.broadcast();
  final _companyInfoController = StreamController<CompanyModel>.broadcast();

  // Status
  bool _isListening = false;
  final _syncEventsController = StreamController<RealtimeSyncEvent>.broadcast();

  _RealtimeSyncModule({
    required FirestoreService firestoreService,
    required Box<InvoiceModel> invoicesBox,
    required Box<CustomerModel> customersBox,
    required Box<ProductModel> productsBox,
    required Box<CategoryModel> categoriesBox,
    required Box<BrandModel> brandsBox,
    required Box settingsBox,
  })  : _firestoreService = firestoreService,
        _invoicesBox = invoicesBox,
        _customersBox = customersBox,
        _productsBox = productsBox,
        _categoriesBox = categoriesBox,
        _brandsBox = brandsBox,
        _settingsBox = settingsBox;

  // ═══════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════

  bool get isListening => _isListening;
  Stream<RealtimeSyncEvent> get syncEvents => _syncEventsController.stream;
  Stream<List<InvoiceModel>> get invoicesStream => _invoicesController.stream;
  Stream<List<CustomerModel>> get customersStream =>
      _customersController.stream;
  Stream<List<ProductModel>> get productsStream => _productsController.stream;
  Stream<List<CategoryModel>> get categoriesStream =>
      _categoriesController.stream;
  Stream<List<BrandModel>> get brandsStream => _brandsController.stream;
  Stream<CompanyModel> get companyInfoStream => _companyInfoController.stream;

  // ═══════════════════════════════════════════════════════════
  // START/STOP LISTENING
  // ═══════════════════════════════════════════════════════════

  /// بدء الاستماع لكل التغييرات
  void startListening() {
    if (_isListening) return;
    _isListening = true;

    debugPrint('🔄 RealtimeSync: Starting listeners...');

    _listenToInvoices();
    _listenToCustomers();
    _listenToProducts();
    _listenToCategories();
    _listenToBrands();
    _listenToCompanyInfo();

    _emitEvent(RealtimeSyncEvent(
      type: SyncEventType.started,
      message: 'بدأ الاستماع للتغييرات',
    ));
  }

  /// إيقاف الاستماع
  void stopListening() {
    _isListening = false;

    _invoicesSubscription?.cancel();
    _customersSubscription?.cancel();
    _productsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _brandsSubscription?.cancel();
    _companyInfoSubscription?.cancel();

    debugPrint('🔄 RealtimeSync: Stopped listeners');

    _emitEvent(RealtimeSyncEvent(
      type: SyncEventType.stopped,
      message: 'توقف الاستماع للتغييرات',
    ));
  }

  /// تحرير الموارد
  void dispose() {
    stopListening();
    _invoicesController.close();
    _customersController.close();
    _productsController.close();
    _categoriesController.close();
    _brandsController.close();
    _companyInfoController.close();
    _syncEventsController.close();
  }

  // ═══════════════════════════════════════════════════════════
  // INVOICES LISTENER
  // ═══════════════════════════════════════════════════════════

  void _listenToInvoices() {
    // الاستماع لكل الفواتير وفلترة الملغاة في الكود
    // لتجنب مشاكل الـ composite index ولضمان جلب الفواتير القديمة
    _invoicesSubscription = _firestoreService.invoicesCollection
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .listen(
      (snapshot) {
        _handleInvoicesSnapshot(snapshot);
      },
      onError: (error) {
        debugPrint('🔄 RealtimeSync: Invoices error: $error');
        _emitEvent(RealtimeSyncEvent(
          type: SyncEventType.error,
          message: 'خطأ في مزامنة الفواتير',
          error: error.toString(),
        ));
      },
    );
  }

  void _handleInvoicesSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    int addedCount = 0;
    int modifiedCount = 0;
    int removedCount = 0;

    for (final change in snapshot.docChanges) {
      final doc = change.doc;
      final data = doc.data();

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          try {
            // تجاهل الفواتير الملغاة
            if (data?['status'] == 'cancelled') {
              // إذا تم إلغاء الفاتورة، احذفها محلياً
              if (_invoicesBox.containsKey(doc.id)) {
                _invoicesBox.delete(doc.id);
                removedCount++;
              }
              continue;
            }

            final invoice = InvoiceModel.fromFirestore(doc);

            // التحقق من أن البيانات جديدة
            final localInvoice = _invoicesBox.get(invoice.id);
            if (localInvoice == null ||
                (invoice.updatedAt
                        ?.isAfter(localInvoice.updatedAt ?? DateTime(2000)) ??
                    false)) {
              _invoicesBox.put(invoice.id, invoice);

              if (change.type == DocumentChangeType.added) {
                addedCount++;
              } else {
                modifiedCount++;
              }
            }
          } catch (e) {
            debugPrint('🔄 RealtimeSync: Error parsing invoice: $e');
          }
          break;

        case DocumentChangeType.removed:
          _invoicesBox.delete(doc.id);
          removedCount++;
          break;
      }
    }

    // إشعار بالتغييرات
    if (addedCount > 0 || modifiedCount > 0 || removedCount > 0) {
      final invoices = _invoicesBox.values
          .where((i) => i.status != InvoiceModel.invoiceCancelled)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      _invoicesController.add(invoices);

      _emitEvent(RealtimeSyncEvent(
        type: SyncEventType.invoicesUpdated,
        message: 'تم تحديث الفواتير',
        details: {
          'added': addedCount,
          'modified': modifiedCount,
          'removed': removedCount,
        },
      ));

      debugPrint(
          '🔄 RealtimeSync: Invoices updated - Added: $addedCount, Modified: $modifiedCount, Removed: $removedCount');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CUSTOMERS LISTENER
  // ═══════════════════════════════════════════════════════════

  void _listenToCustomers() {
    _customersSubscription = _firestoreService.customersCollection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .listen(
      (snapshot) {
        _handleCustomersSnapshot(snapshot);
      },
      onError: (error) {
        debugPrint('🔄 RealtimeSync: Customers error: $error');
        _emitEvent(RealtimeSyncEvent(
          type: SyncEventType.error,
          message: 'خطأ في مزامنة العملاء',
          error: error.toString(),
        ));
      },
    );
  }

  void _handleCustomersSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    int addedCount = 0;
    int modifiedCount = 0;
    int removedCount = 0;

    for (final change in snapshot.docChanges) {
      final doc = change.doc;

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          try {
            final customer = CustomerModel.fromFirestore(doc);

            final localCustomer = _customersBox.get(customer.id);
            if (localCustomer == null ||
                (customer.updatedAt
                        ?.isAfter(localCustomer.updatedAt ?? DateTime(2000)) ??
                    false)) {
              _customersBox.put(customer.id, customer);

              if (change.type == DocumentChangeType.added) {
                addedCount++;
              } else {
                modifiedCount++;
              }
            }
          } catch (e) {
            debugPrint('🔄 RealtimeSync: Error parsing customer: $e');
          }
          break;

        case DocumentChangeType.removed:
          _customersBox.delete(doc.id);
          removedCount++;
          break;
      }
    }

    if (addedCount > 0 || modifiedCount > 0 || removedCount > 0) {
      final customers = _customersBox.values.where((c) => c.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      _customersController.add(customers);

      _emitEvent(RealtimeSyncEvent(
        type: SyncEventType.customersUpdated,
        message: 'تم تحديث العملاء',
        details: {
          'added': addedCount,
          'modified': modifiedCount,
          'removed': removedCount,
        },
      ));

      debugPrint(
          '🔄 RealtimeSync: Customers updated - Added: $addedCount, Modified: $modifiedCount, Removed: $removedCount');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PRODUCTS LISTENER
  // ═══════════════════════════════════════════════════════════

  void _listenToProducts() {
    _productsSubscription = _firestoreService.productsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _handleProductsSnapshot(snapshot);
      },
      onError: (error) {
        debugPrint('🔄 RealtimeSync: Products error: $error');
        _emitEvent(RealtimeSyncEvent(
          type: SyncEventType.error,
          message: 'خطأ في مزامنة المنتجات',
          error: error.toString(),
        ));
      },
    );
  }

  void _handleProductsSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    int addedCount = 0;
    int modifiedCount = 0;
    int removedCount = 0;

    for (final change in snapshot.docChanges) {
      final doc = change.doc;

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          try {
            final product = ProductModel.fromFirestore(doc);

            final localProduct = _productsBox.get(product.id);
            if (localProduct == null ||
                (product.updatedAt
                        ?.isAfter(localProduct.updatedAt ?? DateTime(2000)) ??
                    false)) {
              _productsBox.put(product.id, product);

              if (change.type == DocumentChangeType.added) {
                addedCount++;
              } else {
                modifiedCount++;
              }
            }
          } catch (e) {
            debugPrint('🔄 RealtimeSync: Error parsing product: $e');
          }
          break;

        case DocumentChangeType.removed:
          _productsBox.delete(doc.id);
          removedCount++;
          break;
      }
    }

    if (addedCount > 0 || modifiedCount > 0 || removedCount > 0) {
      final products = _productsBox.values.where((p) => p.isActive).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));

      _productsController.add(products);

      _emitEvent(RealtimeSyncEvent(
        type: SyncEventType.productsUpdated,
        message: 'تم تحديث المنتجات',
        details: {
          'added': addedCount,
          'modified': modifiedCount,
          'removed': removedCount,
        },
      ));

      debugPrint(
          '🔄 RealtimeSync: Products updated - Added: $addedCount, Modified: $modifiedCount, Removed: $removedCount');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CATEGORIES LISTENER
  // ═══════════════════════════════════════════════════════════

  void _listenToCategories() {
    _categoriesSubscription = _firestoreService.categoriesCollection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .listen(
      (snapshot) {
        _handleCategoriesSnapshot(snapshot);
      },
      onError: (error) {
        debugPrint('🔄 RealtimeSync: Categories error: $error');
        _emitEvent(RealtimeSyncEvent(
          type: SyncEventType.error,
          message: 'خطأ في مزامنة الفئات',
          error: error.toString(),
        ));
      },
    );
  }

  void _handleCategoriesSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    int addedCount = 0;
    int modifiedCount = 0;
    int removedCount = 0;

    for (final change in snapshot.docChanges) {
      final doc = change.doc;

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          try {
            final category = CategoryModel.fromFirestore(doc);

            final localCategory = _categoriesBox.get(category.id);
            if (localCategory == null ||
                (category.updatedAt
                        ?.isAfter(localCategory.updatedAt ?? DateTime(2000)) ??
                    false)) {
              _categoriesBox.put(category.id, category);

              if (change.type == DocumentChangeType.added) {
                addedCount++;
              } else {
                modifiedCount++;
              }
            }
          } catch (e) {
            debugPrint('🔄 RealtimeSync: Error parsing category: $e');
          }
          break;

        case DocumentChangeType.removed:
          _categoriesBox.delete(doc.id);
          removedCount++;
          break;
      }
    }

    if (addedCount > 0 || modifiedCount > 0 || removedCount > 0) {
      final categories = _categoriesBox.values.where((c) => c.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      _categoriesController.add(categories);

      _emitEvent(RealtimeSyncEvent(
        type: SyncEventType.categoriesUpdated,
        message: 'تم تحديث الفئات',
        details: {
          'added': addedCount,
          'modified': modifiedCount,
          'removed': removedCount,
        },
      ));

      debugPrint(
          '🔄 RealtimeSync: Categories updated - Added: $addedCount, Modified: $modifiedCount, Removed: $removedCount');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BRANDS LISTENER
  // ═══════════════════════════════════════════════════════════

  void _listenToBrands() {
    _brandsSubscription = _firestoreService.brandsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .listen(
      (snapshot) {
        _handleBrandsSnapshot(snapshot);
      },
      onError: (error) {
        debugPrint('🔄 RealtimeSync: Brands error: $error');
        _emitEvent(RealtimeSyncEvent(
          type: SyncEventType.error,
          message: 'خطأ في مزامنة الماركات',
          error: error.toString(),
        ));
      },
    );
  }

  void _handleBrandsSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    int addedCount = 0;
    int modifiedCount = 0;
    int removedCount = 0;

    for (final change in snapshot.docChanges) {
      final doc = change.doc;

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          try {
            final brand = BrandModel.fromFirestore(doc);

            final localBrand = _brandsBox.get(brand.id);
            if (localBrand == null ||
                (brand.updatedAt
                        ?.isAfter(localBrand.updatedAt ?? DateTime(2000)) ??
                    false)) {
              _brandsBox.put(brand.id, brand);

              if (change.type == DocumentChangeType.added) {
                addedCount++;
              } else {
                modifiedCount++;
              }
            }
          } catch (e) {
            debugPrint('🔄 RealtimeSync: Error parsing brand: $e');
          }
          break;

        case DocumentChangeType.removed:
          _brandsBox.delete(doc.id);
          removedCount++;
          break;
      }
    }

    if (addedCount > 0 || modifiedCount > 0 || removedCount > 0) {
      final brands = _brandsBox.values.where((b) => b.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      _brandsController.add(brands);

      _emitEvent(RealtimeSyncEvent(
        type: SyncEventType.brandsUpdated,
        message: 'تم تحديث الماركات',
        details: {
          'added': addedCount,
          'modified': modifiedCount,
          'removed': removedCount,
        },
      ));

      debugPrint(
          '🔄 RealtimeSync: Brands updated - Added: $addedCount, Modified: $modifiedCount, Removed: $removedCount');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // COMPANY INFO LISTENER
  // ═══════════════════════════════════════════════════════════

  void _listenToCompanyInfo() {
    _companyInfoSubscription = _firestoreService.settingsCollection
        .doc('company_info')
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          try {
            final company = CompanyModel.fromFirestore(snapshot);

            // حفظ محلياً في settingsBox
            _settingsBox.put('company_info', company.toJson());
            _companyInfoController.add(company);

            _emitEvent(RealtimeSyncEvent(
              type: SyncEventType.companyInfoUpdated,
              message: 'تم تحديث معلومات الشركة',
            ));

            debugPrint('🔄 RealtimeSync: Company info updated');
          } catch (e) {
            debugPrint('🔄 RealtimeSync: Error parsing company info: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('🔄 RealtimeSync: Company info error: $error');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  void _emitEvent(RealtimeSyncEvent event) {
    if (!_syncEventsController.isClosed) {
      _syncEventsController.add(event);
    }
  }
}

// ═══════════════════════════════════════════════════════════
// INTERNAL: CUSTOMER SYNC MODULE
// ═══════════════════════════════════════════════════════════

/// وحدة مزامنة العملاء - أحداث تحديث العملاء
class _CustomerSyncModule {
  /// Stream Controller للأحداث
  final _eventController = StreamController<CustomerSyncEvent>.broadcast();

  /// Stream للأحداث
  Stream<CustomerSyncEvent> get events => _eventController.stream;

  /// إرسال حدث تحديث
  void emitEvent(CustomerSyncEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// إرسال حدث إنشاء عميل
  void customerCreated(CustomerModel customer) {
    emitEvent(CustomerSyncEvent.created(customer));
  }

  /// إرسال حدث تحديث عميل
  void customerUpdated(CustomerModel customer) {
    emitEvent(CustomerSyncEvent.updated(customer));
  }

  /// إرسال حدث حذف عميل
  void customerDeleted(String customerId) {
    emitEvent(CustomerSyncEvent.deleted(customerId));
  }

  /// إرسال حدث تحديث جماعي
  void customersBulkUpdated(List<CustomerModel> customers) {
    emitEvent(CustomerSyncEvent.bulkUpdated(customers));
  }

  /// تنظيف الموارد
  void dispose() {
    _eventController.close();
  }
}

// ═══════════════════════════════════════════════════════════
// INTERNAL: MANUAL SYNC MODULE
// ═══════════════════════════════════════════════════════════

/// وحدة المزامنة اليدوية بين Hive و Firestore
class _ManualSyncModule {
  final InvoiceRepository _invoiceRepository;
  final CustomerRepository _customerRepository;
  final ProductRepository _productRepository;
  final SettingsRepository _settingsRepository;
  final FirestoreService _firestoreService;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;

  // Callbacks
  Function(SyncStatus)? onStatusChanged;
  Function(SyncResult)? onSyncComplete;

  _ManualSyncModule({
    required InvoiceRepository invoiceRepository,
    required CustomerRepository customerRepository,
    required ProductRepository productRepository,
    required SettingsRepository settingsRepository,
    required FirestoreService firestoreService,
  })  : _invoiceRepository = invoiceRepository,
        _customerRepository = customerRepository,
        _productRepository = productRepository,
        _settingsRepository = settingsRepository,
        _firestoreService = firestoreService;

  // ═══════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════

  SyncStatus get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;
  bool get isOnline => _firestoreService.isOnline;

  // ═══════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════

  /// تهيئة خدمة المزامنة
  Future<void> initialize(Function() onReconnect) async {
    await _firestoreService.initialize();

    // مراقبة حالة الاتصال
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);

      if (isOnline && _status == SyncStatus.offline) {
        // عند العودة للاتصال، نبدأ المزامنة
        onReconnect();
      }

      if (!isOnline) {
        _updateStatus(SyncStatus.offline);
      }
    });

    // التحقق من الاتصال الحالي
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.every((r) => r == ConnectivityResult.none)) {
      _updateStatus(SyncStatus.offline);
    }
  }

  /// إغلاق خدمة المزامنة
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // ═══════════════════════════════════════════════════════════
  // SYNC OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// مزامنة كل البيانات
  Future<SyncResult> syncAll() async {
    if (_status == SyncStatus.syncing) {
      return SyncResult(
        success: false,
        error: 'مزامنة جارية بالفعل',
        timestamp: DateTime.now(),
      );
    }

    if (!isOnline) {
      _updateStatus(SyncStatus.offline);
      return SyncResult(
        success: false,
        error: 'لا يوجد اتصال بالإنترنت',
        timestamp: DateTime.now(),
      );
    }

    _updateStatus(SyncStatus.syncing);
    final syncedCounts = <String, int>{};

    try {
      // مزامنة الإعدادات أولاً (سعر الصرف)
      await _settingsRepository.syncToCloud();
      await _settingsRepository.syncFromCloud();
      syncedCounts['settings'] = 1;

      // مزامنة العملاء
      await _customerRepository.syncToCloud();
      await _customerRepository.syncFromCloud();
      syncedCounts['customers'] = _customerRepository.getAllCustomers().length;

      // مزامنة المنتجات
      await _productRepository.syncToCloud();
      await _productRepository.syncFromCloud();
      syncedCounts['products'] =
          (await _productRepository.getProducts()).length;

      // مزامنة الفواتير
      await _invoiceRepository.syncToCloud();
      await _invoiceRepository.syncFromCloud();
      syncedCounts['invoices'] =
          (await _invoiceRepository.getInvoices()).length;

      _lastSyncTime = DateTime.now();
      _lastError = null;
      _updateStatus(SyncStatus.success);

      final result = SyncResult(
        success: true,
        timestamp: _lastSyncTime!,
        syncedCounts: syncedCounts,
      );

      onSyncComplete?.call(result);
      return result;
    } catch (e) {
      _lastError = e.toString();
      _updateStatus(SyncStatus.error);

      final result = SyncResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
        syncedCounts: syncedCounts,
      );

      onSyncComplete?.call(result);
      return result;
    }
  }

  /// مزامنة من السحابة فقط (Pull)
  Future<SyncResult> pullFromCloud() async {
    if (!isOnline) {
      return SyncResult(
        success: false,
        error: 'لا يوجد اتصال بالإنترنت',
        timestamp: DateTime.now(),
      );
    }

    _updateStatus(SyncStatus.syncing);

    try {
      await _settingsRepository.syncFromCloud();
      await _customerRepository.syncFromCloud();
      await _productRepository.syncFromCloud();
      await _invoiceRepository.syncFromCloud();

      _lastSyncTime = DateTime.now();
      _updateStatus(SyncStatus.success);

      return SyncResult(
        success: true,
        timestamp: _lastSyncTime!,
      );
    } catch (e) {
      _lastError = e.toString();
      _updateStatus(SyncStatus.error);

      return SyncResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// مزامنة إلى السحابة فقط (Push)
  Future<SyncResult> pushToCloud() async {
    if (!isOnline) {
      return SyncResult(
        success: false,
        error: 'لا يوجد اتصال بالإنترنت',
        timestamp: DateTime.now(),
      );
    }

    _updateStatus(SyncStatus.syncing);

    try {
      await _settingsRepository.syncToCloud();
      await _customerRepository.syncToCloud();
      await _productRepository.syncToCloud();
      await _invoiceRepository.syncToCloud();

      _lastSyncTime = DateTime.now();
      _updateStatus(SyncStatus.success);

      return SyncResult(
        success: true,
        timestamp: _lastSyncTime!,
      );
    } catch (e) {
      _lastError = e.toString();
      _updateStatus(SyncStatus.error);

      return SyncResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  void _updateStatus(SyncStatus newStatus) {
    _status = newStatus;
    onStatusChanged?.call(newStatus);
  }

  /// الوقت منذ آخر مزامنة
  String getTimeSinceLastSync() {
    if (_lastSyncTime == null) {
      return 'لم تتم المزامنة بعد';
    }

    final diff = DateTime.now().difference(_lastSyncTime!);

    if (diff.inSeconds < 60) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else {
      return 'منذ ${diff.inDays} يوم';
    }
  }
}

// ═══════════════════════════════════════════════════════════
// UNIFIED SYNC SERVICE (FACADE)
// ═══════════════════════════════════════════════════════════

/// خدمة المزامنة الموحدة - Facade Pattern
/// توفر واجهة موحدة لجميع عمليات المزامنة
class UnifiedSyncService {
  late final _InitialSyncModule _initialSync;
  late final _RealtimeSyncModule _realtimeSync;
  late final _CustomerSyncModule _customerSync;
  late final _ManualSyncModule _manualSync;

  UnifiedSyncService({
    required FirestoreService firestoreService,
    required Box<InvoiceModel> invoicesBox,
    required Box<CustomerModel> customersBox,
    required Box<ProductModel> productsBox,
    required Box<CategoryModel> categoriesBox,
    required Box<BrandModel> brandsBox,
    required Box settingsBox,
    required InvoiceRepository invoiceRepository,
    required CustomerRepository customerRepository,
    required ProductRepository productRepository,
    required SettingsRepository settingsRepository,
  }) {
    _initialSync = _InitialSyncModule(
      firestoreService: firestoreService,
      invoicesBox: invoicesBox,
      customersBox: customersBox,
      productsBox: productsBox,
      categoriesBox: categoriesBox,
      brandsBox: brandsBox,
      settingsBox: settingsBox,
    );

    _realtimeSync = _RealtimeSyncModule(
      firestoreService: firestoreService,
      invoicesBox: invoicesBox,
      customersBox: customersBox,
      productsBox: productsBox,
      categoriesBox: categoriesBox,
      brandsBox: brandsBox,
      settingsBox: settingsBox,
    );

    _customerSync = _CustomerSyncModule();

    _manualSync = _ManualSyncModule(
      invoiceRepository: invoiceRepository,
      customerRepository: customerRepository,
      productRepository: productRepository,
      settingsRepository: settingsRepository,
      firestoreService: firestoreService,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // INITIAL SYNC API
  // ═══════════════════════════════════════════════════════════

  /// تنفيذ المزامنة الأولية
  Future<InitialSyncResult> performInitialSync() =>
      _initialSync.performInitialSync();

  /// جلب كل الفواتير
  Future<int> syncAllInvoices() => _initialSync.syncAllInvoices();

  /// هل المزامنة الأولية جارية؟
  bool get isInitialSyncing => _initialSync.isSyncing;

  /// هل اكتملت المزامنة الأولية؟
  bool get hasCompletedInitialSync => _initialSync.hasCompletedInitialSync;

  // ═══════════════════════════════════════════════════════════
  // REALTIME SYNC API
  // ═══════════════════════════════════════════════════════════

  /// بدء الاستماع للتغييرات في الوقت الحقيقي
  void startListening() => _realtimeSync.startListening();

  /// إيقاف الاستماع
  void stopListening() => _realtimeSync.stopListening();

  /// هل الاستماع نشط؟
  bool get isListening => _realtimeSync.isListening;

  /// Stream لأحداث المزامنة في الوقت الحقيقي
  Stream<RealtimeSyncEvent> get syncEvents => _realtimeSync.syncEvents;

  /// Streams للبيانات المحلية
  Stream<List<InvoiceModel>> get invoicesStream => _realtimeSync.invoicesStream;
  Stream<List<CustomerModel>> get customersStream =>
      _realtimeSync.customersStream;
  Stream<List<ProductModel>> get productsStream => _realtimeSync.productsStream;
  Stream<List<CategoryModel>> get categoriesStream =>
      _realtimeSync.categoriesStream;
  Stream<List<BrandModel>> get brandsStream => _realtimeSync.brandsStream;
  Stream<CompanyModel> get companyInfoStream => _realtimeSync.companyInfoStream;

  // ═══════════════════════════════════════════════════════════
  // CUSTOMER SYNC API
  // ═══════════════════════════════════════════════════════════

  /// Stream لأحداث العملاء
  Stream<CustomerSyncEvent> get customerEvents => _customerSync.events;

  /// إرسال حدث إنشاء عميل
  void customerCreated(CustomerModel customer) =>
      _customerSync.customerCreated(customer);

  /// إرسال حدث تحديث عميل
  void customerUpdated(CustomerModel customer) =>
      _customerSync.customerUpdated(customer);

  /// إرسال حدث حذف عميل
  void customerDeleted(String customerId) =>
      _customerSync.customerDeleted(customerId);

  /// إرسال حدث تحديث جماعي للعملاء
  void customersBulkUpdated(List<CustomerModel> customers) =>
      _customerSync.customersBulkUpdated(customers);

  // ═══════════════════════════════════════════════════════════
  // MANUAL SYNC API
  // ═══════════════════════════════════════════════════════════

  /// تهيئة المزامنة اليدوية
  Future<void> initializeManualSync() =>
      _manualSync.initialize(() => syncAll());

  /// مزامنة كل البيانات
  Future<SyncResult> syncAll() => _manualSync.syncAll();

  /// جلب البيانات من السحابة
  Future<SyncResult> pullFromCloud() => _manualSync.pullFromCloud();

  /// دفع البيانات إلى السحابة
  Future<SyncResult> pushToCloud() => _manualSync.pushToCloud();

  /// حالة المزامنة
  SyncStatus get status => _manualSync.status;

  /// آخر وقت للمزامنة
  DateTime? get lastSyncTime => _manualSync.lastSyncTime;

  /// آخر خطأ
  String? get lastError => _manualSync.lastError;

  /// هل متصل بالإنترنت؟
  bool get isOnline => _manualSync.isOnline;

  /// الوقت منذ آخر مزامنة
  String getTimeSinceLastSync() => _manualSync.getTimeSinceLastSync();

  /// Callback عند تغيير حالة المزامنة
  set onStatusChanged(Function(SyncStatus)? callback) {
    _manualSync.onStatusChanged = callback;
  }

  /// Callback عند اكتمال المزامنة
  set onSyncComplete(Function(SyncResult)? callback) {
    _manualSync.onSyncComplete = callback;
  }

  // ═══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════

  /// تحرير الموارد
  void dispose() {
    _realtimeSync.dispose();
    _customerSync.dispose();
    _manualSync.dispose();
  }
}

// ═══════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════

/// Provider للتحقق من حالة الاتصال
final isOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
});

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);
