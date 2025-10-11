// lib/presentation/widgets/backup/backup_progress_widget.dart
import 'package:flutter/material.dart';

/// Widget لعرض تقدم عمليات النسخ الاحتياطي والاستعادة
class BackupProgressWidget extends StatefulWidget {
  final String title;
  final String? subtitle;
  final double progress;
  final bool isActive;
  final Color? primaryColor;
  final VoidCallback? onCancel;
  final Widget? leadingIcon;

  const BackupProgressWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.progress,
    required this.isActive,
    this.primaryColor,
    this.onCancel,
    this.leadingIcon,
  });

  @override
  State<BackupProgressWidget> createState() => _BackupProgressWidgetState();
}

class _BackupProgressWidgetState extends State<BackupProgressWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _animationController.forward();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BackupProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.progress != oldWidget.progress) {
      _progressAnimation =
          Tween<double>(
            begin: oldWidget.progress,
            end: widget.progress,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            ),
          );
      _animationController.reset();
      _animationController.forward();
    }

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor ?? Theme.of(context).primaryColor;

    return Card(
      elevation: widget.isActive ? 8 : 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: widget.isActive
              ? LinearGradient(
                  colors: [color.withOpacity(0.05), color.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                if (widget.leadingIcon != null) ...[
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: widget.isActive ? _pulseAnimation.value : 1.0,
                        child: widget.leadingIcon,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.isActive ? color : null,
                            ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.onCancel != null && widget.isActive)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel,
                    tooltip: 'إلغاء',
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'التقدم',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Text(
                          '${(_progressAnimation.value * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 8,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Status Indicators
            if (widget.isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'جاري المعالجة...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget مبسط لعرض تقدم سريع
class SimpleProgressWidget extends StatelessWidget {
  final double progress;
  final String? label;
  final Color? color;
  final double height;

  const SimpleProgressWidget({
    super.key,
    required this.progress,
    this.label,
    this.color,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label!, style: Theme.of(context).textTheme.bodySmall),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget لعرض حالة متعددة المراحل
class MultiStageProgressWidget extends StatelessWidget {
  final List<ProgressStage> stages;
  final int currentStage;
  final Color? primaryColor;

  const MultiStageProgressWidget({
    super.key,
    required this.stages,
    required this.currentStage,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? Theme.of(context).primaryColor;

    return Column(
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          Row(
            children: [
              // Stage Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStageColor(i, color),
                  border: Border.all(color: _getStageColor(i, color), width: 2),
                ),
                child: Icon(
                  _getStageIcon(i),
                  size: 16,
                  color: i <= currentStage ? Colors.white : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),

              // Stage Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stages[i].title,
                      style: TextStyle(
                        fontWeight: i == currentStage
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: i <= currentStage ? color : Colors.grey,
                      ),
                    ),
                    if (stages[i].description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        stages[i].description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),

              // Stage Status
              if (i < currentStage)
                Icon(Icons.check, color: color, size: 20)
              else if (i == currentStage)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
            ],
          ),

          // Connector Line
          if (i < stages.length - 1)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Container(
                width: 2,
                height: 20,
                color: i < currentStage ? color : Colors.grey[300],
              ),
            ),
        ],
      ],
    );
  }

  Color _getStageColor(int index, Color primaryColor) {
    if (index < currentStage) return primaryColor;
    if (index == currentStage) return primaryColor;
    return Colors.grey[300]!;
  }

  IconData _getStageIcon(int index) {
    if (index < currentStage) return Icons.check;
    return stages[index].icon ?? Icons.radio_button_unchecked;
  }
}

/// معلومات مرحلة في التقدم متعدد المراحل
class ProgressStage {
  final String title;
  final String? description;
  final IconData? icon;

  const ProgressStage({required this.title, this.description, this.icon});
}
