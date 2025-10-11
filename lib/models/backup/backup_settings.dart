// lib/models/backup/backup_settings.dart

/// جدولة النسخ الاحتياطي
enum BackupSchedule {
  disabled, // معطل
  daily, // يومي
  weekly, // أسبوعي
  monthly, // شهري
  manual, // يدوي فقط
}

/// مقدم الخدمة السحابية
enum CloudProvider {
  none, // بدون
  googleDrive, // Google Drive
  // يمكن إضافة المزيد لاحقاً: dropbox, oneDrive, etc.
}

/// إعدادات النسخ الاحتياطي
class BackupSettings {
  final bool autoBackupEnabled;
  final BackupSchedule schedule;
  final CloudProvider cloudProvider;
  final bool encryptionEnabled;
  final String? encryptionPassword;
  final bool deleteOldBackups;
  final int maxBackupCount;
  final bool wifiOnlyUpload;
  final String? customBackupPath;
  final bool notificationEnabled;
  final bool syncOnAppStart;
  final int maxBackupsToKeep;
  final bool compressionEnabled;
  final bool includeImages;
  final bool notificationsEnabled;

  const BackupSettings({
    required this.autoBackupEnabled,
    required this.schedule,
    required this.cloudProvider,
    required this.encryptionEnabled,
    this.encryptionPassword,
    required this.deleteOldBackups,
    required this.maxBackupCount,
    required this.wifiOnlyUpload,
    this.customBackupPath,
    required this.notificationEnabled,
    required this.syncOnAppStart,
    required this.maxBackupsToKeep,
    required this.compressionEnabled,
    required this.includeImages,
    required this.notificationsEnabled,
  });

  /// الإعدادات الافتراضية
  factory BackupSettings.defaultSettings() {
    return const BackupSettings(
      autoBackupEnabled: false,
      schedule: BackupSchedule.weekly,
      cloudProvider: CloudProvider.googleDrive,
      encryptionEnabled: false,
      deleteOldBackups: true,
      maxBackupCount: 10,
      wifiOnlyUpload: true,
      notificationEnabled: true,
      syncOnAppStart: false,
      maxBackupsToKeep: 10,
      compressionEnabled: true,
      includeImages: true,
      notificationsEnabled: true,
    );
  }

  /// تحويل إلى Map للتخزين
  Map<String, dynamic> toMap() {
    return {
      'auto_backup_enabled': autoBackupEnabled,
      'schedule': schedule.name,
      'cloud_provider': cloudProvider.name,
      'encryption_enabled': encryptionEnabled,
      'encryption_password': encryptionPassword,
      'delete_old_backups': deleteOldBackups,
      'max_backup_count': maxBackupCount,
      'wifi_only_upload': wifiOnlyUpload,
      'custom_backup_path': customBackupPath,
      'notification_enabled': notificationEnabled,
      'sync_on_app_start': syncOnAppStart,
      'max_backups_to_keep': maxBackupsToKeep,
      'compression_enabled': compressionEnabled,
      'include_images': includeImages,
      'notifications_enabled': notificationsEnabled,
    };
  }

  /// إنشاء من Map
  factory BackupSettings.fromMap(Map<String, dynamic> map) {
    return BackupSettings(
      autoBackupEnabled: map['auto_backup_enabled'] ?? false,
      schedule: BackupSchedule.values.firstWhere(
        (e) => e.name == map['schedule'],
        orElse: () => BackupSchedule.weekly,
      ),
      cloudProvider: CloudProvider.values.firstWhere(
        (e) => e.name == map['cloud_provider'],
        orElse: () => CloudProvider.googleDrive,
      ),
      encryptionEnabled: map['encryption_enabled'] ?? false,
      encryptionPassword: map['encryption_password'],
      deleteOldBackups: map['delete_old_backups'] ?? true,
      maxBackupCount: map['max_backup_count'] ?? 10,
      wifiOnlyUpload: map['wifi_only_upload'] ?? true,
      customBackupPath: map['custom_backup_path'],
      notificationEnabled: map['notification_enabled'] ?? true,
      syncOnAppStart: map['sync_on_app_start'] ?? false,
      maxBackupsToKeep: map['max_backups_to_keep'] ?? 10,
      compressionEnabled: map['compression_enabled'] ?? true,
      includeImages: map['include_images'] ?? true,
      notificationsEnabled: map['notifications_enabled'] ?? true,
    );
  }

  /// نسخة محدثة من الإعدادات
  BackupSettings copyWith({
    bool? autoBackupEnabled,
    BackupSchedule? schedule,
    CloudProvider? cloudProvider,
    bool? encryptionEnabled,
    String? encryptionPassword,
    bool? deleteOldBackups,
    int? maxBackupCount,
    bool? wifiOnlyUpload,
    String? customBackupPath,
    bool? notificationEnabled,
    bool? syncOnAppStart,
    int? maxBackupsToKeep,
    bool? compressionEnabled,
    bool? includeImages,
    bool? notificationsEnabled,
  }) {
    return BackupSettings(
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      schedule: schedule ?? this.schedule,
      cloudProvider: cloudProvider ?? this.cloudProvider,
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      encryptionPassword: encryptionPassword ?? this.encryptionPassword,
      deleteOldBackups: deleteOldBackups ?? this.deleteOldBackups,
      maxBackupCount: maxBackupCount ?? this.maxBackupCount,
      wifiOnlyUpload: wifiOnlyUpload ?? this.wifiOnlyUpload,
      customBackupPath: customBackupPath ?? this.customBackupPath,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      syncOnAppStart: syncOnAppStart ?? this.syncOnAppStart,
      maxBackupsToKeep: maxBackupsToKeep ?? this.maxBackupsToKeep,
      compressionEnabled: compressionEnabled ?? this.compressionEnabled,
      includeImages: includeImages ?? this.includeImages,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  /// هل هناك إعدادات سحابية نشطة؟
  bool get hasCloudBackup => cloudProvider != CloudProvider.none;

  /// هل التشفير نشط ومعين؟
  bool get isEncryptionReady =>
      encryptionEnabled &&
      encryptionPassword != null &&
      encryptionPassword!.isNotEmpty;

  @override
  String toString() {
    return 'BackupSettings(autoBackup: $autoBackupEnabled, '
        'schedule: $schedule, provider: $cloudProvider, '
        'encryption: $encryptionEnabled)';
  }
}
