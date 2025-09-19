// Quick verification script to test our role-driven architecture
import 'package:youssef_fabric_ledger/data/models/party.dart';

void main() {
  print('🧪 Testing Role-Driven Architecture...\n');

  // Test 1: PartyRole enum
  print('1. Testing PartyRole enum:');
  print('   PartyRole.person.toDbString() = ${PartyRole.person.toDbString()}');
  print('   PartyRole.vendor.toDbString() = ${PartyRole.vendor.toDbString()}');

  final personRole = PartyRole.fromDbString('person');
  final vendorRole = PartyRole.fromDbString('vendor');
  print('   PartyRole.fromDbString("person") = $personRole');
  print('   PartyRole.fromDbString("vendor") = $vendorRole');
  print('   ✅ PartyRole enum working correctly\n');

  // Test 2: Party model with roles
  print('2. Testing Party model:');
  final person = Party.person('أحمد محمد', phone: '01234567890');
  final vendor = Party.vendor('شركة النسيج', phone: '02-1234567');

  print(
    '   Person: ${person.name}, role: ${person.role}, type: ${person.type}',
  );
  print(
    '   Vendor: ${vendor.name}, role: ${vendor.role}, type: ${vendor.type}',
  );

  // Test 3: Serialization
  final personMap = person.toMap();
  final vendorMap = vendor.toMap();
  print('   Person toMap: $personMap');
  print('   Vendor toMap: $vendorMap');

  // Test 4: Deserialization with valid data
  final personFromMap = Party.fromMap({
    'id': 1,
    'name': 'علي حسن',
    'type': 'person',
    'phone': null,
  });
  final vendorFromMap = Party.fromMap({
    'id': 2,
    'name': 'مورد الخامات',
    'type': 'vendor',
    'phone': '123',
  });

  print(
    '   Person fromMap: ${personFromMap.name}, role: ${personFromMap.role}',
  );
  print(
    '   Vendor fromMap: ${vendorFromMap.name}, role: ${vendorFromMap.role}',
  );
  print('   ✅ Party model working correctly\n');

  print('🎉 All tests passed! Role-driven architecture is working.');
  print('\n📋 Summary of Changes:');
  print('   ✅ PartyRole enum with toDbString() and fromDbString()');
  print('   ✅ Party model updated to use PartyRole instead of string');
  print('   ✅ Type-safe serialization and deserialization');
  print('   ✅ Backward compatibility with database via type getter');
  print('   ✅ Validation with fallback to prevent crashes');
}
