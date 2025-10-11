// lib/services/neon_database_service.dart
import 'package:postgres/postgres.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// خدمة قاعدة البيانات السحابية Neon
class NeonDatabaseService {
  static Connection? _connection;

  /// التحقق من صحة الاتصال وإعادة الاتصال عند الحاجة
  static Future<bool> _ensureConnection() async {
    try {
      // إذا لم يكن هناك اتصال، قم بإنشاء واحد جديد
      if (_connection == null) {
        return await connect();
      }

      // اختبار الاتصال الحالي
      try {
        await _connection!.execute('SELECT 1');
        return true;
      } catch (e) {
        // الاتصال معطل، أغلقه وأنشئ واحداً جديداً
        print('⚠️ الاتصال معطل، إعادة الاتصال...');
        try {
          await _connection!.close();
        } catch (_) {}
        _connection = null;
        return await connect();
      }
    } catch (e) {
      print('❌ خطأ في التحقق من الاتصال: $e');
      _connection = null;
      return false;
    }
  }

  /// الاتصال بقاعدة البيانات
  static Future<bool> connect() async {
    try {
      print('🔄 محاولة الاتصال بقاعدة بيانات Neon...');

      _connection = await Connection.open(
        Endpoint(
          host:
              'ep-lingering-cherry-ad9zg49v-pooler.c-2.us-east-1.aws.neon.tech',
          port: 5432,
          database: 'neondb',
          username: 'neondb_owner',
          password: 'npg_TP8agCUdutO0',
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.require,
          connectTimeout: Duration(seconds: 30),
          queryTimeout: Duration(seconds: 60),
          timeZone: 'UTC',
        ),
      );

      print('✅ تم الاتصال بنجاح بقاعدة بيانات Neon!');

      // التأكد من إنشاء الجداول
      await _initializeTables();

      return true;
    } catch (e) {
      print('❌ فشل في الاتصال بقاعدة البيانات: $e');
      _connection = null;
      return false;
    }
  }

