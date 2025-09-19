import 'package:flutter/foundation.dart';
import 'package:youssef_fabric_ledger/core/enums.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/data/models/drawer_snapshot.dart';
import 'package:youssef_fabric_ledger/data/models/expense.dart';
import 'package:youssef_fabric_ledger/logic/providers/date_provider.dart';

enum DrawerStatus {
  complete,
  pendingEnd,
  missingStart,
  crossDateComplete, // حسابات متقاطعة مكتملة
}

class FinanceProvider with ChangeNotifier {
  final DatabaseHelper dbHelper;
  final DateProvider dateProvider;

  // --- الحالة المالية ---
  double _totalCashBalance = 0.0;
  double get totalCashBalance => _totalCashBalance;

  // ... (rest of the properties are the same)
  double _grossProfit = 0.0; // = ربح اليوم (20%)
  double get grossProfit => _grossProfit;
  double get dailyProfit => _grossProfit;
  double _totalExpenses = 0.0; // مصروفات اليوم
  double get totalExpenses => _totalExpenses;

  double _totalIncome = 0.0; // دخل اليوم
  double get totalIncome => _totalIncome;

  double _netProfit = 0.0; // صافي ربح اليوم = ربح اليوم - مصروفات اليوم
  double get netProfit => _netProfit;

  DrawerStatus _drawerStatus = DrawerStatus.pendingEnd;
  DrawerStatus get drawerStatus => _drawerStatus;

  // --- أرصدة الدرج لليوم ---
  double? _startOfDayBalance;
  double? get startOfDayBalance => _startOfDayBalance;

  double? _endOfDayBalance;
  double? get endOfDayBalance => _endOfDayBalance;

  // --- التواريخ الفعالة للحسابات المتقاطعة ---
  DateTime? _effectiveStartDate;
  DateTime? get effectiveStartDate => _effectiveStartDate;

  DateTime? _effectiveEndDate;
  DateTime? get effectiveEndDate => _effectiveEndDate;

  // --- مؤشر إذا كانت البيانات من أيام مختلفة ---
  bool get isCrossDateCalculation =>
      _effectiveStartDate != null &&
      _effectiveEndDate != null &&
      _effectiveStartDate!.day != _effectiveEndDate!.day;

  double _calculatedTurnover = 0.0;
  double get calculatedTurnover => _calculatedTurnover;

  double _profitPercent = 0.20; // 20%

  Map<String, double> get drawerFinalState {
    final opening = _startOfDayBalance ?? 0.0;
    final closing = _endOfDayBalance ?? 0.0;
    // This calculation might need adjustment based on business logic
    // For now, it's a simple difference.
    final difference = closing - opening;

    return {
      'openingBalance': opening,
      'closingBalance': closing,
      'difference': difference,
    };
  }

  // --- حالة الدرج المحدثة ---
  Map<String, DrawerSnapshot?> _drawerSnapshots = {'start': null, 'end': null};
  Map<String, DrawerSnapshot?> get drawerSnapshots => _drawerSnapshots;

  // إحصائيات شهرية وسنوية
  double _monthlyIncome = 0.0;
  double get monthlyIncome => _monthlyIncome;

  double _monthlyExpenses = 0.0;
  double get monthlyExpenses => _monthlyExpenses;

  double _monthlyNetProfit = 0.0;
  double get monthlyNetProfit => _monthlyNetProfit;

  FinanceProvider({required this.dbHelper, required this.dateProvider}) {
    // Listen to date changes and refetch data
    dateProvider.addListener(_onDateChanged);
    loadInitialData();
  }

  void _onDateChanged() {
    fetchFinancialDataForSelectedDate();
  }

  @override
  void dispose() {
    dateProvider.removeListener(_onDateChanged);
    super.dispose();
  }

  Future<void> loadInitialData() async {
    final savedBalance = await dbHelper.getSetting('totalCashBalance');
    _totalCashBalance = double.tryParse(savedBalance ?? '0.0') ?? 0.0;
    await fetchFinancialDataForSelectedDate();
  }

