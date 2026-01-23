import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/brand_model.dart';
import 'package:wholesale_shoes_invoice/data/models/category_model.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';
import 'package:wholesale_shoes_invoice/data/models/company_model.dart';
import 'package:wholesale_shoes_invoice/data/repositories/category_brand_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/customer_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/invoice_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/product_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/settings_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/statistics_repository.dart';
import 'package:wholesale_shoes_invoice/core/services/firestore_service.dart';
import 'package:wholesale_shoes_invoice/core/services/realtime_sync_service.dart';
import 'package:wholesale_shoes_invoice/core/services/initial_sync_service.dart';

// ═══════════════════════════════════════════════════════════
// FIRESTORE SERVICE PROVIDER
// ═══════════════════════════════════════════════════════════

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// تفعيل/تعطيل Firestore (اضبطه على true بعد تفعيل Firebase)
final enableFirestoreProvider = StateProvider<bool>((ref) => true);
// ═══════════════════════════════════════════════════════════
// HIVE BOXES PROVIDERS
// ═══════════════════════════════════════════════════════════

final productsBoxProvider = Provider<Box<ProductModel>>((ref) {
  return Hive.box<ProductModel>('products');
});

final invoicesBoxProvider = Provider<Box<InvoiceModel>>((ref) {
  return Hive.box<InvoiceModel>('invoices');
});

final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box('settings');
});

final categoriesBoxProvider = Provider<Box<CategoryModel>>((ref) {
  return Hive.box<CategoryModel>('categories');
});

final brandsBoxProvider = Provider<Box<BrandModel>>((ref) {
  return Hive.box<BrandModel>('brands');
});

final customersBoxProvider = Provider<Box<CustomerModel>>((ref) {
  return Hive.box<CustomerModel>('customers');
});

