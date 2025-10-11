// lib/models/bank_transaction.dart

import 'dart:convert';

/// أنواع المعاملات المصرفية
enum BankTransactionType {
  credit('credit'),
  debit('debit'),
  transfer('transfer'),
  fee('fee'),
  interest('interest'),
  other('other');

  const BankTransactionType(this.value);
  final String value;
}

/// نموذج المعاملة المصرفية
class BankTransaction {
  final int? id;
  final String bankName;
  final String accountNumber;
  final String transactionId;
  final DateTime date;
  final double amount;
  final BankTransactionType type;
  final String description;
  final String? reference;
  final double balance;
  final String? category;
  final bool isReconciled;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const BankTransaction({
    this.id,
    required this.bankName,
    required this.accountNumber,
    required this.transactionId,
    required this.date,
    required this.amount,
    required this.type,
    required this.description,
    this.reference,
    required this.balance,
    this.category,
    this.isReconciled = false,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// تحويل إلى Map للتخزين في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'reference': reference,
      'description': description,
      'category': category,
      'transactionDate': date.toIso8601String().split('T')[0],
      'processedDate': DateTime.now().toIso8601String().split('T')[0],
      'balance': balance,
      'isReconciled': isReconciled ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata != null ? _encodeMetadata(metadata!) : null,
    };
  }

  /// إنشاء من Map (من قاعدة البيانات)
  factory BankTransaction.fromMap(Map<String, dynamic> map) {
    return BankTransaction(
      id: map['id']?.toInt(),
      bankName: map['bankName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      transactionId: map['id']?.toString() ?? '', // استخدام ID كـ transactionId
      date: DateTime.parse(map['transactionDate']),
      amount: map['amount']?.toDouble() ?? 0.0,
      type: BankTransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BankTransactionType.other,
      ),
      description: map['description'] ?? '',
      reference: map['reference'],
      balance: map['balance']?.toDouble() ?? 0.0,
      category: map['category'],
      isReconciled: (map['isReconciled'] ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      metadata: map['metadata'] != null
          ? _decodeMetadata(map['metadata'])
          : null,
    );
  }

  /// إنشاء نسخة محدثة
  BankTransaction copyWith({
    int? id,
    String? bankName,
    String? accountNumber,
    String? transactionId,
    DateTime? date,
    double? amount,
    BankTransactionType? type,
    String? description,
    String? reference,
    double? balance,
    String? category,
    bool? isReconciled,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return BankTransaction(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      transactionId: transactionId ?? this.transactionId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      balance: balance ?? this.balance,
      category: category ?? this.category,
      isReconciled: isReconciled ?? this.isReconciled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods for metadata encoding/decoding
  static String _encodeMetadata(Map<String, dynamic> metadata) {
    return jsonEncode(metadata);
  }

  static Map<String, dynamic> _decodeMetadata(String metadata) {
    return Map<String, dynamic>.from(jsonDecode(metadata));
  }

  @override
  String toString() {
    return 'BankTransaction{id: $id, bankName: $bankName, accountNumber: $accountNumber, amount: $amount, type: $type}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankTransaction &&
        other.id == id &&
        other.bankName == bankName &&
        other.accountNumber == accountNumber &&
        other.transactionId == transactionId &&
        other.date == date &&
        other.amount == amount &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      bankName,
      accountNumber,
      transactionId,
      date,
      amount,
      type,
    );
  }
}
