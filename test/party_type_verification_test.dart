import 'package:flutter_test/flutter_test.dart';
import 'package:youssef_fabric_ledger/data/models/party.dart';

void main() {
  group('Party Type Verification Tests', () {
    test('Party.kVendor and Party.kPerson should be distinct constants', () {
      expect(Party.kVendor, equals('vendor'));
      expect(Party.kPerson, equals('person'));
      expect(Party.kVendor, isNot(equals(Party.kPerson)));
    });

    test('Party.vendor factory should create vendor type', () {
      final vendor = Party.vendor('Test Vendor');
      expect(vendor.type, equals(Party.kVendor));
      expect(vendor.name, equals('Test Vendor'));
    });

    test('Party.person factory should create person type', () {
      final person = Party.person('Test Person');
      expect(person.type, equals(Party.kPerson));
      expect(person.name, equals('Test Person'));
    });

    test('Party.fromMap should normalize and validate type', () {
      // Test valid types
      final vendorMap = {
        'id': 1,
        'name': 'Vendor1',
        'type': 'vendor',
        'phone': null,
      };
      final vendor = Party.fromMap(vendorMap);
      expect(vendor.type, equals(Party.kVendor));

      final personMap = {
        'id': 2,
        'name': 'Person1',
        'type': 'person',
        'phone': null,
      };
      final person = Party.fromMap(personMap);
      expect(person.type, equals(Party.kPerson));

      // Test invalid type (should default to person)
      final invalidMap = {
        'id': 3,
        'name': 'Invalid1',
        'type': 'invalid',
        'phone': null,
      };
      final invalid = Party.fromMap(invalidMap);
      expect(invalid.type, equals(Party.kPerson));

      // Test case normalization
      final upperCaseMap = {
        'id': 4,
        'name': 'Upper1',
        'type': 'VENDOR',
        'phone': null,
      };
      final upperCase = Party.fromMap(upperCaseMap);
      expect(upperCase.type, equals(Party.kVendor));
    });
  });
}
