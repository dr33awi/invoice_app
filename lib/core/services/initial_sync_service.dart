import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';
import 'package:wholesale_shoes_invoice/data/models/category_model.dart';
import 'package:wholesale_shoes_invoice/data/models/brand_model.dart';
import 'package:wholesale_shoes_invoice/data/models/company_model.dart';
import 'package:wholesale_shoes_invoice/core/services/firestore_service.dart';

/// خدمة المزامنة الأولية - تجلب كل البيانات من Firestore عند فتح التطبيق
class InitialSyncService {
  final FirestoreService _firestoreService;
  final Box<InvoiceModel> _invoicesBox;
  final Box<CustomerModel> _customersBox;
  final Box<ProductModel> _productsBox;
  final Box<CategoryModel> _categoriesBox;
  final Box<BrandModel> _brandsBox;
  final Box _settingsBox;

  bool _isSyncing = false;
  bool _hasCompletedInitialSync = false;

  InitialSyncService({
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
