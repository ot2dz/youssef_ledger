// lib/presentation/screens/backup_operations_screen.dart
import 'package:flutter/material.dart';
import 'package:youssef_fabric_ledger/models/backup/backup_models.dart';
import 'package:youssef_fabric_ledger/services/backup_service.dart';
import 'package:youssef_fabric_ledger/services/google_drive_service.dart';
import 'package:youssef_fabric_ledger/data/local/database_helper.dart';

/// شاشة عمليات النسخ الاحتياطي والاستعادة
class BackupOperationsScreen extends StatefulWidget {
  const BackupOperationsScreen({super.key});

  @override
  State<BackupOperationsScreen> createState() => _BackupOperationsScreenState();
}

class _BackupOperationsScreenState extends State<BackupOperationsScreen> {
  late BackupService _backupService;
  late GoogleDriveService _googleDriveService;

  bool _isBackupInProgress = false;
  bool _isRestoreInProgress = false;
  double _backupProgress = 0.0;
  double _restoreProgress = 0.0;
  String? _statusMessage;
  List<BackupFileInfo> _localBackups = [];
  List<BackupFileInfo> _cloudBackups = [];

  @override
  void initState() {
    super.initState();
    _backupService = BackupService(DatabaseHelper.instance);
    _googleDriveService = GoogleDriveService();
    _loadBackupsList();
  }

  Future<void> _loadBackupsList() async {
    try {
      // تحميل النسخ المحلية
      _localBackups = await _getLocalBackups();

      // تحميل النسخ السحابية
      if (_googleDriveService.isAuthenticated) {
        _cloudBackups = await _getCloudBackups();
      }

      setState(() {});
    } catch (e) {
      _showSnackBar('خطأ في تحميل قائمة النسخ: $e', Colors.red);
    }
  }

