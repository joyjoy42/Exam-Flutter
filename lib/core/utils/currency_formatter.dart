import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _format = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: AppConstants.currencyCode,
    decimalDigits: 0,
  );

  /// Renders e.g. 50000 -> "50 000 XOF" per the spec's example formatting.
  static String format(num amount) => _format.format(amount).trim();
}
