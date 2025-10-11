import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/neon_database_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = true;
  String _statusMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_isLoginMode) {
      if (value == null || value.isEmpty) {
        return 'يرجى تأكيد كلمة المرور';
      }
      if (value != _passwordController.text) {
        return 'كلمة المرور غير متطابقة';
      }
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLoginMode) {
        // تسجيل الدخول
        final response = await NeonDatabaseService.loginUser(email, password);
        if (response['success'] == true) {
          final userMap = response['user'] as Map<String, dynamic>;
          await AuthService.saveLoginSession(
            userId: userMap['id'],
            email: userMap['email'],
          );
          setState(() {
            _statusMessage = 'مرحباً $email!';
          });

          // انتظار قصير لعرض الرسالة
          await Future.delayed(const Duration(milliseconds: 500));

          // استدعاء callback للانتقال إلى الصفحة الرئيسية
          if (widget.onLoginSuccess != null) {
            widget.onLoginSuccess!();
          }
        } else {
          setState(() {
            _statusMessage =
                response['message'] ??
                'البريد الإلكتروني أو كلمة المرور غير صحيحة';
          });
        }
      } else {
        // تسجيل مستخدم جديد
        final response = await NeonDatabaseService.registerUser(
          email,
          password,
        );
        if (response['success'] == true) {
          final userMap = response['user'] as Map<String, dynamic>;
          await AuthService.saveLoginSession(
            userId: userMap['id'],
            email: userMap['email'],
          );
          setState(() {
            _statusMessage = 'تم تسجيل المستخدم بنجاح! مرحباً $email!';
          });

          // انتظار قصير لعرض الرسالة
          await Future.delayed(const Duration(milliseconds: 1000));

          // استدعاء callback للانتقال إلى الصفحة الرئيسية
          if (widget.onLoginSuccess != null) {
            widget.onLoginSuccess!();
          }
        } else {
          setState(() {
            _statusMessage = response['message'] ?? 'فشل في تسجيل المستخدم';
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ في الاتصال: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _statusMessage = '';
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          _isLoginMode ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // شعار أو أيقونة
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        spreadRadius: 5,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 40),

                // عنوان
                Text(
                  _isLoginMode ? 'مرحباً بعودتك!' : 'أنشئ حسابك الآن',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _isLoginMode
                      ? 'سجل دخولك للوصول إلى حسابك'
                      : 'املأ البيانات أدناه لإنشاء حساب جديد',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),

                const SizedBox(height: 40),

                // حقل البريد الإلكتروني
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'example@gmail.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: _validateEmail,
                ),

                const SizedBox(height: 20),

                // حقل كلمة المرور
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    hintText: 'أدخل كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: _validatePassword,
                ),

                // حقل تأكيد كلمة المرور (فقط في وضع التسجيل)
                if (!_isLoginMode) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      hintText: 'أعد إدخال كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: _validateConfirmPassword,
                  ),
                ],

                const SizedBox(height: 30),

                // زر الإرسال
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isLoginMode ? 'تسجيل الدخول' : 'إنشاء الحساب',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // رسالة الحالة
                if (_statusMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color:
                          _statusMessage.contains('خطأ') ||
                              _statusMessage.contains('غير صحيحة')
                          ? Colors.red[50]
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _statusMessage.contains('خطأ') ||
                                _statusMessage.contains('غير صحيحة')
                            ? Colors.red[300]!
                            : Colors.green[300]!,
                      ),
                    ),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _statusMessage.contains('خطأ') ||
                                _statusMessage.contains('غير صحيحة')
                            ? Colors.red[700]
                            : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                // رابط التبديل بين تسجيل الدخول والتسجيل
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLoginMode ? 'ليس لديك حساب؟ ' : 'لديك حساب بالفعل؟ ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: _toggleMode,
                      child: Text(
                        _isLoginMode ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
