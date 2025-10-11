// lib/models/backup/backup_metadata.dart

/// مصدر النسخة الاحتياطية
enum BackupSource {
  manual, // يدوي
  scheduled, // مجدول
  automatic, // تلقائي
}

/// معلومات النسخة الاحتياطية
class BackupMetadata {
  final String version;
  final DateTime createdAt;
  final String appVersion;
  final String deviceInfo;
  final bool isEncrypted;
  final String checksum;
  final int dataSize;
  final BackupSource source;
  final Map<String, int> tableRecordCounts;

  const BackupMetadata({
    required this.version,
    required this.createdAt,
    required this.appVersion,
    required this.deviceInfo,
    required this.isEncrypted,
    required this.checksum,
    required this.dataSize,
    required this.source,
    required this.tableRecordCounts,
  });

  /// تحويل إلى Map للتخزين في JSON
  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'app_version': appVersion,
      'device_info': deviceInfo,
      'encrypted': isEncrypted,
      'checksum': checksum,
      'data_size': dataSize,
      'source': source.name,
      'table_record_counts': tableRecordCounts,
    };
  }

  /// إنشاء من Map
  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    return BackupMetadata(
      version: map['version'] ?? '1.0',
      createdAt: DateTime.parse(map['created_at']),
      appVersion: map['app_version'] ?? '1.0.0',
      deviceInfo: map['device_info'] ?? 'Unknown',
      isEncrypted: map['encrypted'] ?? false,
      checksum: map['checksum'] ?? '',
      dataSize: map['data_size'] ?? 0,
      source: BackupSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => BackupSource.manual,
      ),
      tableRecordCounts: Map<String, int>.from(
        map['table_record_counts'] ?? {},
      ),
    );
  }

  /// نسخة محدثة من النسخة الاحتياطية
  BackupMetadata copyWith({
    String? version,
    DateTime? createdAt,
    String? appVersion,
    String? deviceInfo,
    bool? isEncrypted,
    String? checksum,
    int? dataSize,
    BackupSource? source,
    Map<String, int>? tableRecordCounts,
  }) {
    return BackupMetadata(
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      appVersion: appVersion ?? this.appVersion,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      checksum: checksum ?? this.checksum,
      dataSize: dataSize ?? this.dataSize,
      source: source ?? this.source,
      tableRecordCounts: tableRecordCounts ?? this.tableRecordCounts,
    );
  }

  @override
  String toString() {
    return 'BackupMetadata(version: $version, createdAt: $createdAt, '
        'appVersion: $appVersion, isEncrypted: $isEncrypted, '
        'dataSize: $dataSize, source: $source)';
  }
}
