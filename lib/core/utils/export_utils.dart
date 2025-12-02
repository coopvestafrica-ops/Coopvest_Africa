import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';

/// Utility class for exporting transaction data to various formats
class ExportUtils {
  static final _currencyFormatter = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
  static final _dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Escapes special characters in CSV fields
  static String _escapeCSVField(String field) {
    if (field.contains(RegExp(r'[",\n\r]'))) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Exports transactions to a CSV file with proper formatting and encoding
  static Future<File> exportToCSV(
    List<Transaction> transactions, {
    String? prefix,
    bool includeHeaders = true,
  }) async {
    try {
      if (transactions.isEmpty) {
        throw Exception('No transactions to export');
      }

      // Prepare data with proper escaping for CSV
      final rows = <List<dynamic>>[];

      // Add headers if requested
      if (includeHeaders) {
        rows.add([
          'Date',
          'Type',
          'Category',
          'Description',
          'Amount',
          'Reference',
        ]);
      }

      // Add data with proper formatting and escaping
      rows.addAll(transactions.map((t) => [
        _dateFormatter.format(t.date),
        t.type.toString().split('.').last,
        t.category.name,
        _escapeCSVField(t.description),
        _currencyFormatter.format(t.amount),
        _escapeCSVField(t.reference ?? ''),
      ]));

      final csv = ListToCsvConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        textEndDelimiter: '"',
        eol: '\r\n',
      ).convert(rows);

      final output = await getTemporaryDirectory()
        .catchError((e) => throw Exception('Failed to access temporary directory: $e'));
        
      final fileName = '${prefix ?? 'transactions'}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${output.path}/$fileName');

      // Add BOM for Excel compatibility
      final List<int> bom = [0xEF, 0xBB, 0xBF];
      await file.writeAsBytes(bom + const Utf8Encoder().convert(csv))
        .catchError((e) => throw Exception('Failed to write CSV file: $e'));

      return file;
    } catch (e) {
      throw Exception('Failed to export CSV file: $e');
    }
  }

  /// Exports transactions to an Excel file with proper formatting and styling
  static Future<File> exportToExcel(List<Transaction> transactions, {String? prefix}) async {
    try {
      if (transactions.isEmpty) {
        throw Exception('No transactions to export');
      }

      final excel = Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet()!];

      // Style for headers
      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Add header
      final headers = [
        'Date',
        'Type',
        'Category',
        'Description',
        'Amount',
        'Reference'
      ];

      // Add headers with style
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = headerStyle;
      }

      // Add data
      int rowIndex = 1;
      for (var transaction in transactions) {
        final row = [
          _dateFormatter.format(transaction.date),
          transaction.type.toString().split('.').last,
          transaction.category.name,
          transaction.description,
          _currencyFormatter.format(transaction.amount),
          transaction.reference ?? '',
        ];

        // Add cells with proper styling
        for (var i = 0; i < row.length; i++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: i,
            rowIndex: rowIndex,
          ));
          
          cell.value = TextCellValue(row[i].toString());
          
          // Right-align amount column
          if (i == 4) { // Amount column
            cell.cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right);
          }
        }
        rowIndex++;
      }

      // Column widths are set automatically by the excel package

      try {
        final output = await getTemporaryDirectory()
          .catchError((e) => throw Exception('Failed to access temporary directory: $e'));
          
        final fileName = '${prefix ?? 'transactions'}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final file = File('${output.path}/$fileName');

        final bytes = excel.save();
        if (bytes == null) {
          throw Exception('Failed to encode Excel file');
        }

        await file.writeAsBytes(bytes)
          .catchError((e) => throw Exception('Failed to write Excel file: $e'));
          
        return file;
      } catch (e) {
        throw Exception('Failed to save Excel file: $e');
      }
    } catch (e) {
      throw Exception('Failed to export Excel file: $e');
    }
  }
}
