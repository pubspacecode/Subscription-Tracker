import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui; // Added for explicit Rect usage
import 'package:flutter/material.dart' hide Rect; // Avoid conflict if any
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../database/hive_service.dart';
import '../../features/subscriptions/data/subscription_model.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Formatter for dates in the report
  final DateFormat _df = DateFormat('MMM dd, yyyy');
  final DateFormat _tf = DateFormat('yyyy-MM-dd_HHmm');

  /// ── CSV Export ────────────────────────────────────────────────────────────

  Future<void> exportToCSV() async {
    final subscriptions = HiveService.subscriptionBox.values.toList();
    
    // Headers
    List<List<dynamic>> rows = [
      [
        'Name',
        'Amount',
        'Currency',
        'Billing Cycle',
        'Category',
        'Next Renewal',
        'Status',
        'Payment Method',
        'Notes',
        'Created At'
      ]
    ];

    // Data rows
    for (var s in subscriptions) {
      if (s.isDeleted) continue;
      rows.add([
        s.name,
        s.amount,
        s.currency,
        s.billingCycle.name,
        s.category,
        _df.format(s.nextRenewalDate),
        s.isActive ? 'Active' : 'Inactive',
        s.paymentMethod ?? '',
        s.notes ?? '',
        _df.format(s.createdAt)
      ]);
    }

    // Manual CSV generation to avoid package issues
    final csvData = rows.map((row) {
      return row.map((cell) {
        String val = cell.toString();
        // If it contains comma, newline or double quotes, wrap in quotes and escape internal quotes
        if (val.contains(',') || val.contains('\n') || val.contains('"')) {
          val = '"${val.replaceAll('"', '""')}"';
        }
        return val;
      }).join(',');
    }).join('\n');
    
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/subscriptions_export_${_tf.format(DateTime.now())}.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: 'Subscription Tracker CSV Export');
  }

  /// ── PDF Export ────────────────────────────────────────────────────────────

  Future<void> exportToPDF() async {
    final subscriptions = HiveService.subscriptionBox.values.where((s) => !s.isDeleted).toList();
    
    // Create a new PDF document
    PdfDocument document = PdfDocument();
    
    // Header section
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;
    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold);
    final PdfFont subTitleFont = PdfStandardFont(PdfFontFamily.helvetica, 14);
    final PdfFont normalFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final PdfFont boldFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

    // Title
    graphics.drawString('Subscription Tracker', titleFont,
        bounds: const ui.Rect.fromLTWH(0, 0, 0, 0));
    
    graphics.drawString('Financial Report', subTitleFont,
        bounds: const ui.Rect.fromLTWH(0, 30, 0, 0));
    
    graphics.drawString('Report Generated: ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}', normalFont,
        bounds: const ui.Rect.fromLTWH(0, 50, 0, 0));

    // Summary calculation
    double monthlyTotal = 0;
    for (var s in subscriptions) {
      if (!s.isActive) continue;
      double monthly = s.amount;
      if (s.billingCycle == BillingCycle.yearly) monthly /= 12;
      else if (s.billingCycle == BillingCycle.weekly) monthly *= 4.33;
      monthlyTotal += monthly;
    }

    // Draw Summary Box
    graphics.drawRectangle(
        brush: PdfBrushes.lightGray,
        bounds: const ui.Rect.fromLTWH(0, 80, 500, 40));
    
    graphics.drawString('ESTIMATED MONTHLY SPEND', boldFont,
        bounds: const ui.Rect.fromLTWH(10, 85, 0, 0));
    
    graphics.drawString('${monthlyTotal.toStringAsFixed(2)} (Projected average)', normalFont,
        bounds: const ui.Rect.fromLTWH(10, 100, 0, 0));

    // Detailed Table
    PdfGrid grid = PdfGrid();
    grid.columns.add(count: 6);
    grid.headers.add(1);

    PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Subscription';
    header.cells[1].value = 'Amount';
    header.cells[2].value = 'Cycle';
    header.cells[3].value = 'Category';
    header.cells[4].value = 'Renewal';
    header.cells[5].value = 'Status';

    // Apply header style
    header.style = PdfGridRowStyle(
      backgroundBrush: PdfBrushes.darkBlue,
      textBrush: PdfBrushes.white,
      font: boldFont
    );

    for (var s in subscriptions) {
      PdfGridRow row = grid.rows.add();
      row.cells[0].value = s.name;
      row.cells[1].value = '${s.amount} ${s.currency}';
      row.cells[2].value = s.billingCycle.name;
      row.cells[3].value = s.category;
      row.cells[4].value = _df.format(s.nextRenewalDate);
      row.cells[5].value = s.isActive ? 'Active' : 'Paused';
    }

    // Set grid format
    grid.style.cellPadding = PdfPaddings(left: 5, top: 5);
    
    // Draw grid
    grid.draw(
      page: page,
      bounds: const ui.Rect.fromLTWH(0, 140, 0, 0)
    );

    // Footer
    final int pageCount = document.pages.count;
    for (int i = 0; i < pageCount; i++) {
      document.pages[i].graphics.drawString(
          'Generated by Subscription Tracker App', normalFont,
          brush: PdfBrushes.gray,
          bounds: ui.Rect.fromLTWH(0, document.pages[i].getClientSize().height - 20, 0, 0));
    }

    // Save and Share
    List<int> bytes = await document.save();
    document.dispose();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/subscription_report_${_tf.format(DateTime.now())}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Subscription Tracker PDF Report');
  }
}
