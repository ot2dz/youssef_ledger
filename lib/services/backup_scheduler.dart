// lib/services/backup_scheduler.dart
import 'package:workmanager/workmanager.dart';
import 'package:youssef_fabric_ledger/models/backup/backup_models.dart';
import 'package:youssef_fabric_ledger/services/backup_service.dart';
import 'package:youssef_fabric_ledger/services/google_drive_service.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';

/// خدمة جدولة النسخ الاحتياطي التلقائي
class BackupScheduler {
  static const String _dailyBackupTask = 'daily_backup_task';
  static const String _weeklyBackupTask = 'weekly_backup_task';
  static const String _monthlyBackupTask = 'monthly_backup_task';

  static BackupScheduler? _instance;
  static BackupScheduler get instance => _instance ??= BackupScheduler._();

  BackupScheduler._();

  late BackupService _backupService;
  late GoogleDriveService _googleDriveService;
  bool _isInitialized = false;

  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // تهيئة Workmanager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // تعطيل في الإنتاج
      );

      // تهيئة الخدمات
      _backupService = BackupService(DatabaseHelper.instance);
      _googleDriveService = GoogleDriveService();

      _isInitialized = true;
    } catch (e) {
      throw Exception('فشل في تهيئة خدمة الجدولة: $e');
    }
  }

  /// جدولة النسخ الاحتياطي حسب الإعدادات
  Future<void> scheduleBackup(BackupSettings settings) async {
    if (!_isInitialized) await initialize();

    // إلغاء جميع المهام الحالية
    await cancelAllScheduledBackups();

    if (!settings.autoBackupEnabled) return;

    try {
      switch (settings.schedule) {
        case BackupSchedule.daily:
          await _scheduleDailyBackup(settings);
          break;
        case BackupSchedule.weekly:
          await _scheduleWeeklyBackup(settings);
          break;
        case BackupSchedule.monthly:
          await _scheduleMonthlyBackup(settings);
          break;
        case BackupSchedule.manual:
        case BackupSchedule.disabled:
          // لا حاجة لجدولة
          break;
      }
    } catch (e) {
      throw Exception('فشل في جدولة النسخ الاحتياطي: $e');
    }
  }

  /// جدولة نسخ يومي
  Future<void> _scheduleDailyBackup(BackupSettings settings) async {
    await Workmanager().registerPeriodicTask(
      _dailyBackupTask,
      _dailyBackupTask,
      frequency: const Duration(hours: 24),
      initialDelay: _getInitialDelay(settings),
      constraints: Constraints(
        networkType: settings.wifiOnlyUpload
            ? NetworkType.unmetered
            : NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresStorageNotLow: true,
      ),
      inputData: _buildInputData(settings),
    );
  }

  /// جدولة نسخ أسبوعي
  Future<void> _scheduleWeeklyBackup(BackupSettings settings) async {
    await Workmanager().registerPeriodicTask(
      _weeklyBackupTask,
      _weeklyBackupTask,
      frequency: const Duration(days: 7),
      initialDelay: _getInitialDelay(settings),
      constraints: Constraints(
        networkType: settings.wifiOnlyUpload
            ? NetworkType.unmetered
            : NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresStorageNotLow: true,
      ),
      inputData: _buildInputData(settings),
    );
  }

  /// جدولة نسخ شهري
  Future<void> _scheduleMonthlyBackup(BackupSettings settings) async {
    await Workmanager().registerPeriodicTask(
      _monthlyBackupTask,
      _monthlyBackupTask,
      frequency: const Duration(days: 30),
      initialDelay: _getInitialDelay(settings),
      constraints: Constraints(
        networkType: settings.wifiOnlyUpload
            ? NetworkType.unmetered
            : NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresStorageNotLow: true,
      ),
      inputData: _buildInputData(settings),
    );
  }

  /// حساب التأخير الأولي (للتشغيل في وقت مناسب)
  Duration _getInitialDelay(BackupSettings settings) {
    final now = DateTime.now();

    // جدولة للساعة 2:00 صباحاً (وقت مناسب للنسخ التلقائي)
    var targetTime = DateTime(now.year, now.month, now.day, 2, 0);

    // إذا فات الوقت اليوم، اجدول للغد
    if (targetTime.isBefore(now)) {
      targetTime = targetTime.add(const Duration(days: 1));
    }

    return targetTime.difference(now);
  }

  /// بناء بيانات الإدخال للمهمة
  Map<String, dynamic> _buildInputData(BackupSettings settings) {
    return {
      'encryption_enabled': settings.encryptionEnabled,
      'cloud_provider': settings.cloudProvider.name,
      'compression_enabled': settings.compressionEnabled,
      'include_images': settings.includeImages,
      'wifi_only_upload': settings.wifiOnlyUpload,
      'notification_enabled': settings.notificationsEnabled,
      'max_backups_to_keep': settings.maxBackupsToKeep,
    };
  }

  /// إلغاء جميع النسخ المجدولة
  Future<void> cancelAllScheduledBackups() async {
    try {
      await Workmanager().cancelByUniqueName(_dailyBackupTask);
      await Workmanager().cancelByUniqueName(_weeklyBackupTask);
      await Workmanager().cancelByUniqueName(_monthlyBackupTask);
    } catch (e) {
      // تجاهل الأخطاء إذا لم تكن المهام موجودة
    }
  }

  /// إلغاء مهمة محددة
  Future<void> cancelScheduledBackup(BackupSchedule schedule) async {
    String taskName;
    switch (schedule) {
      case BackupSchedule.daily:
        taskName = _dailyBackupTask;
        break;
      case BackupSchedule.weekly:
        taskName = _weeklyBackupTask;
        break;
      case BackupSchedule.monthly:
        taskName = _monthlyBackupTask;
        break;
      default:
        return;
    }

    try {
      await Workmanager().cancelByUniqueName(taskName);
    } catch (e) {
      // تجاهل الأخطاء إذا لم تكن المهمة موجودة
    }
  }

  /// تشغيل نسخ فوري (خارج الجدولة)
  Future<BackupResult> performInstantBackup({
    required BackupSettings settings,
    bool forceCloudUpload = false,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // إنشاء النسخة الاحتياطية
      final result = await _backupService.createBackup(
        source: BackupSource.scheduled,
        encrypt: settings.encryptionEnabled,
        encryptionPassword: settings.encryptionPassword,
      );

      if (!result.success) {
        return result;
      }

      // رفع إلى السحابة إذا كان مطلوباً
      if ((settings.cloudProvider != CloudProvider.none || forceCloudUpload) &&
          _googleDriveService.isAuthenticated) {
        final uploadResult = await _googleDriveService.uploadBackup(
          result.filePath!,
        );

        if (!uploadResult.success) {
          // النسخة المحلية نجحت، لكن الرفع فشل
          return BackupResult.warning(
            message: 'تم إنشاء النسخة المحلية، لكن فشل الرفع إلى السحابة',
            filePath: result.filePath,
            duration: result.duration,
            errorDetails: uploadResult.message,
          );
        }
      }

      // تنظيف النسخ القديمة
      await _cleanupOldBackups(settings.maxBackupsToKeep);

      return result;
    } catch (e) {
      return BackupResult.failure(
        message: 'فشل في النسخ التلقائي',
        errorDetails: e.toString(),
        duration: Duration.zero,
      );
    }
  }

  /// تنظيف النسخ القديمة
  Future<void> _cleanupOldBackups(int maxBackups) async {
    try {
      // هذه وظيفة محاكاة - في التطبيق الحقيقي ستحتاج للتنفيذ الفعلي
      // await _backupService.cleanupOldBackups(maxBackups);
    } catch (e) {
      // تجاهل أخطاء التنظيف
    }
  }

  /// التحقق من حالة النسخ المجدولة
  Future<SchedulerStatus> getSchedulerStatus() async {
    try {
      // في التطبيق الحقيقي، يمكن الاستعلام عن حالة المهام
      return SchedulerStatus(
        isActive: _isInitialized,
        nextScheduledBackup: _calculateNextBackupTime(),
        lastBackupTime: await _getLastBackupTime(),
        pendingTasks: await _getPendingTasksCount(),
      );
    } catch (e) {
      return SchedulerStatus(
        isActive: false,
        nextScheduledBackup: null,
        lastBackupTime: null,
        pendingTasks: 0,
        error: e.toString(),
      );
    }
  }

  DateTime? _calculateNextBackupTime() {
    // محاكاة حساب موعد النسخة التالية
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 2, 0);
  }

  Future<DateTime?> _getLastBackupTime() async {
    // محاكاة الحصول على موعد آخر نسخة
    return DateTime.now().subtract(const Duration(days: 1));
  }

  Future<int> _getPendingTasksCount() async {
    // محاكاة عدد المهام المعلقة
    return 1;
  }
}

