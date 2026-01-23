import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// خدمة المصادقة - للحصول على معرف المستخدم الحالي
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  /// الحصول على معرف المستخدم الحالي (Firebase فقط)
  String? get currentUserId => _auth.currentUser?.uid;

  /// التحقق من تسجيل الدخول بـ Firebase (مصادقة حقيقية)
  bool get isLoggedIn => _auth.currentUser != null;

  /// التحقق من أن المستخدم مسجل بالإيميل
  bool get isEmailAuthenticated => _auth.currentUser?.email != null;

  /// الحصول على إيميل المستخدم
  String? get userEmail => _auth.currentUser?.email;

  /// مراقبة حالة المصادقة
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ═══════════════════════════════════════════════════════════
  // EMAIL AUTHENTICATION
  // ═══════════════════════════════════════════════════════════

  /// تسجيل الدخول بالإيميل وكلمة المرور
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Signed in with email: ${credential.user?.uid}');
      return credential.user != null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Email sign in failed: ${e.code} - ${e.message}');
      throw _getEmailAuthErrorMessage(e.code);
    } catch (e) {
      debugPrint('❌ Email sign in error: $e');
      throw 'حدث خطأ في تسجيل الدخول';
    }
  }

  /// إنشاء حساب جديد بالإيميل وكلمة المرور
  Future<bool> createAccountWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Account created with email: ${credential.user?.uid}');
      return credential.user != null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Account creation failed: ${e.code} - ${e.message}');
      throw _getEmailAuthErrorMessage(e.code);
    } catch (e) {
      debugPrint('❌ Account creation error: $e');
      throw 'حدث خطأ في إنشاء الحساب';
    }
  }

  /// إرسال رابط إعادة تعيين كلمة المرور
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent to: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Password reset failed: ${e.code}');
      throw _getEmailAuthErrorMessage(e.code);
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      throw 'حدث خطأ في إرسال رابط إعادة التعيين';
    }
  }

  /// ترجمة رسائل أخطاء الإيميل
  String _getEmailAuthErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'هذا الحساب معطل';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مسجل مسبقاً';
      case 'operation-not-allowed':
        return 'تسجيل الدخول بالإيميل غير مفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'too-many-requests':
        return 'محاولات كثيرة جداً. الرجاء المحاولة لاحقاً';
      case 'network-request-failed':
        return 'لا يوجد اتصال بالإنترنت';
      default:
        return 'حدث خطأ غير متوقع';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ANONYMOUS AUTHENTICATION (Fallback)
  // ═══════════════════════════════════════════════════════════

  /// تسجيل الدخول مجهول (للتطوير فقط - غير مستخدم)
  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      debugPrint('✅ Signed in anonymously: ${credential.user?.uid}');
      return credential;
    } catch (e) {
      debugPrint('⚠️ Anonymous sign in failed: $e');
      debugPrint('💡 يجب تسجيل الدخول بالهاتف');
      return null;
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('👋 User signed out');
  }

  /// التأكد من وجود مستخدم مصادق عليه
  /// يُرجع true إذا كان المستخدم مسجل دخول بـ Firebase
  bool get isAuthenticated => _auth.currentUser != null;

  /// التأكد من المصادقة - يُرجع userId أو null
  Future<String?> ensureAuthenticated() async {
    // فقط نتحقق من وجود مستخدم Firebase حقيقي
    return currentUserId;
  }
}
