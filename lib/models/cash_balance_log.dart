/// Cash balance change log model for tracking all modifications to cash balance
///
/// This model provides audit trail functionality to track:
/// - Manual edits by user
/// - Automatic deductions for cash expenses
/// - Automatic additions during day closing
/// - Balance restoration from expense deletions
class CashBalanceLog {
  final int? id;
  final DateTime timestamp;
  final CashBalanceChangeType changeType;
  final double oldBalance;
  final double newBalance;
  final double amount;
  final String reason;
  final String? details;
  final DateTime createdAt;

  const CashBalanceLog({
    this.id,
    required this.timestamp,
    required this.changeType,
    required this.oldBalance,
    required this.newBalance,
    required this.amount,
    required this.reason,
    this.details,
    required this.createdAt,
  });

  /// Calculated field for change amount (positive for increases, negative for decreases)
  double get changeAmount => newBalance - oldBalance;

  /// Human-readable description of the change type
  String get changeTypeDescription {
    switch (changeType) {
      case CashBalanceChangeType.manualEdit:
        return 'تعديل يدوي';
      case CashBalanceChangeType.cashExpense:
        return 'مصروف نقدي';
      case CashBalanceChangeType.dayClosing:
        return 'إقفال يوم';
      case CashBalanceChangeType.expenseDeletion:
        return 'حذف مصروف';
      case CashBalanceChangeType.debtPayment:
        return 'دفع دين';
      case CashBalanceChangeType.debtCollection:
        return 'استلام من مدين';
      case CashBalanceChangeType.cashIncome:
        return 'دخل نقدي';
    }
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'changeType': changeType.value,
      'oldBalance': oldBalance,
      'newBalance': newBalance,
      'amount': amount,
      'reason': reason,
      'details': details,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from database map
  factory CashBalanceLog.fromMap(Map<String, dynamic> map) {
    return CashBalanceLog(
      id: map['id']?.toInt(),
      timestamp: DateTime.parse(map['timestamp']),
      changeType: CashBalanceChangeType.fromValue(map['changeType']),
      oldBalance: map['oldBalance']?.toDouble() ?? 0.0,
      newBalance: map['newBalance']?.toDouble() ?? 0.0,
      amount: map['amount']?.toDouble() ?? 0.0,
      reason: map['reason'] ?? '',
      details: map['details'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  /// Create copy with updated fields
  CashBalanceLog copyWith({
    int? id,
    DateTime? timestamp,
    CashBalanceChangeType? changeType,
    double? oldBalance,
    double? newBalance,
    double? amount,
    String? reason,
    String? details,
    DateTime? createdAt,
  }) {
    return CashBalanceLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      changeType: changeType ?? this.changeType,
      oldBalance: oldBalance ?? this.oldBalance,
      newBalance: newBalance ?? this.newBalance,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CashBalanceLog{id: $id, timestamp: $timestamp, changeType: $changeType, oldBalance: $oldBalance, newBalance: $newBalance, amount: $amount, reason: $reason, details: $details, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CashBalanceLog &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.changeType == changeType &&
        other.oldBalance == oldBalance &&
        other.newBalance == newBalance &&
        other.amount == amount &&
        other.reason == reason &&
        other.details == details &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        timestamp.hashCode ^
        changeType.hashCode ^
        oldBalance.hashCode ^
        newBalance.hashCode ^
        amount.hashCode ^
        reason.hashCode ^
        details.hashCode ^
        createdAt.hashCode;
  }
}

/// Enum for cash balance change types with database values
enum CashBalanceChangeType {
  manualEdit('manual_edit'),
  cashExpense('cash_expense'),
  dayClosing('day_closing'),
  expenseDeletion('expense_deletion'),
  debtPayment('debt_payment'), // دفع دين نقداً
  debtCollection('debt_collection'), // استلام من مدين نقداً
  cashIncome('cash_income'); // دخل نقدي

  const CashBalanceChangeType(this.value);

  final String value;

  /// Create from database value
  static CashBalanceChangeType fromValue(String value) {
    switch (value) {
      case 'manual_edit':
        return CashBalanceChangeType.manualEdit;
      case 'cash_expense':
        return CashBalanceChangeType.cashExpense;
      case 'day_closing':
        return CashBalanceChangeType.dayClosing;
      case 'expense_deletion':
        return CashBalanceChangeType.expenseDeletion;
      case 'debt_payment':
        return CashBalanceChangeType.debtPayment;
      case 'debt_collection':
        return CashBalanceChangeType.debtCollection;
      case 'cash_income':
        return CashBalanceChangeType.cashIncome;
      default:
        throw ArgumentError('Unknown cash balance change type: $value');
    }
  }
}
