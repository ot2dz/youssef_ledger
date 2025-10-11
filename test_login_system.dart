// test_login_system.dart - اختبار تسجيل الدخول
import 'dart:io';
import 'lib/services/neon_database_service.dart';

void main() async {
  try {
    print('\n🔧 بدء اختبار نظام تسجيل الدخول...\n');

    // اختبار تسجيل الدخول بالمستخدم الموجود
    print('🔑 اختبار تسجيل الدخول بالمستخدم test@example.com...');
    final loginResult = await NeonDatabaseService.loginUser(
      'test@example.com',
      'test123',
    );

    if (loginResult['success']) {
      print('✅ تم تسجيل الدخول بنجاح!');
      print('📧 البريد الإلكتروني: ${loginResult['user']['email']}');
      print('🆔 الرقم التعريفي: ${loginResult['user']['id']}');
      print('📅 تاريخ الإنشاء: ${loginResult['user']['created_at']}');
    } else {
      print('❌ فشل تسجيل الدخول: ${loginResult['message']}');
    }

    print('\n' + '=' * 50);

    // اختبار تسجيل دخول بكلمة مرور خاطئة
    print('\n🔐 اختبار تسجيل الدخول بكلمة مرور خاطئة...');
    final wrongPasswordResult = await NeonDatabaseService.loginUser(
      'test@example.com',
      'wrongpassword',
    );

    if (!wrongPasswordResult['success']) {
      print('✅ تم رفض الدخول بكلمة المرور الخاطئة (كما هو متوقع)');
      print('📝 الرسالة: ${wrongPasswordResult['message']}');
    } else {
      print('❌ خطأ: يجب رفض الدخول بكلمة مرور خاطئة!');
    }

    print('\n' + '=' * 50);

    // اختبار تسجيل دخول بإيميل غير موجود
    print('\n📧 اختبار تسجيل الدخول بإيميل غير موجود...');
    final nonExistentResult = await NeonDatabaseService.loginUser(
      'nonexistent@example.com',
      'anypassword',
    );

    if (!nonExistentResult['success']) {
      print('✅ تم رفض الدخول بإيميل غير موجود (كما هو متوقع)');
      print('📝 الرسالة: ${nonExistentResult['message']}');
    } else {
      print('❌ خطأ: يجب رفض الدخول بإيميل غير موجود!');
    }

    print('\n🎉 انتهى اختبار نظام تسجيل الدخول بنجاح!');
  } catch (e) {
    print('❌ خطأ في الاختبار: $e');
    exit(1);
  }
}
