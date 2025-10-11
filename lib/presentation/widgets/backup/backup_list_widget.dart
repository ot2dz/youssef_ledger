// lib/presentation/widgets/backup/backup_list_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget لعرض قائمة النسخ الاحتياطية
class BackupListWidget extends StatefulWidget {
  final List<BackupListItem> backups;
  final Function(BackupListItem)? onRestore;
  final Function(BackupListItem)? onDelete;
  final Function(BackupListItem)? onDownload;
  final Function(BackupListItem)? onShare;
  final Function(BackupListItem)? onInfo;
  final bool isLoading;
  final String? emptyMessage;
  final Widget? emptyWidget;

  const BackupListWidget({
    super.key,
    required this.backups,
    this.onRestore,
    this.onDelete,
    this.onDownload,
    this.onShare,
    this.onInfo,
    this.isLoading = false,
    this.emptyMessage,
    this.emptyWidget,
  });

  @override
  State<BackupListWidget> createState() => _BackupListWidgetState();
}

class _BackupListWidgetState extends State<BackupListWidget> {
  String _sortBy = 'date'; // 'date', 'size', 'name'
  bool _sortAscending = false;
  String _filterBy = 'all'; // 'all', 'encrypted', 'local', 'cloud'

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('تحميل النسخ الاحتياطية...'),
          ],
        ),
      );
    }

    final filteredBackups = _getFilteredAndSortedBackups();

    if (filteredBackups.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Controls
        _buildControlsBar(),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filteredBackups.length,
            itemBuilder: (context, index) {
              return _buildBackupItem(filteredBackups[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Sort Menu
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _sortBy = value),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort, size: 20),
                const SizedBox(width: 4),
                Text(_getSortLabel()),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date', child: Text('التاريخ')),
              const PopupMenuItem(value: 'size', child: Text('الحجم')),
              const PopupMenuItem(value: 'name', child: Text('الاسم')),
            ],
          ),

          // Sort Direction
          IconButton(
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
            icon: Icon(
              _sortAscending
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 20,
            ),
            tooltip: _sortAscending ? 'تصاعدي' : 'تنازلي',
          ),

          const SizedBox(width: 16),

          // Filter Menu
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _filterBy = value),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list, size: 20),
                const SizedBox(width: 4),
                Text(_getFilterLabel()),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('الكل')),
              const PopupMenuItem(value: 'encrypted', child: Text('مشفر')),
              const PopupMenuItem(value: 'local', child: Text('محلي')),
              const PopupMenuItem(value: 'cloud', child: Text('سحابي')),
            ],
          ),

          const Spacer(),

          // Count
          Text(
            '${_getFilteredAndSortedBackups().length} نسخة',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupItem(BackupListItem backup) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: () => widget.onInfo?.call(backup),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Type Icon
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getTypeColor(backup.type),
                    child: Icon(
                      _getTypeIcon(backup.type),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          backup.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(backup.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleAction(action, backup),
                    itemBuilder: (context) => _buildMenuItems(backup),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details Row
              Row(
                children: [
                  // Size
                  _buildDetailChip(
                    icon: Icons.data_usage,
                    label: backup.size,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),

                  // Encryption
                  if (backup.isEncrypted)
                    _buildDetailChip(
                      icon: Icons.lock,
                      label: 'مشفر',
                      color: Colors.orange,
                    ),
                  if (backup.isEncrypted) const SizedBox(width: 8),

                  // Records Count
                  if (backup.recordsCount != null)
                    _buildDetailChip(
                      icon: Icons.list_alt,
                      label: '${backup.recordsCount} سجل',
                      color: Colors.green,
                    ),
                ],
              ),

              // Description
              if (backup.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  backup.description!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],

              // Status
              if (backup.status != BackupItemStatus.completed) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(backup.status),
                      size: 16,
                      color: _getStatusColor(backup.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusText(backup.status),
                      style: TextStyle(
                        color: _getStatusColor(backup.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.backup_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            widget.emptyMessage ?? 'لا توجد نسخ احتياطية',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإنشاء نسخة احتياطية جديدة',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  List<BackupListItem> _getFilteredAndSortedBackups() {
    var filtered = widget.backups.where((backup) {
      switch (_filterBy) {
        case 'encrypted':
          return backup.isEncrypted;
        case 'local':
          return backup.type == BackupType.local;
        case 'cloud':
          return backup.type == BackupType.cloud;
        default:
          return true;
      }
    }).toList();

    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'size':
          comparison = (a.sizeBytes ?? 0).compareTo(b.sizeBytes ?? 0);
          break;
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        default: // date
          comparison = a.createdAt.compareTo(b.createdAt);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'size':
        return 'الحجم';
      case 'name':
        return 'الاسم';
      default:
        return 'التاريخ';
    }
  }

  String _getFilterLabel() {
    switch (_filterBy) {
      case 'encrypted':
        return 'مشفر';
      case 'local':
        return 'محلي';
      case 'cloud':
        return 'سحابي';
      default:
        return 'الكل';
    }
  }

  Color _getTypeColor(BackupType type) {
    switch (type) {
      case BackupType.local:
        return Colors.blue;
      case BackupType.cloud:
        return Colors.green;
    }
  }

  IconData _getTypeIcon(BackupType type) {
    switch (type) {
      case BackupType.local:
        return Icons.phone_android;
      case BackupType.cloud:
        return Icons.cloud;
    }
  }

  Color _getStatusColor(BackupItemStatus status) {
    switch (status) {
      case BackupItemStatus.completed:
        return Colors.green;
      case BackupItemStatus.inProgress:
        return Colors.blue;
      case BackupItemStatus.failed:
        return Colors.red;
      case BackupItemStatus.cancelled:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(BackupItemStatus status) {
    switch (status) {
      case BackupItemStatus.completed:
        return Icons.check_circle;
      case BackupItemStatus.inProgress:
        return Icons.sync;
      case BackupItemStatus.failed:
        return Icons.error;
      case BackupItemStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(BackupItemStatus status) {
    switch (status) {
      case BackupItemStatus.completed:
        return 'مكتمل';
      case BackupItemStatus.inProgress:
        return 'قيد التقدم';
      case BackupItemStatus.failed:
        return 'فشل';
      case BackupItemStatus.cancelled:
        return 'ملغي';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'اليوم ${DateFormat('HH:mm').format(date)}';
    } else if (diff.inDays == 1) {
      return 'أمس ${DateFormat('HH:mm').format(date)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} أيام ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BackupListItem backup) {
    final items = <PopupMenuEntry<String>>[];

    if (widget.onRestore != null) {
      items.add(
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
      );
    }

    if (widget.onDownload != null && backup.type == BackupType.cloud) {
      items.add(
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
      );
    }

    if (widget.onShare != null) {
      items.add(
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
      );
    }

    if (widget.onInfo != null) {
      items.add(
        const PopupMenuItem(
          value: 'info',
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('تفاصيل'),
            ],
          ),
        ),
      );
    }

    if (widget.onDelete != null) {
      if (items.isNotEmpty) {
        items.add(const PopupMenuDivider());
      }
      items.add(
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
      );
    }

    return items;
  }

  void _handleAction(String action, BackupListItem backup) {
    switch (action) {
      case 'restore':
        widget.onRestore?.call(backup);
        break;
      case 'download':
        widget.onDownload?.call(backup);
        break;
      case 'share':
        widget.onShare?.call(backup);
        break;
      case 'info':
        widget.onInfo?.call(backup);
        break;
      case 'delete':
        widget.onDelete?.call(backup);
        break;
    }
  }
}

/// عنصر في قائمة النسخ الاحتياطية
class BackupListItem {
  final String id;
  final String name;
  final DateTime createdAt;
  final String size;
  final int? sizeBytes;
  final bool isEncrypted;
  final BackupType type;
  final BackupItemStatus status;
  final String? description;
  final int? recordsCount;
  final Map<String, dynamic>? metadata;

  BackupListItem({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.size,
    this.sizeBytes,
    required this.isEncrypted,
    required this.type,
    this.status = BackupItemStatus.completed,
    this.description,
    this.recordsCount,
    this.metadata,
  });
}

/// نوع النسخة الاحتياطية
enum BackupType {
  local, // محلي
  cloud, // سحابي
}

/// حالة عنصر النسخة الاحتياطية
enum BackupItemStatus {
  completed, // مكتمل
  inProgress, // قيد التقدم
  failed, // فشل
  cancelled, // ملغي
}
