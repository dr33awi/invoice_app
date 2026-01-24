import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/data/models/customer_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Customer Sync Service
/// ═══════════════════════════════════════════════════════════════════════════
///
/// خدمة مركزية لمزامنة بيانات العملاء عبر التطبيق بالكامل.
/// تعمل كـ Single Source of Truth لضمان تحديث جميع الشاشات تلقائياً.
///
/// Architecture:
/// - Stream-based reactive updates
/// - Event-driven synchronization
/// - Decoupled from UI layer
/// ═══════════════════════════════════════════════════════════════════════════

/// أحداث تحديث العملاء
enum CustomerSyncEventType {
  created,
  updated,
  deleted,
  bulkUpdated,
}

/// حدث تحديث عميل
class CustomerSyncEvent {
  final CustomerSyncEventType type;
  final CustomerModel? customer;
  final List<CustomerModel>? customers;
  final DateTime timestamp;

  CustomerSyncEvent({
    required this.type,
    this.customer,
    this.customers,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory CustomerSyncEvent.created(CustomerModel customer) {
    return CustomerSyncEvent(
      type: CustomerSyncEventType.created,
      customer: customer,
    );
  }

  factory CustomerSyncEvent.updated(CustomerModel customer) {
    return CustomerSyncEvent(
      type: CustomerSyncEventType.updated,
      customer: customer,
    );
  }

  factory CustomerSyncEvent.deleted(String customerId) {
    return CustomerSyncEvent(
      type: CustomerSyncEventType.deleted,
      customer: CustomerModel(id: customerId, name: ''),
    );
  }

  factory CustomerSyncEvent.bulkUpdated(List<CustomerModel> customers) {
    return CustomerSyncEvent(
      type: CustomerSyncEventType.bulkUpdated,
      customers: customers,
    );
  }
}

/// خدمة مزامنة العملاء
class CustomerSyncService {
  /// Stream Controller للأحداث
  final _eventController = StreamController<CustomerSyncEvent>.broadcast();

  /// Stream للأحداث
  Stream<CustomerSyncEvent> get events => _eventController.stream;

  /// إرسال حدث تحديث
  void emitEvent(CustomerSyncEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// إرسال حدث إنشاء عميل
  void customerCreated(CustomerModel customer) {
    emitEvent(CustomerSyncEvent.created(customer));
  }

  /// إرسال حدث تحديث عميل
  void customerUpdated(CustomerModel customer) {
    emitEvent(CustomerSyncEvent.updated(customer));
  }

  /// إرسال حدث حذف عميل
  void customerDeleted(String customerId) {
    emitEvent(CustomerSyncEvent.deleted(customerId));
  }

  /// إرسال حدث تحديث جماعي
  void customersBulkUpdated(List<CustomerModel> customers) {
    emitEvent(CustomerSyncEvent.bulkUpdated(customers));
  }

  /// تنظيف الموارد
  void dispose() {
    _eventController.close();
  }
}

/// Provider للخدمة
final customerSyncServiceProvider = Provider<CustomerSyncService>((ref) {
  final service = CustomerSyncService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider لـ Stream الأحداث
final customerSyncEventsProvider = StreamProvider<CustomerSyncEvent>((ref) {
  final service = ref.watch(customerSyncServiceProvider);
  return service.events;
});
