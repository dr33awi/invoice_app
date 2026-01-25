import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'data/models/product_model.dart';
import 'data/models/invoice_model.dart';
import 'data/models/sync_metadata.dart';
import 'data/models/category_model.dart';
import 'data/models/brand_model.dart';
import 'data/models/customer_model.dart';
import 'data/models/payment_model.dart';
import 'data/models/hive_adapters.dart';
import 'core/services/firestore_service.dart';
import 'core/services/logger_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run critical initializations in parallel for faster startup
  await Future.wait([
    _initializeFirebase(),
    _initializeHive(),
  ]);

  logger.info('App started successfully', tag: 'App');

  runApp(
    const ProviderScope(
      child: WholesaleShoesApp(),
    ),
  );
}

/// Initialize Firebase and Firestore
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize Firestore Service (enables offline persistence + auth)
    await FirestoreService().initialize();
    logger.info('Firebase initialized successfully', tag: 'App');
  } catch (e) {
    logger.warning('Firebase initialization failed: $e', tag: 'App');
    logger.info('App will work in offline mode only', tag: 'App');
  }
}

/// Initialize Hive and open boxes
Future<void> _initializeHive() async {
  // Initialize Hive
  await Hive.initFlutter();

  // Register all Hive Adapters
  _registerHiveAdapters();

  // Open Hive Boxes in parallel for faster startup
  await Future.wait([
    Hive.openBox<ProductModel>('products'),
    Hive.openBox<InvoiceModel>('invoices'),
    Hive.openBox<SyncMetadata>('sync_queue'),
    Hive.openBox<CategoryModel>('categories'),
    Hive.openBox<BrandModel>('brands'),
    Hive.openBox<CustomerModel>('customers'),
    Hive.openBox<PaymentModel>('payments'),
    Hive.openBox('settings'),
  ]);
}

/// Register all Hive adapters
void _registerHiveAdapters() {
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(ProductSizeModelAdapter());
  Hive.registerAdapter(InvoiceModelAdapter());
  Hive.registerAdapter(InvoiceItemModelAdapter());
  Hive.registerAdapter(PaymentModelAdapter());
  Hive.registerAdapter(SyncMetadataAdapter());
  Hive.registerAdapter(SyncStatusAdapter());
  Hive.registerAdapter(SyncOperationAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(BrandModelAdapter());
  Hive.registerAdapter(CustomerModelAdapter());
}
