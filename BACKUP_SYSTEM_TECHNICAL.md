# 🔄 Backup System Technical Documentation
## نظام النسخ الاحتياطي المتقدم - التوثيق التقني

### 📋 نظرة عامة على النظام

نظام النسخ الاحتياطي المتقدم هو نظام شامل ومتكامل لحماية البيانات في تطبيق Youssef Fabric Ledger. تم تصميم النظام ليكون قويًا وموثوقًا وآمنًا، مع دعم للنسخ الاحتياطي المحلي والسحابي.

### 🏗️ هندسة النظام

#### المكونات الأساسية

```
Backup System Architecture
├── Core Services
│   ├── BackupService           # الخدمة الرئيسية للنسخ الاحتياطي
│   ├── RestoreService          # خدمة الاستعادة الذكية
│   ├── EncryptionService       # خدمة التشفير المتقدم
│   ├── DataAggregationService  # تجميع البيانات
│   └── GoogleDriveService      # تكامل Google Drive
├── UI Components
│   ├── BackupSettingsScreen    # شاشة إعدادات النسخ الاحتياطي
│   ├── BackupOperationsScreen  # شاشة عمليات النسخ والاستعادة
│   └── Backup Widgets          # مكونات واجهة المستخدم
├── Scheduling & Automation
│   ├── BackupScheduler         # جدولة النسخ التلقائي
│   └── WorkManager Integration # تنفيذ المهام في الخلفية
└── Models & Data
    ├── BankTransaction         # نموذج المعاملات المصرفية
    ├── BackupSettings          # إعدادات النسخ الاحتياطي
    └── Backup Metadata         # معلومات النسخ الاحتياطية
```

### 🔧 الخدمات الأساسية

#### 1. BackupService
**الملف**: `lib/services/backup_service.dart`

**الوظائف الرئيسية**:
```dart
class BackupService {
  // إنشاء نسخة احتياطية محلية
  Future<String> createLocalBackup({
    bool includeImages = true,
    String? customPath
  });
  
  // إنشاء نسخة احتياطية سحابية
  Future<String> createCloudBackup({
    bool encrypt = true,
    bool compress = true
  });
  
  // قائمة النسخ الاحتياطية المحلية
  Future<List<BackupInfo>> getLocalBackups();
  
  // قائمة النسخ الاحتياطية السحابية
  Future<List<BackupInfo>> getCloudBackups();
  
  // حذف نسخة احتياطية
  Future<bool> deleteBackup(String backupPath);
}
```

**الميزات المتقدمة**:
- ضغط البيانات باستخدام Gzip
- تشفير AES-256 للملفات الحساسة
- دعم النسخ الاحتياطي التدريجي
- فحص سلامة البيانات

#### 2. RestoreService
**الملف**: `lib/services/restore_service.dart`

**أنواع الاستعادة**:
```dart
enum RestoreType {
  full,        // استعادة كاملة
  partial,     // استعادة جزئية
  dateRange,   // استعادة نطاق زمني
  selective    // استعادة انتقائية
}
```

**الوظائف الرئيسية**:
```dart
class RestoreService {
  // استعادة كاملة للبيانات
  Future<RestoreResult> restoreFullBackup(String backupPath);
  
  // استعادة جزئية بتحديد الجداول
  Future<RestoreResult> restorePartialBackup(
    String backupPath,
    List<String> tables
  );
  
  // استعادة بنطاق زمني
  Future<RestoreResult> restoreDateRangeBackup(
    String backupPath,
    DateTime startDate,
    DateTime endDate
  );
  
  // معاينة محتويات النسخة الاحتياطية
  Future<BackupPreview> previewBackup(String backupPath);
}
```

#### 3. EncryptionService
**الملف**: `lib/services/encryption_service.dart`

**خوارزميات التشفير**:
- **AES-256-CBC**: للملفات الكبيرة
- **RSA-2048**: لتشفير المفاتيح
- **SHA-256**: للتحقق من سلامة البيانات

```dart
class EncryptionService {
  // تشفير النص
  Future<String> encryptText(String plainText, String key);
  
  // فك تشفير النص
  Future<String> decryptText(String encryptedText, String key);
  
  // تشفير الملف
  Future<String> encryptFile(String filePath, String password);
  
  // فك تشفير الملف
  Future<String> decryptFile(String encryptedFilePath, String password);
  
  // إنشاء مفتاح تشفير قوي
  String generateSecureKey();
  
  // التحقق من سلامة البيانات
  Future<bool> verifyDataIntegrity(String data, String hash);
}
```

