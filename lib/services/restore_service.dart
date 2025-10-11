// lib/services/restore_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youssef_fabric_ledger/models/backup/backup_models.dart';
import 'package:youssef_fabric_ledger/services/backup_service.dart';
import 'package:youssef_fabric_ledger/services/encryption_service.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';

/// خدمة الاستعادة الذكية للنسخ الاحتياطية
class RestoreService {
  final DatabaseHelper _databaseHelper;
  final BackupService _backupService;

  RestoreService(this._databaseHelper)
    : _backupService = BackupService(_databaseHelper);

  /// استعادة كاملة - استبدال جميع البيانات
  Future<RestoreResult> performFullRestore({
    required String backupFilePath,
    String? encryptionPassword,
    bool createBackupBeforeRestore = true,
    VoidCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      onProgress?.call();

      // 1. إنشاء نسخة احتياطية قبل الاستعادة
      String? preRestoreBackupPath;
      if (createBackupBeforeRestore) {
        final preBackupResult = await _backupService.createBackup(
          source: BackupSource.manual,
          customPath: await _getPreRestoreBackupPath(),
        );

        if (preBackupResult.success) {
          preRestoreBackupPath = preBackupResult.filePath;
        }
      }

      // 2. قراءة وتحليل ملف النسخة الاحتياطية
      final backupData = await _parseBackupFile(
        backupFilePath,
        encryptionPassword,
      );

      // 3. التحقق من صحة البيانات
      final validationResult = await _validateBackupData(backupData);
      if (!validationResult.isValid) {
        throw RestoreException(
          'البيانات غير صحيحة: ${validationResult.errors.join(', ')}',
        );
      }

      // 4. بدء الاستعادة
      final restoredTables = <String, int>{};

      // حذف البيانات الحالية
      await _clearCurrentData();

      // استعادة البيانات جدول بجدول
      final tables = backupData.data.keys.toList();
      for (int i = 0; i < tables.length; i++) {
        final tableName = tables[i];
        final tableData = backupData.data[tableName] as List<dynamic>;

        final restoredCount = await _restoreTable(tableName, tableData);
        restoredTables[tableName] = restoredCount;

        // تحديث التقدم
        onProgress?.call();
      }

      stopwatch.stop();

      return RestoreResult.success(
        message: 'تمت الاستعادة الكاملة بنجاح',
        duration: stopwatch.elapsed,
        restoredTables: restoredTables,
        backupFilePath: backupFilePath,
        preRestoreBackupPath: preRestoreBackupPath,
        restoreType: RestoreType.full,
      );
    } catch (e) {
      stopwatch.stop();
      return RestoreResult.failure(
        message: 'فشل في الاستعادة الكاملة',
        errorDetails: e.toString(),
        duration: stopwatch.elapsed,
        restoreType: RestoreType.full,
      );
    }
  }

  /// استعادة جزئية - دمج البيانات مع الموجود
  Future<RestoreResult> performPartialRestore({
    required String backupFilePath,
    required List<String> selectedTables,
    String? encryptionPassword,
    MergeStrategy mergeStrategy = MergeStrategy.replaceExisting,
    bool createBackupBeforeRestore = true,
    VoidCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      onProgress?.call();

      // 1. إنشاء نسخة احتياطية قبل الاستعادة
      String? preRestoreBackupPath;
      if (createBackupBeforeRestore) {
        final preBackupResult = await _backupService.createBackup(
          source: BackupSource.manual,
          customPath: await _getPreRestoreBackupPath(),
        );

        if (preBackupResult.success) {
          preRestoreBackupPath = preBackupResult.filePath;
        }
      }

      // 2. قراءة وتحليل ملف النسخة الاحتياطية
      final backupData = await _parseBackupFile(
        backupFilePath,
        encryptionPassword,
      );

      // 3. التحقق من توفر الجداول المطلوبة
      final availableTables = backupData.data.keys.toSet();
      final missingTables = selectedTables
          .where((table) => !availableTables.contains(table))
          .toList();

      if (missingTables.isNotEmpty) {
        throw RestoreException(
          'الجداول التالية غير موجودة في النسخة الاحتياطية: ${missingTables.join(', ')}',
        );
      }

      // 4. بدء الاستعادة الجزئية
      final restoredTables = <String, int>{};

      for (int i = 0; i < selectedTables.length; i++) {
        final tableName = selectedTables[i];
        final tableData = backupData.data[tableName] as List<dynamic>;

        final restoredCount = await _restoreTableWithMerge(
          tableName,
          tableData,
          mergeStrategy,
        );
        restoredTables[tableName] = restoredCount;

        // تحديث التقدم
        onProgress?.call();
      }

      stopwatch.stop();

      return RestoreResult.success(
        message: 'تمت الاستعادة الجزئية بنجاح',
        duration: stopwatch.elapsed,
        restoredTables: restoredTables,
        backupFilePath: backupFilePath,
        preRestoreBackupPath: preRestoreBackupPath,
        restoreType: RestoreType.partial,
        mergeStrategy: mergeStrategy,
      );
    } catch (e) {
      stopwatch.stop();
      return RestoreResult.failure(
        message: 'فشل في الاستعادة الجزئية',
        errorDetails: e.toString(),
        duration: stopwatch.elapsed,
        restoreType: RestoreType.partial,
      );
    }
  }

