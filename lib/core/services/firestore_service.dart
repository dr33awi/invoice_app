import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wholesale_shoes_invoice/core/services/logger_service.dart';
import 'package:wholesale_shoes_invoice/core/services/auth_service.dart';

/// خدمة مركزية للتعامل مع Firestore
/// تدعم العمل Online/Offline مع المزامنة التلقائية
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  final AuthService _authService = AuthService();

  bool _isInitialized = false;
  bool _isOnline = true;

  // ═══════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_isInitialized) return;

    // تفعيل الـ Offline Persistence مع تحديد حجم Cache معقول (100MB)
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024, // 100MB
    );

    // مراقبة حالة الاتصال
    _connectivity.onConnectivityChanged.listen((results) {
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      logger.debug('تغيرت حالة الاتصال: ${_isOnline ? "متصل" : "غير متصل"}',
          tag: 'Firestore');
    });

    // التحقق من الاتصال الحالي
    final connectivityResult = await _connectivity.checkConnectivity();
    _isOnline = connectivityResult.any((r) => r != ConnectivityResult.none);

    // ملاحظة: لا نحاول المصادقة هنا - يجب أن يسجل المستخدم دخوله بالهاتف أولاً

    _isInitialized = true;
    logger.info('Firestore Service تم تهيئة', tag: 'Firestore');
  }

  // ═══════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════

  FirebaseFirestore get firestore => _firestore;
  bool get isOnline => _isOnline;
  String? get currentUserId => _authService.currentUserId;

  // ═══════════════════════════════════════════════════════════
  // COLLECTION REFERENCES
  // ═══════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> get invoicesCollection =>
      _firestore.collection('invoices');

  CollectionReference<Map<String, dynamic>> get customersCollection =>
      _firestore.collection('customers');

  CollectionReference<Map<String, dynamic>> get productsCollection =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get categoriesCollection =>
      _firestore.collection('categories');

  CollectionReference<Map<String, dynamic>> get brandsCollection =>
      _firestore.collection('brands');

  CollectionReference<Map<String, dynamic>> get settingsCollection =>
      _firestore.collection('settings');

  CollectionReference<Map<String, dynamic>> get statisticsCollection =>
      _firestore.collection('statistics');

  // ═══════════════════════════════════════════════════════════
  // GENERIC CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// إضافة مستند جديد
  Future<void> addDocument({
    required CollectionReference<Map<String, dynamic>> collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await collection.doc(docId).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// تحديث مستند
  Future<void> updateDocument({
    required CollectionReference<Map<String, dynamic>> collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await collection.doc(docId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// حذف مستند (soft delete)
  Future<void> softDeleteDocument({
    required CollectionReference<Map<String, dynamic>> collection,
    required String docId,
  }) async {
    await collection.doc(docId).update({
      'isActive': false,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// حذف مستند نهائي
  Future<void> hardDeleteDocument({
    required CollectionReference<Map<String, dynamic>> collection,
    required String docId,
  }) async {
    await collection.doc(docId).delete();
  }

  /// الحصول على مستند واحد
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required CollectionReference<Map<String, dynamic>> collection,
    required String docId,
  }) async {
    return collection.doc(docId).get();
  }

  /// الحصول على جميع المستندات النشطة
  Future<QuerySnapshot<Map<String, dynamic>>> getActiveDocuments({
    required CollectionReference<Map<String, dynamic>> collection,
    String? orderBy,
    bool descending = false,
  }) async {
    Query<Map<String, dynamic>> query =
        collection.where('isActive', isEqualTo: true);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    return query.get();
  }

  /// مراقبة التغييرات في المستندات
  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveDocuments({
    required CollectionReference<Map<String, dynamic>> collection,
    String? orderBy,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> query =
        collection.where('isActive', isEqualTo: true);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    return query.snapshots();
  }

  // ═══════════════════════════════════════════════════════════
  // BATCH OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// تنفيذ عمليات متعددة دفعة واحدة
  Future<void> runBatch(
      Future<void> Function(WriteBatch batch) operations) async {
    final batch = _firestore.batch();
    await operations(batch);
    await batch.commit();
  }

  /// Transaction للعمليات المعقدة
  Future<T> runTransaction<T>(
      Future<T> Function(Transaction transaction) operations) async {
    return _firestore.runTransaction(operations);
  }

  // ═══════════════════════════════════════════════════════════
  // STATISTICS HELPERS
  // ═══════════════════════════════════════════════════════════

  /// الحصول على مرجع الإحصائيات اليومية
  DocumentReference<Map<String, dynamic>> getDailyStatDoc(DateTime date) {
    final docId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return statisticsCollection.doc('daily').collection('days').doc(docId);
  }

  /// الحصول على مرجع الإحصائيات الشهرية
  DocumentReference<Map<String, dynamic>> getMonthlyStatDoc(
      int year, int month) {
    final docId = '$year-${month.toString().padLeft(2, '0')}';
    return statisticsCollection.doc('monthly').collection('months').doc(docId);
  }

  /// زيادة قيمة في الإحصائيات
  Future<void> incrementStat({
    required DocumentReference<Map<String, dynamic>> docRef,
    required String field,
    int incrementBy = 1,
  }) async {
    await docRef.set(
      {
        field: FieldValue.increment(incrementBy),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // COUNTERS
  // ═══════════════════════════════════════════════════════════

  /// الحصول على رقم تسلسلي جديد
  Future<int> getNextSequence(String counterName) async {
    final counterDoc = settingsCollection.doc('counters');

    return _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(counterDoc);

      int currentValue = 0;
      if (snapshot.exists) {
        currentValue = snapshot.data()?[counterName] ?? 0;
      }

      final newValue = currentValue + 1;

      transaction.set(
        counterDoc,
        {counterName: newValue, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      return newValue;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════

  /// الحصول على الفواتير حسب التاريخ
  Future<QuerySnapshot<Map<String, dynamic>>> getInvoicesByDate({
    required int year,
    int? month,
    int? day,
  }) async {
    Query<Map<String, dynamic>> query = invoicesCollection
        .where('isActive', isEqualTo: true)
        .where('year', isEqualTo: year);

    if (month != null) {
      query = query.where('month', isEqualTo: month);
    }

    if (day != null) {
      query = query.where('day', isEqualTo: day);
    }

    return query.orderBy('createdAt', descending: true).get();
  }

  /// الحصول على فواتير العميل
  Future<QuerySnapshot<Map<String, dynamic>>> getCustomerInvoices(
      String customerId) async {
    return invoicesCollection
        .where('customerId', isEqualTo: customerId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
  }

  /// البحث عن العملاء
  Future<QuerySnapshot<Map<String, dynamic>>> searchCustomers(
      String searchTerm) async {
    // البحث بالاسم (يبدأ بـ)
    return customersCollection
        .where('isActive', isEqualTo: true)
        .where('nameSearch', arrayContains: searchTerm.toLowerCase())
        .limit(20)
        .get();
  }

  /// الحصول على المنتجات حسب الفئة
  Future<QuerySnapshot<Map<String, dynamic>>> getProductsByCategory(
      String categoryId) async {
    return productsCollection
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .get();
  }

  /// الحصول على المنتجات حسب الماركة
  Future<QuerySnapshot<Map<String, dynamic>>> getProductsByBrand(
      String brandId) async {
    return productsCollection
        .where('brandId', isEqualTo: brandId)
        .where('isActive', isEqualTo: true)
        .get();
  }

  /// الحصول على المنتجات منخفضة المخزون
  Future<QuerySnapshot<Map<String, dynamic>>> getLowStockProducts() async {
    return productsCollection
        .where('isActive', isEqualTo: true)
        .where('isLowStock', isEqualTo: true)
        .get();
  }
}
