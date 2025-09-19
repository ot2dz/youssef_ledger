import 'package:sqflite/sqflite.dart';
import '../../../data/local/database_helper.dart';
import 'models.dart';

/// Repository for reports data calculations and database queries
class ReportsRepository {
  final DatabaseHelper _databaseHelper;

  ReportsRepository(this._databaseHelper);

  /// Calculate report data for given date range
  Future<ReportDataState> getReportData(ReportFilterState filter) async {
    try {
      final db = await _databaseHelper.database;

      print(
        '[REPORTS] Loading data for range: ${filter.fromDate} to ${filter.toDate}',
      );

      // Parallel queries for better performance
      final results = await Future.wait([
        _getIncomeTotal(db, filter.fromDate, filter.toDate),
        _getExpensesTotal(db, filter.fromDate, filter.toDate),
        _getDailyProfits(
          db,
          filter.fromDate,
          filter.toDate,
          filter.profitMargin,
        ),
        _getExpensesByCategory(db, filter.fromDate, filter.toDate),
        _getReceivableTotal(db),
        _getPayableTotal(db),
      ]);

      final incomeTotal = results[0] as double;
      final expensesTotal = results[1] as double;
      final dailySeries = results[2] as List<DailyProfitPoint>;
      final expensesByCategory = results[3] as List<ExpenseCategoryData>;
      final receivableTotal = results[4] as double;
      final payableTotal = results[5] as double;

      print('[REPORTS] Income: $incomeTotal, Expenses: $expensesTotal');
      print('[REPORTS] Daily series count: ${dailySeries.length}');
      print('[REPORTS] Expense categories count: ${expensesByCategory.length}');

      final netProfitTotal = ReportDataState.calculateNetProfit(
        incomeTotal,
        filter.profitMargin,
        expensesTotal,
      );

      return ReportDataState(
        incomeTotal: incomeTotal,
        expensesTotal: expensesTotal,
        netProfitTotal: netProfitTotal,
        dailySeries: dailySeries,
        expensesByCategory: expensesByCategory,
        receivableTotal: receivableTotal,
        payableTotal: payableTotal,
      );
    } catch (e) {
      print('[REPORTS] Error: $e');
      return ReportDataState(error: 'فشل في تحميل البيانات: ${e.toString()}');
    }
  }

  /// Get total income for date range
  Future<double> _getIncomeTotal(
    Database db,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    // Get manual income from income table
    final manualIncomeResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM income
      WHERE date >= ? AND date <= ?
    ''',
      [fromDate.toIso8601String(), toDate.toIso8601String()],
    );

    // Get drawer turnover for the date range with enhanced logic
    final drawerTurnoverResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(turnover), 0) as total
      FROM (
        SELECT 
          DATE(end_snapshot.date) as turnover_date,
          (end_snapshot.cashAmount - COALESCE(
            -- Try to find start snapshot for same date
            (SELECT cashAmount FROM drawer_snapshots 
             WHERE DATE(date) = DATE(end_snapshot.date) AND type = 'start' LIMIT 1),
            -- If not found, use last start balance before last closure logic
            (SELECT cashAmount FROM drawer_snapshots start_before
             WHERE type = 'start' 
             AND DATE(start_before.date) <= DATE(end_snapshot.date)
             AND DATE(start_before.date) <= (
               SELECT COALESCE(MAX(DATE(last_end.date)), '9999-12-31')
               FROM drawer_snapshots last_end
               WHERE type = 'end' AND DATE(last_end.date) < DATE(end_snapshot.date)
             )
             ORDER BY DATE(start_before.date) DESC LIMIT 1),
            0
          )) + COALESCE(drawer_outflows.total, 0) as turnover
        FROM drawer_snapshots end_snapshot
        LEFT JOIN (
          SELECT 
            DATE(date) as expense_date,
            SUM(amount) as total
          FROM expenses
          WHERE source = 'drawer'
          GROUP BY DATE(date)
        ) drawer_outflows ON DATE(end_snapshot.date) = drawer_outflows.expense_date
        WHERE end_snapshot.type = 'end'
        AND DATE(end_snapshot.date) >= ? AND DATE(end_snapshot.date) <= ?
      )
    ''',
      [
        fromDate.toIso8601String().split('T')[0],
        toDate.toIso8601String().split('T')[0],
      ],
    );

