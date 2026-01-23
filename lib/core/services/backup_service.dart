import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/data/models/product_model.dart';
import 'package:wholesale_shoes_invoice/data/models/category_model.dart';
import 'package:wholesale_shoes_invoice/data/models/brand_model.dart';

/// خدمة النسخ الاحتياطي والاستعادة
class BackupService {
  final Box<InvoiceModel> _invoicesBox;
  final Box<CustomerModel> _customersBox;
  final Box<ProductModel> _productsBox;
  final Box<CategoryModel> _categoriesBox;
  final Box<BrandModel> _brandsBox;
  final Box _settingsBox;

  BackupService({
    required Box<InvoiceModel> invoicesBox,
    required Box<CustomerModel> customersBox,
    required Box<ProductModel> productsBox,
    required Box<CategoryModel> categoriesBox,
    required Box<BrandModel> brandsBox,
    required Box settingsBox,
  })  : _invoicesBox = invoicesBox,
        _customersBox = customersBox,
        _productsBox = productsBox,
        _categoriesBox = categoriesBox,
        _brandsBox = brandsBox,
        _settingsBox = settingsBox;

  // ═══════════════════════════════════════════════════════════
  // النسخ الاحتياطي
  // ═══════════════════════════════════════════════════════════

  /// إنشاء نسخة احتياطية كاملة
  Future<BackupResult> createBackup() async {
    try {
      debugPrint('📦 BackupService: Starting backup...');

      // جمع كل البيانات
      final backupData = {
        'version': '1.0',
        'createdAt': DateTime.now().toIso8601String(),
        'appName': 'Invoice App',
        'data': {
          'invoices': _invoicesBox.values.map((i) => i.toJson()).toList(),
          'customers': _customersBox.values.map((c) => c.toJson()).toList(),
          'products': _productsBox.values.map((p) => p.toJson()).toList(),
          'categories': _categoriesBox.values.map((c) => c.toJson()).toList(),
          'brands': _brandsBox.values.map((b) => b.toJson()).toList(),
          'settings': {
            'exchange_rate': _settingsBox.get('exchange_rate'),
            'company_info': _settingsBox.get('company_info'),
          },
        },
        'counts': {
          'invoices': _invoicesBox.length,
          'customers': _customersBox.length,
          'products': _productsBox.length,
          'categories': _categoriesBox.length,
          'brands': _brandsBox.length,
        },
      };

      // تحويل إلى JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // إنشاء اسم الملف
      final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
      final fileName =
          'invoice_backup_${dateFormat.format(DateTime.now())}.json';

      // حفظ الملف
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      debugPrint('✅ BackupService: Backup created successfully');
      debugPrint('   - Invoices: ${_invoicesBox.length}');
      debugPrint('   - Customers: ${_customersBox.length}');
      debugPrint('   - Products: ${_productsBox.length}');
      debugPrint('   - Categories: ${_categoriesBox.length}');
      debugPrint('   - Brands: ${_brandsBox.length}');

      return BackupResult(
        success: true,
        message: 'تم إنشاء النسخة الاحتياطية بنجاح',
        filePath: filePath,
        fileName: fileName,
        counts: {
          'invoices': _invoicesBox.length,
          'customers': _customersBox.length,
          'products': _productsBox.length,
          'categories': _categoriesBox.length,
          'brands': _brandsBox.length,
        },
      );
    } catch (e) {
      debugPrint('❌ BackupService: Backup failed - $e');
      return BackupResult(
        success: false,
        message: 'فشل إنشاء النسخة الاحتياطية: $e',
      );
    }
  }

