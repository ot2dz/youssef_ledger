// lib/models/backup/backup_result.dart

/// حالة عملية النسخ الاحتياطي
enum BackupStatus {
  success, // نجحت
  failed, // فشلت
  cancelled, // ملغاة
  inProgress, // قيد التقدم
  warning, // تحذير (نجحت مع مشاكل)
}

/// نتيجة عملية النسخ الاحتياطي
class BackupResult {
  final BackupStatus status;
  final String message;
  final String? filePath;
  final String? cloudUrl;
  final int? fileSize;
  final DateTime timestamp;
  final Duration duration;
  final Map<String, int>? processedTables;
  final String? errorDetails;

  const BackupResult({
    required this.status,
    required this.message,
    this.filePath,
    this.cloudUrl,
    this.fileSize,
    required this.timestamp,
    required this.duration,
    this.processedTables,
    this.errorDetails,
  });

  /// هل العملية نجحت؟
  bool get success => status == BackupStatus.success;

  /// نتيجة نجاح
  factory BackupResult.success({
    required String message,
    String? filePath,
    String? cloudUrl,
    int? fileSize,
    required Duration duration,
    Map<String, int>? processedTables,
  }) {
    return BackupResult(
      status: BackupStatus.success,
      message: message,
      filePath: filePath,
      cloudUrl: cloudUrl,
      fileSize: fileSize,
      timestamp: DateTime.now(),
      duration: duration,
      processedTables: processedTables,
    );
  }

  /// نتيجة فشل
  factory BackupResult.failure({
    required String message,
    String? errorDetails,
    required Duration duration,
  }) {
    return BackupResult(
      status: BackupStatus.failed,
      message: message,
      timestamp: DateTime.now(),
      duration: duration,
      errorDetails: errorDetails,
    );
  }

  /// نتيجة إلغاء
  factory BackupResult.cancelled({
    required String message,
    required Duration duration,
  }) {
    return BackupResult(
      status: BackupStatus.cancelled,
      message: message,
      timestamp: DateTime.now(),
      duration: duration,
    );
  }

  /// نتيجة تحذير (نجحت مع مشاكل)
  factory BackupResult.warning({
    required String message,
    String? filePath,
    String? cloudUrl,
    int? fileSize,
    required Duration duration,
    Map<String, int>? processedTables,
    String? errorDetails,
  }) {
    return BackupResult(
      status: BackupStatus.warning,
      message: message,
      filePath: filePath,
      cloudUrl: cloudUrl,
      fileSize: fileSize,
      timestamp: DateTime.now(),
      duration: duration,
      processedTables: processedTables,
      errorDetails: errorDetails,
    );
  }

  /// هل العملية نجحت؟
  bool get isSuccess => status == BackupStatus.success;

  /// هل العملية فشلت؟
  bool get isFailed => status == BackupStatus.failed;

  /// هل العملية ملغاة؟
  bool get isCancelled => status == BackupStatus.cancelled;

  /// هل العملية قيد التقدم؟
  bool get isInProgress => status == BackupStatus.inProgress;

  /// تحويل إلى Map للتخزين
  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'message': message,
      'file_path': filePath,
      'cloud_url': cloudUrl,
      'file_size': fileSize,
      'timestamp': timestamp.toIso8601String(),
      'duration_seconds': duration.inSeconds,
      'processed_tables': processedTables,
      'error_details': errorDetails,
    };
  }

  /// إنشاء من Map
  factory BackupResult.fromMap(Map<String, dynamic> map) {
    return BackupResult(
      status: BackupStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BackupStatus.failed,
      ),
      message: map['message'] ?? '',
      filePath: map['file_path'],
      cloudUrl: map['cloud_url'],
      fileSize: map['file_size'],
      timestamp: DateTime.parse(map['timestamp']),
      duration: Duration(seconds: map['duration_seconds'] ?? 0),
      processedTables: map['processed_tables'] != null
          ? Map<String, int>.from(map['processed_tables'])
          : null,
      errorDetails: map['error_details'],
    );
  }

  @override
  String toString() {
    return 'BackupResult(status: $status, message: $message, '
        'duration: ${duration.inSeconds}s, fileSize: $fileSize)';
  }
}
