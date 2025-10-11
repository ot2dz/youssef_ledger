// test_cleanup_duplicates.dart
import 'package:flutter/material.dart';
import 'lib/data/local/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 بدء تنظيف البيانات المكررة...');

  try {
    final db = DatabaseHelper.instance;

    // عرض إحصائيات قبل التنظيف
    final beforeCleanup = await db.database;
    final categoriesCountBefore = await beforeCleanup.rawQuery(
      'SELECT COUNT(*) as count FROM categories',
    );
    final totalBefore = categoriesCountBefore.first['count'] as int;

    print('📊 عدد الفئات قبل التنظيف: $totalBefore');

    // تشغيل عملية التنظيف
    await db.cleanupDuplicateData();

    // عرض إحصائيات بعد التنظيف
    final categoriesCountAfter = await beforeCleanup.rawQuery(
      'SELECT COUNT(*) as count FROM categories',
    );
    final totalAfter = categoriesCountAfter.first['count'] as int;

    print('📊 عدد الفئات بعد التنظيف: $totalAfter');
    print('🗑️ تم حذف ${totalBefore - totalAfter} فئة مكررة');

    print('✅ تم الانتهاء من التنظيف بنجاح!');
  } catch (e) {
    print('❌ خطأ في عملية التنظيف: $e');
  }
}