// ═══════════════════════════════════════════════════════════
// REPOSITORY PROVIDERS
// ═══════════════════════════════════════════════════════════

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final box = ref.watch(productsBoxProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final enableFirestore = ref.watch(enableFirestoreProvider);
  return ProductRepositoryImpl(
    localBox: box,
    firestoreService: firestoreService,
    enableFirestore: enableFirestore,
  );
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final box = ref.watch(invoicesBoxProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final enableFirestore = ref.watch(enableFirestoreProvider);
  return InvoiceRepositoryImpl(
    localBox: box,
    firestoreService: firestoreService,
    enableFirestore: enableFirestore,
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final box = ref.watch(settingsBoxProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final enableFirestore = ref.watch(enableFirestoreProvider);
  return SettingsRepositoryImpl(
    localBox: box,
    firestoreService: firestoreService,
    enableFirestore: enableFirestore,
  );
});

final categoryRepositoryProvider = Provider<CategoryRepositoryImpl>((ref) {
  final box = ref.watch(categoriesBoxProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final enableFirestore = ref.watch(enableFirestoreProvider);
  return CategoryRepositoryImpl(
    localBox: box,
    firestoreService: firestoreService,
    enableFirestore: enableFirestore,
  );
});

final brandRepositoryProvider = Provider<BrandRepositoryImpl>((ref) {
  final box = ref.watch(brandsBoxProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final enableFirestore = ref.watch(enableFirestoreProvider);
  return BrandRepositoryImpl(
    localBox: box,
    firestoreService: firestoreService,
    enableFirestore: enableFirestore,
  );
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final box = ref.watch(customersBoxProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final enableFirestore = ref.watch(enableFirestoreProvider);
  return CustomerRepositoryImpl(
    localBox: box,
    firestoreService: firestoreService,
    enableFirestore: enableFirestore,
  );
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return StatisticsRepository(firestoreService: firestoreService);
});

// ═══════════════════════════════════════════════════════════
// INITIAL SYNC SERVICE
// ═══════════════════════════════════════════════════════════

final initialSyncServiceProvider = Provider<InitialSyncService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final invoicesBox = ref.watch(invoicesBoxProvider);
  final customersBox = ref.watch(customersBoxProvider);
  final productsBox = ref.watch(productsBoxProvider);
  final categoriesBox = ref.watch(categoriesBoxProvider);
  final brandsBox = ref.watch(brandsBoxProvider);
  final settingsBox = ref.watch(settingsBoxProvider);

  return InitialSyncService(
    firestoreService: firestoreService,
    invoicesBox: invoicesBox,
    customersBox: customersBox,
    productsBox: productsBox,
    categoriesBox: categoriesBox,
    brandsBox: brandsBox,
    settingsBox: settingsBox,
  );
});

/// Provider لتنفيذ المزامنة الأولية
final initialSyncProvider = FutureProvider<InitialSyncResult>((ref) async {
  final enableFirestore = ref.watch(enableFirestoreProvider);
  if (!enableFirestore) {
    return InitialSyncResult(
      success: true,
      message: 'Firestore غير مُفعّل',
    );
  }

  final service = ref.watch(initialSyncServiceProvider);
  return service.performInitialSync();
});

// ═══════════════════════════════════════════════════════════
// REALTIME SYNC SERVICE
// ═══════════════════════════════════════════════════════════

final realtimeSyncServiceProvider = Provider<RealtimeSyncService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final invoicesBox = ref.watch(invoicesBoxProvider);
  final customersBox = ref.watch(customersBoxProvider);
  final productsBox = ref.watch(productsBoxProvider);
  final categoriesBox = ref.watch(categoriesBoxProvider);
  final brandsBox = ref.watch(brandsBoxProvider);
  final settingsBox = ref.watch(settingsBoxProvider);

  final service = RealtimeSyncService(
    firestoreService: firestoreService,
    invoicesBox: invoicesBox,
    customersBox: customersBox,
    productsBox: productsBox,
    categoriesBox: categoriesBox,
    brandsBox: brandsBox,
    settingsBox: settingsBox,
  );

  // بدء الاستماع تلقائياً إذا كان Firestore مُفعّلاً
  final enableFirestore = ref.watch(enableFirestoreProvider);
  if (enableFirestore) {
    // تنفيذ المزامنة الأولية في الخلفية
    final initialSyncService = ref.read(initialSyncServiceProvider);
    initialSyncService.performInitialSync().then((_) {
      // بعد المزامنة الأولية، ابدأ الاستماع للتحديثات
      service.startListening();
    });
  }

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Stream لأحداث المزامنة في الوقت الحقيقي
final realtimeSyncEventsProvider = StreamProvider<RealtimeSyncEvent>((ref) {
  final service = ref.watch(realtimeSyncServiceProvider);
  return service.syncEvents;
});

/// Stream للفواتير من المزامنة في الوقت الحقيقي
final realtimeInvoicesProvider = StreamProvider<List<InvoiceModel>>((ref) {
  final service = ref.watch(realtimeSyncServiceProvider);
  return service.invoicesStream;
});

/// Stream للعملاء من المزامنة في الوقت الحقيقي
final realtimeCustomersProvider = StreamProvider<List<CustomerModel>>((ref) {
  final service = ref.watch(realtimeSyncServiceProvider);
  return service.customersStream;
});

/// Stream للمنتجات من المزامنة في الوقت الحقيقي
final realtimeProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final service = ref.watch(realtimeSyncServiceProvider);
  return service.productsStream;
});

/// Stream للفئات من المزامنة في الوقت الحقيقي
final realtimeCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final service = ref.watch(realtimeSyncServiceProvider);
  return service.categoriesStream;
});

/// Stream للماركات من المزامنة في الوقت الحقيقي
final realtimeBrandsProvider = StreamProvider<List<BrandModel>>((ref) {
  final service = ref.watch(realtimeSyncServiceProvider);
  return service.brandsStream;
});

/// Stream لمعلومات الشركة من المزامنة في الوقت الحقيقي
final realtimeCompanyInfoProvider = StreamProvider<CompanyModel>((ref) {
  final service = ref.watch(realtimeSyncServiceProvider);
  return service.companyInfoStream;
});

// ═══════════════════════════════════════════════════════════
// PRODUCTS PROVIDERS
// ═══════════════════════════════════════════════════════════

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProducts();
});

final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.watchProducts();
});

