import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'data/models/product_model.dart';
import 'data/models/invoice_model.dart';
import 'data/models/sync_metadata.dart';
import 'data/models/hive_adapters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (disabled temporarily)
  // await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(InvoiceModelAdapter());
  Hive.registerAdapter(InvoiceItemModelAdapter());
  Hive.registerAdapter(SyncMetadataAdapter());
  Hive.registerAdapter(SyncStatusAdapter());
  Hive.registerAdapter(SyncOperationAdapter());

  // Open Hive Boxes
  await Hive.openBox<ProductModel>('products');
  await Hive.openBox<InvoiceModel>('invoices');
  await Hive.openBox<SyncMetadata>('sync_queue');
  await Hive.openBox('settings');

  runApp(
    const ProviderScope(
      child: WholesaleShoesApp(),
    ),
  );
}
