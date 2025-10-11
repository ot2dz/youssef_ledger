// test_register_user.dart
import 'lib/services/neon_database_service.dart';

void main() async {
  print('🚀 بدء اختبار تسجيل مستخدم جديد...\n');

  try {
    // بيانات المستخدم للاختبار
    const testEmail = 'test@example.com';
    const testPassword = 'password123';

    print('📧 البريد الإلكتروني: $testEmail');
    print('🔒 كلمة المرور: $testPassword\n');

    // تسجيل مستخدم جديد
    final result = await NeonDatabaseService.registerUser(
      testEmail,
      testPassword,
    );

    if (result['success']) {
      print('🎉 نجح تسجيل المستخدم!');
      print('📄 تفاصيل المستخدم:');
      final user = result['user'];
      print('   - ID: ${user['id']}');
      print('   - البريد الإلكتروني: ${user['email']}');
      print('   - تاريخ التسجيل: ${user['created_at']}');
    } else {
      print('❌ فشل في تسجيل المستخدم: ${result['message']}');
    }

    // اختبار تسجيل نفس المستخدم مرة أخرى (يجب أن يفشل)
    print('\n🔄 اختبار تسجيل نفس البريد مرة أخرى...');
    final duplicateResult = await NeonDatabaseService.registerUser(
      testEmail,
      testPassword,
    );

    if (!duplicateResult['success']) {
      print(
        '✅ النظام يمنع التسجيل المكرر بنجاح: ${duplicateResult['message']}',
      );
    } else {
      print('❌ مشكلة: النظام سمح بالتسجيل المكرر!');
    }

    // إغلاق الاتصال
    await NeonDatabaseService.disconnect();
  } catch (e) {
    print('\n💥 خطأ غير متوقع: $e');
  }

  print('\n✅ انتهى اختبار تسجيل المستخدم.');
}
