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

  // Initialize Firebase with options
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

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
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

  // Open Hive Boxes
  await Hive.openBox<ProductModel>('products');
  await Hive.openBox<InvoiceModel>('invoices');
  await Hive.openBox<SyncMetadata>('sync_queue');
  await Hive.openBox<CategoryModel>('categories');
  await Hive.openBox<BrandModel>('brands');
  await Hive.openBox<CustomerModel>('customers');
  await Hive.openBox<PaymentModel>('payments');
  await Hive.openBox('settings');

  logger.info('App started successfully', tag: 'App');

  runApp(
    const ProviderScope(
      child: WholesaleShoesApp(),
    ),
  );
}
