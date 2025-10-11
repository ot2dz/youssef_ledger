// test_check_user_with_service.dart - فحص بيانات المستخدم بالخدمة
import 'dart:io';
import 'lib/services/neon_database_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() async {
  try {
    print('\n🔧 بدء فحص بيانات المستخدم...\n');

    // حساب التشفير المتوقع لكلمة المرور
    final passwordBytes = utf8.encode('test123');
    final digest = sha256.convert(passwordBytes);
    final expectedHash = digest.toString();

    print('🔐 التشفير المتوقع لكلمة المرور "test123": $expectedHash');

    print('\n' + '=' * 50);

    // محاولة تسجيل مستخدم جديد لاختبار النظام
    print('\n👤 محاولة تسجيل مستخدم جديد للاختبار...');
    final registerResult = await NeonDatabaseService.registerUser(
      'login_test@example.com',
      'test123',
    );

    if (registerResult['success']) {
      print('✅ تم تسجيل المستخدم الاختباري بنجاح!');
      print('🆔 الرقم التعريفي: ${registerResult['userId']}');

      // محاولة تسجيل الدخول بالمستخدم الجديد
      print('\n🔑 محاولة تسجيل الدخول بالمستخدم الجديد...');
      final loginResult = await NeonDatabaseService.loginUser(
        'login_test@example.com',
        'test123',
      );

      if (loginResult['success']) {
        print('✅ تم تسجيل الدخول بنجاح!');
        print('📧 البريد الإلكتروني: ${loginResult['user']['email']}');
        print('🆔 الرقم التعريفي: ${loginResult['user']['id']}');
      } else {
        print('❌ فشل تسجيل الدخول: ${loginResult['message']}');
      }
    } else {
      print('❌ فشل تسجيل المستخدم: ${registerResult['message']}');

      // إذا فشل التسجيل بسبب وجود المستخدم، جرب تسجيل الدخول
      if (registerResult['message'].contains('موجود')) {
        print('\n🔑 المستخدم موجود، محاولة تسجيل الدخول...');
        final loginResult = await NeonDatabaseService.loginUser(
          'login_test@example.com',
          'test123',
        );

        if (loginResult['success']) {
          print('✅ تم تسجيل الدخول بنجاح!');
          print('📧 البريد الإلكتروني: ${loginResult['user']['email']}');
          print('🆔 الرقم التعريفي: ${loginResult['user']['id']}');
        } else {
          print('❌ فشل تسجيل الدخول: ${loginResult['message']}');
        }
      }
    }

    print('\n🎉 انتهى الاختبار!');
  } catch (e) {
    print('❌ خطأ في الاختبار: $e');
    exit(1);
  }
}