  /// تهيئة الجداول المطلوبة
  static Future<void> _initializeTables() async {
    if (_connection == null) return;

    try {
      // إنشاء جدول المستخدمين
      await _connection!.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          email VARCHAR(255) UNIQUE NOT NULL,
          password_hash VARCHAR(255) NOT NULL,
          created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // إنشاء جدول النسخ الاحتياطية
      await _connection!.execute('''
        CREATE TABLE IF NOT EXISTS backup_data (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          backup_type VARCHAR(50) NOT NULL DEFAULT 'complete_backup',
          data_json TEXT NOT NULL,
          backup_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
          device_info VARCHAR(255),
          backup_size INTEGER DEFAULT 0,
          created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // إنشاء فهارس للأداء
      await _connection!.execute('''
        CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)
      ''');

      await _connection!.execute('''
        CREATE INDEX IF NOT EXISTS idx_backup_user_id ON backup_data(user_id)
      ''');

      await _connection!.execute('''
        CREATE INDEX IF NOT EXISTS idx_backup_date ON backup_data(backup_date DESC)
      ''');

      print('✅ تم التحقق من الجداول والفهارس');
    } catch (e) {
      print('❌ خطأ في تهيئة الجداول: $e');
    }
  }

  /// اختبار الاتصال (ping test)
  static Future<bool> testConnection() async {
    try {
      final connected = await _ensureConnection();
      if (!connected) return false;

      print('🔄 اختبار الاتصال...');

      // تنفيذ استعلام بسيط للاختبار
      final result = await _connection!.execute('SELECT 1 as test');

      if (result.isNotEmpty) {
        print('✅ اختبار الاتصال نجح! النتيجة: ${result.first[0]}');
        return true;
      } else {
        print('❌ اختبار الاتصال فشل: لا توجد نتائج');
        return false;
      }
    } catch (e) {
      print('❌ خطأ في اختبار الاتصال: $e');
      return false;
    }
  }

  /// إنشاء جدول المستخدمين
  static Future<bool> createUsersTable() async {
    try {
      final connected = await _ensureConnection();
      if (!connected) return false;

      print('🔄 إنشاء جدول المستخدمين...');

      const createTableQuery = '''
        CREATE TABLE IF NOT EXISTS users (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          email VARCHAR(255) UNIQUE NOT NULL,
          password_hash VARCHAR(255) NOT NULL,
          created_at TIMESTAMP DEFAULT NOW(),
          updated_at TIMESTAMP DEFAULT NOW()
        )
      ''';

      await _connection!.execute(createTableQuery);
      print('✅ تم إنشاء جدول المستخدمين بنجاح!');

      // إنشاء فهارس للأداء
      await _connection!.execute('''
        CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)
      ''');

      return true;
    } catch (e) {
      print('❌ خطأ في إنشاء جدول المستخدمين: $e');
      return false;
    }
  }

  /// إنشاء جدول النسخ الاحتياطية
  static Future<bool> createBackupTable() async {
    try {
      final connected = await _ensureConnection();
      if (!connected) return false;

      print('🔄 إنشاء جدول النسخ الاحتياطية...');

      const createTableQuery = '''
        CREATE TABLE IF NOT EXISTS backup_data (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          backup_type VARCHAR(50) NOT NULL,
          data_json TEXT NOT NULL,
          backup_date TIMESTAMP DEFAULT NOW(),
          device_info VARCHAR(255),
          backup_size INTEGER DEFAULT 0
        )
      ''';

      await _connection!.execute(createTableQuery);
      print('✅ تم إنشاء جدول النسخ الاحتياطية بنجاح!');

      // إنشاء فهارس للأداء
      await _connection!.execute('''
        CREATE INDEX IF NOT EXISTS idx_backup_user_id ON backup_data(user_id)
      ''');

      await _connection!.execute('''
        CREATE INDEX IF NOT EXISTS idx_backup_date ON backup_data(backup_date)
      ''');

      // التحقق من إنشاء الجدول
      final result = await _connection!.execute(
        "SELECT table_name FROM information_schema.tables WHERE table_name = 'backup_data'",
      );

      if (result.isNotEmpty) {
        print('✅ تم التأكد من وجود جدول backup_data في قاعدة البيانات');
        return true;
      } else {
        print('❌ لم يتم إنشاء الجدول بشكل صحيح');
        return false;
      }
    } catch (e) {
      print('❌ خطأ في إنشاء جدول النسخ الاحتياطية: $e');
      return false;
    }
  }

  /// تشفير كلمة المرور
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// تسجيل مستخدم جديد
  static Future<Map<String, dynamic>> registerUser(
    String email,
    String password,
  ) async {
    try {
      final connected = await _ensureConnection();
      if (!connected) {
        return {'success': false, 'message': 'فشل في الاتصال بقاعدة البيانات'};
      }

      print('🔄 تسجيل مستخدم جديد: $email');

      // تشفير كلمة المرور
      final hashedPassword = _hashPassword(password);

      // إدراج المستخدم الجديد
      final result = await _connection!.execute(
        Sql.named('''
          INSERT INTO users (email, password_hash)
          VALUES (@email, @password_hash)
          RETURNING id, email, created_at
        '''),
        parameters: {'email': email, 'password_hash': hashedPassword},
      );

      if (result.isNotEmpty) {
        final userData = result.first;
        print('✅ تم تسجيل المستخدم بنجاح!');
        print(
          'ID: ${userData[0]}, Email: ${userData[1]}, تاريخ التسجيل: ${userData[2]}',
        );

        return {
          'success': true,
          'message': 'تم تسجيل المستخدم بنجاح',
          'user': {
            'id': userData[0].toString(),
            'email': userData[1],
            'created_at': userData[2].toString(),
          },
        };
      } else {
        return {'success': false, 'message': 'فشل في تسجيل المستخدم'};
      }
    } catch (e) {
      print('❌ خطأ في تسجيل المستخدم: $e');
      return {'success': false, 'message': 'خطأ في تسجيل المستخدم: $e'};
    }
  }

  /// تسجيل الدخول
  static Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
  ) async {
    try {
      final connected = await _ensureConnection();
      if (!connected) {
        return {'success': false, 'message': 'فشل في الاتصال بقاعدة البيانات'};
      }

      print('🔄 محاولة تسجيل الدخول: $email');

      // تشفير كلمة المرور المدخلة للمقارنة
      final hashedPassword = _hashPassword(password);

      // البحث عن المستخدم بالإيميل وكلمة المرور المشفرة
      final result = await _connection!.execute(
        Sql.named('''
          SELECT id, email, created_at
          FROM users 
          WHERE email = @email AND password_hash = @password_hash
        '''),
        parameters: {'email': email, 'password_hash': hashedPassword},
      );

      if (result.isNotEmpty) {
        final userData = result.first;
        print('✅ تم تسجيل الدخول بنجاح!');
        print('ID: ${userData[0]}, Email: ${userData[1]}');

        return {
          'success': true,
          'message': 'تم تسجيل الدخول بنجاح',
          'user': {
            'id': userData[0].toString(),
            'email': userData[1],
            'created_at': userData[2].toString(),
          },
        };
      } else {
        print('❌ بيانات تسجيل الدخول غير صحيحة');
        return {
          'success': false,
          'message': 'بريد إلكتروني أو كلمة مرور غير صحيحة',
        };
      }
    } catch (e) {
      print('❌ خطأ في تسجيل الدخول: $e');
      return {'success': false, 'message': 'خطأ في تسجيل الدخول: $e'};
    }
  }

  /// إنشاء نسخة احتياطية
  static Future<Map<String, dynamic>> createBackup(
    String userId,
    String backupType,
    Map<String, dynamic> data, {
    String? deviceInfo,
  }) async {
    try {
      final connected = await _ensureConnection();
      if (!connected) {
        return {'success': false, 'message': 'فشل في الاتصال بقاعدة البيانات'};
      }

      print('🔄 إنشاء نسخة احتياطية للمستخدم: $userId');

      final dataJson = jsonEncode(data);
      final backupSize = dataJson.length;

      final result = await _connection!.execute(
        Sql.named('''
          INSERT INTO backup_data (user_id, backup_type, data_json, device_info, backup_size)
          VALUES (@user_id, @backup_type, @data_json, @device_info, @backup_size)
          RETURNING id, backup_date
        '''),
        parameters: {
          'user_id': userId,
          'backup_type': backupType,
          'data_json': dataJson,
          'device_info': deviceInfo ?? 'Unknown',
          'backup_size': backupSize,
        },
      );

      if (result.isNotEmpty) {
        final backupData = result.first;
        print('✅ تم إنشاء النسخة الاحتياطية بنجاح!');
        print('🆔 معرف النسخة الاحتياطية: ${backupData[0]}');
        print('📅 تاريخ النسخة الاحتياطية: ${backupData[1]}');

        return {
          'success': true,
          'message': 'تم إنشاء النسخة الاحتياطية بنجاح',
          'backup_id': backupData[0].toString(),
          'backup_date': backupData[1].toString(),
          'backup_size': backupSize,
        };
      } else {
        return {'success': false, 'message': 'فشل في إنشاء النسخة الاحتياطية'};
      }
    } catch (e) {
      print('❌ خطأ في إنشاء النسخة الاحتياطية: $e');
      return {
        'success': false,
        'message': 'خطأ في إنشاء النسخة الاحتياطية: $e',
      };
    }
  }

  /// استرجاع النسخة الاحتياطية الأحدث للمستخدم
  static Future<Map<String, dynamic>> getLatestBackup(
    String userId, {
    String? backupType,
  }) async {
    try {
      final connected = await _ensureConnection();
      if (!connected) {
        return {'success': false, 'message': 'فشل في الاتصال بقاعدة البيانات'};
      }

      print('🔄 استرجاع النسخة الاحتياطية الأحدث للمستخدم: $userId');

      String query = '''
        SELECT id, backup_type, data_json, backup_date, device_info, backup_size
        FROM backup_data 
        WHERE user_id = @user_id
      ''';

      Map<String, dynamic> parameters = {'user_id': userId};

      if (backupType != null) {
        query += ' AND backup_type = @backup_type';
        parameters['backup_type'] = backupType;
      }

      query += ' ORDER BY backup_date DESC LIMIT 1';

      final result = await _connection!.execute(
        Sql.named(query),
        parameters: parameters,
      );

      if (result.isNotEmpty) {
        final backupData = result.first;
        final dataJson = backupData[2] as String;
        final data = jsonDecode(dataJson);

        print('✅ تم العثور على النسخة الاحتياطية!');
        print('📅 تاريخ النسخة: ${backupData[3]}');

        return {
          'success': true,
          'message': 'تم استرجاع النسخة الاحتياطية بنجاح',
          'backup': {
            'id': backupData[0].toString(),
            'backup_type': backupData[1],
            'backup_date': backupData[3].toString(),
            'device_info': backupData[4],
            'backup_size': backupData[5],
          },
          'data': data,
        };
      } else {
        print('📋 لم يتم العثور على نسخ احتياطية للمستخدم');
        return {
          'success': false,
          'message': 'لا توجد نسخ احتياطية لهذا المستخدم',
        };
      }
    } catch (e) {
      print('❌ خطأ في استرجاع النسخة الاحتياطية: $e');
      return {
        'success': false,
        'message': 'خطأ في استرجاع النسخة الاحتياطية: $e',
      };
    }
  }

  /// الحصول على جميع النسخ الاحتياطية للمستخدم
  static Future<Map<String, dynamic>> getUserBackups(String userId) async {
    try {
      final connected = await _ensureConnection();
      if (!connected) {
        return {'success': false, 'message': 'فشل في الاتصال بقاعدة البيانات'};
      }

      print('🔄 استرجاع جميع النسخ الاحتياطية للمستخدم: $userId');

      final result = await _connection!.execute(
        Sql.named('''
          SELECT id, backup_type, backup_date, device_info, backup_size
          FROM backup_data 
          WHERE user_id = @user_id
          ORDER BY backup_date DESC
        '''),
        parameters: {'user_id': userId},
      );

      final backups = result
          .map(
            (row) => {
              'id': row[0].toString(),
              'backup_type': row[1],
              'backup_date': row[2].toString(),
              'device_info': row[3],
              'backup_size': row[4],
            },
          )
          .toList();

      print('✅ تم العثور على ${backups.length} نسخة احتياطية');

      return {
        'success': true,
        'message': 'تم استرجاع النسخ الاحتياطية بنجاح',
        'backups': backups,
      };
    } catch (e) {
      print('❌ خطأ في استرجاع النسخ الاحتياطية: $e');
      return {
        'success': false,
        'message': 'خطأ في استرجاع النسخ الاحتياطية: $e',
      };
    }
  }

  /// قطع الاتصال
  static Future<void> disconnect() async {
    try {
      if (_connection != null) {
        await _connection!.close();
        _connection = null;
        print('✅ تم قطع الاتصال بنجاح');
      }
    } catch (e) {
      print('❌ خطأ في قطع الاتصال: $e');
    }
  }

  // Getters
  static Connection? get connection => _connection;
  static bool get isConnected => _connection != null;
}
