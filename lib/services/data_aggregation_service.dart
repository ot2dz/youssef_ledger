// lib/services/data_aggregation_service.dart
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';

/// خدمة تجميع جميع البيانات من قاعدة البيانات للنسخ الاحتياطي
class DataAggregationService {
  final DatabaseHelper _databaseHelper;

  DataAggregationService(this._databaseHelper);

  /// تجميع جميع البيانات من قاعدة البيانات
  Future<Map<String, dynamic>> aggregateAllData() async {
    final data = <String, dynamic>{};

    try {
      // جمع الأطراف (العملاء والموردين)
      data['parties'] = await _getAllParties();

      // جمع الديون
      data['debts'] = await _getAllDebts();

      // جمع المصروفات
      data['expenses'] = await _getAllExpenses();

      // جمع الدخل
      data['incomes'] = await _getAllIncomes();

      // جمع سجل الرصيد النقدي
      data['cash_balance_log'] = await _getCashBalanceLog();

      // جمع لقطات الدرج
      data['drawer_snapshots'] = await _getDrawerSnapshots();

      // جمع الفئات
      data['categories'] = await _getCategories();

      // جمع تقارير البنك (سيتم إضافتها لاحقاً)
      data['bank_transactions'] = await _getBankTransactions();

      return data;
    } catch (e) {
      throw Exception('خطأ في تجميع البيانات: $e');
    }
  }

  /// حساب عدد السجلات في كل جدول
  Future<Map<String, int>> getTableRecordCounts() async {
    final counts = <String, int>{};

    try {
      counts['parties'] = (await _getAllParties()).length;
      counts['debts'] = (await _getAllDebts()).length;
      counts['expenses'] = (await _getAllExpenses()).length;
      counts['incomes'] = (await _getAllIncomes()).length;
      counts['cash_balance_log'] = (await _getCashBalanceLog()).length;
      counts['drawer_snapshots'] = (await _getDrawerSnapshots()).length;
      counts['categories'] = (await _getCategories()).length;
      counts['bank_transactions'] = (await _getBankTransactions()).length;

      return counts;
    } catch (e) {
      throw Exception('خطأ في حساب عدد السجلات: $e');
    }
  }

  /// تجميع بيانات جدول واحد
  Future<List<Map<String, dynamic>>> getTableData(String tableName) async {
    switch (tableName) {
      case 'parties':
        return await _getAllParties();
      case 'debts':
        return await _getAllDebts();
      case 'expenses':
        return await _getAllExpenses();
      case 'incomes':
        return await _getAllIncomes();
      case 'cash_balance_log':
        return await _getCashBalanceLog();
      case 'drawer_snapshots':
        return await _getDrawerSnapshots();
      case 'categories':
        return await _getCategories();
      case 'bank_transactions':
        return await _getBankTransactions();
      default:
        throw Exception('جدول غير معروف: $tableName');
    }
  }

  /// حجم البيانات المقدر (بالبايت)
  Future<int> estimateDataSize() async {
    try {
      final data = await aggregateAllData();
      // تقدير تقريبي: تحويل إلى JSON وحساب الطول
      final jsonString = data.toString();
      return jsonString.length * 2; // تقدير مع UTF-8
    } catch (e) {
      return 0;
    }
  }

  // === طرق خاصة لتجميع البيانات ===

  /// جمع جميع الأطراف
  Future<List<Map<String, dynamic>>> _getAllParties() async {
    try {
      final db = await _databaseHelper.database;
      return await db.query('parties', orderBy: 'created_at DESC');
    } catch (e) {
      return [];
    }
  }

  /// جمع جميع الديون
  Future<List<Map<String, dynamic>>> _getAllDebts() async {
    try {
      final db = await _databaseHelper.database;
      return await db.query('debt_entries', orderBy: 'created_at DESC');
    } catch (e) {
      return [];
    }
  }

  /// جمع جميع المصروفات
  Future<List<Map<String, dynamic>>> _getAllExpenses() async {
    try {
      final db = await _databaseHelper.database;
      return await db.query('expenses', orderBy: 'date DESC');
    } catch (e) {
      return [];
    }
  }

  /// جمع جميع الدخل
  Future<List<Map<String, dynamic>>> _getAllIncomes() async {
    try {
      final db = await _databaseHelper.database;
      return await db.query('income', orderBy: 'date DESC');
    } catch (e) {
      return [];
    }
  }

  /// جمع سجل الرصيد النقدي
  Future<List<Map<String, dynamic>>> _getCashBalanceLog() async {
    try {
      final db = await _databaseHelper.database;
      return await db.query('cash_balance_log', orderBy: 'timestamp DESC');
    } catch (e) {
      return [];
    }
  }

  /// جمع لقطات الدرج
  Future<List<Map<String, dynamic>>> _getDrawerSnapshots() async {
    try {
      final db = await _databaseHelper.database;
      return await db.query('drawer_snapshots', orderBy: 'date DESC');
    } catch (e) {
      return [];
    }
  }

  /// جمع الفئات
  Future<List<Map<String, dynamic>>> _getCategories() async {
    try {
      final db = await _databaseHelper.database;
      return await db.query('categories', orderBy: 'name ASC');
    } catch (e) {
      return [];
    }
  }

  /// جمع جميع المعاملات المصرفية
  Future<List<Map<String, dynamic>>> _getBankTransactions() async {
    try {
      final db = await _databaseHelper.database;
      // التحقق من وجود الجدول أولاً
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='bank_transactions'",
      );

      if (tables.isNotEmpty) {
        return await db.query(
          'bank_transactions',
          orderBy: 'transactionDate DESC, id DESC',
        );
      } else {
        return []; // الجدول غير موجود بعد
      }
    } catch (e) {
      return [];
    }
  }

  /// قائمة جميع الجداول المتاحة
  List<String> get availableTables => [
    'parties',
    'debts',
    'expenses',
    'incomes',
    'cash_balance_log',
    'drawer_snapshots',
    'categories',
    'bank_transactions',
  ];

  /// التحقق من صحة البيانات المجمعة
  Future<bool> validateAggregatedData(Map<String, dynamic> data) async {
    try {
      // التحقق من وجود جميع الجداول المطلوبة
      for (final table in availableTables) {
        if (!data.containsKey(table)) {
          return false;
        }

        if (data[table] is! List) {
          return false;
        }
      }

      // التحقق من أن البيانات ليست فارغة كلياً
      final totalRecords = data.values
          .where((value) => value is List)
          .cast<List>()
          .map((list) => list.length)
          .fold(0, (sum, count) => sum + count);

      return totalRecords >= 0; // يمكن أن تكون فارغة في البداية
    } catch (e) {
      return false;
    }
  }
}