  Future<List<BackupFileInfo>> _getLocalBackups() async {
    // محاكاة تحميل النسخ المحلية
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      BackupFileInfo(
        name: 'backup_2025_09_20.json',
        date: DateTime.now().subtract(const Duration(hours: 1)),
        size: '2.5 MB',
        isEncrypted: true,
        location: BackupLocation.local,
      ),
      BackupFileInfo(
        name: 'backup_2025_09_19.json',
        date: DateTime.now().subtract(const Duration(days: 1)),
        size: '2.3 MB',
        isEncrypted: false,
        location: BackupLocation.local,
      ),
    ];
  }

  Future<List<BackupFileInfo>> _getCloudBackups() async {
    // محاكاة تحميل النسخ السحابية
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      BackupFileInfo(
        name: 'backup_2025_09_20.json',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        size: '2.5 MB',
        isEncrypted: true,
        location: BackupLocation.cloud,
      ),
      BackupFileInfo(
        name: 'backup_2025_09_18.json',
        date: DateTime.now().subtract(const Duration(days: 2)),
        size: '2.1 MB',
        isEncrypted: true,
        location: BackupLocation.cloud,
      ),
    ];
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _createBackup({required BackupLocation location}) async {
    if (_isBackupInProgress) return;

    setState(() {
      _isBackupInProgress = true;
      _backupProgress = 0.0;
      _statusMessage = 'بدء إنشاء النسخة الاحتياطية...';
    });

    try {
      // تحديث التقدم - جمع البيانات
      setState(() {
        _backupProgress = 0.2;
        _statusMessage = 'جمع البيانات من قاعدة البيانات...';
      });
      await Future.delayed(const Duration(seconds: 1));

      // تحديث التقدم - معالجة البيانات
      setState(() {
        _backupProgress = 0.4;
        _statusMessage = 'معالجة وتنظيم البيانات...';
      });
      await Future.delayed(const Duration(seconds: 1));

      // تحديث التقدم - التشفير (إن وجد)
      setState(() {
        _backupProgress = 0.6;
        _statusMessage = 'تشفير البيانات...';
      });
      await Future.delayed(const Duration(seconds: 1));

      // إنشاء النسخة الاحتياطية
      final result = await _backupService.createBackup(
        source: BackupSource.manual, // سواء محلي أو سحابي، المصدر يدوي
        encrypt: true,
        encryptionPassword: 'test123', // في التطبيق الحقيقي ستأتي من الإعدادات
      );

      if (result.success) {
        if (location == BackupLocation.cloud &&
            _googleDriveService.isAuthenticated) {
          // رفع إلى السحابة
          setState(() {
            _backupProgress = 0.8;
            _statusMessage = 'رفع النسخة إلى Google Drive...';
          });
          await Future.delayed(const Duration(seconds: 2));

          // محاكاة الرفع
          final uploadResult = await _googleDriveService.uploadBackup(
            result.filePath!,
          );

          if (uploadResult.success) {
            setState(() {
              _backupProgress = 1.0;
              _statusMessage = 'تم إنشاء ورفع النسخة الاحتياطية بنجاح';
            });
          } else {
            throw Exception('فشل في رفع النسخة: ${uploadResult.message}');
          }
        } else {
          setState(() {
            _backupProgress = 1.0;
            _statusMessage = 'تم إنشاء النسخة الاحتياطية بنجاح';
          });
        }

        _showSnackBar('تم إنشاء النسخة الاحتياطية بنجاح', Colors.green);
        await _loadBackupsList(); // إعادة تحميل القائمة
      } else {
        throw Exception(result.message);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'فشل في إنشاء النسخة الاحتياطية';
      });
      _showSnackBar('خطأ: $e', Colors.red);
    } finally {
      setState(() {
        _isBackupInProgress = false;
      });

      // إخفاء رسالة الحالة بعد 3 ثواني
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _statusMessage = null;
          });
        }
      });
    }
  }

  Future<void> _restoreBackup(BackupFileInfo backupInfo) async {
    if (_isRestoreInProgress) return;

    // تأكيد الاستعادة
    final confirmed = await _showRestoreConfirmDialog(backupInfo);
    if (!confirmed) return;

    setState(() {
      _isRestoreInProgress = true;
      _restoreProgress = 0.0;
      _statusMessage = 'بدء استعادة النسخة الاحتياطية...';
    });

    try {
      // تحديث التقدم - تحميل الملف
      setState(() {
        _restoreProgress = 0.2;
        _statusMessage = 'تحميل ملف النسخة الاحتياطية...';
      });
      await Future.delayed(const Duration(seconds: 1));

      // تحديث التقدم - فك التشفير
      if (backupInfo.isEncrypted) {
        setState(() {
          _restoreProgress = 0.4;
          _statusMessage = 'فك تشفير البيانات...';
        });
        await Future.delayed(const Duration(seconds: 1));
      }

      // تحديث التقدم - التحقق من البيانات
      setState(() {
        _restoreProgress = 0.6;
        _statusMessage = 'التحقق من صحة البيانات...';
      });
      await Future.delayed(const Duration(seconds: 1));

      // تحديث التقدم - استعادة البيانات
      setState(() {
        _restoreProgress = 0.8;
        _statusMessage = 'استعادة البيانات إلى قاعدة البيانات...';
      });
      await Future.delayed(const Duration(seconds: 2));

      // محاكاة الاستعادة
      setState(() {
        _restoreProgress = 1.0;
        _statusMessage = 'تم استعادة النسخة الاحتياطية بنجاح';
      });

      _showSnackBar('تم استعادة البيانات بنجاح', Colors.green);
    } catch (e) {
      setState(() {
        _statusMessage = 'فشل في استعادة النسخة الاحتياطية';
      });
      _showSnackBar('خطأ في الاستعادة: $e', Colors.red);
    } finally {
      setState(() {
        _isRestoreInProgress = false;
      });

      // إخفاء رسالة الحالة بعد 3 ثواني
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _statusMessage = null;
          });
        }
      });
    }
  }

  Future<bool> _showRestoreConfirmDialog(BackupFileInfo backupInfo) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الاستعادة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('هل أنت متأكد من استعادة هذة النسخة الاحتياطية؟'),
                const SizedBox(height: 16),
                Text(
                  'الملف: ${backupInfo.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('التاريخ: ${_formatDate(backupInfo.date)}'),
                Text('الحجم: ${backupInfo.size}'),
                if (backupInfo.isEncrypted)
                  const Row(
                    children: [
                      Icon(Icons.lock, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text('مشفر', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Text(
                    '⚠️ تحذير: ستستبدل جميع البيانات الحالية',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('استعادة'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'النسخ الاحتياطي والاستعادة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackupsList,
            tooltip: 'تحديث القائمة',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط التقدم وحالة العملية
          if (_isBackupInProgress ||
              _isRestoreInProgress ||
              _statusMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Column(
                children: [
                  if (_statusMessage != null) ...[
                    Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_isBackupInProgress) ...[
                    LinearProgressIndicator(
                      value: _backupProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${(_backupProgress * 100).toInt()}%'),
                  ] else if (_isRestoreInProgress) ...[
                    LinearProgressIndicator(
                      value: _restoreProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${(_restoreProgress * 100).toInt()}%'),
                  ],
                ],
              ),
            ),

          // أزرار العمليات السريعة
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isBackupInProgress || _isRestoreInProgress
                        ? null
                        : () => _createBackup(location: BackupLocation.local),
                    icon: const Icon(Icons.save),
                    label: const Text('نسخ محلي'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isBackupInProgress ||
                            _isRestoreInProgress ||
                            !_googleDriveService.isAuthenticated
                        ? null
                        : () => _createBackup(location: BackupLocation.cloud),
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('نسخ سحابي'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // قائمة النسخ الاحتياطية
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: const Color(0xFF6366F1),
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: const Color(0xFF6366F1),
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.phone_android),
                        text: 'النسخ المحلية',
                      ),
                      Tab(icon: Icon(Icons.cloud), text: 'النسخ السحابية'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildBackupsList(_localBackups, BackupLocation.local),
                        _buildBackupsList(_cloudBackups, BackupLocation.cloud),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupsList(
    List<BackupFileInfo> backups,
    BackupLocation location,
  ) {
    if (backups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              location == BackupLocation.local
                  ? Icons.phone_android
                  : Icons.cloud_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              location == BackupLocation.local
                  ? 'لا توجد نسخ احتياطية محلية'
                  : 'لا توجد نسخ احتياطية سحابية',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            if (location == BackupLocation.cloud &&
                !_googleDriveService.isAuthenticated) ...[
              const SizedBox(height: 8),
              const Text(
                'يجب تسجيل الدخول إلى Google Drive',
                style: TextStyle(color: Colors.orange, fontSize: 14),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: backups.length,
      itemBuilder: (context, index) {
        final backup = backups[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: location == BackupLocation.local
                  ? const Color(0xFF6366F1)
                  : Colors.green,
              child: Icon(
                location == BackupLocation.local
                    ? Icons.phone_android
                    : Icons.cloud,
                color: Colors.white,
              ),
            ),
            title: Text(
              backup.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(backup.date)),
                Row(
                  children: [
                    Text(backup.size),
                    if (backup.isEncrypted) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.lock, size: 16, color: Colors.orange),
                      const Text(
                        ' مشفر',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'restore':
                    _restoreBackup(backup);
                    break;
                  case 'download':
                    _downloadBackup(backup);
                    break;
                  case 'delete':
                    _deleteBackup(backup);
                    break;
                  case 'share':
                    _shareBackup(backup);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.restore, color: Colors.green),
                      SizedBox(width: 8),
                      Text('استعادة'),
                    ],
                  ),
                ),
                if (location == BackupLocation.cloud)
                  const PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(Icons.download, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('تحميل'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('مشاركة'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _downloadBackup(BackupFileInfo backup) {
    // محاكاة تحميل النسخة
    _showSnackBar('تم بدء تحميل النسخة الاحتياطية', Colors.blue);
  }

  void _deleteBackup(BackupFileInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف النسخة الاحتياطية "${backup.name}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // محاكاة حذف النسخة
      _showSnackBar('تم حذف النسخة الاحتياطية', Colors.orange);
      await _loadBackupsList();
    }
  }

  void _shareBackup(BackupFileInfo backup) {
    // محاكاة مشاركة النسخة
    _showSnackBar('تم فتح خيارات المشاركة', Colors.blue);
  }
}

/// معلومات ملف النسخة الاحتياطية
class BackupFileInfo {
  final String name;
  final DateTime date;
  final String size;
  final bool isEncrypted;
  final BackupLocation location;

  BackupFileInfo({
    required this.name,
    required this.date,
    required this.size,
    required this.isEncrypted,
    required this.location,
  });
}

/// مكان النسخة الاحتياطية
enum BackupLocation {
  local, // محلي
  cloud, // سحابي
}
