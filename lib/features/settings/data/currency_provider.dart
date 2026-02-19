import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/hive_service.dart';

class Currency {
  final String code;
  final String symbol;

  const Currency(this.code, this.symbol);
}

const List<Currency> supportedCurrencies = [
  Currency('USD', '\$'),
  Currency('EUR', '€'),
  Currency('GBP', '£'),
  Currency('AOA', 'Kz'),
  Currency('AUD', '\$'),
  Currency('BRL', 'R\$'),
  Currency('CAD', '\$'),
  Currency('CHF', 'Fr'),
  Currency('CNY', '¥'),
  Currency('CZK', 'Kč'),
  Currency('DKK', 'kr'),
  Currency('HKD', '\$'),
  Currency('HUF', 'Ft'),
  Currency('IDR', 'Rp'),
  Currency('ILS', '₪'),
  Currency('INR', '₹'),
  Currency('JPY', '¥'),
  Currency('KRW', '₩'),
  Currency('MXN', '\$'),
  Currency('MYR', 'RM'),
  Currency('NGN', '₦'),
  Currency('NOK', 'kr'),
  Currency('NZD', '\$'),
  Currency('PHP', '₱'),
  Currency('PLN', 'zł'),
  Currency('RUB', '₽'),
  Currency('SAR', '﷼'),
  Currency('SEK', 'kr'),
  Currency('SGD', '\$'),
  Currency('THB', '฿'),
  Currency('TRY', '₺'),
  Currency('TWD', 'NT\$'),
  Currency('VND', '₫'),
  Currency('ZAR', 'R'),
];

final currencyProvider = NotifierProvider<CurrencyNotifier, Currency>(CurrencyNotifier.new);

class CurrencyNotifier extends Notifier<Currency> {
  static const _storageKey = 'preferred_currency_code';

  @override
  Currency build() {
    return _loadCurrency();
  }

  Currency _loadCurrency() {
    try {
      final box = HiveService.settingsBox;
      final savedCode = box.get(_storageKey, defaultValue: 'USD');
      return supportedCurrencies.firstWhere(
        (c) => c.code == savedCode,
        orElse: () => const Currency('USD', '\$'),
      );
    } catch (e) {
      return const Currency('USD', '\$');
    }
  }

  Future<void> setCurrency(Currency currency) async {
    state = currency;
    final box = HiveService.settingsBox;
    await box.put(_storageKey, currency.code);
  }
}
