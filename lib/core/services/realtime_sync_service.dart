import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';
import 'package:wholesale_shoes_invoice/data/models/category_model.dart';
import 'package:wholesale_shoes_invoice/data/models/brand_model.dart';
import 'package:wholesale_shoes_invoice/data/models/company_model.dart';
import 'package:wholesale_shoes_invoice/core/services/firestore_service.dart';

/// خدمة المزامنة في الوقت الحقيقي
/// تستمع للتغييرات من Firestore وتحدث البيانات المحلية فوراً
class RealtimeSyncService {
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

  RealtimeSyncService({
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
// MODELS
// ═══════════════════════════════════════════════════════════

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
