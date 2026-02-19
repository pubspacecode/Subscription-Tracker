
import 'dart:io';
import '../../../../core/constants/parsing_constants.dart';
import 'package:csv/csv.dart' as csv_pkg;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../data/subscription_model.dart';
import '../data/service_repository.dart';

final statementParserServiceProvider = Provider<StatementParserService>((ref) {
  return StatementParserService(ref.read(serviceRepositoryProvider));
});

class Transaction {
  final DateTime date;
  final String description;
  final double amount;

  Transaction({required this.date, required this.description, required this.amount});

  @override
  String toString() => '$date - $description - $amount';
}

class DetectedSubscription {
  final String name;
  final double amount;
  final BillingCycle billingCycle;
  final DateTime nextDate;
  final DateTime lastPaymentDate;
  final int frequencyCount;
  final double confidence; // 0.0 to 1.0
  final int? iconCodePoint;
  final int? colorValue;

  DetectedSubscription({
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.nextDate,
    required this.lastPaymentDate,
    required this.frequencyCount,
    required this.confidence,
    this.iconCodePoint,
    this.colorValue,
  });
}

class StatementParserService {
  final ServiceRepository _serviceRepository;

  StatementParserService(this._serviceRepository);

  Future<List<DetectedSubscription>> pickAndParseFile() async {
    try {
      // Request storage permission on Android before picking files
      if (!kIsWeb) {
        final Permission perm = (await Permission.photos.status).isGranted
            ? Permission.photos
            : Permission.storage;
        final status = await perm.request();
        if (!status.isGranted && !status.isLimited) {
          if (status.isPermanentlyDenied) await openAppSettings();
          return [];
        }
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final extension = result.files.single.extension?.toLowerCase();

        List<Transaction> transactions = [];
        if (extension == 'pdf') {
          transactions = await _parsePDF(file);
        } else if (extension == 'csv') {
          transactions = await _parseCSV(file);
        }

        return analyzeRecurrence(transactions);
      }
    } catch (e) {
      debugPrint('Error picking/parsing file: $e');
    }
    return [];
  }

  Future<List<Transaction>> _parsePDF(File file) async {
    try {
       // Load the existing PDF document.
       final PdfDocument document = PdfDocument(inputBytes: file.readAsBytesSync());

       // Create a new instance of the PdfTextExtractor.
       final PdfTextExtractor extractor = PdfTextExtractor(document);

       // Extract all the text from the document.
       String text = extractor.extractText();
       debugPrint('PDF Extracted Text (first 500 chars): ${text.substring(0, text.length > 500 ? 500 : text.length)}');

       // Dispose the document.
       document.dispose();
       
       return parseText(text);
    } catch (e) {
       debugPrint('Error parsing PDF: $e');
       return [];
    }
  }

