// lib/presentation/screens/app_wrapper.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'main_layout.dart';

/// وسيط التطبيق للتحكم في التنقل بناءً على حالة تسجيل الدخول
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  /// التحقق من حالة المصادقة
  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  /// التنقل إلى التطبيق الرئيسي بعد تسجيل الدخول بنجاح
  void _onLoginSuccess(String userId, String email) {
    setState(() {
      _isLoggedIn = true;
    });
  }

  /// تسجيل الخروج والعودة لشاشة تسجيل الدخول
  Future<void> _onLogout() async {
    await AuthService.logout();
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    if (_isLoggedIn) {
      return MainLayout(onLogout: () => _onLogout());
    } else {
      return LoginScreen(onLoginSuccess: () => _onLoginSuccess('', ''));
    }
  }
}
