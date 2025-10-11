// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youssef_fabric_ledger/models/backup/backup_models.dart';
import 'package:youssef_fabric_ledger/services/data_aggregation_service.dart';
import 'package:youssef_fabric_ledger/services/encryption_service.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';

/// خدمة النسخ الاحتياطي الأساسية
class BackupService {
  final DataAggregationService _dataAggregationService;
  final DatabaseHelper _databaseHelper;

  BackupService(this._databaseHelper)
    : _dataAggregationService = DataAggregationService(_databaseHelper);

  /// الوصول لقاعدة البيانات
  DatabaseHelper get databaseHelper => _databaseHelper;

  /// إنشاء نسخة احتياطية كاملة
  Future<BackupResult> createBackup({
    required BackupSource source,
    String? customPath,
    bool encrypt = false,
    String? encryptionPassword,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. تجميع البيانات
      final data = await _dataAggregationService.aggregateAllData();
      final recordCounts = await _dataAggregationService.getTableRecordCounts();
      final estimatedSize = await _dataAggregationService.estimateDataSize();

      // 2. إنشاء metadata
      final metadata = BackupMetadata(
        version: '1.0',
        createdAt: DateTime.now(),
        appVersion: '1.0.0', // يمكن الحصول عليها من pubspec.yaml
        deviceInfo: await _getDeviceInfo(),
        isEncrypted: encrypt,
        checksum: '', // سيتم حسابه لاحقاً
        dataSize: estimatedSize,
        source: source,
        tableRecordCounts: recordCounts,
      );

      // 3. إنشاء BackupData
      final backupData = BackupData(metadata: metadata, data: data);

      // 4. تحويل إلى JSON
      final jsonData = backupData.toJson();
      String jsonString = json.encode(jsonData);

      // 5. التشفير إذا كان مطلوباً
      if (encrypt && encryptionPassword != null) {
        // سيتم تطبيق التشفير لاحقاً
        jsonString = await _encryptData(jsonString, encryptionPassword);
      }

      // 6. حساب checksum
      final checksum = _calculateChecksum(jsonString);
      final updatedMetadata = metadata.copyWith(checksum: checksum);

      // 7. إعادة إنشاء JSON مع checksum المحدث
      final finalBackupData = BackupData(metadata: updatedMetadata, data: data);
      final finalJsonString = encrypt && encryptionPassword != null
          ? await _encryptData(
              json.encode(finalBackupData.toJson()),
              encryptionPassword,
            )
          : json.encode(finalBackupData.toJson());

      // 8. حفظ الملف
      final filePath = await _saveBackupFile(finalJsonString, customPath);
      final fileSize = await File(filePath).length();

      stopwatch.stop();

      return BackupResult.success(
        message: 'تم إنشاء النسخة الاحتياطية بنجاح',
        filePath: filePath,
        fileSize: fileSize,
        duration: stopwatch.elapsed,
        processedTables: recordCounts,
      );
    } catch (e) {
      stopwatch.stop();
      return BackupResult.failure(
        message: 'فشل في إنشاء النسخة الاحتياطية',
        errorDetails: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// التحقق من صحة نسخة احتياطية
  Future<BackupResult> validateBackup(String filePath) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. قراءة الملف
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود');
      }

      final fileContent = await file.readAsString();

      // 2. محاولة تحليل JSON
      final jsonData = json.decode(fileContent);

      // 3. التحقق من البنية الأساسية
      if (!jsonData.containsKey('metadata') || !jsonData.containsKey('data')) {
        throw Exception('بنية الملف غير صحيحة');
      }

      // 4. إنشاء BackupData من JSON
      final backupData = BackupData.fromJson(jsonData);

      // 5. التحقق من checksum
      final expectedChecksum = backupData.metadata.checksum;
      final actualData = json.encode(backupData.data);
      final actualChecksum = _calculateChecksum(actualData);

      if (expectedChecksum != actualChecksum) {
        throw Exception('checksum غير متطابق - الملف قد يكون تالفاً');
      }

      // 6. التحقق من صحة البيانات
      final isValid = await _dataAggregationService.validateAggregatedData(
        backupData.data,
      );
      if (!isValid) {
        throw Exception('بيانات النسخة الاحتياطية غير صحيحة');
      }

      stopwatch.stop();

      return BackupResult.success(
        message: 'النسخة الاحتياطية صحيحة ومتكاملة',
        filePath: filePath,
        fileSize: await file.length(),
        duration: stopwatch.elapsed,
        processedTables: backupData.metadata.tableRecordCounts,
      );
    } catch (e) {
      stopwatch.stop();
      return BackupResult.failure(
        message: 'فشل في التحقق من النسخة الاحتياطية',
        errorDetails: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// تحليل نسخة احتياطية وإرجاع بياناتها
  Future<BackupData?> parseBackup(
    String filePath, {
    String? decryptionPassword,
  }) async {
    try {
      // 1. قراءة الملف
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود');
      }

      String fileContent = await file.readAsString();

      // 2. فك التشفير إذا كان مشفراً
      if (decryptionPassword != null) {
        fileContent = await _decryptData(fileContent, decryptionPassword);
      }

      // 3. تحليل JSON
      final jsonData = json.decode(fileContent);

      // 4. إنشاء BackupData
      return BackupData.fromJson(jsonData);
    } catch (e) {
      print('خطأ في تحليل النسخة الاحتياطية: $e');
      return null;
    }
  }

  /// الحصول على قائمة النسخ الاحتياطية المحلية
  Future<List<FileSystemEntity>> getLocalBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.yfl'))
          .toList();

      // ترتيب حسب تاريخ الإنشاء (الأحدث أولاً)
      files.sort(
        (a, b) => File(
          b.path,
        ).lastModifiedSync().compareTo(File(a.path).lastModifiedSync()),
      );

      return files;
    } catch (e) {
      return [];
    }
  }

  /// حذف نسخة احتياطية محلية
  Future<bool> deleteLocalBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // === طرق مساعدة خاصة ===

  /// حفظ النسخة الاحتياطية في ملف
  Future<String> _saveBackupFile(String content, String? customPath) async {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final fileName = 'backup_$timestamp.yfl';

    final Directory directory;
    if (customPath != null) {
      directory = Directory(customPath);
    } else {
      directory = await _getBackupDirectory();
    }

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);

    return file.path;
  }

  /// الحصول على مجلد النسخ الاحتياطية
  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/backups');
  }

  /// حساب checksum للبيانات
  String _calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// الحصول على معلومات الجهاز
  Future<String> _getDeviceInfo() async {
    // يمكن تطوير هذا لاحقاً للحصول على معلومات أكثر تفصيلاً
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }

  /// تشفير البيانات باستخدام EncryptionService
  Future<String> _encryptData(String data, String password) async {
    return await EncryptionService.encrypt(data, password);
  }

  /// فك تشفير البيانات باستخدام EncryptionService
  Future<String> _decryptData(String encryptedData, String password) async {
    return await EncryptionService.decrypt(encryptedData, password);
  }
}
