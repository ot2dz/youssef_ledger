/// Data models for Reports feature
/// Contains filter state, report data, and chart data points

enum FilterPreset { week, month, year, custom }

extension FilterPresetExtension on FilterPreset {
  String get displayName {
    switch (this) {
      case FilterPreset.week:
        return 'هذا الأسبوع';
      case FilterPreset.month:
        return 'هذا الشهر';
      case FilterPreset.year:
        return 'هذه السنة';
      case FilterPreset.custom:
        return 'مخصص';
    }
  }
}

/// State for date range filtering and profit margin
class ReportFilterState {
  final DateTime fromDate;
  final DateTime toDate;
  final FilterPreset preset;
  final double profitMargin; // 0.0 - 1.0

  const ReportFilterState({
    required this.fromDate,
    required this.toDate,
    required this.preset,
    this.profitMargin = 0.2, // Default 20%
  });

  factory ReportFilterState.defaultWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return ReportFilterState(
      fromDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
      toDate: DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
      preset: FilterPreset.week,
    );
  }

  factory ReportFilterState.month() {
    final now = DateTime.now();
    return ReportFilterState(
      fromDate: DateTime(now.year, now.month, 1),
      toDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      preset: FilterPreset.month,
    );
  }

  factory ReportFilterState.year() {
    final now = DateTime.now();
    return ReportFilterState(
      fromDate: DateTime(now.year, 1, 1),
      toDate: DateTime(now.year, 12, 31, 23, 59, 59),
      preset: FilterPreset.year,
    );
  }

  ReportFilterState copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    FilterPreset? preset,
    double? profitMargin,
  }) {
    return ReportFilterState(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      preset: preset ?? this.preset,
      profitMargin: profitMargin ?? this.profitMargin,
    );
  }
}

/// Data point for daily profit chart
class DailyProfitPoint {
  final DateTime date;
  final double netProfit;

  const DailyProfitPoint({required this.date, required this.netProfit});
}

/// Data for expense category breakdown
class ExpenseCategoryData {
  final String categoryName;
  final double amount;
  final int categoryId;

  const ExpenseCategoryData({
    required this.categoryName,
    required this.amount,
    required this.categoryId,
  });

  double getPercentage(double total) {
    if (total == 0) return 0;
    return (amount / total) * 100;
  }
}

/// Complete report data state
class ReportDataState {
  final double incomeTotal;
  final double expensesTotal;
  final double netProfitTotal;
  final List<DailyProfitPoint> dailySeries;
  final List<ExpenseCategoryData> expensesByCategory;
  final double receivableTotal; // مستحق لك
  final double payableTotal; // مستحق عليك
  final bool isLoading;
  final String? error;

  const ReportDataState({
    this.incomeTotal = 0.0,
    this.expensesTotal = 0.0,
    this.netProfitTotal = 0.0,
    this.dailySeries = const [],
    this.expensesByCategory = const [],
    this.receivableTotal = 0.0,
    this.payableTotal = 0.0,
    this.isLoading = false,
    this.error,
  });

  ReportDataState copyWith({
    double? incomeTotal,
    double? expensesTotal,
    double? netProfitTotal,
    List<DailyProfitPoint>? dailySeries,
    List<ExpenseCategoryData>? expensesByCategory,
    double? receivableTotal,
    double? payableTotal,
    bool? isLoading,
    String? error,
  }) {
    return ReportDataState(
      incomeTotal: incomeTotal ?? this.incomeTotal,
      expensesTotal: expensesTotal ?? this.expensesTotal,
      netProfitTotal: netProfitTotal ?? this.netProfitTotal,
      dailySeries: dailySeries ?? this.dailySeries,
      expensesByCategory: expensesByCategory ?? this.expensesByCategory,
      receivableTotal: receivableTotal ?? this.receivableTotal,
      payableTotal: payableTotal ?? this.payableTotal,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Calculate net profit based on income, profit margin, and expenses
  static double calculateNetProfit(
    double income,
    double profitMargin,
    double expenses,
  ) {
    return (income * profitMargin) - expenses;
  }
}
