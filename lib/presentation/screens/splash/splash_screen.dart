import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/providers/providers.dart';
import 'package:wholesale_shoes_invoice/core/services/auth_service.dart';

/// شاشة البداية مع المزامنة الأولية
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _statusMessage = 'جاري التحميل...';
  bool _isError = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthAndSync();
  }

  Future<void> _checkAuthAndSync() async {
    // التحقق من وجود مستخدم Firebase حقيقي (ليس deviceId)
    final firebaseUser = _authService.currentUser;

    if (firebaseUser == null) {
      // لا يوجد مستخدم Firebase حقيقي → انتقل لتسجيل الدخول
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToLogin();
      return;
    }

    // يوجد مستخدم مصادق عليه → متابعة المزامنة
    _performInitialSync();
  }

  Future<void> _performInitialSync() async {
    final enableFirestore = ref.read(enableFirestoreProvider);

    if (!enableFirestore) {
      // إذا Firestore غير مُفعّل، انتقل للصفحة الرئيسية مباشرة
      _navigateToHome();
      return;
    }

    setState(() {
      _statusMessage = 'جاري مزامنة البيانات...';
    });

    try {
      final syncService = ref.read(initialSyncServiceProvider);
      final result = await syncService.performInitialSync();

      if (result.success) {
        setState(() {
          _statusMessage = 'تم مزامنة ${result.totalSynced} عنصر';
        });

        // بدء الاستماع للتحديثات في الوقت الحقيقي
        ref.read(realtimeSyncServiceProvider).startListening();

        // انتظار قليلاً لعرض الرسالة
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToHome();
      } else {
        setState(() {
          _statusMessage = result.message;
          _isError = true;
        });

        // حتى لو فشلت المزامنة، انتقل للصفحة الرئيسية
        await Future.delayed(const Duration(seconds: 2));
        _navigateToHome();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ في المزامنة';
        _isError = true;
      });

      await Future.delayed(const Duration(seconds: 2));
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة التطبيق
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              // اسم التطبيق
              const Text(
                'نظام الفواتير',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'إدارة فواتير الجملة',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 48),

              // مؤشر التحميل
              if (!_isError)
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              if (_isError)
                Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: Colors.orange.shade300,
                ),
              const SizedBox(height: 24),

              // رسالة الحالة
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: _isError ? Colors.orange.shade300 : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              // زر إعادة المحاولة
              if (_isError)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isError = false;
                        _statusMessage = 'جاري إعادة المحاولة...';
                      });
                      _performInitialSync();
                    },
                    child: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
