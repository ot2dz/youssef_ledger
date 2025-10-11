import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/reports_provider.dart';
import '../../data/models.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'فلاتر التقارير',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Modern filters
            const _ModernFilterContent(),
          ],
        ),
      ),
    );
  }
}

class _ModernFilterContent extends StatelessWidget {
  const _ModernFilterContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Period Selection with Modern Pills
            _buildSectionTitle('🗓️ اختيار الفترة'),
            const SizedBox(height: 12),
            _buildPeriodPills(provider),
            const SizedBox(height: 20),

            // Report Type Selection
            _buildSectionTitle('📊 نوع التقرير'),
            const SizedBox(height: 12),
            _buildReportTypeCards(provider),

            // Custom Date Range (if custom is selected)
            if (provider.filterState.preset == FilterPreset.custom) ...[
              const SizedBox(height: 20),
              _buildSectionTitle('📅 تحديد التاريخ'),
              const SizedBox(height: 12),
              _buildCustomDateRange(provider),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildPeriodPills(ReportsProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          FilterPreset.values.where((p) => p != FilterPreset.custom).map((
            preset,
          ) {
            final isSelected = provider.filterState.preset == preset;
            return _ModernPill(
              text: preset.displayName,
              isSelected: isSelected,
              onTap: () => provider.applyPreset(preset),
            );
          }).toList()..add(
            _ModernPill(
              text: FilterPreset.custom.displayName,
              isSelected: provider.filterState.preset == FilterPreset.custom,
              onTap: () => provider.applyPreset(FilterPreset.custom),
              icon: Icons.edit_calendar,
            ),
          ),
    );
  }

  Widget _buildReportTypeCards(ReportsProvider provider) {
    return Row(
      children: ReportType.values.map((type) {
        final isSelected = provider.filterState.reportType == type;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: _ModernTypeCard(
              type: type,
              isSelected: isSelected,
              onTap: () => provider.updateReportType(type),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomDateRange(ReportsProvider provider) {
    final filter = provider.filterState;
    return Row(
      children: [
        Expanded(
          child: _ModernDateSelector(
            label: 'من تاريخ',
            date: filter.fromDate,
            icon: Icons.event_available,
            onDateSelected: (date) {
              provider.updateDateRange(
                date,
                filter.toDate,
                preset: FilterPreset.custom,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModernDateSelector(
            label: 'إلى تاريخ',
            date: filter.toDate,
            icon: Icons.event_busy,
            onDateSelected: (date) {
              provider.updateDateRange(
                filter.fromDate,
                date,
                preset: FilterPreset.custom,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModernPill extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _ModernPill({
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              )
            : null,
        color: isSelected ? null : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernTypeCard extends StatelessWidget {
  final ReportType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModernTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(type);
    final icon = _getTypeIcon(type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              )
            : null,
        color: isSelected ? null : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(icon, size: 24, color: isSelected ? Colors.white : color),
                const SizedBox(height: 8),
                Text(
                  type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(ReportType type) {
    switch (type) {
      case ReportType.all:
        return const Color(0xFF6366F1);
      case ReportType.income:
        return const Color(0xFF10B981);
      case ReportType.expenses:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.all:
        return Icons.analytics;
      case ReportType.income:
        return Icons.trending_up;
      case ReportType.expenses:
        return Icons.trending_down;
    }
  }
}

class _ModernDateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final IconData icon;
  final ValueChanged<DateTime> onDateSelected;

  const _ModernDateSelector({
    required this.label,
    required this.date,
    required this.icon,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: const Color(0xFF6366F1)),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF6366F1)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != date) {
      onDateSelected(picked);
    }
  }
}