  /// استعادة بناء على التاريخ - استعادة البيانات التي تم إنشاؤها أو تحديثها بعد تاريخ معين
  Future<RestoreResult> performDateBasedRestore({
    required String backupFilePath,
    required DateTime afterDate,
    String? encryptionPassword,
    MergeStrategy mergeStrategy = MergeStrategy.addNew,
    bool createBackupBeforeRestore = true,
    VoidCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      onProgress?.call();

      // 1. إنشاء نسخة احتياطية قبل الاستعادة
      String? preRestoreBackupPath;
      if (createBackupBeforeRestore) {
        final preBackupResult = await _backupService.createBackup(
          source: BackupSource.manual,
          customPath: await _getPreRestoreBackupPath(),
        );

        if (preBackupResult.success) {
          preRestoreBackupPath = preBackupResult.filePath;
        }
      }

      // 2. قراءة وتحليل ملف النسخة الاحتياطية
      final backupData = await _parseBackupFile(
        backupFilePath,
        encryptionPassword,
      );

      // 3. تصفية البيانات بناء على التاريخ
      final filteredData = _filterDataByDate(backupData.data, afterDate);

      if (filteredData.isEmpty) {
        return RestoreResult.success(
          message: 'لا توجد بيانات للاستعادة بعد التاريخ المحدد',
          duration: stopwatch.elapsed,
          restoredTables: {},
          backupFilePath: backupFilePath,
          restoreType: RestoreType.dateBased,
        );
      }

      // 4. بدء الاستعادة المصفاة
      final restoredTables = <String, int>{};

      final tables = filteredData.keys.toList();
      for (int i = 0; i < tables.length; i++) {
        final tableName = tables[i];
        final tableData = filteredData[tableName] as List<dynamic>;

        final restoredCount = await _restoreTableWithMerge(
          tableName,
          tableData,
          mergeStrategy,
        );
        restoredTables[tableName] = restoredCount;

        // تحديث التقدم
        onProgress?.call();
      }

      stopwatch.stop();

      return RestoreResult.success(
        message: 'تمت الاستعادة المصفاة بنجاح',
        duration: stopwatch.elapsed,
        restoredTables: restoredTables,
        backupFilePath: backupFilePath,
        preRestoreBackupPath: preRestoreBackupPath,
        restoreType: RestoreType.dateBased,
        mergeStrategy: mergeStrategy,
      );
    } catch (e) {
      stopwatch.stop();
      return RestoreResult.failure(
        message: 'فشل في الاستعادة المصفاة',
        errorDetails: e.toString(),
        duration: stopwatch.elapsed,
        restoreType: RestoreType.dateBased,
      );
    }
  }

  /// معاينة محتويات النسخة الاحتياطية
  Future<BackupPreview> previewBackup({
    required String backupFilePath,
    String? encryptionPassword,
  }) async {
    try {
      final backupData = await _parseBackupFile(
        backupFilePath,
        encryptionPassword,
      );

      final tables = <TablePreview>[];

      for (final entry in backupData.data.entries) {
        final tableName = entry.key;
        final tableData = entry.value as List<dynamic>;

        tables.add(
          TablePreview(
            name: tableName,
            recordCount: tableData.length,
            sampleData: tableData.take(3).toList(), // عينة من 3 سجلات
            hasDateField: _hasDateField(tableData),
            dateRange: _getDateRange(tableData),
          ),
        );
      }

      return BackupPreview(
        metadata: backupData.metadata,
        tables: tables,
        totalRecords: tables.fold(0, (sum, table) => sum + table.recordCount),
        isValid: true,
      );
    } catch (e) {
      return BackupPreview(
        metadata: null,
        tables: [],
        totalRecords: 0,
        isValid: false,
        error: e.toString(),
      );
    }
  }

