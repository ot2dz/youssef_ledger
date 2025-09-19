// Test the complete architecture by running the app and checking logs
import 'package:flutter/material.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';
import 'package:youssef_fabric_ledger/data/models/party.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🧪 Testing Database Architecture...\n');

  try {
    final dbHelper = DatabaseHelper.instance;

    // Test 1: Role-specific queries work
    print('1. Testing role-specific queries:');
    final persons = await dbHelper.getPersons();
    final vendors = await dbHelper.getVendors();
    print('   Found ${persons.length} persons and ${vendors.length} vendors');

    // Test 2: Role-specific insertions work
    print('\n2. Testing role-specific insertions:');
    final newPerson = await dbHelper.insertPerson(Party.person('تست شخص'));
    final newVendor = await dbHelper.insertVendor(Party.vendor('تست مورد'));
    print('   Inserted person: ${newPerson?.name} (ID: ${newPerson?.id})');
    print('   Inserted vendor: ${newVendor?.name} (ID: ${newVendor?.id})');

    // Test 3: Verify separation
    print('\n3. Testing role separation:');
    final updatedPersons = await dbHelper.getPersons();
    final updatedVendors = await dbHelper.getVendors();

    bool foundPersonInPersons = updatedPersons.any((p) => p.name == 'تست شخص');
    bool foundVendorInVendors = updatedVendors.any((p) => p.name == 'تست مورد');
    bool foundPersonInVendors = updatedVendors.any((p) => p.name == 'تست شخص');
    bool foundVendorInPersons = updatedPersons.any((p) => p.name == 'تست مورد');

    print('   Person appears in persons list: $foundPersonInPersons');
    print('   Vendor appears in vendors list: $foundVendorInVendors');
    print(
      '   Person appears in vendors list: $foundPersonInVendors (should be false)',
    );
    print(
      '   Vendor appears in persons list: $foundVendorInPersons (should be false)',
    );

    if (foundPersonInPersons &&
        foundVendorInVendors &&
        !foundPersonInVendors &&
        !foundVendorInPersons) {
      print('\n🎉 Database role separation working correctly!');
    } else {
      print('\n❌ Database role separation has issues');
    }

    // Clean up test data
    if (newPerson?.id != null) {
      await dbHelper.deleteParty(newPerson!.id!);
    }
    if (newVendor?.id != null) {
      await dbHelper.deleteParty(newVendor!.id!);
    }
    print('\n🧹 Cleaned up test data');
  } catch (e) {
    print('❌ Database test failed: $e');
  }
}
