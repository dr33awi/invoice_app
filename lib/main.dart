import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'data/models/product_model.dart';
import 'data/models/invoice_model.dart';
import 'data/models/sync_metadata.dart';
import 'data/models/category_model.dart';
import 'data/models/brand_model.dart';
import 'data/models/customer_model.dart';
import 'data/models/hive_adapters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(InvoiceModelAdapter());
  Hive.registerAdapter(InvoiceItemModelAdapter());
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
  await Hive.openBox('settings');

  runApp(
    const ProviderScope(
      child: WholesaleShoesApp(),
    ),
  );
}
