import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel?> getProductById(String id);
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Stream<List<ProductModel>> watchProducts();
}

class ProductRepositoryImpl implements ProductRepository {
  final Box<ProductModel> _localBox;
  // final FirebaseFirestore _firestore;  // معلق حالياً

  ProductRepositoryImpl({
    required Box<ProductModel> localBox,
    // required FirebaseFirestore firestore,
  }) : _localBox = localBox;
  // _firestore = firestore;

  // ═══════════════════════════════════════════════════════════
  // LOCAL STORAGE (HIVE)
  // ═══════════════════════════════════════════════════════════

  @override
  Future<List<ProductModel>> getProducts() async {
    final products = _localBox.values.where((p) => p.isActive).toList();
    products.sort((a, b) => (b.createdAt ?? DateTime.now())
        .compareTo(a.createdAt ?? DateTime.now()));
    return products;
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    return _localBox.get(id);
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    await _localBox.put(product.id, product);

    // TODO: Sync to Firestore when enabled
    // await _syncToCloud(product);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final updatedProduct = product.copyWith(
      updatedAt: DateTime.now(),
    );
    await _localBox.put(product.id, updatedProduct);

    // TODO: Sync to Firestore when enabled
    // await _syncToCloud(updatedProduct);
  }

  @override
  Future<void> deleteProduct(String id) async {
    final product = _localBox.get(id);
    if (product != null) {
      // Soft delete
      final deletedProduct = product.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );
      await _localBox.put(id, deletedProduct);

      // TODO: Sync to Firestore when enabled
      // await _syncToCloud(deletedProduct);
    }
  }

  @override
  Stream<List<ProductModel>> watchProducts() {
    return _localBox.watch().map((_) {
      final products = _localBox.values.where((p) => p.isActive).toList();
      products.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return products;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // FIRESTORE (معلق حالياً)
  // ═══════════════════════════════════════════════════════════

  /*
  Future<void> _syncToCloud(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .set(product.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('Error syncing product to cloud: $e');
      // Queue for later sync
    }
  }

  Future<void> syncFromCloud() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in snapshot.docs) {
        final product = ProductModel.fromFirestore(doc);
        await _localBox.put(product.id, product);
      }
    } catch (e) {
      print('Error syncing products from cloud: $e');
    }
  }

  Stream<List<ProductModel>> watchProductsFromCloud() {
    return _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }
  */
}