#### 4. DataAggregationService
**الملف**: `lib/services/data_aggregation_service.dart`

**تجميع البيانات**:
```dart
class DataAggregationService {
  // تجميع جميع البيانات
  Future<Map<String, dynamic>> aggregateAllData();
  
  // تجميع بيانات محددة
  Future<Map<String, dynamic>> aggregateSelectedData(List<String> tables);
  
  // تحسين البيانات قبل النسخ الاحتياطي
  Future<Map<String, dynamic>> optimizeDataForBackup(Map<String, dynamic> data);
  
  // إحصائيات البيانات
  Future<DataStatistics> getDataStatistics();
}
```

**الجداول المدعومة**:
- `parties` - العملاء والموردين
- `debts` - الديون
- `expenses` - المصروفات  
- `income` - الدخل
- `drawer_snapshots` - لقطات الصندوق
- `cash_balance_log` - سجل الرصيد النقدي
- `bank_transactions` - المعاملات المصرفية
- `categories` - التصنيفات
- `settings` - الإعدادات

#### 5. GoogleDriveService
**الملف**: `lib/services/google_drive_service.dart`

**وظائف Google Drive**:
```dart
class GoogleDriveService {
  // تسجيل الدخول إلى Google
  Future<bool> signIn();
  
  // تسجيل الخروج
  Future<void> signOut();
  
  // رفع ملف إلى Drive
  Future<String> uploadFile(String filePath, String fileName);
  
  // تحميل ملف من Drive
  Future<String> downloadFile(String fileId, String localPath);
  
  // قائمة الملفات في Drive
  Future<List<DriveFile>> listFiles();
  
  // حذف ملف من Drive
  Future<bool> deleteFile(String fileId);
  
  // فحص المساحة المتاحة
  Future<StorageInfo> getStorageInfo();
}
```

### 🕒 النسخ الاحتياطي المجدول

#### BackupScheduler
**الملف**: `lib/services/backup_scheduler.dart`

**أنواع الجدولة**:
```dart
enum BackupFrequency {
  daily,      // يومياً
  weekly,     // أسبوعياً
  monthly,    // شهرياً
  custom      // مخصص
}
```

**إعداد الجدولة**:
```dart
class BackupScheduler {
  // جدولة نسخة احتياطية تلقائية
  Future<void> scheduleAutoBackup({
    required BackupFrequency frequency,
    required BackupSettings settings,
    DateTime? specificTime
  });
  
  // إلغاء الجدولة
  Future<void> cancelScheduledBackup();
  
  // فحص حالة الجدولة
  Future<ScheduleStatus> getScheduleStatus();
  
  // تنفيذ نسخة احتياطية فورية
  Future<void> triggerImmediateBackup();
}
```

**تكامل WorkManager**:
```dart
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'backup-task':
        await BackupService.performScheduledBackup();
        break;
      case 'cleanup-task':
        await BackupService.cleanupOldBackups();
        break;
    }
    return Future.value(true);
  });
}
```

### 🗄️ نموذج المعاملات المصرفية

#### BankTransaction Model
**الملف**: `lib/models/bank_transaction.dart`

**الهيكل**:
```dart
class BankTransaction {
  final int? id;
  final String bankName;
  final String accountNumber;
  final String transactionId;
  final DateTime date;
  final double amount;
  final BankTransactionType type;
  final String description;
  final String? reference;
  final double balance;
  final String? category;
  final bool isReconciled;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
}
```

**أنواع المعاملات**:
```dart
enum BankTransactionType {
  credit,    // إيداع
  debit,     // سحب
  transfer,  // تحويل
  fee,       // رسوم
  interest,  // فوائد
  other      // أخرى
}
```

**وظائف قاعدة البيانات**:
```dart
// إضافة معاملة مصرفية
Future<int> createBankTransaction(Map<String, dynamic> transaction);

// استعلام المعاملات مع فلترة
Future<List<Map<String, dynamic>>> getBankTransactions({
  String? accountNumber,
  String? bankName,
  String? type,
  String? startDate,
  String? endDate
});

// إحصائيات المعاملات
Future<Map<String, dynamic>> getBankTransactionStats();

// قائمة الحسابات المصرفية
Future<List<Map<String, dynamic>>> getBankAccounts();

// تسوية المعاملات
Future<int> reconcileBankTransaction(int id, bool isReconciled);
```

