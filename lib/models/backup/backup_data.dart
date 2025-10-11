// lib/models/backup/backup_data.dart
import 'backup_metadata.dart';

/// هيكل النسخة الاحتياطية الكامل
class BackupData {
  final BackupMetadata metadata;
  final Map<String, dynamic> data;

  const BackupData({required this.metadata, required this.data});

  /// تحويل إلى JSON كامل
  Map<String, dynamic> toJson() {
    return {'metadata': metadata.toMap(), 'data': data};
  }

  /// إنشاء من JSON
  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      metadata: BackupMetadata.fromMap(json['metadata']),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }

  /// الحصول على بيانات جدول معين
  List<Map<String, dynamic>>? getTableData(String tableName) {
    final tableData = data[tableName];
    if (tableData is List) {
      return List<Map<String, dynamic>>.from(tableData);
    }
    return null;
  }

  /// تحديث بيانات جدول معين
  BackupData updateTableData(
    String tableName,
    List<Map<String, dynamic>> tableData,
  ) {
    final newData = Map<String, dynamic>.from(data);
    newData[tableName] = tableData;

    // تحديث عدد السجلات في metadata
    final newTableCounts = Map<String, int>.from(metadata.tableRecordCounts);
    newTableCounts[tableName] = tableData.length;

    return BackupData(
      metadata: metadata.copyWith(tableRecordCounts: newTableCounts),
      data: newData,
    );
  }

  /// عدد السجلات الإجمالي
  int get totalRecords {
    return metadata.tableRecordCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );
  }

  /// قائمة الجداول الموجودة
  List<String> get availableTables {
    return data.keys.toList();
  }

  /// حجم البيانات المقدر (بالبايت)
  int get estimatedSize {
    return metadata.dataSize;
  }

  @override
  String toString() {
    return 'BackupData(metadata: $metadata, tables: ${availableTables.length}, '
        'totalRecords: $totalRecords)';
  }
}
