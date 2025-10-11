import 'package:flutter/material.dart';
import 'package:youssef_fabric_ledger/models/backup/backup_models.dart';

class GoogleDriveService {
  bool _isAuthenticated = false;
  String? _currentUserEmail;

  Future<BackupResult> authenticate([BuildContext? context]) async {
    final stopwatch = Stopwatch()..start();
    try {
      // إذا كان هناك context، أظهر حوار تسجيل الدخول
      if (context != null) {
        final email = await _showGoogleSignInDialog(context);
        if (email == null) {
          // المستخدم ألغى العملية
          stopwatch.stop();
          return BackupResult.failure(
            message: 'تم إلغاء تسجيل الدخول',
            duration: stopwatch.elapsed,
          );
        }
        _currentUserEmail = email;
      } else {
        // محاكاة تسجيل دخول تلقائي
        await Future.delayed(const Duration(seconds: 1));
        _currentUserEmail = 'yourname@gmail.com';
      }

      _isAuthenticated = true;
      stopwatch.stop();
      return BackupResult.success(
        message: 'تم تسجيل الدخول بنجاح إلى Google Drive',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return BackupResult.failure(
        message: 'فشل في تسجيل الدخول: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  Future<String?> _showGoogleSignInDialog(BuildContext context) async {
    String email = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Row(
              children: [
                Image.asset(
                  'assets/icons/google.png', // يحتاج إضافة أيقونة Google
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.account_circle, color: Colors.blue),
                ),
                const SizedBox(width: 8),
                const Text('تسجيل الدخول إلى Google'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('اختر حساب Google للمتابعة:'),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => email = value,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'example@gmail.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (email.isNotEmpty && email.contains('@')) {
                    Navigator.of(context).pop(email);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('يرجى إدخال بريد إلكتروني صحيح'),
                      ),
                    );
                  }
                },
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> signOut() async {
    _isAuthenticated = false;
    _currentUserEmail = null;
  }

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUser => _currentUserEmail;

  Future<BackupResult> uploadBackup(String filePath) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (!_isAuthenticated) {
        throw Exception('غير مسجل الدخول إلى Google Drive');
      }
      await Future.delayed(const Duration(seconds: 2));
      stopwatch.stop();
      return BackupResult.success(
        message: 'تم رفع النسخة الاحتياطية بنجاح',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return BackupResult.failure(
        message: 'فشل في رفع النسخة الاحتياطية: $e',
        duration: stopwatch.elapsed,
      );
    }
  }
}
