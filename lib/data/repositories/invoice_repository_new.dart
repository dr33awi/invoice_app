import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/data/models/payment_model.dart';
import 'package:wholesale_shoes_invoice/core/services/firestore_service.dart';
import 'package:wholesale_shoes_invoice/core/services/logger_service.dart';

/// نتيجة الـ Pagination
class PaginatedResult<T> {
  final List<T> items;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  PaginatedResult({
    required this.items,
    required this.hasMore,
    this.lastDocument,
  });
}

/// Repository للفواتير يدعم العمل Online/Offline
/// يستخدم Hive للتخزين المحلي و Firestore للسحابة
abstract class InvoiceRepository {
  // القراءة
  Future<List<InvoiceModel>> getInvoices();
  Future<InvoiceModel?> getInvoiceById(String id);
  Future<List<InvoiceModel>> getInvoicesByDateRange(
      DateTime start, DateTime end);
  Future<List<InvoiceModel>> getInvoicesByCustomer(String customerId);
  Future<List<InvoiceModel>> getTodayInvoices();
  Stream<List<InvoiceModel>> watchInvoices();

  // Pagination
  Future<PaginatedResult<InvoiceModel>> getInvoicesPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  });

  // الكتابة
  Future<void> addInvoice(InvoiceModel invoice);
  Future<void> updateInvoice(InvoiceModel invoice);
  Future<void> deleteInvoice(String id);

  // الدفعات
  Future<void> addPayment(String invoiceId, PaymentModel payment);

  // أرقام الفواتير
  Future<String> generateInvoiceNumber();

  // الإحصائيات
  Future<Map<String, dynamic>> getTodayStats();

  // المزامنة
  Future<void> syncToCloud();
  Future<void> syncFromCloud();
}

class InvoiceRepositoryImpl implements InvoiceRepository {
  final Box<InvoiceModel> _localBox;
  final FirestoreService _firestoreService;
  final bool _enableFirestore;

  InvoiceRepositoryImpl({
    required Box<InvoiceModel> localBox,
    required FirestoreService firestoreService,
    bool enableFirestore = true,
  })  : _localBox = localBox,
        _firestoreService = firestoreService,
        _enableFirestore = enableFirestore;

  /// التحقق من أن الفاتورة نشطة (غير ملغاة)
  bool _isActiveInvoice(InvoiceModel invoice) {
    return invoice.status != InvoiceModel.invoiceCancelled;
  }