### 💻 واجهة المستخدم

#### 1. BackupSettingsScreen
**الملف**: `lib/presentation/screens/backup_settings_screen.dart`

**الميزات**:
- إعدادات النسخ الاحتياطي التلقائي
- تكامل Google Drive
- إعدادات التشفير والأمان
- جدولة النسخ الاحتياطي
- إدارة مساحة التخزين

**المكونات الرئيسية**:
```dart
class BackupSettingsScreen extends StatefulWidget {
  // أقسام الإعدادات
  Widget _buildGeneralSettings();
  Widget _buildCloudSettings();
  Widget _buildSecuritySettings();
  Widget _buildScheduleSettings();
  Widget _buildStorageSettings();
  Widget _buildAdvancedSettings();
}
```

#### 2. BackupOperationsScreen
**الملف**: `lib/presentation/screens/backup_operations_screen.dart`

**العمليات المتاحة**:
- إنشاء نسخة احتياطية يدوية
- استعادة من نسخة احتياطية
- إدارة النسخ الاحتياطية الموجودة
- مراقبة تقدم العمليات
- معاينة محتويات النسخ الاحتياطية

#### 3. Backup Widgets
**المسار**: `lib/presentation/widgets/backup/`

**المكونات**:
```dart
// CloudConnectionWidget - إدارة الاتصال السحابي
class CloudConnectionWidget extends StatefulWidget {
  // عرض حالة الاتصال
  Widget _buildConnectionStatus();
  // أزرار الاتصال/قطع الاتصال
  Widget _buildConnectionActions();
}

// BackupProgressWidget - عرض تقدم العملية
class BackupProgressWidget extends StatefulWidget {
  // شريط التقدم المتحرك
  Widget _buildProgressBar();
  // تفاصيل العملية الجارية
  Widget _buildOperationDetails();
}

// BackupListWidget - قائمة النسخ الاحتياطية
class BackupListWidget extends StatefulWidget {
  // عرض النسخ المحلية والسحابية
  Widget _buildBackupsList();
  // خيارات كل نسخة احتياطية
  Widget _buildBackupActions();
}
```

### 🔒 الأمان والتشفير

#### طبقات الحماية

1. **تشفير البيانات**:
   ```dart
   // تشفير AES-256 للملفات
   final encryptedData = await EncryptionService.encryptFile(
     filePath: backupPath,
     password: userPassword
   );
   ```

2. **التحقق من السلامة**:
   ```dart
   // إنشاء hash للتحقق من السلامة
   final dataHash = EncryptionService.generateSHA256Hash(data);
   
   // التحقق من سلامة البيانات عند الاستعادة
   final isValid = await EncryptionService.verifyDataIntegrity(
     data: restoredData,
     expectedHash: originalHash
   );
   ```

3. **حماية كلمات المرور**:
   ```dart
   // تخزين آمن لكلمات المرور
   await SecureStorage.store(
     key: 'backup_password',
     value: hashedPassword
   );
   ```

#### إعدادات الأمان

```json
{
  "encryption": {
    "algorithm": "AES-256-CBC",
    "keyDerivation": "PBKDF2",
    "iterations": 100000,
    "saltLength": 32
  },
  "integrity": {
    "hashAlgorithm": "SHA-256",
    "verifyOnRestore": true
  },
  "storage": {
    "secureKeyStorage": true,
    "autoLock": true,
    "lockTimeout": 300
  }
}
```

### 📊 الأداء والتحسين

#### تحسينات قاعدة البيانات

```sql
-- فهارس محسنة للاستعلامات السريعة
CREATE INDEX IF NOT EXISTS idx_bank_transactions_type ON bank_transactions(type);
CREATE INDEX IF NOT EXISTS idx_bank_transactions_date ON bank_transactions(transactionDate);
CREATE INDEX IF NOT EXISTS idx_bank_transactions_account ON bank_transactions(accountNumber);
CREATE INDEX IF NOT EXISTS idx_bank_transactions_bank ON bank_transactions(bankName);
```

#### تحسينات الذاكرة

```dart
class BackupService {
  // تحميل البيانات بشكل تدريجي
  Stream<Map<String, dynamic>> aggregateDataStreaming() async* {
    for (final table in tables) {
      final tableData = await _loadTableData(table);
      yield {table: tableData};
    }
  }
  
  // ضغط البيانات لتوفير المساحة
  Future<Uint8List> compressData(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    return gzip.encode(utf8.encode(jsonString));
  }
}
```

