// test_backup_functions.dart - اختبار وظائف النسخ الاحتياطي
import 'dart:io';
import 'lib/services/neon_database_service.dart';

void main() async {
  try {
    print('\n🔧 بدء اختبار وظائف النسخ الاحتياطي...\n');

    // بيانات تجريبية للنسخ الاحتياطي
    final testUserId =
        'f71329d3-504f-4515-bb69-e1efc27d470c'; // المستخدم المُنشأ سابقاً
    final testData = {
      'parties': [
        {'id': 1, 'name': 'أحمد محمد', 'phone': '123456789'},
        {'id': 2, 'name': 'فاطمة علي', 'phone': '987654321'},
      ],
      'transactions': [
        {'id': 1, 'party_id': 1, 'amount': 1500, 'type': 'income'},
        {'id': 2, 'party_id': 2, 'amount': 800, 'type': 'expense'},
      ],
      'export_date': DateTime.now().toIso8601String(),
    };

    print('📦 البيانات التجريبية جاهزة:');
    print('- عدد الأطراف: ${(testData['parties'] as List).length}');
    print('- عدد المعاملات: ${(testData['transactions'] as List).length}');

    print('\n' + '=' * 50);

    // 1. إنشاء نسخة احتياطية
    print('\n💾 إنشاء نسخة احتياطية...');
    final backupResult = await NeonDatabaseService.createBackup(
      testUserId,
      'parties_backup',
      testData,
      deviceInfo: 'iOS Simulator - Test Device',
    );

    if (backupResult['success']) {
      print('✅ تم إنشاء النسخة الاحتياطية بنجاح!');
      print('🆔 معرف النسخة: ${backupResult['backup_id']}');
      print('📅 تاريخ النسخة: ${backupResult['backup_date']}');
      print('📏 حجم النسخة: ${backupResult['backup_size']} بايت');
    } else {
      print('❌ فشل في إنشاء النسخة الاحتياطية: ${backupResult['message']}');
      exit(1);
    }

    print('\n' + '=' * 50);

    // 2. استرجاع النسخة الاحتياطية الأحدث
    print('\n📥 استرجاع النسخة الاحتياطية الأحدث...');
    final latestBackup = await NeonDatabaseService.getLatestBackup(
      testUserId,
      backupType: 'parties_backup',
    );

    if (latestBackup['success']) {
      final backup = latestBackup['backup'];
      print('✅ تم العثور على النسخة الاحتياطية!');
      print('🆔 معرف النسخة: ${backup['id']}');
      print('📅 تاريخ النسخة: ${backup['backup_date']}');
      print('📏 حجم النسخة: ${backup['backup_size']} بايت');
      print('🔍 نوع النسخة: ${backup['backup_type']}');

      // التحقق من صحة البيانات المسترجعة
      final retrievedData = backup['data'];
      final partiesCount = retrievedData['parties']?.length ?? 0;
      final transactionsCount = retrievedData['transactions']?.length ?? 0;

      print('📊 محتوى النسخة المسترجعة:');
      print('- عدد الأطراف: $partiesCount');
      print('- عدد المعاملات: $transactionsCount');

      if (partiesCount == 2 && transactionsCount == 2) {
        print('✅ تم استرجاع البيانات بشكل صحيح!');
      } else {
        print('❌ البيانات المسترجعة غير صحيحة!');
      }
    } else {
      print('❌ فشل في استرجاع النسخة الاحتياطية: ${latestBackup['message']}');
    }

    print('\n' + '=' * 50);

    // 3. الحصول على قائمة جميع النسخ الاحتياطية
    print('\n📋 استرجاع قائمة جميع النسخ الاحتياطية...');
    final backupsList = await NeonDatabaseService.getUserBackups(testUserId);

    if (backupsList['success']) {
      print('✅ تم العثور على ${backupsList['count']} نسخة احتياطية');

      final backups = backupsList['backups'] as List;
      for (int i = 0; i < backups.length; i++) {
        final backup = backups[i];
        print('📦 النسخة ${i + 1}:');
        print('   - المعرف: ${backup['id']}');
        print('   - النوع: ${backup['backup_type']}');
        print('   - التاريخ: ${backup['backup_date']}');
        print('   - الجهاز: ${backup['device_info']}');
        print('   - الحجم: ${backup['backup_size']} بايت');
      }
    } else {
      print(
        '❌ فشل في استرجاع قائمة النسخ الاحتياطية: ${backupsList['message']}',
      );
    }

    print('\n🎉 انتهى اختبار وظائف النسخ الاحتياطي بنجاح!');
  } catch (e) {
    print('❌ خطأ في الاختبار: $e');
    exit(1);
  }
}