/// معلومات حالة المجدول
class SchedulerStatus {
  final bool isActive;
  final DateTime? nextScheduledBackup;
  final DateTime? lastBackupTime;
  final int pendingTasks;
  final String? error;

  SchedulerStatus({
    required this.isActive,
    this.nextScheduledBackup,
    this.lastBackupTime,
    required this.pendingTasks,
    this.error,
  });

  bool get hasError => error != null;
  bool get isScheduled => nextScheduledBackup != null;
}

/// نقطة دخول لتشغيل المهام في الخلفية
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // تهيئة الخدمات
      final backupService = BackupService(DatabaseHelper.instance);
      final googleDriveService = GoogleDriveService();

      // استخراج الإعدادات
      final settings = BackupSettings(
        autoBackupEnabled: true,
        schedule: BackupSchedule.daily, // سيتم تحديد النوع من اسم المهمة
        cloudProvider: CloudProvider.values.firstWhere(
          (e) => e.name == (inputData?['cloud_provider'] ?? 'googleDrive'),
          orElse: () => CloudProvider.googleDrive,
        ),
        encryptionEnabled: inputData?['encryption_enabled'] ?? false,
        syncOnAppStart: false,
        maxBackupsToKeep: inputData?['max_backups_to_keep'] ?? 10,
        compressionEnabled: inputData?['compression_enabled'] ?? true,
        includeImages: inputData?['include_images'] ?? true,
        notificationsEnabled: inputData?['notification_enabled'] ?? true,
        deleteOldBackups: true,
        maxBackupCount: 10,
        wifiOnlyUpload: inputData?['wifi_only_upload'] ?? true,
        notificationEnabled: true,
      );

      // تنفيذ النسخ الاحتياطي
      final result = await backupService.createBackup(
        source: BackupSource.scheduled,
        encrypt: settings.encryptionEnabled,
      );

      // رفع إلى السحابة إذا كان متاحاً
      if (result.success &&
          settings.cloudProvider != CloudProvider.none &&
          googleDriveService.isAuthenticated) {
        await googleDriveService.uploadBackup(result.filePath!);
      }

      // إرسال إشعار (محاكاة)
      if (settings.notificationsEnabled) {
        // await NotificationService.showBackupNotification(result);
      }

      return result.success;
    } catch (e) {
      return false;
    }
  });
}
