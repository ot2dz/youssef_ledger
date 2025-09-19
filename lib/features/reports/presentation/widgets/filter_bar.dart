import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/reports_provider.dart';
import '../../data/models.dart';
import '../../../../core/formatters/date_formatters.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تصفية التقارير',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Date Range Presets
            const _DatePresetButtons(),
            const SizedBox(height: 16),

            // Custom Date Range
            const _CustomDateRange(),
            const SizedBox(height: 16),

            // Profit Margin Slider
            const _ProfitMarginSlider(),
          ],
        ),
      ),
    );
  }
}

class _DatePresetButtons extends StatelessWidget {
  const _DatePresetButtons();

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        return Wrap(
          spacing: 8,
          children: FilterPreset.values
              .where((p) => p != FilterPreset.custom)
              .map((preset) {
                final isSelected = provider.filterState.preset == preset;

                return FilterChip(
                  label: Text(preset.displayName),
                  selected: isSelected,
                  onSelected: (_) => provider.applyPreset(preset),
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                );
              })
              .toList(),
        );
      },
    );
  }
}

class _CustomDateRange extends StatelessWidget {
  const _CustomDateRange();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        final filter = provider.filterState;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نطاق مخصص', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateSelector(
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
                const SizedBox(width: 16),
                Expanded(
                  child: _DateSelector(
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
            ),
          ],
        );
      },
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: const Icon(Icons.calendar_today, size: 18),
            ),
            child: Text(
              DateFormatters.formatShortDate(date),
              style: Theme.of(context).textTheme.bodyMedium,
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

class _ProfitMarginSlider extends StatelessWidget {
  const _ProfitMarginSlider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        final margin = provider.filterState.profitMargin;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('هامش الربح', style: theme.textTheme.labelLarge),
                Text(
                  '${(margin * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: margin,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: provider.updateProfitMargin,
              label: '${(margin * 100).toStringAsFixed(0)}%',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0%', style: theme.textTheme.labelSmall),
                  Text('100%', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
