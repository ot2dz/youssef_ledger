// test_data_export.dart - اختبار تصدير البيانات المحلية
import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/services/local_data_export_service.dart';
import 'lib/data/local/database_helper.dart';
import 'lib/data/models/party.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('\n🔧 بدء اختبار تصدير البيانات المحلية...\n');

    // التأكد من وجود بيانات تجريبية
    await _ensureTestData();

    print('\n' + '=' * 50);

    // 1. اختبار تصدير بيانات الأطراف
    print('\n📊 اختبار تصدير بيانات الأطراف...');
    final partiesData = await LocalDataExportService.exportPartiesData();

    print('✅ تم تصدير البيانات بنجاح!');
    print('📈 الإحصائيات:');
    print('- عدد الأطراف: ${partiesData['statistics']['total_parties']}');
    print('- عدد الأشخاص: ${partiesData['statistics']['persons_count']}');
    print('- عدد الموردين: ${partiesData['statistics']['vendors_count']}');
    print(
      '- عدد المعاملات: ${partiesData['statistics']['total_transactions']}',
    );

    // حساب حجم البيانات
    final partiesSize = LocalDataExportService.estimateDataSize(partiesData);
    print('📏 حجم البيانات التقديري: $partiesSize بايت');

    print('\n' + '=' * 50);

    // 2. اختبار تصدير بيانات النظام
    print('\n⚙️ اختبار تصدير بيانات النظام...');
    final systemData = await LocalDataExportService.exportSystemData();

    print('✅ تم تصدير بيانات النظام بنجاح!');
    print('🔧 الإعدادات: ${systemData['settings']?.keys.length ?? 0}');
    print(
      '📁 فئات المصروفات: ${(systemData['categories']['expense'] as List?)?.length ?? 0}',
    );
    print(
      '📁 فئات الدخل: ${(systemData['categories']['income'] as List?)?.length ?? 0}',
    );

    final systemSize = LocalDataExportService.estimateDataSize(systemData);
    print('📏 حجم بيانات النظام: $systemSize بايت');

    print('\n' + '=' * 50);

    // 3. اختبار التصدير الشامل
    print('\n🎯 اختبار التصدير الشامل...');
    final fullData = await LocalDataExportService.exportAllData();

    print('✅ تم التصدير الشامل بنجاح!');
    final fullSize = LocalDataExportService.estimateDataSize(fullData);
    print('📏 حجم البيانات الكاملة: $fullSize بايت');

    // تحسين البيانات
    final optimizedData = LocalDataExportService.optimizeExportData(fullData);
    final optimizedSize = LocalDataExportService.estimateDataSize(
      optimizedData,
    );
    print('🗜️ حجم البيانات المحسنة: $optimizedSize بايت');
    print(
      '📉 نسبة التحسين: ${((fullSize - optimizedSize) / fullSize * 100).toStringAsFixed(1)}%',
    );

    print('\n' + '=' * 50);

    // 4. اختبار تصدير حسب نوع الطرف
    print('\n👥 اختبار تصدير الأشخاص فقط...');
    final personsData = await LocalDataExportService.exportPartiesByRole(
      PartyRole.person,
    );
    print('✅ تم تصدير بيانات الأشخاص: ${personsData['count']} شخص');

    print('\n🏪 اختبار تصدير الموردين فقط...');
    final vendorsData = await LocalDataExportService.exportPartiesByRole(
      PartyRole.vendor,
    );
    print('✅ تم تصدير بيانات الموردين: ${vendorsData['count']} مورد');

    print('\n🎉 انتهت جميع اختبارات التصدير بنجاح!');

    // عرض نموذج من البيانات المصدرة
    print('\n📋 نموذج من البيانات المصدرة:');
    final sample = _createSampleOutput(fullData);
    print(sample);
  } catch (e) {
    print('❌ خطأ في الاختبار: $e');
    exit(1);
  }
}

/// إنشاء بيانات تجريبية إذا لم تكن موجودة
Future<void> _ensureTestData() async {
  try {
    print('🔍 التحقق من وجود بيانات تجريبية...');

    final persons = await DatabaseHelper.instance.getPersons();
    final vendors = await DatabaseHelper.instance.getVendors();

    if (persons.isEmpty && vendors.isEmpty) {
      print('📝 إنشاء بيانات تجريبية...');

      // إضافة أشخاص تجريبيين
      await DatabaseHelper.instance.createPerson(
        'أحمد محمد',
        phone: '123456789',
      );
      await DatabaseHelper.instance.createPerson(
        'فاطمة علي',
        phone: '987654321',
      );

      // إضافة موردين تجريبيين
      await DatabaseHelper.instance.createVendor(
        'مورد الأقمشة الذهبية',
        phone: '555000111',
      );
      await DatabaseHelper.instance.createVendor(
        'شركة النسيج المتقدم',
        phone: '555000222',
      );

      print('✅ تم إنشاء البيانات التجريبية');
    } else {
      print(
        '✅ البيانات التجريبية متوفرة: ${persons.length} أشخاص، ${vendors.length} موردين',
      );
    }
  } catch (e) {
    print('❌ خطأ في إنشاء البيانات التجريبية: $e');
  }
}

/// إنشاء نموذج مبسط للعرض
String _createSampleOutput(Map<String, dynamic> fullData) {
  final buffer = StringBuffer();

  try {
    final exportInfo = fullData['export_info'];
    buffer.writeln('تاريخ التصدير: ${exportInfo['export_date']}');
    buffer.writeln('نوع التصدير: ${exportInfo['export_type']}');

    final partiesData = fullData['parties_data'];
    if (partiesData != null) {
      final statistics = partiesData['statistics'];
      buffer.writeln('إجمالي الأطراف: ${statistics['total_parties']}');
      buffer.writeln('إجمالي المعاملات: ${statistics['total_transactions']}');
    }

    final systemData = fullData['system_data'];
    if (systemData != null) {
      final settings = systemData['settings'] as Map?;
      if (settings != null) {
        buffer.writeln('الإعدادات المحفوظة: ${settings.keys.join(', ')}');
      }
    }
  } catch (e) {
    buffer.writeln('خطأ في إنشاء النموذج: $e');
  }

  return buffer.toString();
}
