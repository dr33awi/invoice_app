import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';
import 'package:wholesale_shoes_invoice/data/repositories/customer_repository_new.dart';
import 'package:wholesale_shoes_invoice/core/services/customer_sync_service.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/providers/providers.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Customer Reactive Providers
/// ═══════════════════════════════════════════════════════════════════════════
///
/// مجموعة Providers متخصصة للعملاء تدعم:
/// - التحديث التلقائي (Reactive Updates)
/// - Single Source of Truth
/// - Stream-based Architecture
/// - Offline-first Support
///
/// هذه الـ Providers هي المصدر الوحيد لبيانات العملاء في التطبيق
/// وتضمن تحديث جميع الشاشات تلقائياً عند أي تعديل.
/// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════
// CUSTOMERS STATE NOTIFIER
// ═══════════════════════════════════════════════════════════

/// حالة العملاء
class CustomersState {
  final List<CustomerModel> customers;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const CustomersState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  CustomersState copyWith({
    List<CustomerModel>? customers,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// الحصول على عميل بالـ ID
  CustomerModel? getCustomerById(String id) {
    try {
      return customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// البحث عن عملاء
  List<CustomerModel> searchCustomers(String query) {
    if (query.isEmpty) return customers;
    final lowerQuery = query.toLowerCase();
    return customers.where((c) {
      return c.name.toLowerCase().contains(lowerQuery) ||
          (c.phone?.contains(query) ?? false) ||
          (c.address?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}

/// StateNotifier للعملاء مع دعم التحديث التلقائي
class ReactiveCustomersNotifier extends StateNotifier<CustomersState> {
  final CustomerRepository _repository;
  final CustomerSyncService _syncService;
  final Ref _ref;
  StreamSubscription? _hiveSubscription;
  StreamSubscription? _syncSubscription;

  ReactiveCustomersNotifier({
    required CustomerRepository repository,
    required CustomerSyncService syncService,
    required Ref ref,
  })  : _repository = repository,
        _syncService = syncService,
        _ref = ref,
        super(const CustomersState(isLoading: true)) {
    _init();
  }

  void _init() {
    // تحميل البيانات الأولية
    _loadCustomers();

    // الاستماع لتغييرات Hive
    _hiveSubscription = _repository.watchCustomers().listen((customers) {
      state = state.copyWith(
        customers: customers,
        lastUpdated: DateTime.now(),
        isLoading: false,
      );
    });

    // الاستماع لأحداث المزامنة
    _syncSubscription = _syncService.events.listen((event) {
      _handleSyncEvent(event);
    });
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = _repository.getAllCustomers();
      state = state.copyWith(
        customers: customers,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void _handleSyncEvent(CustomerSyncEvent event) {
    switch (event.type) {
      case CustomerSyncEventType.created:
      case CustomerSyncEventType.updated:
        _loadCustomers();
        break;
      case CustomerSyncEventType.deleted:
        _loadCustomers();
        break;
      case CustomerSyncEventType.bulkUpdated:
        _loadCustomers();
        break;
    }
  }

  /// تحديث البيانات
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadCustomers();
  }

  /// إضافة عميل جديد
  Future<void> addCustomer(CustomerModel customer) async {
    try {
      await _repository.addCustomer(customer);
      _syncService.customerCreated(customer);
      await _loadCustomers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// تحديث عميل
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await _repository.updateCustomer(customer);
      _syncService.customerUpdated(customer);

      // ═══════════════════════════════════════════════════════════════════
      // تحديث الفواتير القديمة بالبيانات الجديدة للعميل
      // ═══════════════════════════════════════════════════════════════════
      await _ref
          .read(invoicesNotifierProvider.notifier)
          .updateInvoicesForCustomer(customer.id, customer);

      await _loadCustomers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// حذف عميل
  Future<void> deleteCustomer(String id) async {
    try {
      await _repository.deleteCustomer(id);
      _syncService.customerDeleted(id);
      await _loadCustomers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  @override
  void dispose() {
    _hiveSubscription?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════

/// Provider الرئيسي للعملاء مع التحديث التلقائي
final reactiveCustomersProvider =
    StateNotifierProvider<ReactiveCustomersNotifier, CustomersState>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  final syncService = ref.watch(customerSyncServiceProvider);
  return ReactiveCustomersNotifier(
    repository: repository,
    syncService: syncService,
    ref: ref,
  );
});

/// Provider للحصول على قائمة العملاء
final customersListProvider = Provider<List<CustomerModel>>((ref) {
  return ref.watch(reactiveCustomersProvider).customers;
});

/// Provider للبحث عن العملاء
final customersSearchProvider =
    Provider.family<List<CustomerModel>, String>((ref, query) {
  return ref.watch(reactiveCustomersProvider).searchCustomers(query);
});

/// Provider للحصول على عميل بالـ ID مع التحديث التلقائي
final customerByIdProvider =
    Provider.family<AsyncValue<CustomerModel?>, String>((ref, customerId) {
  final state = ref.watch(reactiveCustomersProvider);

  if (state.isLoading) {
    return const AsyncValue.loading();
  }

  if (state.error != null) {
    return AsyncValue.error(state.error!, StackTrace.current);
  }

  return AsyncValue.data(state.getCustomerById(customerId));
});

/// Provider للحصول على بيانات العميل (الاسم، الهاتف، العنوان) بالـ ID
final customerDataProvider =
    Provider.family<CustomerData?, String>((ref, customerId) {
  final state = ref.watch(reactiveCustomersProvider);
  final customer = state.getCustomerById(customerId);

  if (customer == null) return null;

  return CustomerData(
    id: customer.id,
    name: customer.name,
    phone: customer.phone,
    address: customer.address,
    city: customer.city,
    type: customer.type,
    balance: customer.balance,
  );
});

/// بيانات العميل المبسطة للاستخدام في شاشات الفواتير
class CustomerData {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? city;
  final String type;
  final double balance;

  const CustomerData({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.city,
    this.type = CustomerModel.typeWholesale,
    this.balance = 0,
  });
}

/// Provider لمراقبة تغييرات عميل معين
final customerChangesProvider =
    StreamProvider.family<CustomerModel?, String>((ref, customerId) async* {
  final syncService = ref.watch(customerSyncServiceProvider);

  // إرسال القيمة الحالية أولاً
  final currentState = ref.read(reactiveCustomersProvider);
  yield currentState.getCustomerById(customerId);

  // الاستماع للتغييرات
  await for (final event in syncService.events) {
    if (event.customer?.id == customerId ||
        event.type == CustomerSyncEventType.bulkUpdated) {
      final state = ref.read(reactiveCustomersProvider);
      yield state.getCustomerById(customerId);
    }
  }
});

// ═══════════════════════════════════════════════════════════
// UTILITY PROVIDERS
// ═══════════════════════════════════════════════════════════

/// Provider للعملاء المدينين
final customersWithDebtProvider = Provider<List<CustomerModel>>((ref) {
  final customers = ref.watch(customersListProvider);
  return customers.where((c) => c.balance > 0).toList()
    ..sort((a, b) => b.balance.compareTo(a.balance));
});

/// Provider للعملاء حسب النوع
final customersByTypeProvider =
    Provider.family<List<CustomerModel>, String>((ref, type) {
  final customers = ref.watch(customersListProvider);
  return customers.where((c) => c.type == type).toList();
});

/// Provider لعدد العملاء
final customersCountProvider = Provider<int>((ref) {
  return ref.watch(customersListProvider).length;
});

/// Provider لإجمالي الديون
final totalCustomersDebtProvider = Provider<double>((ref) {
  final customers = ref.watch(customersListProvider);
  return customers.fold(0.0, (sum, c) => sum + c.balance);
});
