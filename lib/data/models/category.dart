// lib/data/models/category.dart
class Category {
  final int? id;
  final String name;
  final int iconCodePoint; // لتخزين رمز الأيقونة
  final String type; // 'expense' or 'income'

  Category({
    this.id,
    required this.name,
    required this.iconCodePoint,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'type': type,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      iconCodePoint: map['iconCodePoint'],
      type: map['type'],
    );
  }

  /// مقارنة الكائنات بناءً على المحتوى وليس المرجع
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.iconCodePoint == iconCodePoint &&
        other.type == type;
  }

  /// حساب hash code للكائن
  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ iconCodePoint.hashCode ^ type.hashCode;
  }

  /// تمثيل نصي للكائن للتصحيح
  @override
  String toString() {
    return 'Category(id: $id, name: $name, iconCodePoint: $iconCodePoint, type: $type)';
  }

  Category copyWith({int? id, String? name, int? iconCodePoint, String? type}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      type: type ?? this.type,
    );
  }
}
