import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/data/models/invoice_model.dart';
import 'package:wholesale_shoes_invoice/data/repositories/invoice_repository_new.dart';
import 'core_providers.dart';
import 'statistics_providers.dart';

// ═══════════════════════════════════════════════════════════
// INVOICES NOTIFIER
// ═══════════════════════════════════════════════════════════

class InvoicesNotifier extends StateNotifier<AsyncValue<List<InvoiceModel>>> {
  final InvoiceRepository _repository;
  final Ref _ref;

  InvoicesNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    loadInvoices();
  }

  Future<void> loadInvoices({bool showLoading = true}) async {
    if (showLoading && state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }
    try {
      final invoices = await _repository.getInvoices();
      state = AsyncValue.data(invoices);
    } catch (e, st) {
      if (state.hasValue) {
        state = AsyncValue.data(state.value!);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() => loadInvoices(showLoading: false);

  Future<void> addInvoice(InvoiceModel invoice) async {
    try {
      await _repository.addInvoice(invoice);
      await loadInvoices();
      _ref.invalidate(todayStatsProvider);
      _ref.invalidate(dashboardStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    try {
      await _repository.updateInvoice(invoice);
      await loadInvoices();
      _ref.invalidate(todayStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await _repository.deleteInvoice(id);
      await loadInvoices();
      _ref.invalidate(todayStatsProvider);
      _ref.invalidate(dashboardStatsProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> generateInvoiceNumber() async {
    return _repository.generateInvoiceNumber();
  }

  Future<void> syncFromCloud() async {
    try {
      await _repository.syncFromCloud();
      await loadInvoices();
    } catch (e) {
      rethrow;
    }
  }

  /// تحديث جميع الفواتير التي تحتوي على العميل المعطى
  /// [oldCustomerName] - الاسم القديم للعميل للتحقق من الفواتير القديمة
  Future<void> updateInvoicesForCustomer(
      String customerId, CustomerModel updatedCustomer,
      {String? oldCustomerName}) async {
    try {
      final currentInvoices = state.valueOrNull ?? [];

      for (final invoice in currentInvoices) {
        // التحقق من وجود عميل في الفاتورة يطابق العميل المحدث
        // 1. نتحقق من customerId أولاً
        final matchById = invoice.customerId != null &&
            invoice.customerId!.isNotEmpty &&
            invoice.customerId == customerId;

        // 2. للفواتير القديمة التي لا تحتوي على customerId، نتحقق من الاسم القديم
        final matchByOldName = (invoice.customerId == null ||
                invoice.customerId!.isEmpty) &&
            oldCustomerName != null &&
            invoice.customerName.toLowerCase() == oldCustomerName.toLowerCase();

        if (matchById || matchByOldName) {
          // تحديث بيانات العميل في الفاتورة باستخدام copyWith
          // وإضافة customerId للفواتير القديمة التي لا تحتويه
          final updated = invoice.copyWith(
            customerId: customerId, // ربط الفاتورة بـ ID العميل
            customerName: updatedCustomer.name,
            customerPhone: updatedCustomer.phone,
            customerAddress: updatedCustomer.address,
          );
          await _repository.updateInvoice(updated);
        }
      }

      // تحديث الحالة
      await loadInvoices(showLoading: false);
      _ref.invalidate(todayStatsProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final invoicesNotifierProvider =
    StateNotifierProvider<InvoicesNotifier, AsyncValue<List<InvoiceModel>>>(
        (ref) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return InvoicesNotifier(repository, ref);
});

// ═══════════════════════════════════════════════════════════
// ADDITIONAL INVOICE PROVIDERS
// ═══════════════════════════════════════════════════════════

final invoicesProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.getInvoices();
});
