// test_create_backup_table.dart - اختبار إنشاء جدول النسخ الاحتياطية
import 'dart:io';
import 'lib/services/neon_database_service.dart';

void main() async {
  try {
    print('\n🔧 بدء اختبار إنشاء جدول النسخ الاحتياطية...\n');

    // اختبار الاتصال
    print('🔗 اختبار الاتصال بقاعدة البيانات...');
    final connectionTest = await NeonDatabaseService.testConnection();
    if (!connectionTest) {
      print('❌ فشل في الاتصال بقاعدة البيانات');
      exit(1);
    }

    print('\n' + '=' * 50);

    // إنشاء جدول النسخ الاحتياطية
    print('\n🗂️ إنشاء جدول النسخ الاحتياطية...');
    final tableCreated = await NeonDatabaseService.createBackupTable();

    if (tableCreated) {
      print('✅ تم إنشاء جدول backup_data بنجاح!');
    } else {
      print('❌ فشل في إنشاء جدول backup_data');
      exit(1);
    }

    print('\n🎉 انتهى الاختبار بنجاح! جدول النسخ الاحتياطية جاهز للاستخدام.');
  } catch (e) {
    print('❌ خطأ في الاختبار: $e');
    exit(1);
  }
}
