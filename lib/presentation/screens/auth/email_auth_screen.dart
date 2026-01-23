import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wholesale_shoes_invoice/core/services/auth_service.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_colors.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isLogin = true; // true = تسجيل دخول، false = إنشاء حساب
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_isLogin) {
      if (value == null || value.isEmpty) {
        return 'الرجاء تأكيد كلمة المرور';
      }
      if (value != _passwordController.text) {
        return 'كلمة المرور غير متطابقة';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      bool success;
      if (_isLogin) {
        success = await _authService.signInWithEmail(
          email: email,
          password: password,
        );
      } else {
        success = await _authService.createAccountWithEmail(
          email: email,
          password: password,
        );

        // إنشاء document للمستخدم في Firestore
        if (success) {
          final userId = _authService.currentUserId;
          if (userId != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .set({
              'email': email,
              'approved': false,
              'approvalCode': null, // يمكن تعيينه من Firebase Console
              'createdAt': FieldValue.serverTimestamp(),
              'createdBy': userId,
            });
          }
        }
      }

      if (success && mounted) {
        // نجح - الانتقال لشاشة الموافقة
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => _PendingApprovalScreen(
              email: email,
            ),
          ),
        );
      } else {
        _showError(_isLogin ? 'فشل تسجيل الدخول' : 'فشل إنشاء الحساب');
      }
    } catch (e) {
      _showError('حدث خطأ غير متوقع');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('الرجاء إدخال البريد الإلكتروني أولاً');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('البريد الإلكتروني غير صحيح');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authService.sendPasswordResetEmail(email);
      if (success && mounted) {
        _showSuccess('تم إرسال رابط إعادة تعيين كلمة المرور');
      } else {
        _showError('فشل إرسال رابط إعادة التعيين');
      }
    } catch (e) {
      _showError('حدث خطأ');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo أو أيقونة
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.blue600.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 50,
                    color: AppColors.blue600,
                  ),
                ),

                const SizedBox(height: 32),

                // العنوان
                Text(
                  _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  _isLogin
                      ? 'أدخل بريدك الإلكتروني وكلمة المرور'
                      : 'أنشئ حسابك الجديد للبدء',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // حقل البريد الإلكتروني
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  validator: _validateEmail,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'example@email.com',
                    hintTextDirection: TextDirection.ltr,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.blue600,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // حقل كلمة المرور
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    hintText: '••••••••',
                    hintTextDirection: TextDirection.ltr,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.blue600,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // حقل تأكيد كلمة المرور (عند إنشاء حساب جديد)
                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textDirection: TextDirection.ltr,
                    validator: _validateConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      hintText: '••••••••',
                      hintTextDirection: TextDirection.ltr,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword =
                              !_obscureConfirmPassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.blue600,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],

                // نسيت كلمة المرور (عند تسجيل الدخول)
                if (_isLogin) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      child: const Text(
                        'نسيت كلمة المرور؟',
                        style: TextStyle(
                          color: AppColors.blue600,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // زر تسجيل الدخول / إنشاء حساب
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // التبديل بين تسجيل الدخول وإنشاء حساب
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? 'ليس لديك حساب؟' : 'لديك حساب بالفعل؟',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _formKey.currentState?.reset();
                                _confirmPasswordController.clear();
                              });
                            },
                      child: Text(
                        _isLogin ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                        style: const TextStyle(
                          color: AppColors.blue600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ملاحظة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'سيتم مراجعة حسابك والموافقة عليه قبل استخدام التطبيق',
                          style: TextStyle(
                            color: AppColors.info,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// شاشة انتظار الموافقة
// ═══════════════════════════════════════════════════════════

class _PendingApprovalScreen extends StatefulWidget {
  final String email;

  const _PendingApprovalScreen({
    required this.email,
  });

  @override
  State<_PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<_PendingApprovalScreen> {
  final _approvalCodeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isCheckingApproval = false;

  @override
  void initState() {
    super.initState();
    _checkApprovalStatus();
  }

  @override
  void dispose() {
    _approvalCodeController.dispose();
    super.dispose();
  }

  /// التحقق التلقائي من حالة الموافقة
  Future<void> _checkApprovalStatus() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    setState(() => _isCheckingApproval = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final approved = userDoc.data()?['approved'] ?? false;

        if (approved && mounted) {
          // تمت الموافقة - الانتقال للصفحة الرئيسية
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      // تجاهل الأخطاء في التحقق التلقائي
    } finally {
      if (mounted) {
        setState(() => _isCheckingApproval = false);
      }
    }
  }

  /// التحقق من رمز الموافقة
  Future<void> _verifyApprovalCode() async {
    final code = _approvalCodeController.text.trim();
    final userId = _authService.currentUserId;

    if (code.isEmpty) {
      _showError('الرجاء إدخال رمز الموافقة');
      return;
    }

    if (userId == null) {
      _showError('خطأ في معرف المستخدم');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        _showError('لم يتم العثور على بيانات المستخدم');
        return;
      }

      final data = userDoc.data()!;
      final approved = data['approved'] ?? false;
      final storedCode = data['approvalCode'];

      // التحقق من الموافقة المباشرة
      if (approved) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      }

      // التحقق من رمز الموافقة
      if (storedCode != null && storedCode.toString() == code) {
        // تحديث حالة الموافقة
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'approved': true});

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showError('رمز الموافقة غير صحيح');
      }
    } catch (e) {
      _showError('حدث خطأ في التحقق من الرمز');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // أيقونة انتظار
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty,
                  size: 60,
                  color: AppColors.warning,
                ),
              ),

              const SizedBox(height: 32),

              // العنوان
              const Text(
                'في انتظار الموافقة',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'تم تسجيلك بنجاح باستخدام:\n${widget.email}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // معلومات
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 48,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'حسابك قيد المراجعة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أدخل رمز الموافقة الذي حصلت عليه من المسؤول',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // حقل رمز الموافقة
              TextField(
                controller: _approvalCodeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '••••',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.blue600,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // زر التحقق
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyApprovalCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'تأكيد رمز الموافقة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // زر تسجيل الخروج
              TextButton.icon(
                onPressed: _logout,
                icon: const Icon(
                  Icons.logout,
                  color: AppColors.error,
                ),
                label: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: AppColors.error,
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