final productByIdProvider =
    FutureProvider.family<ProductModel?, String>((ref, id) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductById(id);
});

// ═══════════════════════════════════════════════════════════
// INVOICES PROVIDERS
// ═══════════════════════════════════════════════════════════

final invoicesProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.getInvoices();
});

final invoicesStreamProvider = StreamProvider<List<InvoiceModel>>((ref) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.watchInvoices();
});

final invoiceByIdProvider =
    FutureProvider.family<InvoiceModel?, String>((ref, id) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.getInvoiceById(id);
});

final todayStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository =
      ref.watch(invoiceRepositoryProvider) as InvoiceRepositoryImpl;
  return repository.getTodayStats();
});

// ═══════════════════════════════════════════════════════════
// SETTINGS PROVIDERS
// ═══════════════════════════════════════════════════════════

final exchangeRateProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getExchangeRate();
});

final exchangeRateStreamProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchExchangeRate();
});

// ═══════════════════════════════════════════════════════════
// NOTIFIERS (للتحكم بالعمليات)
// ═══════════════════════════════════════════════════════════

class ProductsNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final ProductRepository _repository;
  StreamSubscription? _watchSubscription;

  ProductsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProducts();
    _watchHiveChanges();
  }

  void _watchHiveChanges() {
    // الاستماع لتغييرات Hive مباشرة
    _watchSubscription = _repository.watchProducts().listen((products) {
      state = AsyncValue.data(products);
    });
  }

  @override
  void dispose() {
    _watchSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadProducts({bool showLoading = true}) async {
    // Don't show loading if we already have data (for refresh)
    if (showLoading && state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }
    try {
      final products = await _repository.getProducts();
      state = AsyncValue.data(products);
    } catch (e, st) {
      // Keep old data if available
      if (state.hasValue) {
        state = AsyncValue.data(state.value!);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Refresh without showing loading indicator
  Future<void> refresh() => loadProducts(showLoading: false);

  Future<void> addProduct(ProductModel product) async {
    try {
      await _repository.addProduct(product);
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _repository.updateProduct(product);
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }
}

final productsNotifierProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<ProductModel>>>(
        (ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductsNotifier(repository);
});

class InvoicesNotifier extends StateNotifier<AsyncValue<List<InvoiceModel>>> {
  final InvoiceRepository _repository;
  final Ref _ref;
  StreamSubscription? _watchSubscription;

  InvoicesNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    loadInvoices();
    _watchHiveChanges();
  }

  void _watchHiveChanges() {
    // الاستماع لتغييرات Hive مباشرة
    _watchSubscription = _repository.watchInvoices().listen((invoices) {
      state = AsyncValue.data(invoices);
      _ref.invalidate(todayStatsProvider);
    });
  }

  @override
  void dispose() {
    _watchSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadInvoices({bool showLoading = true}) async {
    // Don't show loading if we already have data (for refresh)
    if (showLoading && state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }
    try {
      final invoices = await _repository.getInvoices();
      state = AsyncValue.data(invoices);
    } catch (e, st) {
      // Keep old data if available
      if (state.hasValue) {
        state = AsyncValue.data(state.value!);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Refresh without showing loading indicator
  Future<void> refresh() => loadInvoices(showLoading: false);

  Future<void> addInvoice(InvoiceModel invoice) async {
    try {
      await _repository.addInvoice(invoice);
      await loadInvoices();
      // Refresh stats
      _ref.invalidate(todayStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    try {
      await _repository.updateInvoice(invoice);
      await loadInvoices();
      _ref.invalidate(todayStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await _repository.deleteInvoice(id);
      await loadInvoices();
      _ref.invalidate(todayStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> generateInvoiceNumber() async {
    return _repository.generateInvoiceNumber();
  }
}

final invoicesNotifierProvider =
    StateNotifierProvider<InvoicesNotifier, AsyncValue<List<InvoiceModel>>>(
        (ref) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return InvoicesNotifier(repository, ref);
});

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
// CATEGORIES PROVIDERS
// ═══════════════════════════════════════════════════════════

class CategoriesNotifier
    extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final CategoryRepositoryImpl _repository;
  StreamSubscription? _watchSubscription;

  CategoriesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
    _watchHiveChanges();
  }

  void _watchHiveChanges() {
    // الاستماع لتغييرات Hive مباشرة
    _watchSubscription = _repository.watchCategories().listen((categories) {
      state = AsyncValue.data(categories);
    });
  }

  @override
  void dispose() {
    _watchSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadCategories({bool showLoading = true}) async {
    if (showLoading && state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }
    try {
      final categories = _repository.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      if (state.hasValue) {
        state = AsyncValue.data(state.value!);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Refresh without showing loading indicator
  Future<void> refresh() => loadCategories(showLoading: false);

  Future<void> addCategory(CategoryModel category) async {
    try {
      await _repository.addCategory(category);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _repository.updateCategory(category);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }
}

final categoriesNotifierProvider =
    StateNotifierProvider<CategoriesNotifier, AsyncValue<List<CategoryModel>>>(
        (ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoriesNotifier(repository);
});

// ═══════════════════════════════════════════════════════════
// BRANDS PROVIDERS
// ═══════════════════════════════════════════════════════════

class BrandsNotifier extends StateNotifier<AsyncValue<List<BrandModel>>> {
  final BrandRepositoryImpl _repository;
  StreamSubscription? _watchSubscription;

  BrandsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBrands();
    _watchHiveChanges();
  }

  void _watchHiveChanges() {
    // الاستماع لتغييرات Hive مباشرة
    _watchSubscription = _repository.watchBrands().listen((brands) {
      state = AsyncValue.data(brands);
    });
  }

  @override
  void dispose() {
    _watchSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadBrands({bool showLoading = true}) async {
    if (showLoading && state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }
    try {
      final brands = _repository.getAllBrands();
      state = AsyncValue.data(brands);
    } catch (e, st) {
      if (state.hasValue) {
        state = AsyncValue.data(state.value!);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Refresh without showing loading indicator
  Future<void> refresh() => loadBrands(showLoading: false);

  Future<void> addBrand(BrandModel brand) async {
    try {
      await _repository.addBrand(brand);
      await loadBrands();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBrand(BrandModel brand) async {
    try {
      await _repository.updateBrand(brand);
      await loadBrands();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBrand(String id) async {
    try {
      await _repository.deleteBrand(id);
      await loadBrands();
    } catch (e) {
      rethrow;
    }
  }
}

final brandsNotifierProvider =
    StateNotifierProvider<BrandsNotifier, AsyncValue<List<BrandModel>>>((ref) {
  final repository = ref.watch(brandRepositoryProvider);
  return BrandsNotifier(repository);
});

// ═══════════════════════════════════════════════════════════
// CUSTOMERS PROVIDERS
// ═══════════════════════════════════════════════════════════

class CustomersNotifier extends StateNotifier<AsyncValue<List<CustomerModel>>> {
  final CustomerRepository _repository;
  StreamSubscription? _watchSubscription;

  CustomersNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCustomers();
    _watchHiveChanges();
  }

  void _watchHiveChanges() {
    // الاستماع لتغييرات Hive مباشرة
    _watchSubscription = _repository.watchCustomers().listen((customers) {
      state = AsyncValue.data(customers);
    });
  }

  @override
  void dispose() {
    _watchSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadCustomers({bool showLoading = true}) async {
    if (showLoading && state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }
    try {
      final customers = _repository.getAllCustomers();
      state = AsyncValue.data(customers);
    } catch (e, st) {
      if (state.hasValue) {
        state = AsyncValue.data(state.value!);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Refresh without showing loading indicator
  Future<void> refresh() => loadCustomers(showLoading: false);

  Future<void> addCustomer(CustomerModel customer) async {
    try {
      await _repository.addCustomer(customer);
      await loadCustomers();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await _repository.updateCustomer(customer);
      await loadCustomers();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _repository.deleteCustomer(id);
      await loadCustomers();
    } catch (e) {
      rethrow;
    }
  }
}

final customersNotifierProvider =
    StateNotifierProvider<CustomersNotifier, AsyncValue<List<CustomerModel>>>(
        (ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return CustomersNotifier(repository);
});
