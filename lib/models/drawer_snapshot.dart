class DrawerSnapshot {
  int? id;
  final DateTime date;
  final double startBalance;
  final double endBalance;

  DrawerSnapshot({
    this.id,
    required this.date,
    required this.startBalance,
    required this.endBalance,
  });

  factory DrawerSnapshot.fromMap(Map<String, dynamic> map) {
    return DrawerSnapshot(
      id: map['id'],
      date: DateTime.parse(map['date']),
      startBalance: map['startBalance'],
      endBalance: map['endBalance'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T').first, // YYYY-MM-DD
      'startBalance': startBalance,
      'endBalance': endBalance,
    };
  }
}