  /// مشاركة النسخة الاحتياطية
  Future<bool> shareBackup() async {
    try {
      final result = await createBackup();
      if (!result.success || result.filePath == null) {
        return false;
      }

      await Share.shareXFiles(
        [XFile(result.filePath!)],
        text: 'نسخة احتياطية من تطبيق الفواتير',
        subject: 'نسخة احتياطية - ${result.fileName}',
      );

      return true;
    } catch (e) {
      debugPrint('❌ BackupService: Share failed - $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // استعادة البيانات
  // ═══════════════════════════════════════════════════════════

  /// استعادة البيانات من ملف
  Future<RestoreResult> restoreFromFile() async {
    try {
      debugPrint('📥 BackupService: Starting restore...');

      // اختيار الملف
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return RestoreResult(
          success: false,
          message: 'لم يتم اختيار ملف',
        );
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // التحقق من صحة البيانات
      if (!backupData.containsKey('data') ||
          !backupData.containsKey('version')) {
        return RestoreResult(
          success: false,
          message: 'ملف النسخة الاحتياطية غير صالح',
        );
      }

      final data = backupData['data'] as Map<String, dynamic>;
      final counts = <String, int>{};

      // استعادة الفئات
      if (data.containsKey('categories')) {
        final categoriesList = data['categories'] as List<dynamic>;
        for (final item in categoriesList) {
          try {
            final category =
                CategoryModel.fromJson(item as Map<String, dynamic>);
            await _categoriesBox.put(category.id, category);
          } catch (e) {
            debugPrint('⚠️ Error restoring category: $e');
          }
        }
        counts['categories'] = categoriesList.length;
      }

      // استعادة الماركات
      if (data.containsKey('brands')) {
        final brandsList = data['brands'] as List<dynamic>;
        for (final item in brandsList) {
          try {
            final brand = BrandModel.fromJson(item as Map<String, dynamic>);
            await _brandsBox.put(brand.id, brand);
          } catch (e) {
            debugPrint('⚠️ Error restoring brand: $e');
          }
        }
        counts['brands'] = brandsList.length;
      }

      // استعادة العملاء
      if (data.containsKey('customers')) {
        final customersList = data['customers'] as List<dynamic>;
        for (final item in customersList) {
          try {
            final customer =
                CustomerModel.fromJson(item as Map<String, dynamic>);
            await _customersBox.put(customer.id, customer);
          } catch (e) {
            debugPrint('⚠️ Error restoring customer: $e');
          }
        }
        counts['customers'] = customersList.length;
      }

      // استعادة المنتجات
      if (data.containsKey('products')) {
        final productsList = data['products'] as List<dynamic>;
        for (final item in productsList) {
          try {
            final product = ProductModel.fromJson(item as Map<String, dynamic>);
            await _productsBox.put(product.id, product);
          } catch (e) {
            debugPrint('⚠️ Error restoring product: $e');
          }
        }
        counts['products'] = productsList.length;
      }

      // استعادة الفواتير
      if (data.containsKey('invoices')) {
        final invoicesList = data['invoices'] as List<dynamic>;
        for (final item in invoicesList) {
          try {
            final invoice = InvoiceModel.fromJson(item as Map<String, dynamic>);
            await _invoicesBox.put(invoice.id, invoice);
          } catch (e) {
            debugPrint('⚠️ Error restoring invoice: $e');
          }
        }
        counts['invoices'] = invoicesList.length;
      }

      // استعادة الإعدادات
      if (data.containsKey('settings')) {
        final settings = data['settings'] as Map<String, dynamic>;
        if (settings['exchange_rate'] != null) {
          await _settingsBox.put('exchange_rate', settings['exchange_rate']);
        }
        if (settings['company_info'] != null) {
          await _settingsBox.put('company_info', settings['company_info']);
        }
        counts['settings'] = 1;
      }

      debugPrint('✅ BackupService: Restore completed successfully');
      debugPrint('   - Categories: ${counts['categories'] ?? 0}');
      debugPrint('   - Brands: ${counts['brands'] ?? 0}');
      debugPrint('   - Customers: ${counts['customers'] ?? 0}');
      debugPrint('   - Products: ${counts['products'] ?? 0}');
      debugPrint('   - Invoices: ${counts['invoices'] ?? 0}');

      return RestoreResult(
        success: true,
        message: 'تمت استعادة البيانات بنجاح',
        counts: counts,
        backupDate: backupData['createdAt'] != null
            ? DateTime.tryParse(backupData['createdAt'])
            : null,
      );
    } catch (e) {
      debugPrint('❌ BackupService: Restore failed - $e');
      return RestoreResult(
        success: false,
        message: 'فشل استعادة البيانات: $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // مسح كل البيانات
  // ═══════════════════════════════════════════════════════════

  /// مسح كل البيانات المحلية
  Future<void> clearAllData() async {
    await _invoicesBox.clear();
    await _customersBox.clear();
    await _productsBox.clear();
    await _categoriesBox.clear();
    await _brandsBox.clear();
    debugPrint('🗑️ BackupService: All data cleared');
  }
}

// ═══════════════════════════════════════════════════════════
// نماذج النتائج
// ═══════════════════════════════════════════════════════════

class BackupResult {
  final bool success;
  final String message;
  final String? filePath;
  final String? fileName;
  final Map<String, int>? counts;
  final DateTime timestamp;

  BackupResult({
    required this.success,
    required this.message,
    this.filePath,
    this.fileName,
    this.counts,
  }) : timestamp = DateTime.now();

  int get totalItems {
    if (counts == null) return 0;
    int total = 0;
    for (final value in counts!.values) {
      total += value;
    }
    return total;
  }
}

class RestoreResult {
  final bool success;
  final String message;
  final Map<String, int>? counts;
  final DateTime? backupDate;
  final DateTime timestamp;

  RestoreResult({
    required this.success,
    required this.message,
    this.counts,
    this.backupDate,
  }) : timestamp = DateTime.now();

  int get totalItems {
    if (counts == null) return 0;
    int total = 0;
    for (final value in counts!.values) {
      total += value;
    }
    return total;
  }
}
