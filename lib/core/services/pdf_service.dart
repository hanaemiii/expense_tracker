import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/painting.dart' show Rect;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/errors/validation_exception.dart';

class PdfService {
  PdfService({
    Future<Directory> Function()? temporaryDirectory,
    Future<ShareResult> Function(ShareParams)? shareFile,
    DateTime Function()? now,
    Future<pw.ThemeData> Function()? pdfTheme,
  }) : _pdfTheme = pdfTheme ?? _loadTheme,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _shareFile = shareFile ?? SharePlus.instance.share,
       _now = now ?? DateTime.now;

  final Future<Directory> Function() _temporaryDirectory;
  final Future<ShareResult> Function(ShareParams) _shareFile;
  final DateTime Function() _now;
  final Future<pw.ThemeData> Function() _pdfTheme;

  static Future<pw.ThemeData> _loadTheme() async {
    final regular = pw.Font.ttf(
      await rootBundle.load('lib/core/services/fonts/Roboto-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('lib/core/services/fonts/Roboto-Bold.ttf'),
    );
    return pw.ThemeData.withFont(base: regular, bold: bold);
  }

  static final _primary = PdfColor.fromHex('#2755FF');
  static final _ink = PdfColor.fromHex('#182341');

  Future<File> create({
    required List<Expense> expenses,
    required Category category,
    required UserProfile profile,
  }) async {
    if (expenses.any((expense) => expense.currency != 'USD')) {
      throw const ValidationException('Only USD expenses can be exported.');
    }
    try {
      final document = pw.Document(
        theme: await _pdfTheme(),
        title: 'Expense Tracker - ${category.name}',
        author: profile.fullName,
      );
      final items = <pw.Widget>[
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(
            color: _primary,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'Expense Tracker',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.SizedBox(height: 18),
        pw.Text(
          'Exported by: ${profile.fullName}',
          style: pw.TextStyle(fontSize: 12, color: _ink),
        ),
        pw.Text('Email: ${profile.email}'),
        pw.Text('Export date: ${_date(_now())}'),
        pw.Text('Category: ${category.name}'),
        pw.SizedBox(height: 22),
        pw.Text(
          'Expenses (${expenses.length})',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
            color: _primary,
          ),
        ),
        pw.SizedBox(height: 10),
      ];

      if (expenses.isEmpty) {
        items.add(pw.Text('No expenses to export.'));
      }
      final imageBudget = _ImageBudget();
      for (final expense in expenses) {
        items.addAll(await _expenseWidgets(expense, category, imageBudget));
      }

      final total = expenses.fold<double>(
        0,
        (sum, expense) => sum + expense.amount,
      );
      items.addAll([
        pw.SizedBox(height: 14),
        pw.Divider(color: _primary),
        pw.Text(
          'Total: \$${_amount(total)}',
          style: pw.TextStyle(
            color: _primary,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ]);

      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          maxPages: items.length * 2 + 20,
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Expense Tracker - ${context.pageNumber}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            ),
          ),
          build: (_) => items,
        ),
      );

      final directory = Directory(
        '${(await _temporaryDirectory()).path}/expense_reports',
      );
      await directory.create(recursive: true);
      final random = Random.secure();
      final token = List<int>.generate(
        16,
        (_) => random.nextInt(256),
      ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
      final output = File('${directory.path}/expense-report-$token.pdf');
      try {
        await output.writeAsBytes(await document.save(), flush: true);
      } catch (_) {
        if (await output.exists()) await output.delete();
        rethrow;
      }
      return output;
    } catch (_) {
      throw const ValidationException(
        'Could not create the PDF report. Please try again.',
      );
    }
  }

  Future<void> share(File file) async {
    try {
      if (!await file.exists()) {
        throw const FileSystemException('PDF report is unavailable.');
      }
      await _shareFile(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          title: 'Expense Tracker report',
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );
    } catch (_) {
      throw const ValidationException(
        'Could not share the PDF report. Please try again.',
      );
    }
  }

  Future<List<pw.Widget>> _expenseWidgets(
    Expense expense,
    Category category,
    _ImageBudget imageBudget,
  ) async {
    final widgets = <pw.Widget>[
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F2F5FF'),
          border: pw.Border(left: pw.BorderSide(color: _primary, width: 3)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              expense.name,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Date: ${_date(expense.date)}    Amount: ${expense.currency.toUpperCase()} ${_amount(expense.amount)}',
            ),
            pw.Text(
              'Status: ${_status(expense.status)}    Category: ${category.name}',
            ),
          ],
        ),
      ),
    ];
    final description = expense.description?.trim();
    if (description != null && description.isNotEmpty) {
      final normalized = description.replaceAll(RegExp(r'\s+'), ' ');
      for (var start = 0; start < normalized.length; start += 300) {
        final end = min(start + 300, normalized.length);
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, top: 3),
            child: pw.Text('Description: ${normalized.substring(start, end)}'),
          ),
        );
      }
    }
    final imagePath = expense.imagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      final receipt = await _receiptWidget(imagePath, imageBudget);
      if (receipt != null) widgets.add(receipt);
    }
    widgets.add(pw.SizedBox(height: 14));
    return widgets;
  }

  static Future<pw.Widget?> _receiptWidget(
    String path,
    _ImageBudget budget,
  ) async {
    try {
      final extension = path.toLowerCase();
      final jpeg = extension.endsWith('.jpg') || extension.endsWith('.jpeg');
      final png = extension.endsWith('.png');
      if (!jpeg && !png) return null;

      final image = File(path);
      if (!await image.exists()) return null;
      final length = await image.length();
      if (length == 0 ||
          length > _ImageBudget.maxFileBytes ||
          length > budget.remainingBytes) {
        return null;
      }
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty ||
          bytes.length > _ImageBudget.maxFileBytes ||
          bytes.length > budget.remainingBytes) {
        return null;
      }
      if (jpeg && !_hasPrefix(bytes, [0xff, 0xd8, 0xff])) return null;
      if (png && !_hasPrefix(bytes, [137, 80, 78, 71, 13, 10, 26, 10])) {
        return null;
      }

      final provider = pw.MemoryImage(bytes);
      final width = provider.width;
      final height = provider.height;
      if (width == null ||
          width <= 0 ||
          height == null ||
          height <= 0 ||
          width * height > _ImageBudget.maxPixels ||
          width * height > budget.remainingPixels) {
        return null;
      }
      PdfImage.file(PdfDocument(), bytes: bytes);
      budget.remainingBytes -= bytes.length;
      budget.remainingPixels -= width * height;
      return pw.Padding(
        padding: const pw.EdgeInsets.only(left: 12, top: 5),
        child: pw.Image(
          provider,
          height: 125,
          width: 170,
          fit: pw.BoxFit.contain,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static bool _hasPrefix(Uint8List bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var index = 0; index < prefix.length; index++) {
      if (bytes[index] != prefix[index]) return false;
    }
    return true;
  }

  static String _status(ExpenseStatus status) => switch (status) {
    ExpenseStatus.draft => 'Draft',
    ExpenseStatus.submitted => 'Submitted',
    ExpenseStatus.inProgress => 'In review',
    ExpenseStatus.finished => 'Finished',
    ExpenseStatus.rejected => 'Rejected',
  };

  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String _amount(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final digits = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '$digits.${parts.last}';
  }
}

class _ImageBudget {
  static const maxFileBytes = 12 * 1024 * 1024;
  static const maxPixels = 16 * 1024 * 1024;

  int remainingBytes = 32 * 1024 * 1024;
  int remainingPixels = 32 * 1024 * 1024;
}