    final manualIncome = manualIncomeResult.isNotEmpty
        ? (manualIncomeResult.first['total'] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final drawerTurnover = drawerTurnoverResult.isNotEmpty
        ? (drawerTurnoverResult.first['total'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    return manualIncome + drawerTurnover;
  }

  /// Get total expenses for date range
  Future<double> _getExpensesTotal(
    Database db,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM expenses
      WHERE date >= ? AND date <= ?
    ''',
      [fromDate.toIso8601String(), toDate.toIso8601String()],
    );

    return result.isNotEmpty
        ? (result.first['total'] as num?)?.toDouble() ?? 0.0
        : 0.0;
  }

  /// Get daily profit data points for chart
  Future<List<DailyProfitPoint>> _getDailyProfits(
    Database db,
    DateTime fromDate,
    DateTime toDate,
    double profitMargin,
  ) async {
    // Get all unique dates first
    final datesResult = await db.rawQuery(
      '''
      SELECT DISTINCT DATE(date) as date
      FROM (
        SELECT date FROM income WHERE date >= ? AND date <= ?
        UNION
        SELECT date FROM expenses WHERE date >= ? AND date <= ?
      )
      ORDER BY date
    ''',
      [
        fromDate.toIso8601String(),
        toDate.toIso8601String(),
        fromDate.toIso8601String(),
        toDate.toIso8601String(),
      ],
    );

    final List<DailyProfitPoint> points = [];

    for (final row in datesResult) {
      final dateStr = row['date'] as String;
      final date = DateTime.parse(dateStr);

      // Get daily manual income
      final manualIncomeResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) as total
        FROM income
        WHERE DATE(date) = ?
      ''',
        [dateStr],
      );

      // Get daily drawer turnover with enhanced logic
      final drawerTurnoverResult = await db.rawQuery(
        '''
        SELECT COALESCE(
          (end_snapshot.cashAmount - COALESCE(
            -- Try to find start snapshot for same date
            (SELECT cashAmount FROM drawer_snapshots 
             WHERE DATE(date) = ? AND type = 'start' LIMIT 1),
            -- If not found, use last start balance before last closure logic
            (SELECT cashAmount FROM drawer_snapshots start_before
             WHERE type = 'start' 
             AND DATE(start_before.date) <= ?
             AND DATE(start_before.date) <= (
               SELECT COALESCE(MAX(DATE(last_end.date)), '9999-12-31')
               FROM drawer_snapshots last_end
               WHERE type = 'end' AND DATE(last_end.date) < ?
             )
             ORDER BY DATE(start_before.date) DESC LIMIT 1),
            0
          )) + COALESCE(drawer_outflows.total, 0), 0) as turnover
        FROM drawer_snapshots end_snapshot
        LEFT JOIN (
          SELECT SUM(amount) as total
          FROM expenses
          WHERE source = 'drawer' AND DATE(date) = ?
        ) drawer_outflows ON 1=1
        WHERE end_snapshot.type = 'end' AND DATE(end_snapshot.date) = ?
      ''',
        [dateStr, dateStr, dateStr, dateStr, dateStr],
      );

      // Get daily expenses
      final expensesResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) as total
        FROM expenses
        WHERE DATE(date) = ?
      ''',
        [dateStr],
      );

      final manualIncome = manualIncomeResult.isNotEmpty
          ? (manualIncomeResult.first['total'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      final drawerTurnover = drawerTurnoverResult.isNotEmpty
          ? (drawerTurnoverResult.first['turnover'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      final income = manualIncome + drawerTurnover;
      final expenses = expensesResult.isNotEmpty
          ? (expensesResult.first['total'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      final netProfit = ReportDataState.calculateNetProfit(
        income,
        profitMargin,
        expenses,
      );

      points.add(DailyProfitPoint(date: date, netProfit: netProfit));
    }

    return points;
  }

  /// Get expenses breakdown by category
  Future<List<ExpenseCategoryData>> _getExpensesByCategory(
    Database db,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT 
        c.id,
        c.name,
        COALESCE(SUM(e.amount), 0) as total_amount
      FROM categories c
      LEFT JOIN expenses e ON c.id = e.categoryId 
        AND e.date >= ? AND e.date <= ?
      WHERE c.type = ?
      GROUP BY c.id, c.name
      HAVING total_amount > 0
      ORDER BY total_amount DESC
    ''',
      [fromDate.toIso8601String(), toDate.toIso8601String(), 'expense'],
    );

    return result
        .map(
          (row) => ExpenseCategoryData(
            categoryId: row['id'] as int,
            categoryName: row['name'] as String,
            amount: (row['total_amount'] as num).toDouble(),
          ),
        )
        .toList();
  }

  /// Get total receivable amount (money owed to you by persons)
  Future<double> _getReceivableTotal(Database db) async {
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total
      FROM (
        SELECT 
          de.partyId,
          SUM(CASE 
            WHEN de.kind = 'purchase_credit' OR de.kind = 'loan_out' THEN de.amount
            WHEN de.kind = 'payment' OR de.kind = 'settlement' THEN -de.amount
            ELSE 0
          END) as balance
        FROM debt_entries de
        JOIN parties p ON de.partyId = p.id
        WHERE p.type = 'person'
        GROUP BY de.partyId
        HAVING balance > 0
      )
    ''');

    return result.isNotEmpty
        ? (result.first['total'] as num?)?.toDouble() ?? 0.0
        : 0.0;
  }

  /// Get total payable amount (money you owe to vendors)
  Future<double> _getPayableTotal(Database db) async {
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total
      FROM (
        SELECT 
          de.partyId,
          SUM(CASE 
            WHEN de.kind = 'purchase_credit' OR de.kind = 'loan_out' THEN de.amount
            WHEN de.kind = 'payment' OR de.kind = 'settlement' THEN -de.amount
            ELSE 0
          END) as balance
        FROM debt_entries de
        JOIN parties p ON de.partyId = p.id
        WHERE p.type = 'vendor'
        GROUP BY de.partyId
        HAVING balance > 0
      )
    ''');

    return result.isNotEmpty
        ? (result.first['total'] as num?)?.toDouble() ?? 0.0
        : 0.0;
  }

  /// Get detailed party debts (for Level 2 implementation)
  Future<List<Map<String, dynamic>>> getPartyDebts() async {
    final db = await _databaseHelper.database;

    return await db.rawQuery('''
      SELECT 
        p.id,
        p.name,
        p.type,
        COALESCE(SUM(CASE 
          WHEN de.kind = 'purchase_credit' OR de.kind = 'loan_out' THEN de.amount
          WHEN de.kind = 'payment' OR de.kind = 'settlement' THEN -de.amount
          ELSE 0
        END), 0) as balance
      FROM parties p
      LEFT JOIN debt_entries de ON p.id = de.partyId
      GROUP BY p.id, p.name, p.type
      HAVING balance != 0
      ORDER BY balance DESC
    ''');
  }
}
