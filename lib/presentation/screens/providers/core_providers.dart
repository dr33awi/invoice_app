import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/brand_model.dart';
import 'package:wholesale_shoes_invoice/data/models/category_model.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';
import 'package:wholesale_shoes_invoice/data/repositories/category_brand_repository.dart';
import 'package:wholesale_shoes_invoice/data/repositories/customer_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/invoice_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/product_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/settings_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/statistics_repository.dart';
import 'package:wholesale_shoes_invoice/core/services/firestore_service.dart';
import 'package:wholesale_shoes_invoice/core/services/unified_sync_service.dart';

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
// UNIFIED SYNC SERVICE PROVIDER
// ═══════════════════════════════════════════════════════════

final unifiedSyncServiceProvider = Provider<UnifiedSyncService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final invoicesBox = ref.watch(invoicesBoxProvider);
  final customersBox = ref.watch(customersBoxProvider);
  final productsBox = ref.watch(productsBoxProvider);
  final categoriesBox = ref.watch(categoriesBoxProvider);
  final brandsBox = ref.watch(brandsBoxProvider);
  final settingsBox = ref.watch(settingsBoxProvider);
  final invoiceRepository = ref.watch(invoiceRepositoryProvider);
  final customerRepository = ref.watch(customerRepositoryProvider);
  final productRepository = ref.watch(productRepositoryProvider);
  final settingsRepository = ref.watch(settingsRepositoryProvider);

  final service = UnifiedSyncService(
    firestoreService: firestoreService,
    invoicesBox: invoicesBox,
    customersBox: customersBox,
    productsBox: productsBox,
    categoriesBox: categoriesBox,
    brandsBox: brandsBox,
    settingsBox: settingsBox,
    invoiceRepository: invoiceRepository,
    customerRepository: customerRepository,
    productRepository: productRepository,
    settingsRepository: settingsRepository,
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// ═══════════════════════════════════════════════════════════
// BACKWARD COMPATIBILITY ALIASES
// ═══════════════════════════════════════════════════════════
// These providers delegate to UnifiedSyncService for backward compatibility

/// Alias for initial sync functionality (backward compatibility)
final initialSyncServiceProvider = Provider<UnifiedSyncService>((ref) {
  return ref.watch(unifiedSyncServiceProvider);
});

/// Alias for realtime sync functionality (backward compatibility)
final realtimeSyncServiceProvider = Provider<UnifiedSyncService>((ref) {
  return ref.watch(unifiedSyncServiceProvider);
});

/// Provider for customer sync events (backward compatibility)
final customerSyncServiceProvider = Provider<UnifiedSyncService>((ref) {
  return ref.watch(unifiedSyncServiceProvider);
});

/// Provider for customer sync events stream
final customerSyncEventsProvider = StreamProvider<CustomerSyncEvent>((ref) {
  final service = ref.watch(unifiedSyncServiceProvider);
  return service.customerEvents;
});
