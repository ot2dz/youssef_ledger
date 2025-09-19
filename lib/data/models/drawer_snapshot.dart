// lib/data/models/drawer_snapshot.dart
import 'package:youssef_fabric_ledger/core/enums.dart';

class DrawerSnapshot {
  final int? id;
  final DateTime date;
  final SnapshotType type;
  final double cashAmount;
  final String? note;
  final DateTime createdAt;

  DrawerSnapshot({
    this.id,
    required this.date,
    required this.type,
    required this.cashAmount,
    this.note,
    required this.createdAt,
  });

  factory DrawerSnapshot.fromMap(Map<String, dynamic> map) {
    final dateString = map['date'] as String;
    // The database might store the date as 'YYYY-MM-DD' for the UNIQUE constraint.
    // We need to parse it correctly, assuming UTC if no time is present.
    final date = dateString.length == 10
        ? DateTime.parse('${dateString}T00:00:00Z')
        : DateTime.parse(dateString);

    return DrawerSnapshot(
      id: map['id'] as int?,
      date: date,
      type: SnapshotType.values.byName(map['type'] as String),
      cashAmount: (map['cashAmount'] as num).toDouble(),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.name,
      'cashAmount': cashAmount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// This map is specifically for inserting/updating the database,
  /// where the 'date' column has a UNIQUE constraint on the date part only (YYYY-MM-DD).
  Map<String, dynamic> toMapForDb() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10), // For UNIQUE constraint
      'type': type.name,
      'cashAmount': cashAmount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  DrawerSnapshot copyWith({
    int? id,
    DateTime? date,
    SnapshotType? type,
    double? cashAmount,
    String? note,
    DateTime? createdAt,
  }) {
    return DrawerSnapshot(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      cashAmount: cashAmount ?? this.cashAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
