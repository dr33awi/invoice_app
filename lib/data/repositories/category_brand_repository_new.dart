import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/brand_model.dart';
import 'package:wholesale_shoes_invoice/data/models/category_model.dart';
import 'package:wholesale_shoes_invoice/core/services/firestore_service.dart';

// ═══════════════════════════════════════════════════════════
// CATEGORY REPOSITORY مع دعم Firestore
// ═══════════════════════════════════════════════════════════

class CategoryRepositoryImpl {
  final Box<CategoryModel> _localBox;
  final FirestoreService _firestoreService;
  final bool _enableFirestore;

  CategoryRepositoryImpl({
    required Box<CategoryModel> localBox,
    required FirestoreService firestoreService,
    required bool enableFirestore,
  })  : _localBox = localBox,
        _firestoreService = firestoreService,
        _enableFirestore = enableFirestore;

  // Get all categories
  List<CategoryModel> getAllCategories() {
    return _localBox.values.where((c) => c.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // Get category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return _localBox.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // Add category
  Future<void> addCategory(CategoryModel category) async {
    // حفظ محلياً
    await _localBox.put(category.id, category);

    // رفع إلى Firestore
    if (_enableFirestore) {
      try {
        await _firestoreService.categoriesCollection
            .doc(category.id)
            .set(category.toFirestore());
      } catch (e) {
        print('⚠️ خطأ في رفع الفئة إلى Firestore: $e');
      }
    }
  }

  // Update category
  Future<void> updateCategory(CategoryModel category) async {
    await _localBox.put(category.id, category);

    if (_enableFirestore) {
      try {
        await _firestoreService.categoriesCollection
            .doc(category.id)
            .update(category.toFirestore());
      } catch (e) {
        print('⚠️ خطأ في تحديث الفئة في Firestore: $e');
      }
    }
  }

  // Delete category (hard delete)
  Future<void> deleteCategory(String id) async {
    await _localBox.delete(id);

    if (_enableFirestore) {
      try {
        await _firestoreService.categoriesCollection.doc(id).delete();
      } catch (e) {
        print('⚠️ خطأ في حذف الفئة من Firestore: $e');
      }
    }
  }

  // Check if name exists
  bool categoryExists(String name, {String? excludeId}) {
    return _localBox.values.any((c) =>
        c.name.toLowerCase() == name.toLowerCase() &&
        c.id != excludeId &&
        c.isActive);
  }

  // Stream categories
  Stream<List<CategoryModel>> watchCategories() {
    return _localBox.watch().map((_) => getAllCategories());
  }
}

// ═══════════════════════════════════════════════════════════
// BRAND REPOSITORY مع دعم Firestore
// ═══════════════════════════════════════════════════════════

class BrandRepositoryImpl {
  final Box<BrandModel> _localBox;
  final FirestoreService _firestoreService;
  final bool _enableFirestore;

  BrandRepositoryImpl({
    required Box<BrandModel> localBox,
    required FirestoreService firestoreService,
    required bool enableFirestore,
  })  : _localBox = localBox,
        _firestoreService = firestoreService,
        _enableFirestore = enableFirestore;

  // Get all brands
  List<BrandModel> getAllBrands() {
    return _localBox.values.where((b) => b.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // Get brand by ID
  BrandModel? getBrandById(String id) {
    try {
      return _localBox.values.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  // Add brand
  Future<void> addBrand(BrandModel brand) async {
    // حفظ محلياً
    await _localBox.put(brand.id, brand);

    // رفع إلى Firestore
    if (_enableFirestore) {
      try {
        await _firestoreService.brandsCollection
            .doc(brand.id)
            .set(brand.toFirestore());
      } catch (e) {
        print('⚠️ خطأ في رفع الماركة إلى Firestore: $e');
      }
    }
  }

  // Update brand
  Future<void> updateBrand(BrandModel brand) async {
    await _localBox.put(brand.id, brand);

    if (_enableFirestore) {
      try {
        await _firestoreService.brandsCollection
            .doc(brand.id)
            .update(brand.toFirestore());
      } catch (e) {
        print('⚠️ خطأ في تحديث الماركة في Firestore: $e');
      }
    }
  }

  // Delete brand (hard delete)
  Future<void> deleteBrand(String id) async {
    await _localBox.delete(id);

    if (_enableFirestore) {
      try {
        await _firestoreService.brandsCollection.doc(id).delete();
      } catch (e) {
        print('⚠️ خطأ في حذف الماركة من Firestore: $e');
      }
    }
  }

  // Check if name exists
  bool brandExists(String name, {String? excludeId}) {
    return _localBox.values.any((b) =>
        b.name.toLowerCase() == name.toLowerCase() &&
        b.id != excludeId &&
        b.isActive);
  }

  // Stream brands
  Stream<List<BrandModel>> watchBrands() {
    return _localBox.watch().map((_) => getAllBrands());
  }
}
