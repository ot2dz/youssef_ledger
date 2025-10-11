// test_check_user_data.dart - فحص بيانات المستخدم
import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  Connection? connection;

  try {
    print('\n🔧 بدء فحص بيانات المستخدم في قاعدة البيانات...\n');

    // الاتصال بقاعدة البيانات
    connection = await Connection.open(
      Endpoint(
        host: 'ep-fragrant-sea-a27ma1od.eu-central-1.aws.neon.tech',
        database: 'neondb',
        username: 'neondb_owner',
        password: 'lTzOT0iw3fJl',
      ),
      settings: ConnectionSettings(sslMode: SslMode.require),
    );

    print('✅ تم الاتصال بنجاح بقاعدة البيانات!');

    // البحث عن المستخدم test@example.com
    final result = await connection.execute(
      "SELECT id, email, password_hash, created_at FROM users WHERE email = 'test@example.com'",
    );

    if (result.isNotEmpty) {
      print('\n📊 بيانات المستخدم الموجود:');
      for (final row in result) {
        print('🆔 الرقم التعريفي: ${row[0]}');
        print('📧 البريد الإلكتروني: ${row[1]}');
        print('🔐 كلمة المرور المُشفرة: ${row[2]}');
        print('📅 تاريخ الإنشاء: ${row[3]}');
      }
    } else {
      print('❌ لم يتم العثور على المستخدم test@example.com');
    }

    // عرض جميع المستخدمين
    final allUsers = await connection.execute(
      "SELECT id, email, created_at FROM users ORDER BY created_at DESC",
    );

    print('\n📋 جميع المستخدمين في قاعدة البيانات:');
    for (final row in allUsers) {
      print('🆔 ${row[0]} | 📧 ${row[1]} | 📅 ${row[2]}');
    }

    print('\n🎉 انتهى فحص البيانات!');
  } catch (e) {
    print('❌ خطأ في فحص البيانات: $e');
    exit(1);
  } finally {
    await connection?.close();
  }
}