  List<Transaction> parseText(String text) {
       final transactions = <Transaction>[];
       final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
       debugPrint('Text Non-empty Line count: ${lines.length}');

       // Regex definitions
       // Matches: DD/MM/YYYY, YYYY-MM-DD, DD-MM-YYYY, D MMM YYYY (en/es/fr/etc)
       // Includes unicode for accents (e.g. Février, Março)
       final dateRegex = RegExp(r'(\d{1,4}[/-]\d{1,2}[/-]\d{2,4})|(\d{1,2}\s+(?:de\s+)?[a-zA-Z\u00C0-\u00FF]{3,}\s+(?:de\s+)?\d{2,4})');
       
       // Stricter amount regex to avoid matching years or generic numbers
       // Supports symbol at start or end: $10.00, 10.00 €, 10,00 kr
       final amountRegex = RegExp(r'^[+\-]?[\$€£¥₹]?\s?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2}))\s?[\$€£¥₹krKzR$Fr¥KčFtRp₪₩฿₺₫₽]?$');

       for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          
          // 1. Check if line starts with a Date
          final dateMatch = dateRegex.firstMatch(line);
          if (dateMatch != null) {
              try {
                  DateTime? date = _parseDate(dateMatch.group(0)!);
                  if (date == null) continue;

                  // Look ahead for Description and Amount in next 1-3 lines
                  String description = '';
                  double amount = 0.0;
                  
                  // Heuristic: Usually Date -> Desc -> Amount OR Date -> Amount -> Desc
                  // We'll peek at next 3 lines
                  
                  bool foundAmount = false;
                  bool foundDesc = false;

                  for (int j = 1; j <= 3 && i + j < lines.length; j++) {
                     final nextLine = lines[i + j].trim();
                     
                     // Helper to check if line is an amount
                     final amtMatch = amountRegex.firstMatch(nextLine);
                     if (amtMatch != null && !foundAmount) {
                        String amountStr = amtMatch.group(1)!.replaceAll(',', '.');
                        // Remove thousands separator if likely
                        if (amountStr.contains('.') && amountStr.indexOf('.') < amountStr.length - 3) {
                             amountStr = amountStr.replaceAll('.', '');
                        }
                        amount = double.tryParse(amountStr) ?? 0.0;
                        foundAmount = true;
                        continue; // Consumed as amount
                     }

                     // If not amount and not a date, assume description
                     // Also avoid lines that look like a balance (usually very high numbers, but hard to distinguish without context)
                     if (!foundDesc && dateRegex.firstMatch(nextLine) == null) {
                         // Simple heuristic: Ignore if it looks like a number but didn't match strict amount
                         if (double.tryParse(nextLine.replaceAll(RegExp(r'[^0-9.]'), '')) == null || nextLine.contains(RegExp(r'[a-zA-Z]'))) {
                             description = nextLine;
                             foundDesc = true;
                         }
                     }
                  }

                  if (foundAmount && foundDesc) {
                     debugPrint('Parsed Tx: $date | $amount | $description');
                     transactions.add(Transaction(date: date, description: description, amount: amount));
                     // Skip the lines we consumed? 
                     // Simple approach: don't manually skip, just let loop continue. 
                     // Risk: 'Date' line might be re-parsed as description for previous? No, we check dateRegex first.
                  }
              } catch (e) {
                  debugPrint('Error parsing block starting at line $i: $e');
              }
          }
       }
       debugPrint('Total transactions found in text: ${transactions.length}');
       return transactions;
  }

  Future<List<Transaction>> _parseCSV(File file) async {
    try {
      final input = file.readAsStringSync();
      debugPrint('Parsing CSV file: ${file.path}');
      final lines = input.split(RegExp(r'\r\n|\n|\r'));
      debugPrint('Read ${lines.length} lines');

      // Regex to split by comma, respecting quotes
      final csvSplit = RegExp(r',(?=(?:[^"]*"[^"]*")*[^"]*$)');

      final fields = <List<String>>[];
      for (var line in lines) {
         // Handle quoted values by removing surrounding quotes
         final row = line.split(csvSplit).map((e) {
           var val = e.trim();
           if (val.startsWith('"') && val.endsWith('"')) {
             val = val.substring(1, val.length - 1);
           }
           return val.replaceAll('""', '"'); // Handle escaped quotes
         }).toList();
         fields.add(row);
      }

      debugPrint('Parsed ${fields.length} rows');
      
      final transactions = <Transaction>[];
      
      // Heuristic: Check first few rows to identify columns
      int dateCol = -1;
      int amountCol = -1;
      int descCol = -1;

      for (var i = 0; i < fields.length; i++) {
        final row = fields[i];
        if (row.isEmpty) continue;

        // Skip header if found
        if (i < 5) { // Check first 5 rows for header
           final rowString = row.join(' ').toLowerCase();
           if (rowString.contains('date') || rowString.contains('amount')) {
              // Try to find indices
              for (var j = 0; j < row.length; j++) {
                  final cell = row[j].toLowerCase();
                  if (ParsingConstants.dateKeywords.any((k) => cell.contains(k))) dateCol = j;
                  if (ParsingConstants.amountKeywords.any((k) => cell.contains(k))) amountCol = j;
                  if (ParsingConstants.descriptionKeywords.any((k) => cell.contains(k))) descCol = j;
              }
              debugPrint('Found Header at row $i: Date:$dateCol, Amount:$amountCol, Desc:$descCol');
              if (dateCol != -1 && amountCol != -1) continue; // Skip the header row itself
           }
        }


        // Add default indices if not found yet
        if (dateCol == -1) dateCol = 0;
        if (amountCol == -1) amountCol = 1; // Often 2nd or last
        if (descCol == -1) descCol = 2; // Often middle

        if (row.length > dateCol && row.length > amountCol) {
            try {
              DateTime? date = _parseDate(row[dateCol].toString());
              double amount = double.tryParse(row[amountCol].toString().replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
              String desc = row.length > descCol ? row[descCol].toString() : 'Unknown';
              
              if (date != null && amount > 0) {
                 transactions.add(Transaction(date: date, description: desc, amount: amount));
              }
            } catch (e) {
              // ignore
            }
        }
      }
      return transactions;
    } catch (e) {
      debugPrint('Error parsing CSV: $e');
      return [];
    }
  }

  DateTime? _parseDate(String dateStr) {
    // Try multiple formats
    // Added Spanish locale 'es' to support 'Ene', 'Dic' etc.
    final locales = ['en_US', 'es_ES'];
    final patterns = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'MM/dd/yyyy',
      'yyyy-MM-dd',
      'd MMM yyyy',
      'd MMMM yyyy', // Full month name
      'dd MMM yyyy',
    ];

    // Try multiple formats with supported locales
    for (var locale in ParsingConstants.supportedLocales) {
      for (var pattern in patterns) {
        try {
          final format = DateFormat(pattern, locale);
          final d = format.parse(dateStr);
          return d;
        } catch (e) {
          // continue
        }
      }
    }
    debugPrint('Failed to parse date: $dateStr');
    return null;
  }

  List<DetectedSubscription> analyzeRecurrence(List<Transaction> transactions) {
     if (transactions.isEmpty) return [];

     // 1. Group by cleaned description
     final Map<String, List<Transaction>> groups = {};
     
     for (var tx in transactions) {
        // Normalize: "Netflix.com* 123" -> "Netflix"
        // This is complex, but for MVP we'll fuzzy match against known services OR just take first 2 words
        String cleaned = tx.description.replaceAll(RegExp(r'[0-9*#]'), '').trim();
        if (cleaned.length > 20) cleaned = cleaned.substring(0, 20); // truncate
        
        int? matchedIcon;
        int? matchedColor;
        
        // Check against known services
        final allServices = _serviceRepository.getAllServices();
        for (var service in allServices) {
           if (tx.description.toLowerCase().contains(service.name.toLowerCase())) {
             cleaned = service.name;
             matchedIcon = service.iconCodePoint;
             matchedColor = service.colorValue;
             break;
           }
        }

        if (!groups.containsKey(cleaned)) {
           groups[cleaned] = [];
        }
        groups[cleaned]!.add(tx);
     }

     final List<DetectedSubscription> candidates = [];

      // 2. Analyze intervals
      groups.forEach((name, txs) {
         if (txs.length < 2) return;

         txs.sort((a, b) => a.date.compareTo(b.date));
         
         final List<int> intervals = [];
         for (int i = 0; i < txs.length - 1; i++) {
            intervals.add(txs[i+1].date.difference(txs[i].date).inDays);
         }

         // Calculate average interval
         if (intervals.isEmpty) return;
         double avg = intervals.reduce((a, b) => a + b) / intervals.length;

         BillingCycle? cycle;
         if (avg >= 25 && avg <= 35) {
            cycle = BillingCycle.monthly;
         } else if (avg >= 360 && avg <= 370) {
            cycle = BillingCycle.yearly;
         } else if (avg >= 6 && avg <= 8) {
            cycle = BillingCycle.weekly;
         }

         if (cycle != null) {
            // Lookup service details for icon
            int? matchedIcon;
            int? matchedColor;
            
            final allServices = _serviceRepository.getAllServices();
            for (var service in allServices) {
                if (service.name == name) {
                    matchedIcon = service.iconCodePoint;
                    matchedColor = service.colorValue;
                    break;
                }
            }

            // It's a recurrence!
            candidates.add(DetectedSubscription(
              name: name,
              amount: txs.last.amount,
              billingCycle: cycle,
              nextDate: _calculateNextDate(txs.last.date, cycle),
              lastPaymentDate: txs.last.date,
              frequencyCount: txs.length,
              confidence: 0.8, // MVP Hardcoded
              iconCodePoint: matchedIcon,
              colorValue: matchedColor,
            ));
         }
      });

     return candidates;
  }

  DateTime _calculateNextDate(DateTime lastDate, BillingCycle cycle) {
     if (cycle == BillingCycle.monthly) {
       return DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
     } else if (cycle == BillingCycle.yearly) {
       return DateTime(lastDate.year + 1, lastDate.month, lastDate.day);
     } else {
       return lastDate.add(const Duration(days: 7));
     }
  }
}
