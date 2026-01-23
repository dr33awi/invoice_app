import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';
import 'package:wholesale_shoes_invoice/core/services/firestore_service.dart';
import 'package:wholesale_shoes_invoice/core/services/logger_service.dart';

/// نتيجة الـ Pagination
class ProductPaginatedResult {
  final List<ProductModel> items;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  ProductPaginatedResult({
    required this.items,
    required this.hasMore,
    this.lastDocument,
  });
}

/// Repository للمنتجات يدعم العمل Online/Offline
/// يستخدم Hive للتخزين المحلي و Firestore للسحابة
abstract class ProductRepository {
  // القراءة
  Future<List<ProductModel>> getProducts();
  Future<ProductModel?> getProductById(String id);
  Future<List<ProductModel>> getProductsByCategory(String categoryId);
  Future<List<ProductModel>> getProductsByBrand(String brandId);
  Future<List<ProductModel>> getLowStockProducts();
  Future<List<ProductModel>> searchProducts(String query);
  Stream<List<ProductModel>> watchProducts();

  // Pagination
  Future<ProductPaginatedResult> getProductsPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  });

  // الكتابة
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);

  // إدارة المخزون
  Future<void> updateStock(String productId, String size, int quantity);
  Future<void> decreaseStock(String productId, String size, int quantity);
  Future<void> increaseStock(String productId, String size, int quantity);

  // المزامنة
  Future<void> syncToCloud();
  Future<void> syncFromCloud();
}

class ProductRepositoryImpl implements ProductRepository {
  final Box<ProductModel> _localBox;
  final FirestoreService _firestoreService;
  final bool _enableFirestore;

  ProductRepositoryImpl({
    required Box<ProductModel> localBox,
    required FirestoreService firestoreService,
    bool enableFirestore = true,
  })  : _localBox = localBox,
        _firestoreService = firestoreService,
        _enableFirestore = enableFirestore;

