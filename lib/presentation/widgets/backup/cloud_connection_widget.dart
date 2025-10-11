// lib/presentation/widgets/backup/cloud_connection_widget.dart
import 'package:flutter/material.dart';
import 'package:youssef_fabric_ledger/services/google_drive_service.dart';

/// Widget للاتصال والتحكم في الخدمات السحابية
class CloudConnectionWidget extends StatefulWidget {
  final GoogleDriveService googleDriveService;
  final VoidCallback? onConnectionChanged;

  const CloudConnectionWidget({
    super.key,
    required this.googleDriveService,
    this.onConnectionChanged,
  });

  @override
  State<CloudConnectionWidget> createState() => _CloudConnectionWidgetState();
}

class _CloudConnectionWidgetState extends State<CloudConnectionWidget> {
  bool _isConnecting = false;
  String? _lastError;

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.googleDriveService.isAuthenticated;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.cloud,
                  color: isConnected ? Colors.green : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Drive',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isConnected ? 'متصل' : 'غير متصل',
                        style: TextStyle(
                          color: isConnected ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildConnectionIndicator(isConnected),
              ],
            ),

            const SizedBox(height: 16),

            // Connection Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isConnected
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isConnected
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isConnected ? Icons.check_circle : Icons.info_outline,
                    color: isConnected ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isConnected
                          ? 'متصل بـ ${widget.googleDriveService.currentUser ?? "Google Drive"}'
                          : 'يمكنك الاتصال بـ Google Drive لحفظ النسخ الاحتياطية في السحابة',
                      style: TextStyle(
                        color: isConnected
                            ? Colors.green[700]
                            : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Error Message
            if (_lastError != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lastError!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _lastError = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                if (!isConnected) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isConnecting ? null : _connectToGoogleDrive,
                      icon: _isConnecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(_isConnecting ? 'جاري الاتصال...' : 'اتصال'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _getStorageInfo,
                      icon: const Icon(Icons.storage),
                      label: const Text('معلومات التخزين'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _disconnectFromGoogleDrive,
                      icon: const Icon(Icons.logout),
                      label: const Text('قطع الاتصال'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator(bool isConnected) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isConnected ? Colors.green : Colors.grey,
        boxShadow: isConnected
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }

  Future<void> _connectToGoogleDrive() async {
    setState(() {
      _isConnecting = true;
      _lastError = null;
    });

    try {
      final result = await widget.googleDriveService.authenticate();

      if (!result.success) {
        setState(() {
          _lastError = result.message;
        });
      } else {
        widget.onConnectionChanged?.call();
      }
    } catch (e) {
      setState(() {
        _lastError = 'خطأ في الاتصال: $e';
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnectFromGoogleDrive() async {
    try {
      await widget.googleDriveService.signOut();
      widget.onConnectionChanged?.call();
      setState(() {
        _lastError = null;
      });
    } catch (e) {
      setState(() {
        _lastError = 'خطأ في قطع الاتصال: $e';
      });
    }
  }

  void _getStorageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storage, color: Colors.blue),
            SizedBox(width: 8),
            Text('معلومات التخزين'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('المساحة المستخدمة', '45.2 GB'),
            _buildInfoRow('المساحة المتاحة', '9.8 GB'),
            _buildInfoRow('المساحة الإجمالية', '15 GB'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.75, // 75% used
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            const Text(
              '75% مستخدم',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // فتح إدارة التخزين
            },
            child: const Text('إدارة التخزين'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }
}
