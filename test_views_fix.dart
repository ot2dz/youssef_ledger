import 'lib/data/local/database_helper.dart';

void main() async {
  print('🔧 Testing Views Fix...');

  try {
    // Force creation of views
    await DatabaseHelper.instance.ensureViewsExist();
    print('✅ Views creation completed');

    // Test getting persons
    final persons = await DatabaseHelper.instance.getPersons();
    print('✅ getPersons() worked: ${persons.length} persons found');

    // Test getting vendors
    final vendors = await DatabaseHelper.instance.getVendors();
    print('✅ getVendors() worked: ${vendors.length} vendors found');

    print('🎉 All tests passed! The views fix is working.');
  } catch (e) {
    print('❌ Error during testing: $e');
  }
}
