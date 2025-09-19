// lib/data/models/party.dart

/// Enum representing the role of a party in the system
enum PartyRole {
  person,
  vendor;

  /// Convert role to database string representation
  String toDbString() {
    switch (this) {
      case PartyRole.person:
        return 'person';
      case PartyRole.vendor:
        return 'vendor';
    }
  }

  /// Parse role from database string representation
  static PartyRole? fromDbString(String? dbString) {
    if (dbString == null) return null;
    final normalized = dbString.trim().toLowerCase();
    switch (normalized) {
      case 'person':
        return PartyRole.person;
      case 'vendor':
        return PartyRole.vendor;
      default:
        return null;
    }
  }
}

class Party {
  // Legacy constants for backward compatibility during migration
  static const String kVendor = 'vendor';
  static const String kPerson = 'person';

  final int? id;
  final String name;
  final PartyRole role; // Use enum instead of string
  final String? phone;

  Party({this.id, required this.name, required this.role, this.phone});

  factory Party.vendor(String name, {String? phone}) =>
      Party(name: name.trim(), role: PartyRole.vendor, phone: phone);

  factory Party.person(String name, {String? phone}) =>
      Party(name: name.trim(), role: PartyRole.person, phone: phone);

  /// Legacy type getter for backward compatibility during migration
  String get type => role.toDbString();

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'type': role.toDbString(), 'phone': phone};
  }

  factory Party.fromMap(Map<String, dynamic> map) {
    final typeString = (map['type'] as String).trim().toLowerCase();

    // Parse role with validation and fallback
    final parsedRole = PartyRole.fromDbString(typeString);
    final validRole =
        parsedRole ?? PartyRole.person; // Default to person if invalid

    // Debug assertion in development
    assert(
      parsedRole != null,
      'Invalid party type "$typeString" found in database. Defaulting to person.',
    );

    return Party(
      id: map['id'],
      name: map['name'],
      role: validRole,
      phone: map['phone'],
    );
  }

  Party copyWith({int? id, String? name, PartyRole? role, String? phone}) {
    return Party(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
    );
  }
}