  /// Fetches financial data for the date selected in DateProvider.
  Future<void> fetchFinancialDataForSelectedDate() async {
    final selectedDate = dateProvider.selectedDate;

    // 1. Fetch drawer snapshots for current date
    final startSnapshot = await dbHelper.getSnapshotForDate(
      selectedDate,
      SnapshotType.start,
    );
    final endSnapshot = await dbHelper.getSnapshotForDate(
      selectedDate,
      SnapshotType.end,
    );

    // 2. Smart balance determination with new logic
    double? startAmount = startSnapshot?.cashAmount;
    double? endAmount = endSnapshot?.cashAmount;
    DateTime? effectiveStartDate = startSnapshot?.date;
    DateTime? effectiveEndDate = endSnapshot?.date;

    // If no start balance for today, use last start balance before last closure
    if (startAmount == null) {
      final lastStartBeforeClosure = await dbHelper
          .getLastStartBalanceBeforeLastClosure();
      if (lastStartBeforeClosure != null) {
        startAmount = lastStartBeforeClosure.cashAmount;
        effectiveStartDate = lastStartBeforeClosure.date;
      }
    }

    // If no end balance for today, find the earliest end snapshot after the effective start date
    if (endAmount == null && effectiveStartDate != null) {
      final nextEndSnapshot = await dbHelper.getEarliestEndSnapshotAfter(
        effectiveStartDate,
      );
      if (nextEndSnapshot != null) {
        endAmount = nextEndSnapshot.cashAmount;
        effectiveEndDate = nextEndSnapshot.date;
      }
    }

    _startOfDayBalance = startAmount;
    _endOfDayBalance = endAmount;
    _effectiveStartDate = effectiveStartDate;
    _effectiveEndDate = effectiveEndDate;

    // 3. Enhanced drawer status with cross-date support
    if (_startOfDayBalance == null) {
      _drawerStatus = DrawerStatus.missingStart;
    } else if (_endOfDayBalance == null) {
      _drawerStatus = DrawerStatus.pendingEnd;
    } else {
      // Check if we have a valid pair
      if (isCrossDateCalculation) {
        _drawerStatus = DrawerStatus.crossDateComplete;
      } else {
        _drawerStatus = DrawerStatus.complete;
      }
    }

    debugPrint('[FINANCE] Enhanced drawer calculation:');
    debugPrint('[FINANCE] Selected date: $selectedDate');
    debugPrint('[FINANCE] Effective start date: $_effectiveStartDate');
    debugPrint('[FINANCE] Effective end date: $_effectiveEndDate');
    debugPrint('[FINANCE] Cross-date calculation: $isCrossDateCalculation');
    debugPrint('[FINANCE] Start balance: $_startOfDayBalance');
    debugPrint('[FINANCE] End balance: $_endOfDayBalance');
    debugPrint('[FINANCE] Drawer status: $_drawerStatus');

    // 4. Calculate turnover with enhanced cross-date support
    _calculatedTurnover = 0.0;
    if ((_drawerStatus == DrawerStatus.complete ||
            _drawerStatus == DrawerStatus.crossDateComplete) &&
        _effectiveStartDate != null &&
        _effectiveEndDate != null) {
      // Calculate expenses for the period between start and end dates
      final drawerOutflows = await dbHelper.getDrawerExpensesForDateRange(
        _effectiveStartDate!,
        _effectiveEndDate!,
      );

      // Pure cash difference (may span multiple days)
      _calculatedTurnover =
          (_endOfDayBalance! - _startOfDayBalance!) + drawerOutflows;

      debugPrint('[FINANCE] Enhanced drawer calculation:');
      debugPrint(
        '[FINANCE] Period: $_effectiveStartDate to $_effectiveEndDate',
      );
      debugPrint('[FINANCE] Start balance: $_startOfDayBalance');
      debugPrint('[FINANCE] End balance: $_endOfDayBalance');
      debugPrint('[FINANCE] Drawer outflows (period): $drawerOutflows');
      debugPrint(
        '[FINANCE] Calculated turnover (enhanced): $_calculatedTurnover',
      );
    }

    // 5. Calculate final totals
    final manualIncomes = await dbHelper.getIncomeForDate(selectedDate);
    final manualIncomesTotal = manualIncomes.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    _totalIncome = _calculatedTurnover + manualIncomesTotal;

    debugPrint('[FINANCE] Final income calculation:');
    debugPrint('[FINANCE] Calculated turnover: $_calculatedTurnover');
    debugPrint('[FINANCE] Manual incomes total: $manualIncomesTotal');
    debugPrint('[FINANCE] Total income: $_totalIncome');

    final allExpenses = await dbHelper.getExpensesForDate(selectedDate);
    _totalExpenses = allExpenses.fold(0.0, (sum, item) => sum + item.amount);

    _grossProfit = _totalIncome * _profitPercent;
    _netProfit = _grossProfit - _totalExpenses;

    notifyListeners();
  }

