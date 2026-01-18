import 'package:hive/hive.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

abstract class InvoiceRepository {
  Future<List<InvoiceModel>> getInvoices();
  Future<InvoiceModel?> getInvoiceById(String id);
  Future<void> addInvoice(InvoiceModel invoice);
  Future<void> updateInvoice(InvoiceModel invoice);
  Future<void> deleteInvoice(String id);
  Stream<List<InvoiceModel>> watchInvoices();
  Future<List<InvoiceModel>> getInvoicesByDateRange(
      DateTime start, DateTime end);
  Future<String> generateInvoiceNumber();
}

class InvoiceRepositoryImpl implements InvoiceRepository {
  final Box<InvoiceModel> _localBox;
  // final FirebaseFirestore _firestore;  // معلق حالياً

  InvoiceRepositoryImpl({
    required Box<InvoiceModel> localBox,
    // required FirebaseFirestore firestore,
  }) : _localBox = localBox;
  // _firestore = firestore;

  // ═══════════════════════════════════════════════════════════
  // LOCAL STORAGE (HIVE)
  // ═══════════════════════════════════════════════════════════

  @override
  Future<List<InvoiceModel>> getInvoices() async {
    final invoices = _localBox.values.toList();
    invoices.sort((a, b) => b.date.compareTo(a.date));
    return invoices;
  }

  @override
  Future<InvoiceModel?> getInvoiceById(String id) async {
    return _localBox.get(id);
  }

  @override
  Future<void> addInvoice(InvoiceModel invoice) async {
    await _localBox.put(invoice.id, invoice);

    // TODO: Sync to Firestore when enabled
    // await _syncToCloud(invoice);
  }

  @override
  Future<void> updateInvoice(InvoiceModel invoice) async {
    final updatedInvoice = invoice.copyWith(
      updatedAt: DateTime.now(),
    );
    await _localBox.put(invoice.id, updatedInvoice);

    // TODO: Sync to Firestore when enabled
    // await _syncToCloud(updatedInvoice);
  }

  @override
  Future<void> deleteInvoice(String id) async {
    await _localBox.delete(id);

    // TODO: Sync delete to Firestore when enabled
  }

  @override
  Stream<List<InvoiceModel>> watchInvoices() {
    return _localBox.watch().map((_) {
      final invoices = _localBox.values.toList();
      invoices.sort((a, b) => b.date.compareTo(a.date));
      return invoices;
    });
  }

  @override
  Future<List<InvoiceModel>> getInvoicesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final invoices = _localBox.values.where((invoice) {
      return invoice.date.isAfter(start.subtract(const Duration(days: 1))) &&
          invoice.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
    invoices.sort((a, b) => b.date.compareTo(a.date));
    return invoices;
  }

  @override
  Future<String> generateInvoiceNumber() async {
    final now = DateTime.now();
    final year = now.year;

    // Get today's invoices count
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayInvoices = _localBox.values.where((invoice) {
      return invoice.date.isAfter(todayStart) &&
          invoice.date.isBefore(todayEnd);
    }).length;

    final sequence = (todayInvoices + 1).toString().padLeft(3, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return 'INV-$year$month$day-$sequence';
  }

  // ═══════════════════════════════════════════════════════════
  // STATISTICS
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getTodayStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayInvoices = _localBox.values.where((invoice) {
      return invoice.date.isAfter(todayStart) &&
          invoice.date.isBefore(todayEnd);
    }).toList();

    final totalUSD = todayInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.totalUSD,
    );

    final totalSYP = todayInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.totalSYP,
    );

    return {
      'count': todayInvoices.length,
      'totalUSD': totalUSD,
      'totalSYP': totalSYP,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // FIRESTORE (معلق حالياً)
  // ═══════════════════════════════════════════════════════════

  /*
  Future<void> _syncToCloud(InvoiceModel invoice) async {
    try {
      await _firestore
          .collection('invoices')
          .doc(invoice.id)
          .set(invoice.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('Error syncing invoice to cloud: $e');
      // Queue for later sync
    }
  }

  Future<void> syncFromCloud() async {
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .orderBy('date', descending: true)
          .limit(100)
          .get();

      for (final doc in snapshot.docs) {
        final invoice = InvoiceModel.fromFirestore(doc);
        await _localBox.put(invoice.id, invoice);
      }
    } catch (e) {
      print('Error syncing invoices from cloud: $e');
    }
  }

  Stream<List<InvoiceModel>> watchInvoicesFromCloud() {
    return _firestore
        .collection('invoices')
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceModel.fromFirestore(doc))
            .toList());
  }
  */
}