#### مراقبة الأداء

```dart
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  
  static void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
  }
  
  static Duration endTimer(String operation) {
    final timer = _timers[operation];
    timer?.stop();
    final duration = timer?.elapsed ?? Duration.zero;
    debugPrint('[$operation] completed in ${duration.inMilliseconds}ms');
    return duration;
  }
}
```

### 🧪 الاختبارات

#### اختبارات التكامل

**الملف**: `test/backup_system_integration_test.dart`

```dart
group('Backup System Integration Tests', () {
  testWidgets('should create and restore backup successfully', (tester) async {
    // إنشاء بيانات تجريبية
    await createTestData();
    
    // إنشاء نسخة احتياطية
    final backupPath = await BackupService.createLocalBackup();
    expect(backupPath, isNotNull);
    
    // مسح البيانات
    await clearDatabase();
    
    // استعادة النسخة الاحتياطية
    final result = await RestoreService.restoreFullBackup(backupPath);
    expect(result.success, isTrue);
    
    // التحقق من استعادة البيانات
    await verifyRestoredData();
  });
});
```

#### اختبارات الأداء

```dart
group('Performance Tests', () {
  test('should handle large datasets efficiently', () async {
    // إنشاء 1000 معاملة مصرفية
    for (int i = 0; i < 1000; i++) {
      await DatabaseHelper.instance.createBankTransaction(createTestTransaction(i));
    }
    
    PerformanceMonitor.startTimer('backup_large_dataset');
    final backupPath = await BackupService.createLocalBackup();
    final duration = PerformanceMonitor.endTimer('backup_large_dataset');
    
    // يجب أن تكتمل العملية في أقل من 30 ثانية
    expect(duration.inSeconds, lessThan(30));
    expect(backupPath, isNotNull);
  });
});
```

### 📈 المراقبة والتحليلات

#### إحصائيات النسخ الاحتياطي

```dart
class BackupAnalytics {
  static Future<BackupStatistics> getStatistics() async {
    return BackupStatistics(
      totalBackups: await _getTotalBackupsCount(),
      lastBackupDate: await _getLastBackupDate(),
      totalSize: await _getTotalBackupsSize(),
      successRate: await _getSuccessRate(),
      averageTime: await _getAverageBackupTime(),
      cloudUsage: await _getCloudStorageUsage(),
    );
  }
  
  static Future<void> logBackupEvent(BackupEvent event) async {
    await DatabaseHelper.instance.insertBackupLog({
      'event_type': event.type,
      'timestamp': DateTime.now().toIso8601String(),
      'duration': event.duration?.inMilliseconds,
      'size': event.size,
      'success': event.success,
      'error_message': event.errorMessage,
    });
  }
}
```

### 🚀 التحديثات المستقبلية

#### خارطة الطريق

1. **الإصدار القادم (v2.1)**:
   - نسخ احتياطي تدريجي ذكي
   - ضغط متقدم للبيانات
   - دعم عدة خدمات سحابية

2. **الإصدارات المستقبلية**:
   - نسخ احتياطي في الوقت الفعلي
   - مزامنة متعددة الأجهزة
   - تحليلات متقدمة بالذكاء الاصطناعي

#### التحسينات المخططة

```dart
// نسخ احتياطي ذكي يعتمد على التغييرات
class IncrementalBackupService {
  Future<String> createIncrementalBackup() async {
    final lastBackupHash = await getLastBackupHash();
    final currentDataHash = await calculateCurrentDataHash();
    
    if (lastBackupHash == currentDataHash) {
      return 'No changes detected';
    }
    
    final changedData = await detectChangedData(lastBackupHash);
    return await createBackupFromChanges(changedData);
  }
}
```

### 📞 الدعم التقني

للحصول على الدعم التقني أو الإبلاغ عن مشاكل في نظام النسخ الاحتياطي:

- **GitHub Issues**: [رفع مشكلة تقنية](https://github.com/ot2dz/youssef_fabric_ledger/issues)
- **التوثيق التقني**: [دليل المطور](https://docs.youssef-ledger.com/backup-system)
- **البريد الإلكتروني**: `backup-support@youssef-ledger.com`

---

**آخر تحديث**: سبتمبر 2025  
**إصدار التوثيق**: 2.0.0  
**متوافق مع**: Flutter 3.x, Dart 3.x