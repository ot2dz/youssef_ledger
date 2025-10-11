import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../features/reports/data/repository.dart';

class PdfService {
  /// إنشاء تقرير PDF للأرباح اليومية
  static Future<void> generateProfitReport({
    required List<DailyProfitData> data,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // عنوان التطبيق
            pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(bottom: 30),
              child: pw.Column(
                children: [
                  pw.Text(
                    'Youssef Fabric Ledger',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Daily Profit Report',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'From ${_formatDate(fromDate)} To ${_formatDate(toDate)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // الجدول
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FixedColumnWidth(80),
                2: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(80),
                4: const pw.FixedColumnWidth(80),
                5: const pw.FixedColumnWidth(80),
              },
              children: [
                // رأس الجدول
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableHeader('No.'),
                    _buildTableHeader('Date'),
                    _buildTableHeader('Total Income'),
                    _buildTableHeader('Gross Profit'),
                    _buildTableHeader('Expenses'),
                    _buildTableHeader('Net Profit'),
                  ],
                ),
                // البيانات
                ...data.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _buildTableCell(index.toString()),
                      _buildTableCell(_formatDate(item.date)),
                      _buildTableCell(_formatAmount(item.totalIncome)),
                      _buildTableCell(_formatAmount(item.grossProfit)),
                      _buildTableCell(_formatAmount(item.totalExpenses)),
                      _buildTableCell(_formatAmount(item.netProfit)),
                    ],
                  );
                }).toList(),
              ],
            ),

            // الإجماليات
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TOTALS:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Total Income: ${_formatAmount(data.fold(0.0, (sum, item) => sum + item.totalIncome))}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Gross Profit: ${_formatAmount(data.fold(0.0, (sum, item) => sum + item.grossProfit))}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Total Expenses: ${_formatAmount(data.fold(0.0, (sum, item) => sum + item.totalExpenses))}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Net Profit: ${_formatAmount(data.fold(0.0, (sum, item) => sum + item.netProfit))}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // تاريخ الإنشاء
            pw.SizedBox(height: 30),
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Generated on: ${_formatDateTime(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // حفظ ومشاركة الملف
    await _savePdf(
      pdf,
      'Profit_Report_${_formatDateForFilename(DateTime.now())}',
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String _formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String _formatDateForFilename(DateTime date) {
    return DateFormat('yyyy-MM-dd_HH-mm').format(date);
  }

  static String _formatAmount(double amount) {
    if (amount == 0) return '0.00 DZD';

    final isNegative = amount < 0;
    final absAmount = amount.abs();

    final formatter = NumberFormat('#,##0.00');
    final formattedAmount = formatter.format(absAmount);

    final sign = isNegative ? '-' : '';
    return '$sign$formattedAmount DZD';
  }

  static Future<void> _savePdf(pw.Document pdf, String filename) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$filename.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Profit Report from Youssef Fabric Ledger');
    } catch (e) {
      throw Exception('Error saving PDF file: $e');
    }
  }
}
