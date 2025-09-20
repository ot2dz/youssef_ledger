// lib/data/models/debt_entry.dart
import 'package:youssef_fabric_ledger/core/enums.dart';

class DebtEntry {
  final int? id;
  final DateTime date;
  final int partyId;
  final String kind; // 'purchase_credit', 'payment', 'loan_out', 'settlement'
  final double amount;
  final PaymentMethod paymentMethod; // طريقة الدفع
  final String? note;
  final DateTime createdAt;

  DebtEntry({
    this.id,
    required this.date,
    required this.partyId,
    required this.kind,
    required this.amount,
    this.paymentMethod = PaymentMethod.credit, // افتراضياً آجل
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'partyId': partyId,
      'kind': kind,
      'amount': amount,
      'paymentMethod': paymentMethod.name,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DebtEntry.fromMap(Map<String, dynamic> map) {
    return DebtEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      partyId: map['partyId'] as int,
      kind: map['kind'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: PaymentMethod.values.byName(
        map['paymentMethod'] as String? ?? 'credit',
      ),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  DebtEntry copyWith({
    int? id,
    DateTime? date,
    int? partyId,
    String? kind,
    double? amount,
    PaymentMethod? paymentMethod,
    String? note,
    DateTime? createdAt,
  }) {
    return DebtEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      partyId: partyId ?? this.partyId,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
