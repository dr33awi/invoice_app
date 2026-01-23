import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/brand_model.dart';
import 'package:wholesale_shoes_invoice/data/models/category_model.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';
import 'package:wholesale_shoes_invoice/data/models/statistics_model.dart';
import 'package:wholesale_shoes_invoice/data/repositories/category_brand_repository.dart';
import 'package:wholesale_shoes_invoice/data/repositories/customer_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/invoice_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/product_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/settings_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/statistics_repository.dart';
import 'package:wholesale_shoes_invoice/core/services/firestore_service.dart';

// ═══════════════════════════════════════════════════════════
// FIRESTORE SERVICE PROVIDER
// ═══════════════════════════════════════════════════════════

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// تفعيل/تعطيل Firestore
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

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final box = ref.watch(categoriesBoxProvider);
  return CategoryRepository(box);
});

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  final box = ref.watch(brandsBoxProvider);
  return BrandRepository(box);
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return StatisticsRepository(firestoreService: firestoreService);
});

// ═══════════════════════════════════════════════════════════
// PRODUCTS NOTIFIER
// ═══════════════════════════════════════════════════════════

class ProductsNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final ProductRepository _repository;

  ProductsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts({bool showLoading = true}) async {
    if (showLoading && state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }
    try {
      final products = await _repository.getProducts();
      state = AsyncValue.data(products);
    } catch (e, st) {
      if (state.hasValue) {
        state = AsyncValue.data(state.value!);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

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

  Future<void> syncFromCloud() async {
    try {
      await _repository.syncFromCloud();
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

// ═══════════════════════════════════════════════════════════
// INVOICES NOTIFIER
// ═══════════════════════════════════════════════════════════

class InvoicesNotifier extends StateNotifier<AsyncValue<List<InvoiceModel>>> {
  final InvoiceRepository _repository;
  final Ref _ref;

  InvoicesNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    loadInvoices();
  }

  Future<void> loadInvoices({bool showLoading = true}) async {
    if (showLoading && state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }
    try {
      final invoices = await _repository.getInvoices();
      state = AsyncValue.data(invoices);
    } catch (e, st) {
      if (state.hasValue) {
        state = AsyncValue.data(state.value!);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() => loadInvoices(showLoading: false);

  Future<void> addInvoice(InvoiceModel invoice) async {
    try {
      await _repository.addInvoice(invoice);
      await loadInvoices();
      _ref.invalidate(todayStatsProvider);
      _ref.invalidate(dashboardStatsProvider);
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
      _ref.invalidate(dashboardStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> generateInvoiceNumber() async {
    return _repository.generateInvoiceNumber();
  }

  Future<void> syncFromCloud() async {
    try {
      await _repository.syncFromCloud();
      await loadInvoices();
    } catch (e) {
      rethrow;
    }
  }
}

final invoicesNotifierProvider =
    StateNotifierProvider<InvoicesNotifier, AsyncValue<List<InvoiceModel>>>(
        (ref) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return InvoicesNotifier(repository, ref);
});

// ═══════════════════════════════════════════════════════════
// CUSTOMERS NOTIFIER
// ═══════════════════════════════════════════════════════════

class CustomersNotifier extends StateNotifier<AsyncValue<List<CustomerModel>>> {
  final CustomerRepository _repository;

  CustomersNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCustomers();
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

  Future<void> syncFromCloud() async {
    try {
      await _repository.syncFromCloud();
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
// CATEGORIES & BRANDS NOTIFIERS
// ═══════════════════════════════════════════════════════════

class CategoriesNotifier
    extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final CategoryRepository _repository;

  CategoriesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
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

class BrandsNotifier extends StateNotifier<AsyncValue<List<BrandModel>>> {
  final BrandRepository _repository;

  BrandsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBrands();
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
// STATISTICS PROVIDERS
// ═══════════════════════════════════════════════════════════

final todayStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.getTodayStats();
});

final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.getDashboardStats();
});

final todayStatisticsProvider = StreamProvider<DailyStatisticsModel?>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.watchTodayStatistics();
});

final currentMonthStatisticsProvider =
    StreamProvider<MonthlyStatisticsModel?>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.watchCurrentMonthStatistics();
});

// ═══════════════════════════════════════════════════════════
// ADDITIONAL PROVIDERS
// ═══════════════════════════════════════════════════════════

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProducts();
});

final invoicesProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.getInvoices();
});

final lowStockProductsProvider =
    FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getLowStockProducts();
});

final customersWithDebtProvider = Provider<List<CustomerModel>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getCustomersWithDebt();
});

final exchangeRateProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getExchangeRate();
});

final exchangeRateStreamProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchExchangeRate();
});
