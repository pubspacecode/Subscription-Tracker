import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import '../data/service_repository.dart';
import '../data/subscription_model.dart';
import 'statement_parser_service.dart';

final subscriptionParserServiceProvider = Provider<SubscriptionParserService>((ref) {
  return SubscriptionParserService(
    ref.read(serviceRepositoryProvider),
    ref.read(statementParserServiceProvider),
  );
});

class ParsedSubscriptionData {
  final String? amount;
  final DateTime? date;
  final String? name;
  final int? iconCodePoint;
  final int? colorValue;
  final String? currency;
  final BillingCycle? billingCycle;
  final List<DetectedSubscription>? detectedSubscriptions;

  ParsedSubscriptionData({
    this.amount,
    this.date,
    this.name,
    this.iconCodePoint,
    this.colorValue,
    this.currency,
    this.billingCycle,
    this.detectedSubscriptions,
  });
}

class SubscriptionParserService {
  final ServiceRepository _serviceRepository;
  final StatementParserService _statementParserService;

  SubscriptionParserService(this._serviceRepository, this._statementParserService);

  Future<ParsedSubscriptionData> parseDocument(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String text = recognizedText.text;
      await textRecognizer.close();

      // Unified Processing: Check if this Text looks like a statement
      List<DetectedSubscription>? detectedSubscriptions;
      try {
         final transactions = _statementParserService.parseText(text);
         // Heuristic: If we find at least 2 transactions, likely a statement
         if (transactions.length >= 2) {
             debugPrint('Detected potential statement with ${transactions.length} transactions');
             detectedSubscriptions = _statementParserService.analyzeRecurrence(transactions);
         }
      } catch (e) {
        debugPrint('Statement check failed: $e');
      }

      String? foundAmount;
      DateTime? foundDate;
      String? foundName;
      int? foundIconCodePoint;
      int? foundColorValue;
      String? foundCurrency;
      BillingCycle? foundBillingCycle;

      // 0. Entity Extraction (Money & Date)
      final extractor = EntityExtractor(language: EntityExtractorLanguage.english);
      try {
        final List<EntityAnnotation> annotations = await extractor.annotateText(text);
        
        for (final annotation in annotations) {
          for (final entity in annotation.entities) {
            if (entity is MoneyEntity) {
              foundAmount = '${entity.integerPart}.${entity.fractionPart.toString().padLeft(2, '0')}';
              foundCurrency = entity.unnormalizedCurrency;
            } else if (entity is DateTimeEntity) {
              try {
                // Use timestamp (ms since epoch)
                final dt = DateTime.fromMillisecondsSinceEpoch(entity.timestamp);
                
                if (dt.year > 2000 && dt.year < 2100) {
                   foundDate = dt;
                   // If date is in the past, assume next year (for renewals)
                   if (foundDate!.isBefore(DateTime.now())) {
                      foundDate = DateTime(foundDate!.year + 1, foundDate!.month, foundDate!.day);
                   }
                }
              } catch (e) {
                // ignore invalid dates
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Entity Extraction failed: $e');
      } finally {
        await extractor.close();
      }

      // 1. Fallback / Regex Amount (If Entity Extraction missed it)
      if (foundAmount == null) {
          final amountRegex = RegExp(r'(?:[\$€£¥₹]|zł|kr|R\$|[A-Z]{3})?[\s-]?(\d{1,5}(?:[.,]\d{2})?)[\s-]?(?:[\$€£¥₹]|zł|kr|R\$|[A-Z]{3})?');
          // ... (existing regex logic) ...
          final matches = amountRegex.allMatches(text);
          final List<double> parsedAmounts = [];
          for (final match in matches) {
            String? valueStr = match.group(1);
            if (valueStr != null) {
              valueStr = valueStr.replaceAll(',', '.');
              final value = double.tryParse(valueStr);
              if (value != null) {
                 if (value >= 2000 && value <= 2030 && !valueStr.contains('.')) continue; // Year filter
                 if (value < 1.0) continue; 
                 parsedAmounts.add(value);
              }
            }
          }
          if (parsedAmounts.isNotEmpty) {
            parsedAmounts.sort();
            foundAmount = parsedAmounts.last.toStringAsFixed(2);
          }
      }

      // 2. Frequency Detection (Regex)
      final lowerText = text.toLowerCase();
      if (lowerText.contains('/mo') || lowerText.contains('per month') || lowerText.contains('monthly')) {
        foundBillingCycle = BillingCycle.monthly;
      } else if (lowerText.contains('/yr') || lowerText.contains('per year') || lowerText.contains('yearly') || lowerText.contains('annually')) {
        foundBillingCycle = BillingCycle.yearly;
      } else if (lowerText.contains('/wk') || lowerText.contains('per week') || lowerText.contains('weekly')) {
        foundBillingCycle = BillingCycle.weekly;
      }

      // 2. Find Date
      final dateRegex = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-]?(\d{2,4})?');
      final dateMatch = dateRegex.firstMatch(text);
      if (dateMatch != null) {
          try {
             int p1 = int.parse(dateMatch.group(1)!);
             int p2 = int.parse(dateMatch.group(2)!);
             int p3 = dateMatch.group(3) != null ? int.parse(dateMatch.group(3)!) : DateTime.now().year;
             
             if (p3 < 100) p3 += 2000;
             
             int month = p1 <= 12 ? p1 : p2;
             int day = p1 <= 12 ? p2 : p1;
             
             if (month > 0 && month <= 12 && day > 0 && day <= 31) {
                foundDate = DateTime(p3, month, day);
                if (foundDate!.isBefore(DateTime.now())) {
                    foundDate = DateTime(foundDate!.year + 1, foundDate!.month, foundDate!.day);
                }
             }
          } catch (e) {
             debugPrint('Date parse error: $e');
          }
      }

      // 3. Find Service Name
      final allServices = _serviceRepository.getAllServices();
      // Sort by length so we match "Youtube Music" before "Youtube"
      allServices.sort((a, b) => b.name.length.compareTo(a.name.length));
      
      for (final service in allServices) {
        if (text.toLowerCase().contains(service.name.toLowerCase())) {
          foundName = service.name;
          foundIconCodePoint = service.iconCodePoint;
          foundColorValue = service.colorValue;
          break;
        }
      }

      return ParsedSubscriptionData(
        amount: foundAmount,
        date: foundDate,
        name: foundName,
        iconCodePoint: foundIconCodePoint,
        colorValue: foundColorValue,
        currency: foundCurrency,
        billingCycle: foundBillingCycle,
        detectedSubscriptions: detectedSubscriptions,
      );

    } catch (e) {
      debugPrint('Parsing failed: $e');
      return ParsedSubscriptionData(); // Return empty on error
    }
  }
}
