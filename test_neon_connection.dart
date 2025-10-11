// test_neon_connection.dart
import 'lib/services/neon_database_service.dart';

void main() async {
  print('🚀 بدء اختبار الاتصال بقاعدة بيانات Neon...\n');

  try {
    // اختبار الاتصال
    final success = await NeonDatabaseService.testConnection();

    if (success) {
      print('\n🎉 نجح الاختبار! يمكننا الاتصال بقاعدة البيانات.');
    } else {
      print('\n❌ فشل الاختبار. تحقق من إعدادات الاتصال.');
    }

    // إغلاق الاتصال
    await NeonDatabaseService.disconnect();
  } catch (e) {
    print('\n💥 خطأ غير متوقع: $e');
  }

  print('\n✅ انتهى الاختبار.');
}
