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
                  child: const Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: 18,
                  ),
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

class _CompactFilterRow extends StatelessWidget {
  const _CompactFilterRow();

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // First row: Date presets and report type
            Row(
              children: [
                // Date presets (compact)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الفترة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: FilterPreset.values
                            .where((p) => p != FilterPreset.custom)
                            .map((preset) {
                              final isSelected =
                                  provider.filterState.preset == preset;
                              return Container(
                                height: 32,
                                child: FilterChip(
                                  label: Text(
                                    preset.displayName,
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      provider.applyPreset(preset),
                                  selectedColor: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.2),
                                  checkmarkColor: const Color(0xFF6366F1),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Report type (compact)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'النوع',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<ReportType>(
                          value: provider.filterState.reportType,
                          isExpanded: true,
                          underline: const SizedBox(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          onChanged: (ReportType? newValue) {
                            if (newValue != null) {
                              provider.updateReportType(newValue);
                            }
                          },
                          items: ReportType.values
                              .map<DropdownMenuItem<ReportType>>((
                                ReportType type,
                              ) {
                                return DropdownMenuItem<ReportType>(
                                  value: type,
                                  child: Text(type.displayName),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Second row: Custom date range (only if custom is selected)
            if (provider.filterState.preset == FilterPreset.custom) ...[
              const SizedBox(height: 12),
              const _CompactCustomDateRange(),
            ],
          ],
        );
      },
    );
  }
}

class _CompactCustomDateRange extends StatelessWidget {
  const _CompactCustomDateRange();

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        final filter = provider.filterState;
        return Row(
          children: [
            Expanded(
              child: _CompactDateSelector(
                label: 'من',
                date: filter.fromDate,
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
              child: _CompactDateSelector(
                label: 'إلى',
                date: filter.toDate,
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
      },
    );
  }
}

class _CompactDateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;

  const _CompactDateSelector({
    required this.label,
    required this.date,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );

    if (picked != null && picked != date) {
      onDateSelected(picked);
    }
  }
}