  /// قراءة وتحليل ملف النسخة الاحتياطية
  Future<BackupData> _parseBackupFile(
    String filePath,
    String? encryptionPassword,
  ) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw RestoreException('ملف النسخة الاحتياطية غير موجود');
    }

    String content = await file.readAsString();

    // فك التشفير إذا كان مطلوباً
    if (encryptionPassword != null) {
      content = await EncryptionService.decrypt(content, encryptionPassword);
    }

    final jsonData = jsonDecode(content) as Map<String, dynamic>;

    // إنشاء BackupData من JSON
    final metadata = BackupMetadata.fromMap(
      jsonData['metadata'] as Map<String, dynamic>,
    );
    final data = jsonData['data'] as Map<String, dynamic>;

    return BackupData(metadata: metadata, data: data);
  }

  /// التحقق من صحة بيانات النسخة الاحتياطية
  Future<ValidationResult> _validateBackupData(BackupData backupData) async {
    final errors = <String>[];

    // التحقق من الإصدار
    if (backupData.metadata.version != '1.0') {
      errors.add(
        'إصدار النسخة الاحتياطية غير مدعوم: ${backupData.metadata.version}',
      );
    }

    // التحقق من وجود البيانات
    if (backupData.data.isEmpty) {
      errors.add('النسخة الاحتياطية فارغة');
    }

    // التحقق من سلامة البيانات
    for (final entry in backupData.data.entries) {
      final tableName = entry.key;
      final tableData = entry.value;

      if (tableData is! List) {
        errors.add('بيانات الجدول $tableName ليست في الشكل الصحيح');
        continue;
      }

      // التحقق من وجود بيانات في الجدول
      if (tableData.isEmpty) {
        continue; // جدول فارغ مقبول
      }

      // التحقق من بنية السجل الأول
      final firstRecord = tableData.first;
      if (firstRecord is! Map<String, dynamic>) {
        errors.add('بنية البيانات في الجدول $tableName غير صحيحة');
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// حذف البيانات الحالية
  Future<void> _clearCurrentData() async {
    final db = await _databaseHelper.database;

    // حذف البيانات من جميع الجداول
    await db.delete('transactions');
    await db.delete('debts');
    await db.delete('income');
    await db.delete('parties');
    await db.delete('orders');
    await db.delete('production_batches');
    await db.delete('cash_balance_changes');
    // إضافة المزيد من الجداول حسب الحاجة
  }

  /// استعادة جدول واحد
  Future<int> _restoreTable(String tableName, List<dynamic> tableData) async {
    final db = await _databaseHelper.database;
    int restoredCount = 0;

    for (final record in tableData) {
      if (record is Map<String, dynamic>) {
        try {
          await db.insert(tableName, record);
          restoredCount++;
        } catch (e) {
          // تجاهل الأخطاء الفردية واستكمال الاستعادة
        }
      }
    }

    return restoredCount;
  }

  /// استعادة جدول مع استراتيجية الدمج
  Future<int> _restoreTableWithMerge(
    String tableName,
    List<dynamic> tableData,
    MergeStrategy strategy,
  ) async {
    final db = await _databaseHelper.database;
    int restoredCount = 0;

    for (final record in tableData) {
      if (record is Map<String, dynamic>) {
        try {
          switch (strategy) {
            case MergeStrategy.replaceExisting:
              // محاولة التحديث أولاً ثم الإدراج
              final id = record['id'];
              if (id != null) {
                final updateCount = await db.update(
                  tableName,
                  record,
                  where: 'id = ?',
                  whereArgs: [id],
                );
                if (updateCount == 0) {
                  await db.insert(tableName, record);
                }
              } else {
                await db.insert(tableName, record);
              }
              restoredCount++;
              break;
            case MergeStrategy.addNew:
              try {
                await db.insert(tableName, record);
                restoredCount++;
              } catch (e) {
                // تجاهل إذا كان السجل موجود
              }
              break;
            case MergeStrategy.updateExisting:
              final id = record['id'];
              if (id != null) {
                final existingRecord = await db.query(
                  tableName,
                  where: 'id = ?',
                  whereArgs: [id],
                );
                if (existingRecord.isNotEmpty) {
                  await db.update(
                    tableName,
                    record,
                    where: 'id = ?',
                    whereArgs: [id],
                  );
                  restoredCount++;
                }
              }
              break;
          }
        } catch (e) {
          // تجاهل الأخطاء الفردية
        }
      }
    }

    return restoredCount;
  }

  /// تصفية البيانات بناء على التاريخ
  Map<String, dynamic> _filterDataByDate(
    Map<String, dynamic> data,
    DateTime afterDate,
  ) {
    final filteredData = <String, dynamic>{};

    for (final entry in data.entries) {
      final tableName = entry.key;
      final tableData = entry.value as List<dynamic>;

      final filteredRecords = tableData.where((record) {
        if (record is Map<String, dynamic>) {
          // البحث عن حقول التاريخ الشائعة
          for (final dateField in [
            'created_at',
            'updated_at',
            'date',
            'timestamp',
          ]) {
            if (record.containsKey(dateField)) {
              try {
                final recordDate = DateTime.parse(record[dateField].toString());
                return recordDate.isAfter(afterDate);
              } catch (e) {
                // تجاهل أخطاء تحليل التاريخ
              }
            }
          }
        }
        return false;
      }).toList();

      if (filteredRecords.isNotEmpty) {
        filteredData[tableName] = filteredRecords;
      }
    }

    return filteredData;
  }

  /// التحقق من وجود حقل تاريخ
  bool _hasDateField(List<dynamic> tableData) {
    if (tableData.isEmpty) return false;

    final firstRecord = tableData.first;
    if (firstRecord is Map<String, dynamic>) {
      return [
        'created_at',
        'updated_at',
        'date',
        'timestamp',
      ].any((field) => firstRecord.containsKey(field));
    }
    return false;
  }

  /// الحصول على نطاق التواريخ
  DateRange? _getDateRange(List<dynamic> tableData) {
    if (!_hasDateField(tableData)) return null;

    DateTime? earliest;
    DateTime? latest;

    for (final record in tableData) {
      if (record is Map<String, dynamic>) {
        for (final dateField in [
          'created_at',
          'updated_at',
          'date',
          'timestamp',
        ]) {
          if (record.containsKey(dateField)) {
            try {
              final date = DateTime.parse(record[dateField].toString());
              earliest = earliest == null || date.isBefore(earliest)
                  ? date
                  : earliest;
              latest = latest == null || date.isAfter(latest) ? date : latest;
            } catch (e) {
              // تجاهل أخطاء تحليل التاريخ
            }
          }
        }
      }
    }

    return earliest != null && latest != null
        ? DateRange(earliest, latest)
        : null;
  }

  /// الحصول على مسار النسخة الاحتياطية قبل الاستعادة
  Future<String> _getPreRestoreBackupPath() async {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'pre_restore_backup_$timestamp.json';
  }
}

/// نتيجة عملية الاستعادة
class RestoreResult {
  final bool success;
  final String message;
  final Duration duration;
  final Map<String, int> restoredTables;
  final String? backupFilePath;
  final String? preRestoreBackupPath;
  final String? errorDetails;
  final RestoreType restoreType;
  final MergeStrategy? mergeStrategy;

  RestoreResult({
    required this.success,
    required this.message,
    required this.duration,
    required this.restoredTables,
    this.backupFilePath,
    this.preRestoreBackupPath,
    this.errorDetails,
    required this.restoreType,
    this.mergeStrategy,
  });

  factory RestoreResult.success({
    required String message,
    required Duration duration,
    required Map<String, int> restoredTables,
    String? backupFilePath,
    String? preRestoreBackupPath,
    required RestoreType restoreType,
    MergeStrategy? mergeStrategy,
  }) {
    return RestoreResult(
      success: true,
      message: message,
      duration: duration,
      restoredTables: restoredTables,
      backupFilePath: backupFilePath,
      preRestoreBackupPath: preRestoreBackupPath,
      restoreType: restoreType,
      mergeStrategy: mergeStrategy,
    );
  }

  factory RestoreResult.failure({
    required String message,
    required Duration duration,
    String? errorDetails,
    required RestoreType restoreType,
  }) {
    return RestoreResult(
      success: false,
      message: message,
      duration: duration,
      restoredTables: {},
      errorDetails: errorDetails,
      restoreType: restoreType,
    );
  }

  int get totalRestoredRecords =>
      restoredTables.values.fold(0, (sum, count) => sum + count);
}

/// أنواع الاستعادة
enum RestoreType {
  full, // كاملة
  partial, // جزئية
  dateBased, // بناء على التاريخ
}

/// استراتيجيات الدمج
enum MergeStrategy {
  replaceExisting, // استبدال الموجود
  addNew, // إضافة الجديد فقط
  updateExisting, // تحديث الموجود فقط
}

/// معاينة النسخة الاحتياطية
class BackupPreview {
  final BackupMetadata? metadata;
  final List<TablePreview> tables;
  final int totalRecords;
  final bool isValid;
  final String? error;

  BackupPreview({
    this.metadata,
    required this.tables,
    required this.totalRecords,
    required this.isValid,
    this.error,
  });
}

/// معاينة جدول
class TablePreview {
  final String name;
  final int recordCount;
  final List<dynamic> sampleData;
  final bool hasDateField;
  final DateRange? dateRange;

  TablePreview({
    required this.name,
    required this.recordCount,
    required this.sampleData,
    required this.hasDateField,
    this.dateRange,
  });
}

/// نطاق التواريخ
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);

  Duration get duration => end.difference(start);
}

/// نتيجة التحقق من صحة البيانات
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});
}

/// استثناء الاستعادة
class RestoreException implements Exception {
  final String message;
  RestoreException(this.message);

  @override
  String toString() => 'RestoreException: $message';
}
