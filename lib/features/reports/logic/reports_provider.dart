import 'package:flutter/foundation.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../../../data/local/database_helper.dart';
import '../../../services/pdf_service.dart';

/// Provider for managing reports state and data loading
class ReportsProvider extends ChangeNotifier {
  final ReportsRepository _repository;

  ReportFilterState _filterState = ReportFilterState.defaultWeek();
  ReportDataState _reportData = const ReportDataState();

  ReportsProvider() : _repository = ReportsRepository(DatabaseHelper.instance);

  ReportFilterState get filterState => _filterState;
  ReportDataState get reportData => _reportData;

  /// Update filter state and reload data
  Future<void> updateFilter(ReportFilterState newFilter) async {
    _filterState = newFilter;
    notifyListeners();
    await loadReportData();
  }

  /// Update date range while keeping other filter settings
  Future<void> updateDateRange(
    DateTime fromDate,
    DateTime toDate, {
    FilterPreset? preset,
  }) async {
    _filterState = _filterState.copyWith(
      fromDate: fromDate,
      toDate: toDate,
      preset: preset ?? FilterPreset.custom,
    );
    notifyListeners();
    await loadReportData();
  }

  /// Update profit margin and reload data
  Future<void> updateProfitMargin(double margin) async {
    _filterState = _filterState.copyWith(profitMargin: margin);
    notifyListeners();
    await loadReportData();
  }

  /// Update report type and reload data
  Future<void> updateReportType(ReportType reportType) async {
    _filterState = _filterState.copyWith(reportType: reportType);
    notifyListeners();
    await loadReportData();
  }

  /// Apply filter preset (week/month/year)
  Future<void> applyPreset(FilterPreset preset) async {
    switch (preset) {
      case FilterPreset.week:
        _filterState = ReportFilterState.defaultWeek().copyWith(
          profitMargin: _filterState.profitMargin,
          reportType: _filterState.reportType,
        );
        break;
      case FilterPreset.month:
        _filterState = ReportFilterState.month().copyWith(
          profitMargin: _filterState.profitMargin,
          reportType: _filterState.reportType,
        );
        break;
      case FilterPreset.year:
        _filterState = ReportFilterState.year().copyWith(
          profitMargin: _filterState.profitMargin,
          reportType: _filterState.reportType,
        );
        break;
      case FilterPreset.custom:
        // Keep current dates for custom
        _filterState = _filterState.copyWith(preset: FilterPreset.custom);
        break;
    }
    notifyListeners();
    await loadReportData();
  }

  /// Load report data from repository
  Future<void> loadReportData() async {
    _reportData = _reportData.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final newData = await _repository.getReportData(_filterState);
      _reportData = newData;
    } catch (e) {
      _reportData = _reportData.copyWith(
        isLoading: false,
        error: 'خطأ في تحميل التقارير: ${e.toString()}',
      );
    }

    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadReportData();
  }

  /// إنشاء تقرير PDF للأرباح
  Future<void> generatePdfReport() async {
    try {
      final data = await _repository.getDailyProfitDataForPdf(
        _filterState.fromDate,
        _filterState.toDate,
      );

      await PdfService.generateProfitReport(
        data: data,
        fromDate: _filterState.fromDate,
        toDate: _filterState.toDate,
      );
    } catch (e) {
      debugPrint('خطأ في إنشاء تقرير PDF: $e');
      rethrow;
    }
  }
}