  /// Refreshes data for the current day.
  Future<void> refreshTodayData() async {
    // This method now simply ensures the date is current and fetches data.
    // The actual date change is handled by DateProvider.
    if (!dateProvider.isSameDay(dateProvider.selectedDate, DateTime.now())) {
      dateProvider.selectDate(DateTime.now());
    } else {
      await fetchFinancialDataForSelectedDate();
    }
    // Force UI refresh after data refresh
    notifyListeners();
  }

  Future<void> updateTotalCashBalance(double newBalance) async {
    _totalCashBalance = newBalance;
    await dbHelper.saveSetting('totalCashBalance', newBalance.toString());
    notifyListeners();
  }

  Future<void> saveDrawerSnapshot({
    required DateTime date,
    required SnapshotType type,
    required double amount,
    String? note,
  }) async {
    final snapshot = DrawerSnapshot(
      date: date,
      type: type,
      cashAmount: amount,
      note: note,
      createdAt: DateTime.now(),
    );
    final savedSnapshot = await dbHelper.saveDrawerSnapshot(snapshot);
    _drawerSnapshots[type.name] = savedSnapshot;

    // If this is an end snapshot (closing the day), add daily income to total cash balance
    if (type == SnapshotType.end) {
      await _handleDayClosing(date);
    }

    if (dateProvider.isSameDay(date, dateProvider.selectedDate)) {
      await fetchFinancialDataForSelectedDate();
    } else {
      notifyListeners();
    }
  }

  /// Handles the closing of a day by adding daily income to total cash balance
  Future<void> _handleDayClosing(DateTime closingDate) async {
    // Calculate the daily income for the closing date
    final dailyIncome = await _calculateDailyIncome(closingDate);

    if (dailyIncome > 0) {
      final newBalance = _totalCashBalance + dailyIncome;
      await updateTotalCashBalance(newBalance);
      debugPrint(
        '[FINANCE] Day closed for $closingDate: Daily income $dailyIncome added, New balance: $newBalance',
      );
    }
  }

