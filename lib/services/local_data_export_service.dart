// lib/services/local_data_export_service.dart
import 'dart:convert';
import '../data/local/database_helper.dart';
import '../data/models/party.dart';

/// خدمة تصدير البيانات المحلية من SQLite إلى JSON
class LocalDataExportService {
  /// تصدير جميع بيانات الأطراف إلى JSON
  static Future<Map<String, dynamic>> exportPartiesData() async {
    try {
      // الحصول على جميع الأشخاص والموردين
      final persons = await DatabaseHelper.instance.getPersons();
      final vendors = await DatabaseHelper.instance.getVendors();

      // تحويل البيانات إلى Map
      final List<Map<String, dynamic>> allParties = [];

      // إضافة الأشخاص
      for (final person in persons) {
        final partyData = person.toMap();

        // الحصول على الإحصائيات
        final stats = await DatabaseHelper.instance.getPartyStats(person.id!);

        // الحصول على تاريخ المعاملات
        final debtEntries = await DatabaseHelper.instance
            .getDebtEntriesForParty(person.id!);
        final debtEntriesData = debtEntries
            .map((entry) => entry.toMap())
            .toList();

        allParties.add({
          ...partyData,
          'balance': stats['balance'],
          'transaction_count': stats['transactionCount'],
          'last_transaction_date': stats['lastTransactionDate']
              ?.toIso8601String(),
          'debt_entries': debtEntriesData,
        });
      }

      // إضافة الموردين
      for (final vendor in vendors) {
        final partyData = vendor.toMap();

        // الحصول على الإحصائيات
        final stats = await DatabaseHelper.instance.getPartyStats(vendor.id!);

        // الحصول على تاريخ المعاملات
        final debtEntries = await DatabaseHelper.instance
            .getDebtEntriesForParty(vendor.id!);
        final debtEntriesData = debtEntries
            .map((entry) => entry.toMap())
            .toList();

        allParties.add({
          ...partyData,
          'balance': stats['balance'],
          'transaction_count': stats['transactionCount'],
          'last_transaction_date': stats['lastTransactionDate']
              ?.toIso8601String(),
          'debt_entries': debtEntriesData,
        });
      }

      // إنشاء النسخة النهائية
      final exportData = {
        'export_info': {
          'export_date': DateTime.now().toIso8601String(),
          'app_version': '1.0.0',
          'data_format': 'youssef_ledger_v1',
        },
        'statistics': {
          'total_parties': allParties.length,
          'persons_count': persons.length,
          'vendors_count': vendors.length,
          'total_transactions': allParties.fold<int>(
            0,
            (sum, party) =>
                sum + ((party['debt_entries'] as List?)?.length ?? 0),
          ),
        },
        'parties': allParties,
      };

      print('📊 تم تصدير البيانات:');
      print('- عدد الأشخاص: ${persons.length}');
      print('- عدد الموردين: ${vendors.length}');
      print('- المجموع: ${allParties.length}');

      return exportData;
    } catch (e) {
      print('❌ خطأ في تصدير البيانات: $e');
      rethrow;
    }
  }

  /// تصدير بيانات محددة بنوع الطرف
  static Future<Map<String, dynamic>> exportPartiesByRole(
    PartyRole role,
  ) async {
    try {
      List<Party> parties;
      if (role == PartyRole.person) {
        parties = await DatabaseHelper.instance.getPersons();
      } else {
        parties = await DatabaseHelper.instance.getVendors();
      }

      final List<Map<String, dynamic>> partiesData = [];

      for (final party in parties) {
        final partyData = party.toMap();
        final stats = await DatabaseHelper.instance.getPartyStats(party.id!);
        final debtEntries = await DatabaseHelper.instance
            .getDebtEntriesForParty(party.id!);

        partiesData.add({
          ...partyData,
          'balance': stats['balance'],
          'transaction_count': stats['transactionCount'],
          'last_transaction_date': stats['lastTransactionDate']
              ?.toIso8601String(),
          'debt_entries': debtEntries.map((entry) => entry.toMap()).toList(),
        });
      }

      return {
        'export_info': {
          'export_date': DateTime.now().toIso8601String(),
          'role_filter': role.toDbString(),
          'data_format': 'youssef_ledger_role_specific_v1',
        },
        'parties': partiesData,
        'count': partiesData.length,
      };
    } catch (e) {
      print('❌ خطأ في تصدير بيانات ${role.toDbString()}: $e');
      rethrow;
    }
  }

  /// تصدير الإعدادات والإحصائيات العامة
  static Future<Map<String, dynamic>> exportSystemData() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // الحصول على الإعدادات
      final settingsResult = await db.query('settings');
      final settings = Map<String, String>.fromEntries(
        settingsResult.map(
          (row) => MapEntry(row['key'] as String, row['value'] as String),
        ),
      );

      // الحصول على الفئات
      final expenseCategories = await DatabaseHelper.instance.getCategories(
        'expense',
      );
      final incomeCategories = await DatabaseHelper.instance.getCategories(
        'income',
      );

      return {
        'export_info': {
          'export_date': DateTime.now().toIso8601String(),
          'data_type': 'system_data',
          'data_format': 'youssef_ledger_system_v1',
        },
        'settings': settings,
        'categories': {
          'expense': expenseCategories.map((cat) => cat.toMap()).toList(),
          'income': incomeCategories.map((cat) => cat.toMap()).toList(),
        },
      };
    } catch (e) {
      print('❌ خطأ في تصدير بيانات النظام: $e');
      rethrow;
    }
  }

  /// تصدير جميع البيانات (شامل)
  static Future<Map<String, dynamic>> exportAllData() async {
    try {
      print('📦 بدء تصدير جميع البيانات...');

      // تصدير بيانات الأطراف
      final partiesData = await exportPartiesData();

      // تصدير بيانات النظام
      final systemData = await exportSystemData();

      // دمج البيانات
      final fullExport = {
        'export_info': {
          'export_date': DateTime.now().toIso8601String(),
          'app_version': '1.0.0',
          'data_format': 'youssef_ledger_full_v1',
          'export_type': 'complete_backup',
        },
        'parties_data': partiesData,
        'system_data': systemData,
        'metadata': {
          'database_version': 8,
          'backup_size_estimate': 'calculated_on_server',
        },
      };

      print('✅ تم تصدير جميع البيانات بنجاح');

      return fullExport;
    } catch (e) {
      print('❌ خطأ في تصدير جميع البيانات: $e');
      rethrow;
    }
  }

  /// حساب حجم البيانات التقديري
  static int estimateDataSize(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return jsonString.length;
  }

  /// تحسين البيانات قبل التصدير (إزالة البيانات غير الضرورية)
  static Map<String, dynamic> optimizeExportData(Map<String, dynamic> data) {
    // إزالة المفاتيح الفارغة أو null
    final optimized = <String, dynamic>{};

    data.forEach((key, value) {
      if (value != null) {
        if (value is Map) {
          final optimizedMap = optimizeExportData(
            value as Map<String, dynamic>,
          );
          if (optimizedMap.isNotEmpty) {
            optimized[key] = optimizedMap;
          }
        } else if (value is List) {
          final optimizedList = value.where((item) => item != null).toList();
          if (optimizedList.isNotEmpty) {
            optimized[key] = optimizedList;
          }
        } else if (value is String && value.isNotEmpty) {
          optimized[key] = value;
        } else if (value is! String) {
          optimized[key] = value;
        }
      }
    });

    return optimized;
  }
}
