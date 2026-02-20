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
  Currency('INR', '₹'),
  Currency('JPY', '¥'),
  Currency('CNY', '¥'),
  Currency('AUD', '\$'),
  Currency('CAD', '\$'),
  Currency('CHF', 'Fr'),
  Currency('HKD', '\$'),
  Currency('SGD', '\$'),
  Currency('SEK', 'kr'),
  Currency('KRW', '₩'),
  Currency('NOK', 'kr'),
  Currency('NZD', '\$'),
  Currency('DKK', 'kr'),
  Currency('AED', 'د.إ'),
  Currency('AFN', '؋'),
  Currency('ALL', 'L'),
  Currency('AMD', '֏'),
  Currency('ANG', 'ƒ'),
  Currency('AOA', 'Kz'),
  Currency('ARS', '\$'),
  Currency('AWG', 'ƒ'),
  Currency('AZN', '₼'),
  Currency('BAM', 'KM'),
  Currency('BBD', '\$'),
  Currency('BDT', '৳'),
  Currency('BGN', 'лв'),
  Currency('BHD', '.د.ب'),
  Currency('BIF', 'FBu'),
  Currency('BMD', '\$'),
  Currency('BND', '\$'),
  Currency('BOB', 'Bs.'),
  Currency('BRL', 'R\$'),
  Currency('BSD', '\$'),
  Currency('BTN', 'Nu.'),
  Currency('BWP', 'P'),
  Currency('BYN', 'Br'),
  Currency('BZD', '\$'),
  Currency('CLP', '\$'),
  Currency('COP', '\$'),
  Currency('CRC', '₡'),
  Currency('CUP', '\$'),
  Currency('CVE', '\$'),
  Currency('CZK', 'Kč'),
  Currency('DJF', 'Fdj'),
  Currency('DOP', '\$'),
  Currency('DZD', 'د.ج'),
  Currency('EGP', 'E£'),
  Currency('ERN', 'Nfk'),
  Currency('ETB', 'Br'),
  Currency('FJD', '\$'),
  Currency('FKP', '£'),
  Currency('GEL', '₾'),
  Currency('GHS', '₵'),
  Currency('GIP', '£'),
  Currency('GMD', 'D'),
  Currency('GNF', 'FG'),
  Currency('GTQ', 'Q'),
  Currency('GYD', '\$'),
  Currency('HNL', 'L'),
  Currency('HUF', 'Ft'),
  Currency('IDR', 'Rp'),
  Currency('ILS', '₪'),
  Currency('IQD', 'ع.د'),
  Currency('ISK', 'kr'),
  Currency('JMD', '\$'),
  Currency('JOD', 'د.ا'),
  Currency('KES', 'KSh'),
  Currency('KGS', 'с'),
  Currency('KHR', '៛'),
  Currency('KMF', 'CF'),
  Currency('KWD', 'د.ك'),
  Currency('KYD', '\$'),
  Currency('KZT', '₸'),
  Currency('LAK', '₭'),
  Currency('LBP', '£'),
  Currency('LKR', 'Rs'),
  Currency('LRD', '\$'),
  Currency('LSL', 'L'),
  Currency('LYD', 'ل.د'),
  Currency('MAD', 'د.م.'),
  Currency('MDL', 'L'),
  Currency('MGA', 'Ar'),
  Currency('MKD', 'ден'),
  Currency('MMK', 'K'),
  Currency('MNT', '₮'),
  Currency('MOP', 'P'),
  Currency('MRU', 'UM'),
  Currency('MUR', '₨'),
  Currency('MVR', 'Rf'),
  Currency('MWK', 'MK'),
  Currency('MXN', '\$'),
  Currency('MYR', 'RM'),
  Currency('MZN', 'MT'),
  Currency('NAD', '\$'),
  Currency('NGN', '₦'),
  Currency('NIO', 'C\$'),
  Currency('NPR', '₨'),
  Currency('OMR', 'ر.ع.'),
  Currency('PAB', 'B/.'),
  Currency('PEN', 'S/.'),
  Currency('PGK', 'K'),
  Currency('PHP', '₱'),
  Currency('PKR', '₨'),
  Currency('PLN', 'zł'),
  Currency('PYG', 'Gs'),
  Currency('QAR', 'ر.ق'),
  Currency('RON', 'lei'),
  Currency('RSD', 'дин.'),
  Currency('RUB', '₽'),
  Currency('RWF', 'FRw'),
  Currency('SAR', 'ر.س'),
  Currency('SBD', '\$'),
  Currency('SCR', '₨'),
  Currency('SDG', 'ج.س.'),
  Currency('SHP', '£'),
  Currency('SLL', 'Le'),
  Currency('SOS', 'S'),
  Currency('SRD', '\$'),
  Currency('SSP', '£'),
  Currency('STN', 'Db'),
  Currency('SVC', '\$'),
  Currency('SYP', '£'),
  Currency('SZL', 'L'),
  Currency('THB', '฿'),
  Currency('TJS', 'SM'),
  Currency('TMT', 'm'),
  Currency('TND', 'د.ت'),
  Currency('TOP', 'T\$'),
  Currency('TRY', '₺'),
  Currency('TTD', '\$'),
  Currency('TWD', 'NT\$'),
  Currency('TZS', 'TSh'),
  Currency('UAH', '₴'),
  Currency('UGX', 'USh'),
  Currency('UYU', '\$U'),
  Currency('UZS', 'сўм'),
  Currency('VES', 'Bs.S'),
  Currency('VND', '₫'),
  Currency('VUV', 'VT'),
  Currency('WST', 'WS\$'),
  Currency('XAF', 'FCFA'),
  Currency('XCD', '\$'),
  Currency('XOF', 'CFA'),
  Currency('XPF', '₣'),
  Currency('YER', '﷼'),
  Currency('ZAR', 'R'),
  Currency('ZMW', 'ZK'),
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
