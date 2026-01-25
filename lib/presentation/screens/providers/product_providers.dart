import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/data/models/brand_model.dart';
import 'package:wholesale_shoes_invoice/data/models/category_model.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';
import 'package:wholesale_shoes_invoice/data/repositories/category_brand_repository.dart';
import 'package:wholesale_shoes_invoice/data/repositories/product_repository_new.dart';
import 'core_providers.dart';

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
// CATEGORIES NOTIFIER
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

// ═══════════════════════════════════════════════════════════
// BRANDS NOTIFIER
// ═══════════════════════════════════════════════════════════

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
// ADDITIONAL PRODUCT PROVIDERS
// ═══════════════════════════════════════════════════════════

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProducts();
});

final lowStockProductsProvider =
    FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getLowStockProducts();
});
