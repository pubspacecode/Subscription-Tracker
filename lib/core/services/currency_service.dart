import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/hive_service.dart';

class CurrencyService {
  // Using a free API (e.g., exchangerate-api.com)
  // Base URL for open access endpoint
  static const String _baseUrl = 'https://open.er-api.com/v6/latest';

  Future<Map<String, double>> fetchExchangeRates(String baseCurrency) async {
    try {
      // Check cache first
      final box = HiveService.settingsBox;
      final lastFetchTime = box.get('last_exchange_rate_fetch_$baseCurrency');
      final cachedRates = box.get('exchange_rates_$baseCurrency');

      // If cached and less than 24 hours old, return cached
      if (lastFetchTime != null && cachedRates != null) {
        final lastFetch = DateTime.parse(lastFetchTime);
        if (DateTime.now().difference(lastFetch).inHours < 24) {
          return Map<String, double>.from(jsonDecode(cachedRates));
        }
      }

      // Fetch from API
      final response = await http.get(Uri.parse('$_baseUrl/$baseCurrency'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success') {
          final rates = Map<String, double>.from(data['rates'].map((k, v) => MapEntry(k, (v as num).toDouble())));
          
          // Cache rates
          await box.put('exchange_rates_$baseCurrency', jsonEncode(rates));
          await box.put('last_exchange_rate_fetch_$baseCurrency', DateTime.now().toIso8601String());
          
          return rates;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching exchange rates: $e');
      // Return cached if available even if old
      final box = HiveService.settingsBox;
      final cachedRates = box.get('exchange_rates_$baseCurrency');
      if (cachedRates != null) {
        return Map<String, double>.from(jsonDecode(cachedRates));
      }
      return {};
    }
  }

  // Helper to convert
  double convert(double amount, String fromCurrency, String toCurrency, Map<String, double> rates) {
    if (fromCurrency == toCurrency) return amount;
    
    // Direct conversion if available
    if (rates.containsKey(toCurrency)) {
      return amount * rates[toCurrency]!;
    }
    
    // If base is not 'fromCurrency', we might need cross rate (not handled in this simple version, 
    // but the API returns all rates relative to base. So if we fetch for 'USD', we get 'USD' -> 'INR'.
    // If we have 'EUR' -> 'INR', we need rates for both or convert via USD).
    // For MVP, let's assume we fetch rates for 'USD' as base always, and convert:
    // Amount(From) / Rate(From) * Rate(To)
    
    double rateFrom = rates[fromCurrency] ?? 1.0;
    double rateTo = rates[toCurrency] ?? 1.0;
    
    return (amount / rateFrom) * rateTo;
  }
}
