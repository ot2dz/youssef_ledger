// lib/data/models/expense.dart
import 'package:youssef_fabric_ledger/core/enums.dart';

class Expense {
  final int? id;
  final DateTime date;
  final double amount;
  final int categoryId;
  final TransactionSource source;
  final String? note;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.date,
    required this.amount,
    required this.categoryId,
    required this.source,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'categoryId': categoryId,
      'source': source.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as int,
      source: TransactionSource.values.byName(map['source'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Expense copyWith({
    int? id,
    DateTime? date,
    double? amount,
    int? categoryId,
    TransactionSource? source,
    String? note,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      source: source ?? this.source,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