  /// Calculates total daily income (drawer turnover + manual income) for a specific date
  Future<double> _calculateDailyIncome(DateTime date) async {
    // Get start snapshot for the date
    final startSnapshot = await dbHelper.getSnapshotForDate(
      date,
      SnapshotType.start,
    );
    final endSnapshot = await dbHelper.getSnapshotForDate(
      date,
      SnapshotType.end,
    );

    double drawerTurnover = 0.0;

    if (startSnapshot != null && endSnapshot != null) {
      // Get drawer expenses for the date
      final drawerExpenses = await dbHelper.getDrawerExpensesForDate(date);

      // Calculate drawer turnover
      drawerTurnover =
          (endSnapshot.cashAmount - startSnapshot.cashAmount) + drawerExpenses;
    } else if (endSnapshot != null) {
      // If no start snapshot for today, use the new logic
      final lastStartBeforeClosure = await dbHelper
          .getLastStartBalanceBeforeLastClosure();
      if (lastStartBeforeClosure != null) {
        final drawerExpenses = await dbHelper.getDrawerExpensesForDate(date);
        drawerTurnover =
            (endSnapshot.cashAmount - lastStartBeforeClosure.cashAmount) +
            drawerExpenses;
      }
    }

    // Get manual income for the date
    final manualIncomes = await dbHelper.getIncomeForDate(date);
    final manualIncomeTotal = manualIncomes.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    final totalDailyIncome = drawerTurnover + manualIncomeTotal;

    debugPrint('[FINANCE] Daily income calculation for $date:');
    debugPrint('[FINANCE] Drawer turnover: $drawerTurnover');
    debugPrint('[FINANCE] Manual income: $manualIncomeTotal');
    debugPrint('[FINANCE] Total daily income: $totalDailyIncome');

    return totalDailyIncome;
  }

  Future<void> addOrUpdateExpense(Expense expense) async {
    // Store old expense amount for update scenarios
    Expense? oldExpense;
    if (expense.id != null) {
      // For updates, get the old expense to calculate the difference
      oldExpense = await dbHelper.getExpenseById(expense.id!);
    }

    if (expense.id == null) {
      await dbHelper.createExpense(expense);

      // For new cash expenses, deduct from total cash balance
      if (expense.source == TransactionSource.cash) {
        final newBalance = _totalCashBalance - expense.amount;
        await updateTotalCashBalance(newBalance);
        debugPrint(
          '[FINANCE] Cash expense added: ${expense.amount}, New balance: $newBalance',
        );
      }
    } else {
      await dbHelper.updateExpense(expense);

      // For cash expense updates, adjust the balance
      if (expense.source == TransactionSource.cash && oldExpense != null) {
        if (oldExpense.source == TransactionSource.cash) {
          // Both old and new are cash: adjust by difference
          final difference = expense.amount - oldExpense.amount;
          final newBalance = _totalCashBalance - difference;
          await updateTotalCashBalance(newBalance);
          debugPrint(
            '[FINANCE] Cash expense updated: difference $difference, New balance: $newBalance',
          );
        } else {
          // Changed from non-cash to cash: deduct full amount
          final newBalance = _totalCashBalance - expense.amount;
          await updateTotalCashBalance(newBalance);
          debugPrint(
            '[FINANCE] Expense changed to cash: ${expense.amount}, New balance: $newBalance',
          );
        }
      } else if (oldExpense?.source == TransactionSource.cash &&
          expense.source != TransactionSource.cash) {
        // Changed from cash to non-cash: add back the old amount
        final newBalance = _totalCashBalance + oldExpense!.amount;
        await updateTotalCashBalance(newBalance);
        debugPrint(
          '[FINANCE] Expense changed from cash: ${oldExpense.amount}, New balance: $newBalance',
        );
      }
    }

    // After saving, refresh the data for the currently selected date
    // to ensure the UI is up-to-date.
    await fetchFinancialDataForSelectedDate();
  }

  Future<void> deleteExpense(int expenseId) async {
    // Get the expense before deleting to check if it's a cash expense
    final expense = await dbHelper.getExpenseById(expenseId);

    await dbHelper.deleteExpense(expenseId);

    // If it was a cash expense, add the amount back to total cash balance
    if (expense != null && expense.source == TransactionSource.cash) {
      final newBalance = _totalCashBalance + expense.amount;
      await updateTotalCashBalance(newBalance);
      debugPrint(
        '[FINANCE] Cash expense deleted: ${expense.amount}, New balance: $newBalance',
      );
    }

    // Refresh data
    await fetchFinancialDataForSelectedDate();
  }
}
