import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/currency_service.dart';

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});

final exchangeRateProvider = FutureProvider<Map<String, double>>((ref) async {
  final service = ref.watch(currencyServiceProvider);
  // Fetch rates with USD as base for now
  return service.fetchExchangeRates('USD');
});