  // ═══════════════════════════════════════════════════════════
  // READ OPERATIONS
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
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    return _localBox.values
        .where((p) => p.isActive && p.categoryId == categoryId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<ProductModel>> getProductsByBrand(String brandId) async {
    return _localBox.values
        .where((p) => p.isActive && p.brandId == brandId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<ProductModel>> getLowStockProducts() async {
    return _localBox.values.where((p) => p.isActive && p.isLowStock).toList()
      ..sort((a, b) =>
          a.totalStock.compareTo(b.totalStock)); // الأقل مخزوناً أولاً
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final lowerQuery = query.toLowerCase();
    return _localBox.values
        .where((p) =>
            p.isActive &&
            (p.name.toLowerCase().contains(lowerQuery) ||
                p.brand.toLowerCase().contains(lowerQuery) ||
                (p.code?.toLowerCase().contains(lowerQuery) ?? false) ||
                p.sizeRange.contains(query)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
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
  // PAGINATION
  // ═══════════════════════════════════════════════════════════

  @override
  Future<ProductPaginatedResult> getProductsPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    if (!_enableFirestore) {
      // Fallback للتخزين المحلي
      final allProducts = await getProducts();
      return ProductPaginatedResult(
        items: allProducts.take(limit).toList(),
        hasMore: allProducts.length > limit,
      );
    }

    try {
      Query<Map<String, dynamic>> query = _firestoreService.productsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit + 1);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;

      final products =
          docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      // تحديث التخزين المحلي
      for (final product in products) {
        await _localBox.put(product.id, product);
      }

      return ProductPaginatedResult(
        items: products,
        hasMore: hasMore,
        lastDocument: docs.isNotEmpty ? docs.last : null,
      );
    } catch (e) {
      logger.error('خطأ في جلب المنتجات مع pagination', error: e);
      // Fallback للتخزين المحلي
      final allProducts = await getProducts();
      return ProductPaginatedResult(
        items: allProducts.take(limit).toList(),
        hasMore: allProducts.length > limit,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // WRITE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> addProduct(ProductModel product) async {
    final productWithTimestamp = product.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _localBox.put(product.id, productWithTimestamp);

    if (_enableFirestore) {
      await _syncProductToCloud(productWithTimestamp);
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final updatedProduct = product.copyWith(
      updatedAt: DateTime.now(),
    );

    await _localBox.put(product.id, updatedProduct);

    if (_enableFirestore) {
      await _syncProductToCloud(updatedProduct);
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    // حذف نهائي من Hive
    await _localBox.delete(id);

    // حذف نهائي من Firestore
    if (_enableFirestore) {
      try {
        await _firestoreService.productsCollection.doc(id).delete();
      } catch (e) {
        logger.error('Error deleting product from Firestore', error: e);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // STOCK MANAGEMENT
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> updateStock(String productId, String size, int quantity) async {
    final product = _localBox.get(productId);
    if (product == null) return;

    final updatedSizes = product.sizes.map((s) {
      if (s.size == size) {
        return ProductSizeModel(
          size: s.size,
          stock: quantity,
          minStock: s.minStock,
        );
      }
      return s;
    }).toList();

    final updatedProduct = product.copyWith(
      sizes: updatedSizes,
      updatedAt: DateTime.now(),
    );

    await _localBox.put(productId, updatedProduct);

    if (_enableFirestore) {
      await _syncProductToCloud(updatedProduct);
    }
  }

  @override
  Future<void> decreaseStock(
      String productId, String size, int quantity) async {
    final product = _localBox.get(productId);
    if (product == null) return;

    final updatedSizes = product.sizes.map((s) {
      if (s.size == size) {
        final newStock = (s.stock - quantity).clamp(0, s.stock);
        return ProductSizeModel(
          size: s.size,
          stock: newStock,
          minStock: s.minStock,
        );
      }
      return s;
    }).toList();

    final updatedProduct = product.copyWith(
      sizes: updatedSizes,
      updatedAt: DateTime.now(),
    );

    await _localBox.put(productId, updatedProduct);

    if (_enableFirestore) {
      try {
        // استخدام Transaction لضمان تحديث صحيح
        await _firestoreService.firestore.runTransaction((transaction) async {
          final docRef = _firestoreService.productsCollection.doc(productId);
          final snapshot = await transaction.get(docRef);

          if (snapshot.exists) {
            final data = snapshot.data()!;
            final sizes = List<Map<String, dynamic>>.from(data['sizes'] ?? []);

            for (int i = 0; i < sizes.length; i++) {
              if (sizes[i]['size'] == size) {
                final currentStock = sizes[i]['stock'] as int;
                sizes[i]['stock'] =
                    (currentStock - quantity).clamp(0, currentStock);
                break;
              }
            }

            // حساب المخزون الكلي
            final totalStock =
                sizes.fold<int>(0, (sum, s) => sum + (s['stock'] as int));

            // التحقق من المخزون المنخفض
            final isLowStock = sizes.any((s) {
              final stock = s['stock'] as int;
              final minStock = s['minStock'] as int? ?? 0;
              return stock <= minStock;
            });

            transaction.update(docRef, {
              'sizes': sizes,
              'totalStock': totalStock,
              'isLowStock': isLowStock,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        });
      } catch (e) {
        logger.error('Error decreasing stock', error: e);
      }
    }
  }

  @override
  Future<void> increaseStock(
      String productId, String size, int quantity) async {
    final product = _localBox.get(productId);
    if (product == null) return;

    final updatedSizes = product.sizes.map((s) {
      if (s.size == size) {
        return ProductSizeModel(
          size: s.size,
          stock: s.stock + quantity,
          minStock: s.minStock,
        );
      }
      return s;
    }).toList();

    final updatedProduct = product.copyWith(
      sizes: updatedSizes,
      updatedAt: DateTime.now(),
    );

    await _localBox.put(productId, updatedProduct);

    if (_enableFirestore) {
      try {
        await _firestoreService.firestore.runTransaction((transaction) async {
          final docRef = _firestoreService.productsCollection.doc(productId);
          final snapshot = await transaction.get(docRef);

          if (snapshot.exists) {
            final data = snapshot.data()!;
            final sizes = List<Map<String, dynamic>>.from(data['sizes'] ?? []);

            for (int i = 0; i < sizes.length; i++) {
              if (sizes[i]['size'] == size) {
                sizes[i]['stock'] = (sizes[i]['stock'] as int) + quantity;
                break;
              }
            }

            final totalStock =
                sizes.fold<int>(0, (sum, s) => sum + (s['stock'] as int));

            final isLowStock = sizes.any((s) {
              final stock = s['stock'] as int;
              final minStock = s['minStock'] as int? ?? 0;
              return stock <= minStock;
            });

            transaction.update(docRef, {
              'sizes': sizes,
              'totalStock': totalStock,
              'isLowStock': isLowStock,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        });
      } catch (e) {
        logger.error('Error increasing stock', error: e);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SYNC OPERATIONS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> syncToCloud() async {
    if (!_enableFirestore) return;

    final products = _localBox.values.toList();
    final batch = _firestoreService.firestore.batch();

    for (final product in products) {
      final docRef = _firestoreService.productsCollection.doc(product.id);
      final data = product.toFirestore();

      // إضافة حقول محسوبة
      data['totalStock'] = product.totalStock;
      data['isLowStock'] = product.isLowStock;
      data['isOutOfStock'] = product.isOutOfStock;
      data['nameSearch'] = _generateSearchTerms(product.name);

      batch.set(docRef, data, SetOptions(merge: true));
    }

    await batch.commit();
  }

  @override
  Future<void> syncFromCloud() async {
    if (!_enableFirestore) return;

    try {
      final snapshot = await _firestoreService.getActiveDocuments(
        collection: _firestoreService.productsCollection,
        orderBy: 'createdAt',
        descending: true,
      );

      for (final doc in snapshot.docs) {
        final product = ProductModel.fromFirestore(doc);
        await _localBox.put(product.id, product);
      }
    } catch (e) {
      logger.error('Error syncing products from cloud', error: e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════

  Future<void> _syncProductToCloud(ProductModel product) async {
    try {
      final data = product.toFirestore();

      // إضافة حقول محسوبة
      data['totalStock'] = product.totalStock;
      data['isLowStock'] = product.isLowStock;
      data['isOutOfStock'] = product.isOutOfStock;
      data['nameSearch'] = _generateSearchTerms(product.name);

      await _firestoreService.productsCollection
          .doc(product.id)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      logger.error('Error syncing product to cloud', error: e);
    }
  }

  List<String> _generateSearchTerms(String name) {
    final terms = <String>[];
    final lowerName = name.toLowerCase();

    for (int i = 1; i <= lowerName.length; i++) {
      terms.add(lowerName.substring(0, i));
    }

    final words = lowerName.split(' ');
    for (final word in words) {
      if (word.isNotEmpty) {
        for (int i = 1; i <= word.length; i++) {
          terms.add(word.substring(0, i));
        }
      }
    }

    return terms.toSet().toList();
  }
}
