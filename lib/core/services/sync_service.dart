import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/data/repositories/customer_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/invoice_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/product_repository_new.dart';
import 'package:wholesale_shoes_invoice/data/repositories/settings_repository_new.dart';
import 'package:wholesale_shoes_invoice/core/services/firestore_service.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/providers/providers.dart';

/// حالة المزامنة
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

/// نتيجة المزامنة
class SyncResult {
  final bool success;
  final String? error;
  final DateTime timestamp;
  final Map<String, int> syncedCounts;

  SyncResult({
    required this.success,
    this.error,
    required this.timestamp,
    this.syncedCounts = const {},
  });
}

/// خدمة المزامنة بين Hive و Firestore
class SyncService {
  final InvoiceRepository _invoiceRepository;
  final CustomerRepository _customerRepository;
  final ProductRepository _productRepository;
  final SettingsRepository _settingsRepository;
  final FirestoreService _firestoreService;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;

  // Callbacks
  Function(SyncStatus)? onStatusChanged;
  Function(SyncResult)? onSyncComplete;

  SyncService({
    required InvoiceRepository invoiceRepository,
    required CustomerRepository customerRepository,
    required ProductRepository productRepository,
    required SettingsRepository settingsRepository,
    required FirestoreService firestoreService,
  })  : _invoiceRepository = invoiceRepository,
        _customerRepository = customerRepository,
        _productRepository = productRepository,
        _settingsRepository = settingsRepository,
        _firestoreService = firestoreService;

  // ═══════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════

  SyncStatus get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;
  bool get isOnline => _firestoreService.isOnline;

  // ═══════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════

  /// تهيئة خدمة المزامنة
  Future<void> initialize() async {
    await _firestoreService.initialize();

    // مراقبة حالة الاتصال
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);

      if (isOnline && _status == SyncStatus.offline) {
        // عند العودة للاتصال، نبدأ المزامنة
        syncAll();
      }

      if (!isOnline) {
        _updateStatus(SyncStatus.offline);
      }
    });

    // التحقق من الاتصال الحالي
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.every((r) => r == ConnectivityResult.none)) {
      _updateStatus(SyncStatus.offline);
    }
  }

  /// إغلاق خدمة المزامنة
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // ═══════════════════════════════════════════════════════════
  // SYNC OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// مزامنة كل البيانات
  Future<SyncResult> syncAll() async {
    if (_status == SyncStatus.syncing) {
      return SyncResult(
        success: false,
        error: 'مزامنة جارية بالفعل',
        timestamp: DateTime.now(),
      );
    }

    if (!isOnline) {
      _updateStatus(SyncStatus.offline);
      return SyncResult(
        success: false,
        error: 'لا يوجد اتصال بالإنترنت',
        timestamp: DateTime.now(),
      );
    }

    _updateStatus(SyncStatus.syncing);
    final syncedCounts = <String, int>{};

    try {
      // مزامنة الإعدادات أولاً (سعر الصرف)
      await _settingsRepository.syncToCloud();
      await _settingsRepository.syncFromCloud();
      syncedCounts['settings'] = 1;

      // مزامنة العملاء
      await _customerRepository.syncToCloud();
      await _customerRepository.syncFromCloud();
      syncedCounts['customers'] = _customerRepository.getAllCustomers().length;

      // مزامنة المنتجات
      await _productRepository.syncToCloud();
      await _productRepository.syncFromCloud();
      syncedCounts['products'] =
          (await _productRepository.getProducts()).length;

      // مزامنة الفواتير
      await _invoiceRepository.syncToCloud();
      await _invoiceRepository.syncFromCloud();
      syncedCounts['invoices'] =
          (await _invoiceRepository.getInvoices()).length;

      _lastSyncTime = DateTime.now();
      _lastError = null;
      _updateStatus(SyncStatus.success);

      final result = SyncResult(
        success: true,
        timestamp: _lastSyncTime!,
        syncedCounts: syncedCounts,
      );

      onSyncComplete?.call(result);
      return result;
    } catch (e) {
      _lastError = e.toString();
      _updateStatus(SyncStatus.error);

      final result = SyncResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
        syncedCounts: syncedCounts,
      );

      onSyncComplete?.call(result);
      return result;
    }
  }

  /// مزامنة من السحابة فقط (Pull)
  Future<SyncResult> pullFromCloud() async {
    if (!isOnline) {
      return SyncResult(
        success: false,
        error: 'لا يوجد اتصال بالإنترنت',
        timestamp: DateTime.now(),
      );
    }

    _updateStatus(SyncStatus.syncing);

    try {
      await _settingsRepository.syncFromCloud();
      await _customerRepository.syncFromCloud();
      await _productRepository.syncFromCloud();
      await _invoiceRepository.syncFromCloud();

      _lastSyncTime = DateTime.now();
      _updateStatus(SyncStatus.success);

      return SyncResult(
        success: true,
        timestamp: _lastSyncTime!,
      );
    } catch (e) {
      _lastError = e.toString();
      _updateStatus(SyncStatus.error);

      return SyncResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// مزامنة إلى السحابة فقط (Push)
  Future<SyncResult> pushToCloud() async {
    if (!isOnline) {
      return SyncResult(
        success: false,
        error: 'لا يوجد اتصال بالإنترنت',
        timestamp: DateTime.now(),
      );
    }

    _updateStatus(SyncStatus.syncing);

    try {
      await _settingsRepository.syncToCloud();
      await _customerRepository.syncToCloud();
      await _productRepository.syncToCloud();
      await _invoiceRepository.syncToCloud();

      _lastSyncTime = DateTime.now();
      _updateStatus(SyncStatus.success);

      return SyncResult(
        success: true,
        timestamp: _lastSyncTime!,
      );
    } catch (e) {
      _lastError = e.toString();
      _updateStatus(SyncStatus.error);

      return SyncResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  void _updateStatus(SyncStatus newStatus) {
    _status = newStatus;
    onStatusChanged?.call(newStatus);
  }

  /// الوقت منذ آخر مزامنة
  String getTimeSinceLastSync() {
    if (_lastSyncTime == null) {
      return 'لم تتم المزامنة بعد';
    }

    final diff = DateTime.now().difference(_lastSyncTime!);

    if (diff.inSeconds < 60) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else {
      return 'منذ ${diff.inDays} يوم';
    }
  }
}

// ═══════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════

final syncServiceProvider = Provider<SyncService>((ref) {
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);
  final customerRepo = ref.watch(customerRepositoryProvider);
  final productRepo = ref.watch(productRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return SyncService(
    invoiceRepository: invoiceRepo,
    customerRepository: customerRepo,
    productRepository: productRepo,
    settingsRepository: settingsRepo,
    firestoreService: firestoreService,
  );
});

// Import providers from the new providers file

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);

/// Provider للتحقق من حالة الاتصال
final isOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
});
