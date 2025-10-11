// test_create_users_table.dart
import 'lib/services/neon_database_service.dart';

void main() async {
  print('🚀 بدء اختبار إنشاء جدول المستخدمين...\n');

  try {
    // إنشاء جدول المستخدمين
    final success = await NeonDatabaseService.createUsersTable();

    if (success) {
      print('\n🎉 نجح إنشاء جدول المستخدمين!');
      print('يمكنك الآن التحقق من وجود الجدول في Neon Dashboard');
    } else {
      print('\n❌ فشل في إنشاء جدول المستخدمين.');
    }

    // إغلاق الاتصال
    await NeonDatabaseService.disconnect();
  } catch (e) {
    print('\n💥 خطأ غير متوقع: $e');
  }

  print('\n✅ انتهى اختبار إنشاء الجدول.');
}