  // ═══════════════════════════════════════════════════════════
  // READ OPERATIONS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<List<InvoiceModel>> getInvoices() async {
    final invoices = _localBox.values.where(_isActiveInvoice).toList();
    invoices.sort((a, b) => b.date.compareTo(a.date));
    return invoices;
  }

  @override
  Future<InvoiceModel?> getInvoiceById(String id) async {
    return _localBox.get(id);
  }

  @override
  Future<List<InvoiceModel>> getInvoicesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final invoices = _localBox.values.where((invoice) {
      return _isActiveInvoice(invoice) &&
          invoice.date.isAfter(start.subtract(const Duration(days: 1))) &&
          invoice.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
    invoices.sort((a, b) => b.date.compareTo(a.date));
    return invoices;
  }

  @override
  Future<List<InvoiceModel>> getInvoicesByCustomer(String customerId) async {
    final invoices = _localBox.values
        .where((i) => _isActiveInvoice(i) && i.customerId == customerId)
        .toList();
    invoices.sort((a, b) => b.date.compareTo(a.date));
    return invoices;
  }

  @override
  Future<List<InvoiceModel>> getTodayInvoices() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _localBox.values
        .where((invoice) =>
            _isActiveInvoice(invoice) &&
            invoice.date.isAfter(todayStart) &&
            invoice.date.isBefore(todayEnd))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Stream<List<InvoiceModel>> watchInvoices() {
    return _localBox.watch().map((_) {
      final invoices = _localBox.values.where(_isActiveInvoice).toList();
      invoices.sort((a, b) => b.date.compareTo(a.date));
      return invoices;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // PAGINATION
  // ═══════════════════════════════════════════════════════════

  @override
  Future<PaginatedResult<InvoiceModel>> getInvoicesPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    if (!_enableFirestore) {
      // Fallback للتخزين المحلي
      final allInvoices = await getInvoices();
      return PaginatedResult(
        items: allInvoices.take(limit).toList(),
        hasMore: allInvoices.length > limit,
      );
    }

    try {
      Query<Map<String, dynamic>> query = _firestoreService.invoicesCollection
          .where('status', isNotEqualTo: InvoiceModel.invoiceCancelled)
          .orderBy('status')
          .orderBy('date', descending: true)
          .limit(limit + 1); // +1 للتحقق من وجود المزيد

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;

      final invoices =
          docs.map((doc) => InvoiceModel.fromFirestore(doc)).toList();

      // تحديث التخزين المحلي
      for (final invoice in invoices) {
        await _localBox.put(invoice.id, invoice);
      }

      return PaginatedResult(
        items: invoices,
        hasMore: hasMore,
        lastDocument: docs.isNotEmpty ? docs.last : null,
      );
    } catch (e) {
      logger.error('خطأ في جلب الفواتير مع pagination',
          tag: 'Invoice', error: e);
      // Fallback للتخزين المحلي
      final allInvoices = await getInvoices();
      return PaginatedResult(
        items: allInvoices.take(limit).toList(),
        hasMore: allInvoices.length > limit,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // WRITE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> addInvoice(InvoiceModel invoice) async {
    // التأكد من وجود التاريخ المفصل للإحصائيات
    final invDate = invoice.invoiceDate ?? invoice.date;
    final invoiceWithDate = invoice.copyWith(
      year: invDate.year,
      month: invDate.month,
      day: invDate.day,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: _firestoreService.currentUserId, // إضافة معرف المستخدم
    );

    // حفظ محلياً
    await _localBox.put(invoiceWithDate.id, invoiceWithDate);

    // مزامنة مع Firestore
    if (_enableFirestore) {
      await _syncInvoiceToCloud(invoiceWithDate);
      await _updateDailyStatistics(invoiceWithDate, isNew: true);
    }

    logger.info('تم إنشاء فاتورة: ${invoiceWithDate.invoiceNumber}',
        tag: 'Invoice');
  }

  @override
  Future<void> updateInvoice(InvoiceModel invoice) async {
    final updatedInvoice = invoice.copyWith(
      updatedAt: DateTime.now(),
    );

    // حفظ محلياً
    await _localBox.put(invoice.id, updatedInvoice);

    // مزامنة مع Firestore
    if (_enableFirestore) {
      await _syncInvoiceToCloud(updatedInvoice);
    }
  }

  @override
  Future<void> deleteInvoice(String id) async {
    final invoice = _localBox.get(id);
    if (invoice == null) return;

    // حذف نهائي من Hive
    await _localBox.delete(id);

    // حذف نهائي من Firestore
    if (_enableFirestore) {
      try {
        await _firestoreService.invoicesCollection.doc(id).delete();
      } catch (e) {
        logger.error('خطأ في حذف الفاتورة من Firestore',
            tag: 'Invoice', error: e);
      }
      await _updateDailyStatistics(invoice, isNew: false, isDeleted: true);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PAYMENTS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> addPayment(String invoiceId, PaymentModel payment) async {
    final invoice = _localBox.get(invoiceId);
    if (invoice == null) return;

    // إضافة الدفعة وتحديث حالة السداد
    final updatedInvoice = invoice.addPayment(payment);
    await _localBox.put(invoiceId, updatedInvoice);

    // مزامنة مع Firestore
    if (_enableFirestore) {
      await _syncInvoiceToCloud(updatedInvoice);

      // تحديث إحصائيات المدفوعات
      final invDate = invoice.invoiceDate ?? invoice.date;
      final statDoc = _firestoreService.getDailyStatDoc(invDate);
      await statDoc.set({
        'totalPaid': FieldValue.increment(payment.amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // ═══════════════════════════════════════════════════════════
  // INVOICE NUMBER GENERATION
  // ═══════════════════════════════════════════════════════════

  @override
  Future<String> generateInvoiceNumber() async {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    if (_enableFirestore && _firestoreService.isOnline) {
      // استخدام Firestore للحصول على رقم فريد
      try {
        final sequence = await _firestoreService
            .getNextSequence('invoiceNumber_$year$month$day');
        return 'INV-$year$month$day-${sequence.toString().padLeft(3, '0')}';
      } catch (e) {
        // Fallback للتخزين المحلي
      }
    }

    // Fallback: استخدام العدد المحلي
    final todayInvoices = await getTodayInvoices();
    final sequence = (todayInvoices.length + 1).toString().padLeft(3, '0');
    return 'INV-$year$month$day-$sequence';
  }

  // ═══════════════════════════════════════════════════════════
  // STATISTICS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getTodayStats() async {
    final todayInvoices = await getTodayInvoices();

    final totalUSD = todayInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.totalUSD,
    );

    final totalIQD = todayInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.totalIQD,
    );

    final totalPaid = todayInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.paidAmount,
    );

    final totalRemaining = todayInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.remainingAmount,
    );

    return {
      'count': todayInvoices.length,
      'totalUSD': totalUSD,
      'totalIQD': totalIQD,
      'totalPaid': totalPaid,
      'totalRemaining': totalRemaining,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // SYNC OPERATIONS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> syncToCloud() async {
    if (!_enableFirestore) return;

    final invoices = _localBox.values.toList();
    final batch = _firestoreService.firestore.batch();

    for (final invoice in invoices) {
      final docRef = _firestoreService.invoicesCollection.doc(invoice.id);
      batch.set(docRef, invoice.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  @override
  Future<void> syncFromCloud() async {
    if (!_enableFirestore) return;

    try {
      final snapshot = await _firestoreService.getActiveDocuments(
        collection: _firestoreService.invoicesCollection,
        orderBy: 'createdAt',
        descending: true,
      );

      for (final doc in snapshot.docs) {
        final invoice = InvoiceModel.fromFirestore(doc);
        await _localBox.put(invoice.id, invoice);
      }
    } catch (e) {
      // سيتم المزامنة لاحقاً عند الاتصال
      logger.warning('خطأ في مزامنة الفواتير من السحابة',
          tag: 'Invoice', error: e);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════

  Future<void> _syncInvoiceToCloud(InvoiceModel invoice) async {
    try {
      await _firestoreService.invoicesCollection
          .doc(invoice.id)
          .set(invoice.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      // سيتم المزامنة لاحقاً
      logger.warning('خطأ في مزامنة الفاتورة للسحابة',
          tag: 'Invoice', error: e);
    }
  }

  Future<void> _updateDailyStatistics(
    InvoiceModel invoice, {
    required bool isNew,
    bool isDeleted = false,
  }) async {
    try {
      final invDate = invoice.invoiceDate ?? invoice.date;
      final statDoc = _firestoreService.getDailyStatDoc(invDate);

      final incrementBy = isDeleted ? -1 : 1;
      final amountMultiplier = isDeleted ? -1.0 : 1.0;

      await statDoc.set({
        'date': invDate.toIso8601String().split('T')[0],
        'year': invDate.year,
        'month': invDate.month,
        'day': invDate.day,
        'invoicesCount': FieldValue.increment(isNew ? incrementBy : 0),
        'totalSalesUSD': FieldValue.increment(
            isNew ? invoice.totalUSD * amountMultiplier : 0),
        'totalSalesIQD': FieldValue.increment(
            isNew ? invoice.totalIQD * amountMultiplier : 0),
        'totalPaid': FieldValue.increment(
            isNew ? invoice.paidAmount * amountMultiplier : 0),
        'totalRemaining': FieldValue.increment(
            isNew ? invoice.remainingAmount * amountMultiplier : 0),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // تحديث الإحصائيات الشهرية
      final monthlyDoc = _firestoreService.getMonthlyStatDoc(
        invDate.year,
        invDate.month,
      );

      await monthlyDoc.set({
        'year': invDate.year,
        'month': invDate.month,
        'invoicesCount': FieldValue.increment(isNew ? incrementBy : 0),
        'totalSalesUSD': FieldValue.increment(
            isNew ? invoice.totalUSD * amountMultiplier : 0),
        'totalSalesIQD': FieldValue.increment(
            isNew ? invoice.totalIQD * amountMultiplier : 0),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating statistics: $e');
    }
  }
}
