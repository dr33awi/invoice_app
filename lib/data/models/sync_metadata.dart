import 'package:hive/hive.dart';

@HiveType(typeId: 10)
enum SyncStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  syncing,

  @HiveField(2)
  synced,

  @HiveField(3)
  error,
}

@HiveType(typeId: 11)
enum SyncOperation {
  @HiveField(0)
  create,

  @HiveField(1)
  update,

  @HiveField(2)
  delete,
}

@HiveType(typeId: 12)
class SyncMetadata extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String collection;

  @HiveField(2)
  final String documentId;

  @HiveField(3)
  final SyncOperation operation;

  @HiveField(4)
  final Map<String, dynamic>? data;

  @HiveField(5)
  final SyncStatus status;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final String? errorMessage;

  @HiveField(8)
  final int retryCount;

  SyncMetadata({
    required this.id,
    required this.collection,
    required this.documentId,
    required this.operation,
    this.data,
    this.status = SyncStatus.pending,
    DateTime? createdAt,
    this.errorMessage,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a copy with updated fields
  SyncMetadata copyWith({
    String? id,
    String? collection,
    String? documentId,
    SyncOperation? operation,
    Map<String, dynamic>? data,
    SyncStatus? status,
    DateTime? createdAt,
    String? errorMessage,
    int? retryCount,
  }) {
    return SyncMetadata(
      id: id ?? this.id,
      collection: collection ?? this.collection,
      documentId: documentId ?? this.documentId,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      errorMessage: errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  String toString() =>
      'SyncMetadata(id: $id, collection: $collection, operation: $operation, status: $status)';
}
