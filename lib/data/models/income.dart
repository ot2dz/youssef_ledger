// lib/data/models/income.dart

import 'package:youssef_fabric_ledger/core/enums.dart';

class Income {
  final int? id;
  final DateTime date;
  final double amount;
  final TransactionSource source;
  final String? note;
  final DateTime createdAt;

  Income({
    this.id,
    required this.date,
    required this.amount,
    required this.source,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'source': source.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num).toDouble(),
      source: TransactionSource.values.byName(map['source'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Income copyWith({
    int? id,
    DateTime? date,
    double? amount,
    TransactionSource? source,
    String? note,
    DateTime? createdAt,
  }) {
    return Income(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
