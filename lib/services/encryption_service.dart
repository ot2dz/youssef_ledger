// lib/services/encryption_service.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// خدمة التشفير باستخدام AES-256
class EncryptionService {
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits
  static const int _saltLength = 16; // 128 bits

  /// تشفير النص باستخدام كلمة مرور
  static Future<String> encrypt(String plainText, String password) async {
    try {
      // 1. إنشاء salt عشوائي
      final salt = _generateRandomBytes(_saltLength);

      // 2. اشتقاق المفتاح من كلمة المرور والملح
      final key = _deriveKey(password, salt);

      // 3. إنشاء IV عشوائي
      final iv = _generateRandomBytes(_ivLength);

      // 4. تحويل النص إلى bytes
      final plainBytes = utf8.encode(plainText);

      // 5. التشفير باستخدام AES-256-CBC (محاكاة)
      final encryptedBytes = _aesEncrypt(plainBytes, key, iv);

      // 6. دمج Salt + IV + البيانات المشفرة
      final combined = Uint8List.fromList([...salt, ...iv, ...encryptedBytes]);

      // 7. تحويل إلى Base64
      return base64.encode(combined);
    } catch (e) {
      throw Exception('خطأ في التشفير: $e');
    }
  }

  /// فك تشفير النص باستخدام كلمة مرور
  static Future<String> decrypt(String encryptedText, String password) async {
    try {
      // 1. تحويل من Base64
      final combined = base64.decode(encryptedText);

      if (combined.length < _saltLength + _ivLength) {
        throw Exception('البيانات المشفرة غير صحيحة');
      }

      // 2. استخراج Salt و IV والبيانات المشفرة
      final salt = combined.sublist(0, _saltLength);
      final iv = combined.sublist(_saltLength, _saltLength + _ivLength);
      final encryptedBytes = combined.sublist(_saltLength + _ivLength);

      // 3. اشتقاق المفتاح من كلمة المرور والملح
      final key = _deriveKey(password, salt);

      // 4. فك التشفير
      final decryptedBytes = _aesDecrypt(encryptedBytes, key, iv);

      // 5. تحويل إلى نص
      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw Exception('خطأ في فك التشفير: $e');
    }
  }

  /// التحقق من قوة كلمة المرور
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 6) {
      return PasswordStrength.weak;
    } else if (password.length < 8) {
      return PasswordStrength.medium;
    } else if (password.length >= 12 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return PasswordStrength.veryStrong;
    } else if (password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'))) {
      return PasswordStrength.strong;
    } else {
      return PasswordStrength.medium;
    }
  }

  /// إنشاء كلمة مرور قوية
  static String generateSecurePassword({int length = 16}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()';
    final random = Random.secure();

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// حساب hash لكلمة المرور للتخزين الآمن
  static String hashPassword(String password) {
    final salt = _generateRandomBytes(16);
    final key = _deriveKey(password, salt);
    final combined = Uint8List.fromList([...salt, ...key]);
    return base64.encode(combined);
  }

  /// التحقق من كلمة المرور مقابل hash
  static bool verifyPassword(String password, String hashedPassword) {
    try {
      final combined = base64.decode(hashedPassword);
      final salt = combined.sublist(0, 16);
      final storedKey = combined.sublist(16);
      final derivedKey = _deriveKey(password, salt);

      // مقارنة آمنة للمفاتيح
      return _constantTimeEquals(storedKey, derivedKey);
    } catch (e) {
      return false;
    }
  }

  // === طرق مساعدة خاصة ===

  /// إنشاء bytes عشوائية آمنة
  static Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (i) => random.nextInt(256)),
    );
  }

  /// اشتقاق مفتاح من كلمة المرور باستخدام PBKDF2
  static Uint8List _deriveKey(String password, Uint8List salt) {
    final passwordBytes = utf8.encode(password);

    // محاكاة PBKDF2 مع SHA-256
    var derivedKey = Uint8List.fromList([...passwordBytes, ...salt]);

    // تطبيق hash متكرر (10000 مرة)
    for (int i = 0; i < 10000; i++) {
      derivedKey = Uint8List.fromList(sha256.convert(derivedKey).bytes);
    }

    // إرجاع أول 32 byte للمفتاح
    return derivedKey.sublist(0, _keyLength);
  }

  /// تشفير AES (محاكاة - في التطبيق الحقيقي استخدم مكتبة encrypt)
  static Uint8List _aesEncrypt(
    Uint8List plainBytes,
    Uint8List key,
    Uint8List iv,
  ) {
    // هذه محاكاة بسيطة - في التطبيق الحقيقي استخدم مكتبة encrypt
    final cipher = <int>[];

    for (int i = 0; i < plainBytes.length; i++) {
      final keyByte = key[i % key.length];
      final ivByte = iv[i % iv.length];
      cipher.add(plainBytes[i] ^ keyByte ^ ivByte);
    }

    return Uint8List.fromList(cipher);
  }

  /// فك تشفير AES (محاكاة)
  static Uint8List _aesDecrypt(
    Uint8List cipherBytes,
    Uint8List key,
    Uint8List iv,
  ) {
    // نفس العملية لأن XOR قابل للعكس
    return _aesEncrypt(cipherBytes, key, iv);
  }

  /// مقارنة آمنة للمصفوفات (منع timing attacks)
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }

    return result == 0;
  }
}

/// قوة كلمة المرور
enum PasswordStrength {
  weak, // ضعيفة
  medium, // متوسطة
  strong, // قوية
  veryStrong, // قوية جداً
}

/// معلومات قوة كلمة المرور
extension PasswordStrengthExtension on PasswordStrength {
  String get arabicName {
    switch (this) {
      case PasswordStrength.weak:
        return 'ضعيفة';
      case PasswordStrength.medium:
        return 'متوسطة';
      case PasswordStrength.strong:
        return 'قوية';
      case PasswordStrength.veryStrong:
        return 'قوية جداً';
    }
  }

  double get strengthValue {
    switch (this) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.medium:
        return 0.5;
      case PasswordStrength.strong:
        return 0.75;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.weak:
        return const Color(0xFFE57373); // أحمر فاتح
      case PasswordStrength.medium:
        return const Color(0xFFFFB74D); // برتقالي
      case PasswordStrength.strong:
        return const Color(0xFF81C784); // أخضر فاتح
      case PasswordStrength.veryStrong:
        return const Color(0xFF4CAF50); // أخضر
    }
  }
}

/// كلاس مساعد للألوان
class Color {
  final int value;
  const Color(this.value);
}
