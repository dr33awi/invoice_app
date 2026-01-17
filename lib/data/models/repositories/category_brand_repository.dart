import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/brand_model.dart';
import 'package:wholesale_shoes_invoice/data/models/category_model.dart';

// ═══════════════════════════════════════════════════════════
// CATEGORY REPOSITORY
// ═══════════════════════════════════════════════════════════

class CategoryRepository {
  final Box<CategoryModel> _box;

  CategoryRepository(this._box);

  // Get all categories
  List<CategoryModel> getAllCategories() {
    return _box.values.where((c) => c.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // Get category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return _box.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // Add category
  Future<void> addCategory(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  // Update category
  Future<void> updateCategory(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  // Delete category (soft delete)
  Future<void> deleteCategory(String id) async {
    final category = getCategoryById(id);
    if (category != null) {
      await _box.put(id, category.copyWith(isActive: false));
    }
  }

  // Hard delete
  Future<void> hardDeleteCategory(String id) async {
    await _box.delete(id);
  }

  // Check if name exists
  bool categoryExists(String name, {String? excludeId}) {
    return _box.values.any((c) =>
        c.name.toLowerCase() == name.toLowerCase() &&
        c.id != excludeId &&
        c.isActive);
  }

  // Stream categories
  Stream<List<CategoryModel>> watchCategories() {
    return _box.watch().map((_) => getAllCategories());
  }
}

// ═══════════════════════════════════════════════════════════
// BRAND REPOSITORY
// ═══════════════════════════════════════════════════════════

class BrandRepository {
  final Box<BrandModel> _box;

  BrandRepository(this._box);

  // Get all brands
  List<BrandModel> getAllBrands() {
    return _box.values.where((b) => b.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // Get brand by ID
  BrandModel? getBrandById(String id) {
    try {
      return _box.values.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  // Add brand
  Future<void> addBrand(BrandModel brand) async {
    await _box.put(brand.id, brand);
  }

  // Update brand
  Future<void> updateBrand(BrandModel brand) async {
    await _box.put(brand.id, brand);
  }

  // Delete brand (soft delete)
  Future<void> deleteBrand(String id) async {
    final brand = getBrandById(id);
    if (brand != null) {
      await _box.put(id, brand.copyWith(isActive: false));
    }
  }

  // Hard delete
  Future<void> hardDeleteBrand(String id) async {
    await _box.delete(id);
  }

  // Check if name exists
  bool brandExists(String name, {String? excludeId}) {
    return _box.values.any((b) =>
        b.name.toLowerCase() == name.toLowerCase() &&
        b.id != excludeId &&
        b.isActive);
  }

  // Stream brands
  Stream<List<BrandModel>> watchBrands() {
    return _box.watch().map((_) => getAllBrands());
  }
}
